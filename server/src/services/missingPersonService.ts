import { db } from '../db/database';
import crypto from 'crypto';

export interface MissingPersonInput {
  full_name: string;
  age: number;
  gender: string;
  last_known_location: string;
  last_seen_time: string;
  reported_by_user_id: string;
  shelter_id?: string;
  child_protection_consent_verified?: boolean;
}

export class MissingPersonService {
  // FR-41: Query missing person registry with Child-Protection Safeguards
  public static getAllMissingPersons(filter?: { status?: string; publicOnly?: boolean }) {
    let query = `
      SELECT m.*, u.name as reporter_name
      FROM missing_person_records m
      LEFT JOIN users u ON m.reported_by_user_id = u.id
      WHERE 1=1
    `;
    const params: any[] = [];

    // FR-41: In public view, children (age < 18) are ONLY visible if child protection consent is verified
    if (filter?.publicOnly) {
      query += ` AND (m.is_child = 0 OR (m.is_child = 1 AND m.child_protection_consent_verified = 1))`;
    }

    if (filter?.status) {
      query += ` AND m.status = ?`;
      params.push(filter.status);
    }

    query += ` ORDER BY m.created_at DESC`;

    const stmt = db.prepare(query);
    return stmt.all(...params);
  }

  public static getById(id: string) {
    const stmt = db.prepare(`
      SELECT m.*, u.name as reporter_name
      FROM missing_person_records m
      LEFT JOIN users u ON m.reported_by_user_id = u.id
      WHERE m.id = ?
    `);
    return stmt.get(id);
  }

  public static reportMissingPerson(input: MissingPersonInput, actorId: string) {
    const isChild = input.age < 18 ? 1 : 0;
    const consentVerified = input.child_protection_consent_verified ? 1 : 0;
    const id = `MP-2026-${crypto.randomUUID().substring(0, 6).toUpperCase()}`;

    const stmt = db.prepare(`
      INSERT INTO missing_person_records (
        id, full_name, age, gender, last_known_location, last_seen_time,
        reported_by_user_id, status, shelter_id, is_child, child_protection_consent_verified
      ) VALUES (
        @id, @full_name, @age, @gender, @last_known_location, @last_seen_time,
        @reported_by_user_id, 'SEARCHING', @shelter_id, @is_child, @child_protection_consent_verified
      )
    `);

    stmt.run({
      id,
      full_name: input.full_name,
      age: input.age,
      gender: input.gender,
      last_known_location: input.last_known_location,
      last_seen_time: input.last_seen_time,
      reported_by_user_id: input.reported_by_user_id || actorId,
      shelter_id: input.shelter_id || null,
      is_child: isChild,
      child_protection_consent_verified: consentVerified
    });

    // Audit log (FR-53)
    db.prepare(`
      INSERT INTO audit_logs (id, action_type, actor_id, actor_role, entity_id, details)
      VALUES (?, 'MISSING_PERSON_REPORTED', ?, 'CITIZEN', ?, ?)
    `).run(
      `AUD-${crypto.randomUUID().substring(0, 8)}`,
      actorId,
      id,
      `Reported missing: ${input.full_name} (${input.age} y/o). Child Protection Status: ${isChild ? (consentVerified ? 'CONSENT_VERIFIED' : 'CONSENT_PENDING') : 'ADULT'}`
    );

    return this.getById(id);
  }

  // Safe-and-well check-in (FR-41)
  public static updateSafeAndWellStatus(
    id: string,
    status: 'SEARCHING' | 'FOUND_SAFE' | 'AT_SHELTER' | 'HOSPITALIZED',
    shelterId?: string,
    actorId?: string
  ) {
    const record = this.getById(id) as any;
    if (!record) {
      throw new Error(`Missing person record ${id} not found`);
    }

    db.prepare(`
      UPDATE missing_person_records
      SET status = ?, shelter_id = COALESCE(?, shelter_id)
      WHERE id = ?
    `).run(status, shelterId || null, id);

    // Audit log
    db.prepare(`
      INSERT INTO audit_logs (id, action_type, actor_id, actor_role, entity_id, details)
      VALUES (?, 'SAFE_AND_WELL_CHECKIN', ?, 'RESPONDER', ?, ?)
    `).run(
      `AUD-${crypto.randomUUID().substring(0, 8)}`,
      actorId || 'USR-ADMIN-01',
      id,
      `Safe-and-well status updated to ${status} for ${record.full_name} at shelter ${shelterId || 'N/A'}`
    );

    return this.getById(id);
  }
}
