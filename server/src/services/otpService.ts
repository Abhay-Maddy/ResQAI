import crypto from 'crypto';
import { db } from '../db/database';

const OTP_HASH_SECRET = process.env.OTP_HASH_SECRET || 'resqai_otp_salt_secret_2026';

export type OtpPurpose = 
  | 'LOGIN' 
  | 'REGISTER' 
  | 'TWO_FACTOR' 
  | 'DELETE_ACCOUNT' 
  | 'PASSWORD_RESET' 
  | 'CHANGE_PHONE';

export interface OtpVerificationResult {
  valid: boolean;
  status: 'SUCCESS' | 'EXPIRED' | 'WRONG_CODE' | 'LOCKED' | 'RATE_LIMITED' | 'NOT_FOUND';
  messageEn: string;
  messageHi: string;
}

export function hashOtp(code: string): string {
  return crypto.createHmac('sha256', OTP_HASH_SECRET).update(code).digest('hex');
}

/**
 * Check if the identifier is locked or has hit resend cooldown/hourly limit
 */
export function checkOtpRateLimit(identifier: string): { 
  allowed: boolean; 
  reason?: string; 
  status?: 'LOCKED' | 'COOLDOWN' | 'HOURLY_LIMIT';
  lockExpiresAt?: string;
  secondsRemaining?: number;
} {
  try {
    const row = db.prepare('SELECT * FROM otp_rate_limits WHERE identifier = ?').get(identifier) as any;
    const now = Date.now();

    if (row) {
      // 1. Check 15-minute Lockout after 5 wrong attempts (OTP-4)
      if (row.locked_until && new Date(row.locked_until).getTime() > now) {
        const remainingMinutes = Math.ceil((new Date(row.locked_until).getTime() - now) / 60000);
        return {
          allowed: false,
          status: 'LOCKED',
          reason: `Too many wrong tries. Locked for ${remainingMinutes} more minutes (अधिक गलत प्रयासों के कारण खाता 15 मिनट के लिए लॉक है)`,
          lockExpiresAt: row.locked_until,
          secondsRemaining: Math.ceil((new Date(row.locked_until).getTime() - now) / 1000)
        };
      }

      // 2. Check 30-second Resend Cooldown (OTP-3)
      if (row.last_sent_at) {
        const elapsedSec = (now - new Date(row.last_sent_at).getTime()) / 1000;
        if (elapsedSec < 30) {
          const waitSec = Math.ceil(30 - elapsedSec);
          return {
            allowed: false,
            status: 'COOLDOWN',
            reason: `Please wait ${waitSec}s before requesting a new OTP (कृपया पुनः ओटीपी भेजने से पहले ${waitSec} सेकंड प्रतीक्षा करें)`,
            secondsRemaining: waitSec
          };
        }
      }

      // 3. Check Maximum 5 sends per hour per number (OTP-3)
      if (row.first_send_in_hour) {
        const hourElapsed = (now - new Date(row.first_send_in_hour).getTime()) / 1000;
        if (hourElapsed < 3600) {
          if (row.hourly_sends >= 5) {
            return {
              allowed: false,
              status: 'HOURLY_LIMIT',
              reason: 'Maximum 5 OTP requests per hour reached (प्रति घंटे अधिकतम 5 ओटीपी सीमा समाप्त)',
              secondsRemaining: Math.ceil(3600 - hourElapsed)
            };
          }
        }
      }
    }
  } catch (_) {}

  return { allowed: true };
}

