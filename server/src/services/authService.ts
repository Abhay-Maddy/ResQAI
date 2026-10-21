import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { hash, verify, Algorithm } from '@node-rs/argon2';
import { db } from '../db/database';
import { logAuditEvent } from './auditService';

const JWT_SECRET = process.env.JWT_SECRET || 'resqai_disaster_jwt_secret_dev_key_2026';
const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_DAYS = 7;

export interface TokenPayload {
  userId: string;
  role: string;
  jurisdictionRegionId?: string | null;
  name: string;
  sessionId: string;
}

export async function hashPassword(plainText: string): Promise<string> {
  return await hash(plainText, { algorithm: Algorithm.Argon2id });
}

export async function verifyPasswordHash(hashStr: string, plainText: string): Promise<boolean> {
  try {
    return await verify(hashStr, plainText);
  } catch {
    return false;
  }
}

function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

// FR-1: Refresh Token Generation & Session Storage
export function createSessionAndTokens(
  user: { id: string; name: string; role: string; jurisdiction_region_id?: string | null },
  userAgent = 'Unknown Client',
  ipAddress = '127.0.0.1'
) {
  const sessionId = `SES-${crypto.randomBytes(8).toString('hex')}`;
  const rawRefreshToken = crypto.randomBytes(32).toString('hex');
  const refreshTokenHash = hashToken(rawRefreshToken);

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + REFRESH_TOKEN_DAYS);

  // Store session in DB
  const stmt = db.prepare(`
    INSERT INTO user_sessions (id, user_id, refresh_token_hash, user_agent, ip_address, expires_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `);
  stmt.run(sessionId, user.id, refreshTokenHash, userAgent, ipAddress, expiresAt.toISOString());

  // Generate short-lived Access JWT
  const payload: TokenPayload = {
    userId: user.id,
    role: user.role,
    jurisdictionRegionId: user.jurisdiction_region_id,
    name: user.name,
    sessionId
  };

  const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: ACCESS_TOKEN_EXPIRY });

  logAuditEvent({
    actionType: 'LOGIN_SESSION_CREATED',
    actorId: user.id,
    actorRole: user.role,
    entityId: sessionId,
    details: `New session created with refresh-token rotation on ${userAgent}`,
    ipAddress
  });

  return {
    accessToken,
    refreshToken: rawRefreshToken,
    sessionId,
    expiresIn: 900 // 15 mins in seconds
  };
}

// FR-1: Refresh-token rotation
export function rotateRefreshToken(
  rawRefreshToken: string,
  userAgent = 'Unknown Client',
  ipAddress = '127.0.0.1'
) {
  const tokenHash = hashToken(rawRefreshToken);

  const session = db.prepare(`
    SELECT s.*, u.name, u.role, u.jurisdiction_region_id
    FROM user_sessions s
    JOIN users u ON s.user_id = u.id
    WHERE s.refresh_token_hash = ?
  `).get(tokenHash) as any;

  if (!session) {
    throw new Error('Invalid refresh token');
  }

  // Token reuse detection: if already revoked, revoke ALL user sessions as security safeguard
  if (session.is_revoked) {
    db.prepare('UPDATE user_sessions SET is_revoked = 1 WHERE user_id = ?').run(session.user_id);
    logAuditEvent({
      actionType: 'SECURITY_ALERT_TOKEN_REUSE',
      actorId: session.user_id,
      actorRole: session.role,
      entityId: session.id,
      details: 'Detected reuse of already revoked refresh token. All active user sessions revoked.',
      ipAddress
    });
    throw new Error('Revoked token reuse detected. All sessions terminated.');
  }

  // Check expiration
  if (new Date(session.expires_at) < new Date()) {
    throw new Error('Refresh token expired');
  }

  // Invalidate old session
  db.prepare('UPDATE user_sessions SET is_revoked = 1 WHERE id = ?').run(session.id);

  // Issue new session with rotation
  return createSessionAndTokens(
    {
      id: session.user_id,
      name: session.name,
      role: session.role,
      jurisdiction_region_id: session.jurisdiction_region_id
    },
    userAgent,
    ipAddress
  );
}

// FR-1: Session revocation
export function revokeSession(sessionId: string, actorId: string) {
  const stmt = db.prepare('UPDATE user_sessions SET is_revoked = 1 WHERE id = ? AND user_id = ?');
  const result = stmt.run(sessionId, actorId);
  return result.changes > 0;
}

export function revokeAllUserSessions(userId: string) {
  db.prepare('UPDATE user_sessions SET is_revoked = 1 WHERE user_id = ?').run(userId);
}

// FR-1: OTP Generation & Verification
export function generateOtp(identifier: string, purpose: 'LOGIN' | 'REGISTER' | 'TWO_FACTOR'): string {
  // Generate cryptographically secure 6-digit numeric code
  const code = crypto.randomInt(100000, 999999).toString();
  const id = `OTP-${crypto.randomBytes(6).toString('hex')}`;
  
  const expiresAt = new Date();
  expiresAt.setMinutes(expiresAt.getMinutes() + 5); // 5 minute validity

  db.prepare(`
    INSERT INTO otp_codes (id, identifier, otp_code, purpose, expires_at)
    VALUES (?, ?, ?, ?, ?)
  `).run(id, identifier, code, purpose, expiresAt.toISOString());

  return code;
}

export function verifyOtp(identifier: string, code: string, purpose: 'LOGIN' | 'REGISTER' | 'TWO_FACTOR'): boolean {
  // Find latest active OTP
  const otpRecord = db.prepare(`
    SELECT * FROM otp_codes 
    WHERE identifier = ? AND purpose = ? AND is_used = 0 
    ORDER BY created_at DESC LIMIT 1
  `).get(identifier, purpose) as any;

  if (!otpRecord) return false;

  if (new Date(otpRecord.expires_at) < new Date()) {
    return false;
  }

  if (otpRecord.attempts >= 5) {
    return false;
  }

  // Increment attempts
  db.prepare('UPDATE otp_codes SET attempts = attempts + 1 WHERE id = ?').run(otpRecord.id);

  if (otpRecord.otp_code === code) {
    db.prepare('UPDATE otp_codes SET is_used = 1 WHERE id = ?').run(otpRecord.id);
    return true;
  }

  return false;
}

export function verifyAccessToken(token: string): TokenPayload {
  const decoded = jwt.verify(token, JWT_SECRET) as TokenPayload;

  // Check if session has been revoked in DB
  const session = db.prepare('SELECT is_revoked FROM user_sessions WHERE id = ?').get(decoded.sessionId) as any;
  if (!session || session.is_revoked) {
    throw new Error('Session has been revoked');
  }

  return decoded;
}
