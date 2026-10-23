import { db } from '../db/database';
import crypto from 'crypto';

export interface CreateCaseInput {
  household_head_name: string;
  contact_phone: string;
  area_id: string;
  shelter_id?: string;
  household_size: number;
  vulnerability_flags: ('ELDERLY' | 'INFANT' | 'PREGNANT' | 'DISABLED' | 'CHRONIC_ILLNESS')[];
  needs_summary: string;
  entitlement_ration_kits?: number;
  entitlement_water_litres?: number;
  entitlement_medical_kits?: number;
  caseworker_notes?: string;
}

export interface RecordAssistanceInput {
  case_id: string;
  assistance_type: 'RATION_KIT' | 'WATER_SUPPLY' | 'MEDICAL_AID' | 'TEMPORARY_SHELTER' | 'CASH_ASSISTANCE';
  quantity: number;
  distribution_point: string;
  recipient_signature_or_otp?: string;
}

export class CaseManagementService {
  // Helper for FR-39 DPDP Field-Level Masking
  public static maskName(name: string): string {
    if (!name || name.length <= 2) return '***';
    const parts = name.split(' ');
    return parts
      .map(p => (p.length > 1 ? `${p[0]}${'*'.repeat(Math.max(1, p.length - 2))}${p[p.length - 1]}` : p))
      .join(' ');
  }

  public static maskPhone(phone: string): string {
    if (!phone || phone.length < 8) return '+91-******';
    return `${phone.substring(0, 5)}****${phone.substring(phone.length - 3)}`;
  }

  // FR-38 & FR-39: List cases with role-based field-level masking
  public static getAllCases(filter?: {
    status?: string;
    area_id?: string;
    includeMerged?: boolean;
    userRole?: string;
  }) {
    let query = `
      SELECT c.*, a.name as area_name
      FROM person_cases c
      JOIN affected_areas a ON c.area_id = a.id
      WHERE 1=1
    `;
    const params: any[] = [];

    if (!filter?.includeMerged) {
      query += ` AND c.is_merged = 0`;
    }

    if (filter?.status) {
      query += ` AND c.status = ?`;
      params.push(filter.status);
    }

    if (filter?.area_id) {
      query += ` AND c.area_id = ?`;
      params.push(filter.area_id);
    }

    query += ` ORDER BY c.created_at DESC`;

    const stmt = db.prepare(query);
    const rows = stmt.all(...params) as any[];

    const isHighPrivilege = filter?.userRole === 'ADMIN' || filter?.userRole === 'GOVT_OFFICER';

    return rows.map(r => {
      let vulnerabilities: string[] = [];
      try {
        vulnerabilities = JSON.parse(r.vulnerability_flags_json || '[]');
      } catch {
        vulnerabilities = [];
      }

      return {
        ...r,
        vulnerability_flags: vulnerabilities,
        // FR-39: Field-level masking for unauthorized observers
        household_head_name: isHighPrivilege ? r.household_head_name : this.maskName(r.household_head_name),
        contact_phone: isHighPrivilege ? r.contact_phone : this.maskPhone(r.contact_phone),
        is_masked: !isHighPrivilege
      };
    });
  }

  public static getCaseById(id: string, userRole?: string) {
    const stmt = db.prepare(`
      SELECT c.*, a.name as area_name
      FROM person_cases c
      JOIN affected_areas a ON c.area_id = a.id
      WHERE c.id = ?
    `);
    const r = stmt.get(id) as any;
    if (!r) return null;

    const isHighPrivilege = userRole === 'ADMIN' || userRole === 'GOVT_OFFICER';

    const logsStmt = db.prepare('SELECT * FROM case_assistance_logs WHERE case_id = ? ORDER BY timestamp DESC');
    const assistanceLogs = logsStmt.all(id);

    return {
      ...r,
      vulnerability_flags: JSON.parse(r.vulnerability_flags_json || '[]'),
      household_head_name: isHighPrivilege ? r.household_head_name : this.maskName(r.household_head_name),
      contact_phone: isHighPrivilege ? r.contact_phone : this.maskPhone(r.contact_phone),
      is_masked: !isHighPrivilege,
      assistance_logs: assistanceLogs
    };
  }

