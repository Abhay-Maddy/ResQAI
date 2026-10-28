import { db } from './database';

/**
 * PRD v3.0 Database Schema & Column Additions
 * Aligned with CLN, SEC, OTP, DEL, NTF, and SOS requirements
 */
export function ensurePrdV3Schema(): void {
  // 1. Users table additions for deletion & verification
  const userCols = db.prepare('PRAGMA table_info(users)').all() as { name: string }[];
  const userColSet = new Set(userCols.map(c => c.name));
  const userColsToAdd: [string, string][] = [
    ['is_deactivated', 'INTEGER DEFAULT 0'],
    ['deactivated_at', 'TEXT'],
    ['deletion_scheduled_at', 'TEXT'],
    ['is_phone_verified', 'INTEGER DEFAULT 0'],
  ];
  for (const [col, def] of userColsToAdd) {
    if (!userColSet.has(col)) {
      try {
        db.exec(`ALTER TABLE users ADD COLUMN ${col} ${def}`);
      } catch (_) {}
    }
  }

  // 2. Incidents table additions for accidental cancellation & form attachment
  const incCols = db.prepare('PRAGMA table_info(incidents)').all() as { name: string }[];
  const incColSet = new Set(incCols.map(c => c.name));
  const incColsToAdd: [string, string][] = [
    ['is_accidental_cancelled', 'INTEGER DEFAULT 0'],
    ['accidental_cancelled_at', 'TEXT'],
    ['accidental_cancelled_by', 'TEXT'],
    ['attached_form_json', 'TEXT'],
    ['battery_level', 'TEXT'],
  ];
  for (const [col, def] of incColsToAdd) {
    if (!incColSet.has(col)) {
      try {
        db.exec(`ALTER TABLE incidents ADD COLUMN ${col} ${def}`);
      } catch (_) {}
    }
  }

  // 3. PRD v3.0 Tables
  db.exec(`
    CREATE TABLE IF NOT EXISTS otp_rate_limits (
      identifier TEXT PRIMARY KEY,
      hourly_sends INTEGER DEFAULT 0,
      first_send_in_hour TEXT,
      last_sent_at TEXT,
      failed_attempts INTEGER DEFAULT 0,
      locked_until TEXT
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      channel TEXT NOT NULL DEFAULT 'IN_APP',
      type TEXT NOT NULL DEFAULT 'GENERAL',
      is_read INTEGER DEFAULT 0,
      data_json TEXT DEFAULT '{}',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS notification_deliveries (
      id TEXT PRIMARY KEY,
      notification_id TEXT,
      user_id TEXT NOT NULL,
      channel TEXT NOT NULL CHECK(channel IN ('IN_APP', 'PUSH', 'SMS')),
      status TEXT NOT NULL CHECK(status IN ('SENT', 'DELIVERED', 'FAILED', 'PENDING')),
      provider_receipt TEXT,
      provider_error TEXT,
      attempt_count INTEGER DEFAULT 1,
      delivered_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS devices (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      device_token TEXT NOT NULL,
      device_type TEXT NOT NULL,
      endpoint TEXT,
      p256dh TEXT,
      auth_secret TEXT,
      last_refreshed_at TEXT NOT NULL DEFAULT (datetime('now')),
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      UNIQUE(user_id, device_token)
    );
  `);
}

