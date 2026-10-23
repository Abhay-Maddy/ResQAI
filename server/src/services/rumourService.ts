import { db } from '../db/database';
import crypto from 'crypto';
import { logAuditEvent } from './auditService';

export interface RumourReportInput {
  reported_claim: string;
  source_platform: string;
}

export interface RumourRecord {
  id: string;
  reported_claim: string;
  source_platform: string;
  counter_verification_status: 'DEBUNKED' | 'OFFICIALLY_CONFIRMED' | 'INVESTIGATING';
  official_correction_notice?: string;
  timestamp: string;
}

export class RumourService {
  /**
   * Submit an unverified rumour / misinformation report
   */
  static reportRumour(input: RumourReportInput, reporterId: string): RumourRecord {
    const id = `RUMOUR-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
    const timestamp = new Date().toISOString();

    db.prepare(`
      INSERT INTO rumour_reports (
        id, reported_claim, source_platform,
        counter_verification_status, timestamp
      ) VALUES (?, ?, ?, 'INVESTIGATING', ?)
    `).run(id, input.reported_claim, input.source_platform, timestamp);

    logAuditEvent({
      actionType: 'RUMOUR_REPORTED',
      actorId: reporterId,
      actorRole: 'CITIZEN',
      entityId: id,
      details: `Reported claim from ${input.source_platform}: "${input.reported_claim.substring(0, 60)}..."`
    });

    return {
      id,
      reported_claim: input.reported_claim,
      source_platform: input.source_platform,
      counter_verification_status: 'INVESTIGATING',
      timestamp
    };
  }

  /**
   * Official fact-check review queue action (Admin / Govt Officer only)
   */
  static verifyRumour(
    rumourId: string,
    decision: 'DEBUNKED' | 'OFFICIALLY_CONFIRMED' | 'INVESTIGATING',
    correctionNotice: string,
    officerId: string,
    officerRole: string
  ): RumourRecord {
    if (!['ADMIN', 'GOVT_OFFICER'].includes(officerRole)) {
      throw new Error(`Unauthorized: Role '${officerRole}' cannot verify or debunk rumors.`);
    }

    const existing = db.prepare('SELECT * FROM rumour_reports WHERE id = ?').get(rumourId) as RumourRecord;
    if (!existing) {
      throw new Error(`Rumour with ID '${rumourId}' not found.`);
    }

    db.prepare(`
      UPDATE rumour_reports
      SET counter_verification_status = ?,
          official_correction_notice = ?
      WHERE id = ?
    `).run(decision, correctionNotice, rumourId);

    logAuditEvent({
      actionType: 'RUMOUR_FACTCHECK_DECISION',
      actorId: officerId,
      actorRole: officerRole,
      entityId: rumourId,
      details: `Marked rumour ${rumourId} as ${decision}. Correction: "${correctionNotice}"`,
      beforeState: existing,
      afterState: { ...existing, counter_verification_status: decision, official_correction_notice: correctionNotice }
    });

    return {
      ...existing,
      counter_verification_status: decision,
      official_correction_notice: correctionNotice
    };
  }

  /**
   * Get all rumours (for review queue)
   */
  static getAllRumours(statusFilter?: string): RumourRecord[] {
    let query = 'SELECT * FROM rumour_reports';
    const params: any[] = [];

    if (statusFilter && statusFilter !== 'ALL') {
      query += ' WHERE counter_verification_status = ?';
      params.push(statusFilter);
    }

    query += ' ORDER BY timestamp DESC';
    return db.prepare(query).all(...params) as RumourRecord[];
  }

  /**
   * Get verified public fact checks (for citizens)
   */
  static getPublicFactChecks(): RumourRecord[] {
    return db.prepare(`
      SELECT * FROM rumour_reports
      WHERE counter_verification_status IN ('DEBUNKED', 'OFFICIALLY_CONFIRMED')
      ORDER BY timestamp DESC
    `).all() as RumourRecord[];
  }
}
