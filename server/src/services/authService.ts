import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { hash, verify, Algorithm } from '@node-rs/argon2';
import { db } from '../db/database';
import { logAuditEvent } from './auditService';

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error('JWT_SECRET must be configured in the environment');
}
const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_DAYS = 30; // PRD R-AUTH-1: Session stays active for 30 days using rotating refresh tokens

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

// --- PRD v2.0 Phase 1 Additions ---

// R-AUTH-4: Account Lockout after 5 failed attempts
export function recordFailedLogin(userId: string): { locked: boolean; lockedUntil?: string } {
  const user = db.prepare('SELECT failed_login_attempts FROM users WHERE id = ?').get(userId) as any;
  const attempts = (user?.failed_login_attempts || 0) + 1;
  let lockedUntil: string | null = null;
  if (attempts >= 5) {
    const lockTime = new Date(Date.now() + 15 * 60 * 1000);
    lockedUntil = lockTime.toISOString();
    db.prepare('UPDATE users SET failed_login_attempts = ?, locked_until = ? WHERE id = ?').run(attempts, lockedUntil, userId);
    logAuditEvent({
      actionType: 'ACCOUNT_LOCKED_5_FAILURES',
      actorId: userId,
      actorRole: 'SYSTEM',
      entityId: userId,
      details: 'Account temporarily locked for 15 minutes due to 5 consecutive failed login attempts (R-AUTH-4)',
      ipAddress: '127.0.0.1'
    });
    return { locked: true, lockedUntil };
  } else {
    db.prepare('UPDATE users SET failed_login_attempts = ? WHERE id = ?').run(attempts, userId);
    return { locked: false };
  }
}

export function resetFailedLogins(userId: string): void {
  db.prepare('UPDATE users SET failed_login_attempts = 0, locked_until = NULL WHERE id = ?').run(userId);
}

export function isAccountLocked(user: any): boolean {
  if (!user.locked_until) return false;
  const lockTime = new Date(user.locked_until).getTime();
  if (Date.now() < lockTime) {
    return true;
  }
  // Lock expired, reset
  resetFailedLogins(user.id);
  return false;
}

// R-AUTH-2: 4-digit App PIN or Passkey Unlock
export function setAppPin(userId: string, pin: string): void {
  const pinHash = crypto.createHash('sha256').update(pin + '_resqai_pin_salt').digest('hex');
  db.prepare('UPDATE users SET app_pin_hash = ? WHERE id = ?').run(pinHash, userId);
}

export function verifyAppPin(userId: string, pin: string): boolean {
  const user = db.prepare('SELECT app_pin_hash FROM users WHERE id = ?').get(userId) as any;
  if (!user || !user.app_pin_hash) return false;
  const pinHash = crypto.createHash('sha256').update(pin + '_resqai_pin_salt').digest('hex');
  return user.app_pin_hash === pinHash;
}

// R-AUTH-3: Re-authentication for sensitive actions
const REAUTH_SECRET = process.env.REAUTH_SECRET;
if (!REAUTH_SECRET) {
  throw new Error('REAUTH_SECRET must be configured in the environment');
}

export function issueReauthChallenge(userId: string, action: string): string {
  return jwt.sign(
    { userId, action, purpose: 'REAUTH_CONFIRMED' },
    REAUTH_SECRET,
    { expiresIn: '5m' }
  );
}

export function verifyReauthChallenge(token: string, expectedAction?: string): { userId: string; action: string } {
  const decoded = jwt.verify(token, REAUTH_SECRET) as any;
  if (decoded.purpose !== 'REAUTH_CONFIRMED') {
    throw new Error('Invalid re-authentication token');
  }
  if (expectedAction && decoded.action !== expectedAction) {
    throw new Error(`Token was issued for ${decoded.action}, not ${expectedAction}`);
  }
  return { userId: decoded.userId, action: decoded.action };
}

// R-AUTH-4: Device management and remote sign-out
export function recordUserDevice(userId: string, deviceId: string, deviceName: string, userAgent = 'Unknown', ipAddress = '127.0.0.1') {
  const id = `DEV-${userId}-${deviceId}`;
  db.prepare(`
    INSERT INTO user_devices (id, user_id, device_id, device_name, user_agent, ip_address, last_active_at, is_revoked)
    VALUES (?, ?, ?, ?, ?, ?, datetime('now'), 0)
    ON CONFLICT(user_id, device_id) DO UPDATE SET
      device_name = excluded.device_name,
      user_agent = excluded.user_agent,
      ip_address = excluded.ip_address,
      last_active_at = datetime('now'),
      is_revoked = 0
  `).run(id, userId, deviceId, deviceName, userAgent, ipAddress);
}

export function revokeUserDevice(userId: string, deviceId: string) {
  db.prepare('UPDATE user_devices SET is_revoked = 1 WHERE user_id = ? AND device_id = ?').run(userId, deviceId);
}