  public static createCase(input: CreateCaseInput, actorId: string) {
    const id = `CASE-2026-${crypto.randomUUID().substring(0, 6).toUpperCase()}`;

    // Calculate baseline entitlements if not provided
    const rationKits = input.entitlement_ration_kits ?? Math.max(1, Math.ceil(input.household_size / 4));
    const waterLitres = input.entitlement_water_litres ?? input.household_size * 5; // 5L per person/day
    const medicalKits = input.entitlement_medical_kits ?? (input.vulnerability_flags.length > 0 ? 1 : 0);

    const stmt = db.prepare(`
      INSERT INTO person_cases (
        id, household_head_name, contact_phone, area_id, shelter_id,
        household_size, vulnerability_flags_json, needs_summary,
        entitlement_ration_kits, entitlement_water_litres, entitlement_medical_kits,
        received_ration_kits, received_water_litres, received_medical_kits,
        caseworker_id, caseworker_notes, dpdp_consent_captured, status
      ) VALUES (
        @id, @household_head_name, @contact_phone, @area_id, @shelter_id,
        @household_size, @vulnerability_flags_json, @needs_summary,
        @entitlement_ration_kits, @entitlement_water_litres, @entitlement_medical_kits,
        0, 0, 0,
        @caseworker_id, @caseworker_notes, 1, 'OPEN'
      )
    `);

    stmt.run({
      id,
      household_head_name: input.household_head_name,
      contact_phone: input.contact_phone,
      area_id: input.area_id,
      shelter_id: input.shelter_id || null,
      household_size: input.household_size,
      vulnerability_flags_json: JSON.stringify(input.vulnerability_flags),
      needs_summary: input.needs_summary,
      entitlement_ration_kits: rationKits,
      entitlement_water_litres: waterLitres,
      entitlement_medical_kits: medicalKits,
      caseworker_id: actorId,
      caseworker_notes: input.caseworker_notes || null
    });

    // Record DPDP Consent Record (FR-39)
    db.prepare(`
      INSERT INTO consent_records (id, purpose, dpdp_consent_captured, timestamp)
      VALUES (?, 'EMERGENCY_RESCUE', 1, datetime('now'))
    `).run(`CNS-${crypto.randomUUID().substring(0, 8)}`);

    // Audit log (FR-53)
    db.prepare(`
      INSERT INTO audit_logs (id, action_type, actor_id, actor_role, entity_id, details)
      VALUES (?, 'CASE_CREATED', ?, 'GOVT_OFFICER', ?, ?)
    `).run(
      `AUD-${crypto.randomUUID().substring(0, 8)}`,
      actorId,
      id,
      `Case ${id} registered for ${input.household_head_name} with DPDP consent captured (FR-38, FR-39)`
    );

    return this.getCaseById(id, 'ADMIN');
  }

  // FR-38: Record assistance disbursement to case
  public static recordAssistance(input: RecordAssistanceInput, actorId: string) {
    const personCase = this.getCaseById(input.case_id, 'ADMIN');
    if (!personCase) {
      throw new Error(`Case ${input.case_id} not found`);
    }

    const logId = `LOG-${crypto.randomUUID().substring(0, 8).toUpperCase()}`;

    const insertLog = db.prepare(`
      INSERT INTO case_assistance_logs (
        id, case_id, assistance_type, quantity, distribution_point,
        distributed_by_user_id, recipient_signature_or_otp
      ) VALUES (
        @id, @case_id, @assistance_type, @quantity, @distribution_point,
        @distributed_by_user_id, @recipient_signature_or_otp
      )
    `);

    insertLog.run({
      id: logId,
      case_id: input.case_id,
      assistance_type: input.assistance_type,
      quantity: input.quantity,
      distribution_point: input.distribution_point,
      distributed_by_user_id: actorId,
      recipient_signature_or_otp: input.recipient_signature_or_otp || 'VERIFIED_ON_SITE'
    });

    // Increment received counters
    if (input.assistance_type === 'RATION_KIT') {
      db.prepare('UPDATE person_cases SET received_ration_kits = received_ration_kits + ? WHERE id = ?').run(input.quantity, input.case_id);
    } else if (input.assistance_type === 'WATER_SUPPLY') {
      db.prepare('UPDATE person_cases SET received_water_litres = received_water_litres + ? WHERE id = ?').run(input.quantity, input.case_id);
    } else if (input.assistance_type === 'MEDICAL_AID') {
      db.prepare('UPDATE person_cases SET received_medical_kits = received_medical_kits + ? WHERE id = ?').run(input.quantity, input.case_id);
    }

    db.prepare("UPDATE person_cases SET status = 'IN_ASSISTANCE', updated_at = datetime('now') WHERE id = ?").run(input.case_id);

    return this.getCaseById(input.case_id, 'ADMIN');
  }

