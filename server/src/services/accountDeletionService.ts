import crypto from 'crypto';
import { db } from '../db/database';
import { verifyPasswordHash } from './authService';
import { verifyOtpDetailed } from './otpService';
import { logAuditEvent } from './auditService';
import { sendSms } from './smsAdapterService';

export interface DeletionStatus {
  isDeactivated: boolean;
  deactivatedAt: string | null;
  deletionScheduledAt: string | null;
  daysRemaining: number | null;
  canCancel: boolean;
}

/**
 * DEL-2: Export user data before deletion ("Download my data")
 */
export function exportUserData(userId: string): Record<string, any> {
  const user = db.prepare('SELECT id, name, email, phone, role, jurisdiction_region_id, preferred_language, created_at FROM users WHERE id = ?').get(userId);
  if (!user) throw new Error('User not found');

  const contacts = db.prepare('SELECT id, name, phone, relationship, is_primary FROM emergency_contacts WHERE user_id = ?').all(userId);
  const places = db.prepare('SELECT id, label, address, ward, latitude, longitude FROM saved_places WHERE user_id = ?').all(userId);
  const incidents = (user as any)?.phone 
    ? db.prepare('SELECT id, category, description, created_at FROM incident_reports WHERE contact_phone = ?').all((user as any).phone)
    : [];
  const claims = db.prepare('SELECT id, loss_types, severity, estimated_value, status, created_at FROM damage_claims WHERE claimant_id = ?').all(userId);
  const donations = (user as any)?.phone || (user as any)?.email
    ? db.prepare('SELECT id, campaign_id, amount_paise, currency, status, created_at FROM donations WHERE donor_phone = ? OR donor_email = ?').all((user as any).phone || '', (user as any).email || '')
    : [];
  const notifications = db.prepare('SELECT id, title, body, created_at, is_read FROM notifications WHERE user_id = ?').all(userId);

  return {
    exportDate: new Date().toISOString(),
    compliance: 'DPDP Act 2023 / PRD v3.0 DEL-2',
    userProfile: user,
    emergencyContacts: contacts,
    savedPlaces: places,
    incidentReports: incidents,
    damageClaims: claims,
    donationHistory: donations,
    notifications: notifications,
  };
}

/**
 * DEL-7: Check if an NGO or Government account must hand over duties before deleting
 */
export function checkAdminHandoverRequirement(userId: string): { blocked: boolean; reason?: string } {
  const user = db.prepare('SELECT role, department FROM users WHERE id = ?').get(userId) as any;
  if (!user) return { blocked: false };

  if (user.role === 'NGO') {
    // Check if NGO owns active campaigns with received funds
    try {
      const activeCampaigns = db.prepare(`
        SELECT count(*) as count FROM campaigns 
        WHERE (ngo_id = ? OR created_by_user_id = ?) AND status = 'ACTIVE'
      `).get(userId, userId) as any;

      if (activeCampaigns && activeCampaigns.count > 0) {
        return {
          blocked: true,
          reason: 'Your NGO account currently owns active relief campaigns. You must transfer or close these campaigns before deleting this account (DEL-7).'
        };
      }
    } catch (_) {}
  }

  if (user.role === 'GOVERNMENT_MEMBER' || user.role === 'GOVT_OFFICER' || user.role === 'ADMIN') {
    // Check if there are unassigned incidents in their department jurisdiction that need another officer
    try {
      const pendingClaims = db.prepare(`
        SELECT count(*) as count FROM damage_claims 
        WHERE assigned_official_id = ? AND status IN ('ASSIGNED_GOVERNMENT', 'UNDER_REVIEW')
      `).get(userId) as any;

      if (pendingClaims && pendingClaims.count > 0) {
        return {
          blocked: true,
          reason: 'Your account has active disaster claims assigned for official verification. Please reassign them to another officer before requesting deletion (DEL-7).'
        };
      }
    } catch (_) {}
  }

  return { blocked: false };
}

/**
 * DEL-1 to DEL-4: Initiate account deletion with password + OTP + 'DELETE' typing and 7-day grace period
 */