export function recordOtpSend(identifier: string): void {
  try {
    const row = db.prepare('SELECT * FROM otp_rate_limits WHERE identifier = ?').get(identifier) as any;
    const now = new Date();
    const nowIso = now.toISOString();

    if (!row) {
      db.prepare(`
        INSERT INTO otp_rate_limits (identifier, hourly_sends, first_send_in_hour, last_sent_at, failed_attempts)
        VALUES (?, 1, ?, ?, 0)
      `).run(identifier, nowIso, nowIso);
    } else {
      const hourElapsed = (now.getTime() - new Date(row.first_send_in_hour).getTime()) / 1000;
      if (hourElapsed >= 3600) {
        db.prepare(`
          UPDATE otp_rate_limits 
          SET hourly_sends = 1, first_send_in_hour = ?, last_sent_at = ?, failed_attempts = 0, locked_until = NULL
          WHERE identifier = ?
        `).run(nowIso, nowIso, identifier);
      } else {
        db.prepare(`
          UPDATE otp_rate_limits 
          SET hourly_sends = hourly_sends + 1, last_sent_at = ?
          WHERE identifier = ?
        `).run(nowIso, identifier);
      }
    }
  } catch (_) {}
}

export function recordOtpFailure(identifier: string): { locked: boolean; lockExpiresAt?: string } {
  try {
    const row = db.prepare('SELECT * FROM otp_rate_limits WHERE identifier = ?').get(identifier) as any;
    const failed = ((row?.failed_attempts || 0) + 1);
    
    // OTP-4: Maximum 5 wrong tries, then a 15-minute lock
    if (failed >= 5) {
      const lockTime = new Date(Date.now() + 15 * 60 * 1000).toISOString();
      db.prepare(`
        INSERT INTO otp_rate_limits (identifier, failed_attempts, locked_until)
        VALUES (?, ?, ?)
        ON CONFLICT(identifier) DO UPDATE SET failed_attempts = ?, locked_until = ?
      `).run(identifier, failed, lockTime, failed, lockTime);
      return { locked: true, lockExpiresAt: lockTime };
    } else {
      db.prepare(`
        INSERT INTO otp_rate_limits (identifier, failed_attempts)
        VALUES (?, ?)
        ON CONFLICT(identifier) DO UPDATE SET failed_attempts = ?
      `).run(identifier, failed, failed);
      return { locked: false };
    }
  } catch (_) {
    return { locked: false };
  }
}

/**
 * Generate a 6-digit OTP, store its hash, enforce rate limits, and log for dev mode (OTP-1 to OTP-7)
 */
export function generateOtp(identifier: string, purpose: OtpPurpose | string = 'LOGIN'): string {
  const rateLimit = checkOtpRateLimit(identifier);
  if (!rateLimit.allowed) {
    throw new Error(rateLimit.reason || 'Rate limit exceeded');
  }

  // 6-digit OTP (OTP-1)
  const code = crypto.randomInt(100000, 999999).toString();
  const id = `OTP-${crypto.randomBytes(6).toString('hex')}`;
  const hashedCode = hashOtp(code);

  // 5 minute validity (OTP-2)
  const expiresAt = new Date();
  expiresAt.setMinutes(expiresAt.getMinutes() + 5);

  // Map custom purposes to database valid purposes ('LOGIN', 'REGISTER', 'TWO_FACTOR')
  const dbPurpose = (purpose === 'DELETE_ACCOUNT' || purpose === 'PASSWORD_RESET' || purpose === 'CHANGE_PHONE')
    ? 'TWO_FACTOR'
    : purpose;

  db.prepare(`
    INSERT INTO otp_codes (id, identifier, otp_code, purpose, expires_at)
    VALUES (?, ?, ?, ?, ?)
  `).run(id, identifier, hashedCode, dbPurpose, expiresAt.toISOString());

  recordOtpSend(identifier);

  // OTP-7: In development mode, the OTP is printed in the server log only and never in API responses
  console.log(`[ResQAI SMS/OTP Dev Adapter] 6-digit OTP for ${identifier}: ${code} (Purpose: ${purpose}, Expires: 5m)`);

  return code;
}

/**
 * Verify OTP: single use, checks expiry, lockout, and matches hash (OTP-2, OTP-4, OTP-8)
 */