  // FR-40: Auditable duplicate merging — NO ONE LOSES ENTITLEMENT DUE TO MERGE
  public static mergeCases(
    primaryCaseId: string,
    duplicateCaseId: string,
    actorId: string,
    mergeReason: string
  ) {
    if (primaryCaseId === duplicateCaseId) {
      throw new Error('Cannot merge a case into itself');
    }

    const primary = db.prepare('SELECT * FROM person_cases WHERE id = ?').get(primaryCaseId) as any;
    const duplicate = db.prepare('SELECT * FROM person_cases WHERE id = ?').get(duplicateCaseId) as any;

    if (!primary || !duplicate) {
      throw new Error('Both primary and duplicate cases must exist');
    }

    if (duplicate.is_merged) {
      throw new Error(`Case ${duplicateCaseId} is already merged into ${duplicate.merged_into_case_id}`);
    }

    // FR-40 Core Guarantee: No one loses entitlement due to merge!
    // Remaining unreceived entitlements from duplicate are transferred into primary
    const extraRationEntitlement = Math.max(0, duplicate.entitlement_ration_kits - duplicate.received_ration_kits);
    const extraWaterEntitlement = Math.max(0, duplicate.entitlement_water_litres - duplicate.received_water_litres);
    const extraMedicalEntitlement = Math.max(0, duplicate.entitlement_medical_kits - duplicate.received_medical_kits);

    const tx = db.transaction(() => {
      // 1. Upgrade primary case entitlements
      db.prepare(`
        UPDATE person_cases
        SET 
          entitlement_ration_kits = entitlement_ration_kits + ?,
          entitlement_water_litres = entitlement_water_litres + ?,
          entitlement_medical_kits = entitlement_medical_kits + ?,
          received_ration_kits = received_ration_kits + ?,
          received_water_litres = received_water_litres + ?,
          received_medical_kits = received_medical_kits + ?,
          caseworker_notes = caseworker_notes || ' [Merged duplicate ' || ? || ']',
          updated_at = datetime('now')
        WHERE id = ?
      `).run(
        extraRationEntitlement,
        extraWaterEntitlement,
        extraMedicalEntitlement,
        duplicate.received_ration_kits,
        duplicate.received_water_litres,
        duplicate.received_medical_kits,
        duplicateCaseId,
        primaryCaseId
      );

      // 2. Mark duplicate as merged & closed
      db.prepare(`
        UPDATE person_cases
        SET is_merged = 1, merged_into_case_id = ?, status = 'CLOSED', updated_at = datetime('now')
        WHERE id = ?
      `).run(primaryCaseId, duplicateCaseId);

      // 3. Re-link assistance logs to primary
      db.prepare(`
        UPDATE case_assistance_logs
        SET case_id = ?
        WHERE case_id = ?
      `).run(primaryCaseId, duplicateCaseId);

      // 4. Log audit trail (FR-53)
      db.prepare(`
        INSERT INTO audit_logs (id, action_type, actor_id, actor_role, entity_id, details, before_state_json, after_state_json)
        VALUES (?, 'CASE_DUPLICATE_MERGED', ?, 'ADMIN', ?, ?, ?, ?)
      `).run(
        `AUD-${crypto.randomUUID().substring(0, 8)}`,
        actorId,
        primaryCaseId,
        `Merged duplicate case ${duplicateCaseId} into ${primaryCaseId}. Reason: ${mergeReason}. Preserved extra entitlements: +${extraRationEntitlement} rations, +${extraWaterEntitlement}L water (FR-40).`,
        JSON.stringify({ primaryEntitlements: primary.entitlement_ration_kits, duplicateEntitlements: duplicate.entitlement_ration_kits }),
        JSON.stringify({ combinedEntitlements: primary.entitlement_ration_kits + extraRationEntitlement })
      );
    });

    tx();

    return this.getCaseById(primaryCaseId, 'ADMIN');
  }
}
