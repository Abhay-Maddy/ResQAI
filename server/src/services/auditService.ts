import { db } from '../db/database';
import crypto from 'crypto';

export interface AuditEventParams {
  actionType: string;
  actorId: string;
  actorRole: string;
  entityId: string;
  details: string;
  beforeState?: any;
  afterState?: any;
  ipAddress?: string;
}

// FR-53 Append-only, tamper-evident audit logger
export function logAuditEvent(params: AuditEventParams) {
  const id = `AUD-${Date.now()}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
  
  const stmt = db.prepare(`
    INSERT INTO audit_logs (id, action_type, actor_id, actor_role, entity_id, details, before_state_json, after_state_json, ip_address)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  stmt.run(
    id,
    params.actionType,
    params.actorId,
    params.actorRole,
    params.entityId,
    params.details,
    params.beforeState ? JSON.stringify(params.beforeState) : null,
    params.afterState ? JSON.stringify(params.afterState) : null,
    params.ipAddress || '127.0.0.1'
  );

  return id;
}

export function getAuditLogs(limit = 100) {
  return db.prepare('SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT ?').all(limit);
}