export async function initiateAccountDeletion(
  userId: string,
  passwordOrPin: string,
  otpCode: string,
  confirmationText: string
): Promise<{ success: boolean; scheduledDeletionAt: string; message: string }> {
  // 1. DEL-3: Must type exact word DELETE
  if (confirmationText !== 'DELETE') {
    throw new Error('You must type the word "DELETE" in capital letters to confirm account deletion (DEL-3).');
  }

  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
  if (!user) throw new Error('User not found');
  if (user.is_deactivated) throw new Error('Account is already scheduled for deletion.');

  // 2. DEL-7: Handover check
  const handover = checkAdminHandoverRequirement(userId);
  if (handover.blocked) {
    throw new Error(handover.reason || 'Account cannot be deleted due to active administrative responsibilities (DEL-7).');
  }

  // 3. Verify Password or PIN
  let isPasswordValid = false;
  if (user.password_hash) {
    isPasswordValid = await verifyPasswordHash(user.password_hash, passwordOrPin);
  }
  if (!isPasswordValid && user.app_pin_hash) {
    const pinHash = crypto.createHash('sha256').update(passwordOrPin + '_resqai_pin_salt').digest('hex');
    isPasswordValid = (user.app_pin_hash === pinHash);
  }
  if (!isPasswordValid) {
    throw new Error('Invalid account password or PIN.');
  }

  // 4. Verify OTP for DELETE_ACCOUNT purpose
  const identifier = user.phone || user.email;
  const otpResult = verifyOtpDetailed(identifier, otpCode, 'DELETE_ACCOUNT');
  if (!otpResult.valid) {
    throw new Error(`OTP Verification failed: ${otpResult.messageEn}`);
  }

  // 5. DEL-4: Set 7-day grace period
  const now = new Date();
  const scheduledDate = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
  const scheduledIso = scheduledDate.toISOString();
  const nowIso = now.toISOString();

  db.prepare(`
    UPDATE users 
    SET is_deactivated = 1, deactivated_at = ?, deletion_scheduled_at = ?
    WHERE id = ?
  `).run(nowIso, scheduledIso, userId);

  // Sign out from everywhere: revoke all sessions and push tokens (DEL-4, DEL-5)
  db.prepare('UPDATE user_sessions SET is_revoked = 1 WHERE user_id = ?').run(userId);
  try {
    db.prepare('UPDATE user_devices SET is_revoked = 1 WHERE user_id = ?').run(userId);
    db.prepare('DELETE FROM devices WHERE user_id = ?').run(userId);
  } catch (_) {}

  // Audit log
  logAuditEvent({
    actionType: 'ACCOUNT_DELETION_SCHEDULED',
    actorId: userId,
    actorRole: user.role,
    entityId: userId,
    details: `Account deletion requested. 7-day grace period active until ${scheduledIso} (DEL-1 to DEL-4)`,
    ipAddress: '127.0.0.1'
  });

  // DEL-8: Notification to phone/email
  if (user.phone) {
    sendSms({
      to: user.phone,
      message: `ResQAI: Your account deletion has been scheduled. Your data will be permanently removed on ${scheduledDate.toLocaleDateString()}. Sign in before this date to cancel.`
    }).catch(() => {});
  }

  return {
    success: true,
    scheduledDeletionAt: scheduledIso,
    message: `Account scheduled for deletion. You have a 7-day grace period until ${scheduledDate.toLocaleDateString()} to cancel this request.`
  };
}

/**
 * DEL-4: Cancel account deletion if within 7-day grace period
 */
export function cancelAccountDeletion(userId: string): { success: boolean; message: string } {
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId) as any;
  if (!user) throw new Error('User not found');
  if (!user.is_deactivated) throw new Error('This account is not scheduled for deletion.');

  db.prepare(`
    UPDATE users 
    SET is_deactivated = 0, deactivated_at = NULL, deletion_scheduled_at = NULL
    WHERE id = ?
  `).run(userId);

  logAuditEvent({
    actionType: 'ACCOUNT_DELETION_CANCELLED',
    actorId: userId,
    actorRole: user.role,
    entityId: userId,
    details: 'User cancelled scheduled account deletion during 7-day grace period (DEL-4)',
    ipAddress: '127.0.0.1'
  });

  if (user.phone) {
    sendSms({
      to: user.phone,
      message: 'ResQAI: Your account deletion request has been cancelled. Your account and data are fully active.'
    }).catch(() => {});
  }

  return {
    success: true,
    message: 'Account deletion has been cancelled. Your account is fully restored.'
  };
}

/**
 * DEL-5 & DEL-6: Purge expired accounts after 7 days
 * Anonymizes incident and financial records, deletes personal identifiable data
 */
export function purgeExpiredAccounts(): { purgedCount: number } {
  const nowIso = new Date().toISOString();
  const expiredUsers = db.prepare(`
    SELECT id, name, phone, email, role FROM users 
    WHERE is_deactivated = 1 AND deletion_scheduled_at <= ?
  `).all(nowIso) as any[];

  for (const u of expiredUsers) {
    const anonId = `ANON_USER_${crypto.randomBytes(4).toString('hex').toUpperCase()}`;

    // DEL-6: Anonymize incident & claim records (user replaced with anonymous ID)
    try {
      if (u.phone) {
        db.prepare('UPDATE incident_reports SET contact_phone = NULL, is_anonymous = 1 WHERE contact_phone = ?').run(u.phone);
      }
      db.prepare('UPDATE damage_claims SET claimant_id = ?, household_address = "[ANONYMIZED_RECORD]" WHERE claimant_id = ?').run(anonId, u.id);
      if (u.phone || u.email) {
        db.prepare('UPDATE donations SET donor_name = "Anonymous Donor", donor_email = "[ANONYMIZED]", donor_phone = NULL, donor_pan = NULL WHERE donor_phone = ? OR donor_email = ?').run(u.phone || '', u.email || '');
      }
    } catch (_) {}

    // DEL-5: Delete personal records
    try {
      db.prepare('DELETE FROM emergency_contacts WHERE user_id = ?').run(u.id);
      db.prepare('DELETE FROM saved_places WHERE user_id = ?').run(u.id);
      db.prepare('DELETE FROM user_devices WHERE user_id = ?').run(u.id);
      db.prepare('DELETE FROM user_sessions WHERE user_id = ?').run(u.id);
      db.prepare('DELETE FROM notifications WHERE user_id = ?').run(u.id);
      db.prepare('DELETE FROM notification_deliveries WHERE user_id = ?').run(u.id);
      db.prepare('DELETE FROM devices WHERE user_id = ?').run(u.id);
      db.prepare('DELETE FROM users WHERE id = ?').run(u.id);
    } catch (_) {}

    logAuditEvent({
      actionType: 'ACCOUNT_PURGED_PERMANENTLY',
      actorId: 'SYSTEM_PURGE_JOB',
      actorRole: 'SYSTEM',
      entityId: u.id,
      details: `Account ${u.id} permanently deleted after 7-day grace period. Records anonymized to ${anonId} (DEL-5, DEL-6)`,
      ipAddress: '127.0.0.1'
    });
  }

  return { purgedCount: expiredUsers.length };
}
