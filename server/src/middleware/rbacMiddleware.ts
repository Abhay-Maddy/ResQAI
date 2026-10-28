import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken, TokenPayload } from '../services/authService';
import { db } from '../db/database';

// Extend Express Request type to include authenticated user
declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

export type RoleName = 
  | 'CITIZEN' 
  | 'VOLUNTEER'
  | 'NGO'
  | 'GOVERNMENT_MEMBER'
  | 'ADMIN' 
  | 'GOVT_OFFICER' 
  | 'RESPONDER' 
  | 'DONOR' 
  | 'AUDITOR';

// FR-2 & FR-3: Server-side authentication middleware
export function authenticate(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Authentication token required'
    });
  }

  const token = authHeader.split(' ')[1];
  try {
    // SEC-5: Private responses send Cache-Control: no-store
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');

    const payload = verifyAccessToken(token);

    // DEL-4: Check if account is deactivated in 7-day grace period
    const userRow = db.prepare('SELECT is_deactivated, deletion_scheduled_at FROM users WHERE id = ?').get(payload.userId) as any;
    if (userRow?.is_deactivated) {
      return res.status(403).json({
        error: 'ACCOUNT_DEACTIVATED',
        message: 'This account is currently scheduled for deletion (DEL-4). Please cancel deletion to restore access.',
        deletionScheduledAt: userRow.deletion_scheduled_at
      });
    }
    req.user = payload;
    next();
  } catch (err: any) {
    return res.status(401).json({
      error: 'INVALID_TOKEN',
      message: err.message || 'Token is invalid, expired, or session has been revoked'
    });
  }
}

// FR-3: Server-side Role Authorization
export function requireRole(...allowedRoles: RoleName[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Authentication required' });
    }

    // Admin has superuser override on operations
    if (req.user.role === 'ADMIN' || allowedRoles.includes(req.user.role as RoleName)) {
      return next();
    }

    return res.status(403).json({
      error: 'FORBIDDEN_ROLE',
      message: `Access denied. Requires one of roles: [${allowedRoles.join(', ')}]. Current role: ${req.user.role}`
    });
  };
}

// FR-2: Jurisdiction-Scoped Enforcement Middleware
export function requireJurisdiction(extractRegionId: (req: Request) => string | undefined) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'UNAUTHORIZED', message: 'Authentication required' });
    }

    // Admins and Auditors have cross-jurisdiction visibility
    if (req.user.role === 'ADMIN' || req.user.role === 'AUDITOR') {
      return next();
    }

    const targetRegionId = extractRegionId(req);
    if (!targetRegionId) {
      return next(); // If endpoint is not region-specific, allow
    }

    if (req.user.jurisdictionRegionId && req.user.jurisdictionRegionId !== targetRegionId) {
      return res.status(403).json({
        error: 'FORBIDDEN_JURISDICTION',
        message: `Action outside authorized jurisdiction. Assigned: ${req.user.jurisdictionRegionId}, Target: ${targetRegionId}`
      });
    }

    next();
  };
}