export function verifyOtpDetailed(
  identifier: string, 
  code: string, 
  purpose: OtpPurpose | string = 'LOGIN'
): OtpVerificationResult {
  const rateLimit = checkOtpRateLimit(identifier);
  if (!rateLimit.allowed && rateLimit.status === 'LOCKED') {
    return {
      valid: false,
      status: 'LOCKED',
      messageEn: 'Maximum 5 wrong attempts reached. Account is locked for 15 minutes.',
      messageHi: '5 बार गलत कोड दर्ज किया गया। यह नंबर 15 मिनट के लिए लॉक है।'
    };
  }

  const dbPurpose = (purpose === 'DELETE_ACCOUNT' || purpose === 'PASSWORD_RESET' || purpose === 'CHANGE_PHONE')
    ? 'TWO_FACTOR'
    : purpose;

  const otpRecord = db.prepare(`
    SELECT * FROM otp_codes 
    WHERE identifier = ? AND purpose = ? AND is_used = 0 
    ORDER BY created_at DESC LIMIT 1
  `).get(identifier, dbPurpose) as any;

  if (!otpRecord) {
    recordOtpFailure(identifier);
    return {
      valid: false,
      status: 'NOT_FOUND',
      messageEn: 'No active OTP found. Please request a new code.',
      messageHi: 'कोई सक्रिय ओटीपी नहीं मिला। कृपया पुनः अनुरोध करें।'
    };
  }

  if (new Date(otpRecord.expires_at) < new Date()) {
    recordOtpFailure(identifier);
    return {
      valid: false,
      status: 'EXPIRED',
      messageEn: 'OTP has expired (validity 5 minutes). Please request a new one.',
      messageHi: 'ओटीपी की समय सीमा (5 मिनट) समाप्त हो चुकी है। कृपया नया कोड मंगाएं।'
    };
  }

  if (otpRecord.attempts >= 5) {
    recordOtpFailure(identifier);
    return {
      valid: false,
      status: 'LOCKED',
      messageEn: 'Maximum attempts reached for this OTP code.',
      messageHi: 'इस ओटीपी के लिए अधिकतम प्रयास पूरे हो चुके हैं।'
    };
  }

  // Increment attempt count on record
  db.prepare('UPDATE otp_codes SET attempts = attempts + 1 WHERE id = ?').run(otpRecord.id);

  const hashedInput = hashOtp(code);
  const isMatch = (otpRecord.otp_code === hashedInput) || (otpRecord.otp_code === code);

  if (isMatch) {
    // Single use: mark as used (OTP-2)
    db.prepare('UPDATE otp_codes SET is_used = 1 WHERE id = ?').run(otpRecord.id);
    
    // Reset failed counter
    try {
      db.prepare('UPDATE otp_rate_limits SET failed_attempts = 0, locked_until = NULL WHERE identifier = ?').run(identifier);
    } catch (_) {}

    return {
      valid: true,
      status: 'SUCCESS',
      messageEn: 'OTP verified successfully.',
      messageHi: 'ओटीपी सफलतापूर्वक सत्यापित किया गया।'
    };
  }

  const failure = recordOtpFailure(identifier);
  if (failure.locked) {
    return {
      valid: false,
      status: 'LOCKED',
      messageEn: '5 wrong tries reached. Locked for 15 minutes.',
      messageHi: '5 बार गलत कोड। सुरक्षा कारणों से 15 मिनट के लिए लॉक।'
    };
  }

  return {
    valid: false,
    status: 'WRONG_CODE',
    messageEn: 'Invalid OTP code. Please re-enter the 6 digits.',
    messageHi: 'अमान्य ओटीपी कोड। कृपया सही 6 अंकों का कोड दर्ज करें।'
  };
}

/**
 * Backward compatible boolean verifyOtp function
 */
export function verifyOtp(identifier: string, code: string, purpose: OtpPurpose | string = 'LOGIN'): boolean {
  const res = verifyOtpDetailed(identifier, code, purpose);
  return res.valid;
}
