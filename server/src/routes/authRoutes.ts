import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { db } from '../db/database';
import { 
  hashPassword, 
  verifyPasswordHash, 
  createSessionAndTokens, 
  rotateRefreshToken, 
  revokeSession, 
  revokeAllUserSessions,
  generateOtp,
  verifyOtp
} from '../services/authService';
import { authenticate } from '../middleware/rbacMiddleware';
import { logAuditEvent } from '../services/auditService';

export const authRouter = Router();
const TWO_FACTOR_JWT_SECRET = 'resqai_disaster_2fa_temp_key_2026';

// FR-1: Register with Email / Phone & Argon2id Password
authRouter.post('/register', async (req: Request, res: Response) => {
  const { name, email, phone, password, role = 'CITIZEN', jurisdictionRegionId } = req.body;

  if (!name || (!email && !phone)) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'Name and email or phone are required' });
  }

  // Validate role
  const validRoles = ['CITIZEN', 'ADMIN', 'GOVT_OFFICER', 'RESPONDER', 'NGO', 'DONOR', 'AUDITOR'];
  if (!validRoles.includes(role)) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: `Invalid role: ${role}` });
  }

  try {
    const existing = db.prepare('SELECT id FROM users WHERE email = ? OR phone = ?').get(email || null, phone || null);
    if (existing) {
      return res.status(409).json({ error: 'USER_EXISTS', message: 'User with this email or phone already exists' });
    }

    const userId = `USR-${Date.now()}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
    const passwordHash = password ? await hashPassword(password) : null;

    // Admin, Govt, NGO Finance default to 2FA enabled (FR-4)
    const twoFactorEnabled = (role === 'ADMIN' || role === 'GOVT_OFFICER' || role === 'NGO') ? 1 : 0;
    const twoFactorSecret = twoFactorEnabled ? `SECRET_2FA_${userId}` : null;

    db.prepare(`
      INSERT INTO users (id, name, email, phone, password_hash, role, jurisdiction_region_id, is_verified, two_factor_enabled, two_factor_secret)
      VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    `).run(userId, name, email || null, phone || null, passwordHash, role, jurisdictionRegionId || null, twoFactorEnabled, twoFactorSecret);

    const user = { id: userId, name, role, jurisdiction_region_id: jurisdictionRegionId || null };
    const session = createSessionAndTokens(user, req.headers['user-agent'], req.ip);

    logAuditEvent({
      actionType: 'USER_REGISTERED',
      actorId: userId,
      actorRole: role,
      entityId: userId,
      details: `User registered with role ${role} and Argon2id security`,
      ipAddress: req.ip
    });

    res.status(201).json({
      message: 'User registered successfully',
      user: { id: userId, name, email, phone, role, jurisdictionRegionId, twoFactorEnabled: !!twoFactorEnabled },
      ...session
    });
  } catch (err: any) {
    res.status(500).json({ error: 'SERVER_ERROR', message: err.message });
  }
});

// FR-1 & FR-4: Login with Password & 2FA Gate
authRouter.post('/login', async (req: Request, res: Response) => {
  const { emailOrPhone, password } = req.body;

  if (!emailOrPhone || !password) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'Email/phone and password are required' });
  }

  try {
    const user = db.prepare(`
      SELECT * FROM users WHERE email = ? OR phone = ?
    `).get(emailOrPhone, emailOrPhone) as any;

    if (!user || !user.password_hash) {
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid credentials provided' });
    }

    // Verify Argon2id password hash
    const isValidPassword = await verifyPasswordHash(user.password_hash, password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'INVALID_CREDENTIALS', message: 'Invalid credentials provided' });
    }

    // FR-4: Two-Factor Authentication check for Admin, Govt, NGO
    if (user.two_factor_enabled) {
      const otpCode = generateOtp(user.email || user.phone, 'TWO_FACTOR');
      const tempToken = jwt.sign(
        { userId: user.id, purpose: 'TWO_FACTOR_PENDING' },
        TWO_FACTOR_JWT_SECRET,
        { expiresIn: '5m' }
      );

      return res.json({
        requires2FA: true,
        message: 'Two-factor authentication code sent to registered contact',
        tempToken,
        demoOtp: otpCode // Available in demo mode for automated testing
      });
    }

    // Standard Login
    const session = createSessionAndTokens(user, req.headers['user-agent'], req.ip);
    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        jurisdictionRegionId: user.jurisdiction_region_id,
        twoFactorEnabled: !!user.two_factor_enabled
      },
      ...session
    });
  } catch (err: any) {
    res.status(500).json({ error: 'SERVER_ERROR', message: err.message });
  }
});

// FR-4: Verify 2FA and complete login
authRouter.post('/verify-2fa', (req: Request, res: Response) => {
  const { tempToken, code } = req.body;

  if (!tempToken || !code) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'Temporary token and 2FA code are required' });
  }

  try {
    const decoded = jwt.verify(tempToken, TWO_FACTOR_JWT_SECRET) as { userId: string; purpose: string };
    if (decoded.purpose !== 'TWO_FACTOR_PENDING') {
      return res.status(401).json({ error: 'INVALID_TOKEN', message: 'Invalid 2FA flow' });
    }

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(decoded.userId) as any;
    if (!user) {
      return res.status(404).json({ error: 'USER_NOT_FOUND', message: 'User not found' });
    }

    // Verify OTP code
    const isCodeValid = verifyOtp(user.email || user.phone, code, 'TWO_FACTOR');
    if (!isCodeValid) {
      return res.status(401).json({ error: 'INVALID_2FA_CODE', message: 'Invalid or expired 2FA code' });
    }

    const session = createSessionAndTokens(user, req.headers['user-agent'], req.ip);
    res.json({
      message: '2FA verified. Login successful.',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        jurisdictionRegionId: user.jurisdiction_region_id
      },
      ...session
    });
  } catch (err: any) {
    res.status(401).json({ error: 'INVALID_TOKEN', message: 'Expired or invalid 2FA token' });
  }
});

// FR-1: Request OTP for Phone/Email Login
authRouter.post('/request-otp', (req: Request, res: Response) => {
  const { identifier, purpose = 'LOGIN' } = req.body;
  if (!identifier) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'Phone or email identifier is required' });
  }

  const code = generateOtp(identifier, purpose);
  res.json({
    message: `OTP sent successfully to ${identifier}`,
    demoOtp: code // Provided in demo mode for instant testing
  });
});

// FR-1: Login with Phone/Email OTP
authRouter.post('/login-otp', (req: Request, res: Response) => {
  const { identifier, otpCode, name } = req.body;

  if (!identifier || !otpCode) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'Identifier and OTP code are required' });
  }

  const isValid = verifyOtp(identifier, otpCode, 'LOGIN');
  if (!isValid) {
    return res.status(401).json({ error: 'INVALID_OTP', message: 'Invalid, expired, or maximum attempts reached for OTP' });
  }

  let user = db.prepare('SELECT * FROM users WHERE email = ? OR phone = ?').get(identifier, identifier) as any;
  if (!user) {
    // Auto-create citizen profile on verified OTP
    const userId = `USR-CITIZEN-${Date.now()}`;
    const isEmail = identifier.includes('@');
    db.prepare(`
      INSERT INTO users (id, name, email, phone, role, is_verified)
      VALUES (?, ?, ?, ?, 'CITIZEN', 1)
    `).run(userId, name || `Citizen ${identifier.slice(-4)}`, isEmail ? identifier : null, isEmail ? null : identifier);

    user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
  }

  const session = createSessionAndTokens(user, req.headers['user-agent'], req.ip);
  res.json({
    message: 'OTP Login successful',
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role
    },
    ...session
  });
});

// FR-1: Refresh Token Rotation
authRouter.post('/refresh', (req: Request, res: Response) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'Refresh token required' });
  }

  try {
    const rotated = rotateRefreshToken(refreshToken, req.headers['user-agent'], req.ip);
    res.json({
      message: 'Token rotated successfully',
      ...rotated
    });
  } catch (err: any) {
    res.status(401).json({ error: 'REFRESH_FAILED', message: err.message });
  }
});

// FR-1: Revoke Current Session (Logout)
authRouter.post('/logout', authenticate, (req: Request, res: Response) => {
  if (req.user?.sessionId) {
    revokeSession(req.user.sessionId, req.user.userId);
  }
  res.json({ message: 'Session successfully revoked' });
});

// FR-1: Revoke All Sessions (Emergency logout all devices)
authRouter.post('/logout-all', authenticate, (req: Request, res: Response) => {
  if (req.user?.userId) {
    revokeAllUserSessions(req.user.userId);
  }
  res.json({ message: 'All active sessions revoked' });
});

// Current User Profile & Active Sessions
authRouter.get('/me', authenticate, (req: Request, res: Response) => {
  const user = db.prepare('SELECT id, name, email, phone, role, jurisdiction_region_id, is_verified, two_factor_enabled, created_at FROM users WHERE id = ?').get(req.user!.userId);
  res.json({ user, currentSessionId: req.user!.sessionId });
});

authRouter.get('/sessions', authenticate, (req: Request, res: Response) => {
  const sessions = db.prepare(`
    SELECT id, user_agent, ip_address, is_revoked, expires_at, created_at, last_used_at
    FROM user_sessions
    WHERE user_id = ?
    ORDER BY created_at DESC
  `).all(req.user!.userId);

  res.json({ sessions });
});
