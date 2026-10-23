import test, { before, describe } from 'node:test';
import assert from 'node:assert';
import { db, initDatabase } from '../src/db/database';
import { CaseManagementService } from '../src/services/caseManagementService';
import { MissingPersonService } from '../src/services/missingPersonService';
import { SMSAdapterService } from '../src/services/smsAdapterService';
import { DrillService } from '../src/services/drillService';

describe('Phase 7: Case Management, DPDP Masking, Missing Persons, SMS Gateway & Synthetic Drills (FR-38 to FR-41, FR-48, FR-50, Part L #7)', () => {
  before(async () => {
    process.env.NODE_ENV = 'test';
    await initDatabase();
  });

  // Step 1: Case Management & DPDP Consent Capture (FR-38, FR-39)
  test('Step 1: FR-38 & FR-39 Person Case Registration with Vulnerability Profiling & DPDP Consent Capture', () => {
    const created = CaseManagementService.createCase(
      {
        household_head_name: 'Surendra Nath Mishra',
        contact_phone: '+919876599887',
        area_id: 'area-a',
        shelter_id: 'SHELTER-A1',
        household_size: 5,
        vulnerability_flags: ['ELDERLY', 'DISABLED'],
        needs_summary: 'Elderly with walking disability; needs wheelchair assistance and clean water.',
        entitlement_ration_kits: 2,
        entitlement_water_litres: 50,
        entitlement_medical_kits: 1
      },
      'USR-ADMIN-01'
    ) as any;

    assert.ok(created.id.startsWith('CASE-2026-'), 'Case ID must have CASE-2026- prefix');
    assert.strictEqual(created.status, 'OPEN');
    assert.strictEqual(created.dpdp_consent_captured, 1, 'DPDP Act 2023 consent must be captured');
    assert.strictEqual(created.entitlement_ration_kits, 2);
    assert.strictEqual(created.entitlement_water_litres, 50);

    // Verify consent record exists in consent_records table (FR-39)
    const consent = db.prepare('SELECT * FROM consent_records WHERE purpose = ? ORDER BY timestamp DESC').get('EMERGENCY_RESCUE') as any;
    assert.ok(consent, 'Consent record must be stored');
    assert.strictEqual(consent.dpdp_consent_captured, 1);
  });

  // Step 2: Role-Based Field-Level Masking (FR-39)
  test('Step 2: FR-39 Role-Based Field-Level Masking of PII (DPDP Data Minimization)', () => {
    // 1. Query as unprivileged citizen / volunteer
    const maskedCases = CaseManagementService.getAllCases({ userRole: 'CITIZEN' }) as any[];
    assert.ok(maskedCases.length > 0);
    const caseItemMasked = maskedCases.find(c => c.id === 'CASE-2026-001');
    assert.ok(caseItemMasked, 'CASE-2026-001 should be returned');
    assert.strictEqual(caseItemMasked.is_masked, true, 'Citizen must receive masked data');
    assert.ok(caseItemMasked.contact_phone.includes('****'), 'Phone number must be masked (e.g. +9198****210)');
    assert.ok(caseItemMasked.household_head_name.includes('*'), 'Name must be masked');

    // 2. Query as authorized Admin / Govt Officer
    const unmaskedCases = CaseManagementService.getAllCases({ userRole: 'ADMIN' }) as any[];
    const caseItemUnmasked = unmaskedCases.find(c => c.id === 'CASE-2026-001');
    assert.ok(caseItemUnmasked);
    assert.strictEqual(caseItemUnmasked.is_masked, false, 'Admin must see unmasked data');
    assert.strictEqual(caseItemUnmasked.contact_phone, '+919876543210', 'Full phone visible to authorized officers');
    assert.strictEqual(caseItemUnmasked.household_head_name, 'Rameshwar Paswan');
  });

  // Step 3: Auditable Duplicate Merging with Entitlement Preservation (FR-40)
  test('Step 3: FR-40 Auditable Duplicate Merging with Entitlement Preservation (No Entitlement Lost)', () => {
    // Create dedicated primary and duplicate cases to ensure test idempotency across runs
    const primaryCreated = CaseManagementService.createCase(
      {
        household_head_name: 'Merge Test Primary Head',
        contact_phone: '+919811122233',
        area_id: 'area-a',
        shelter_id: 'SHELTER-A1',
        household_size: 4,
        entitlement_ration_kits: 3,
        entitlement_water_litres: 60,
        entitlement_medical_kits: 1
      },
      'USR-ADMIN-01'
    ) as any;

    const duplicateCreated = CaseManagementService.createCase(
      {
        household_head_name: 'Merge Test Duplicate Head',
        contact_phone: '+919811122233',
        area_id: 'area-a',
        shelter_id: 'SHELTER-A1',
        household_size: 4,
        entitlement_ration_kits: 2,
        entitlement_water_litres: 30,
        entitlement_medical_kits: 0
      },
      'USR-ADMIN-01'
    ) as any;

    const primaryId = primaryCreated.id;
    const duplicateId = duplicateCreated.id;

    const primaryBefore = CaseManagementService.getCaseById(primaryId, 'ADMIN') as any;
    const duplicateBefore = CaseManagementService.getCaseById(duplicateId, 'ADMIN') as any;

    const merged = CaseManagementService.mergeCases(
      primaryId,
      duplicateId,
      'USR-ADMIN-01',
      'Confirmed same household head registered at auxiliary relief gate.'
    ) as any;

    // Verify entitlements were combined without loss (FR-40)
    const expectedRations = primaryBefore.entitlement_ration_kits + duplicateBefore.entitlement_ration_kits;
    const expectedWater = primaryBefore.entitlement_water_litres + duplicateBefore.entitlement_water_litres;

    assert.strictEqual(merged.entitlement_ration_kits, expectedRations, 'Ration entitlements must be preserved and combined');
    assert.strictEqual(merged.entitlement_water_litres, expectedWater, 'Water entitlements must be preserved and combined');

    // Verify duplicate case is closed and marked merged
    const duplicateAfter = db.prepare('SELECT * FROM person_cases WHERE id = ?').get(duplicateId) as any;
    assert.strictEqual(duplicateAfter.is_merged, 1, 'Duplicate case must have is_merged = 1');
    assert.strictEqual(duplicateAfter.status, 'CLOSED', 'Duplicate case status must be CLOSED');
    assert.strictEqual(duplicateAfter.merged_into_case_id, primaryId);

    // Verify audit log (FR-53)
    const audit = db.prepare("SELECT * FROM audit_logs WHERE entity_id = ? AND action_type = 'CASE_DUPLICATE_MERGED'").get(primaryId) as any;
    assert.ok(audit, 'Audit log must record case merge');
  });

  // Step 4: Assistance Distribution Tracking (FR-38)
  test('Step 4: FR-38 Assistance Distribution Logging & Entitlement Fulfillment Tracking', () => {
    const caseId = 'CASE-2026-002';
    const beforeCase = CaseManagementService.getCaseById(caseId, 'ADMIN') as any;

    const updated = CaseManagementService.recordAssistance(
      {
        case_id: caseId,
        assistance_type: 'RATION_KIT',
        quantity: 1,
        distribution_point: 'Danapur Central Camp Ration Counter 1',
        recipient_signature_or_otp: 'OTP-VERIFIED-9821'
      },
      'USR-ADMIN-01'
    ) as any;

    assert.strictEqual(
      updated.received_ration_kits,
      beforeCase.received_ration_kits + 1,
      'Received ration counter must increment'
    );
    assert.strictEqual(updated.status, 'IN_ASSISTANCE');

    // Verify assistance log entry
    const log = db.prepare('SELECT * FROM case_assistance_logs WHERE case_id = ? ORDER BY timestamp DESC').get(caseId) as any;
    assert.ok(log, 'Assistance log must be saved');
    assert.strictEqual(log.assistance_type, 'RATION_KIT');
    assert.strictEqual(log.quantity, 1);
  });

  // Step 5: Missing Person Registry with Child-Protection Safeguards (FR-41)
  test('Step 5: FR-41 Missing Person Registry with Child-Protection Controls & Safe-and-Well Check-in', () => {
    // 1. Report an unverified child (consent not verified yet)
    const unverifiedChild = MissingPersonService.reportMissingPerson(
      {
        full_name: 'Pooja Kumari',
        age: 7, // Child < 18
        gender: 'Female',
        last_known_location: 'Ward 2 Embankment Camp',
        last_seen_time: '2026-10-22 10:00:00',
        reported_by_user_id: 'USR-CITIZEN-01',
        child_protection_consent_verified: false // Consent NOT verified
      },
      'USR-CITIZEN-01'
    ) as any;

    assert.strictEqual(unverifiedChild.is_child, 1, 'Age < 18 must be flagged as child');
    assert.strictEqual(unverifiedChild.child_protection_consent_verified, 0);

    // 2. Query public registry -> unverified child must NOT appear in public view (Child Protection Rule)
    const publicRegistry = MissingPersonService.getAllMissingPersons({ publicOnly: true }) as any[];
    const isChildPublic = publicRegistry.some(m => m.id === unverifiedChild.id);
    assert.strictEqual(isChildPublic, false, 'Unverified child must be excluded from public listings for protection');

    // 3. Verified child (Aarav Kumar, consent verified = 1) DOES appear in public view
    const isAaravPublic = publicRegistry.some(m => m.id === 'MP-2026-001');
    assert.strictEqual(isAaravPublic, true, 'Consent-verified child is listed for community search');

    // 4. Safe-and-well check-in
    const updated = MissingPersonService.updateSafeAndWellStatus(
      'MP-2026-001',
      'AT_SHELTER',
      'SHELTER-A1',
      'USR-RESPONDER-01'
    ) as any;

    assert.strictEqual(updated.status, 'AT_SHELTER');
    assert.strictEqual(updated.shelter_id, 'SHELTER-A1');
  });

  // Step 6: Inbound SMS Gateway Parser & Incident Creation (FR-48, FR-50)
  test('Step 6: FR-48 & FR-50 Inbound SMS Gateway Parser, De-duplication & Automatic Incident Ingestion', () => {
    const rawSms = 'HELP FLOOD East Embankment Ridge near Primary School 6 people trapped water rising need rescue boat';
    const sender = `+919811${Math.floor(100000 + Math.random() * 900000)}`;

    // 1. Parse inbound SMS
    const result1 = SMSAdapterService.parseInboundSMS(sender, rawSms);

    assert.strictEqual(result1.delivery_status, 'PROCESSED');
    assert.strictEqual(result1.parsed_category, 'FLOOD');
    assert.strictEqual(result1.parsed_urgency, 'CRITICAL');
    assert.strictEqual(result1.parsed_people_count, 6);
    assert.ok(result1.parsed_needs.includes('boat') || result1.parsed_needs.includes('water'));
    assert.ok(result1.incident_id, 'Should automatically create linked Incident');

    // Verify incident was created in database
    const inc = db.prepare('SELECT * FROM incidents WHERE id = ?').get(result1.incident_id) as any;
    assert.ok(inc, 'Incident must be inserted in DB');
    assert.strictEqual(inc.category, 'FLOOD');
    assert.strictEqual(inc.urgency, 'CRITICAL');
    assert.strictEqual(inc.people_affected, 6);

    // 2. Test De-duplication: immediate identical SMS from same number is flagged as DUPLICATE_IGNORED (FR-50)
    const result2 = SMSAdapterService.parseInboundSMS(sender, rawSms);
    assert.strictEqual(result2.delivery_status, 'DUPLICATE_IGNORED', 'Duplicate SMS within 5 min must be de-duplicated');
  });

  // Step 7: Synthetic Drill Simulation Engine (Part L Item 7)
  test('Step 7: Part L Item 7 Synthetic Drill Simulation Engine with Watermarked Test Incidents & Isolation', () => {
    // 1. Start synthetic drill session
    const drill = DrillService.startDrill(
      'Operation Flash-Flood Simulation 2026',
      'URBAN_FLASH_FLOOD',
      'USR-ADMIN-01'
    ) as any;

    assert.ok(drill.id.startsWith('DRILL-'), 'Drill session must receive DRILL- ID');
    assert.strictEqual(drill.status, 'ACTIVE');
    assert.strictEqual(drill.is_watermarked_synthetic, 1, 'Must be flagged as synthetic');

    // 2. Verify synthetic incidents are created and isolated with watermarks
    const syntheticIncidents = db.prepare('SELECT * FROM incidents WHERE is_simulated_drill = 1 AND id LIKE ?').all(`%${drill.id}%`) as any[];
    assert.strictEqual(syntheticIncidents.length, 3, 'Must inject 3 synthetic training incidents');
    for (const inc of syntheticIncidents) {
      assert.ok(inc.title.includes('[SIMULATED DRILL]'), 'Synthetic incident title must carry clear watermark prefix');
    }

    // 3. Conclude drill session
    const concluded = DrillService.concludeDrill(drill.id, 'USR-ADMIN-01') as any;
    assert.strictEqual(concluded.status, 'CONCLUDED');

    // 4. Verify synthetic incidents are safely cleaned up from operational pool
    const remainingSynth = db.prepare('SELECT * FROM incidents WHERE is_simulated_drill = 1 AND id LIKE ?').all(`%${drill.id}%`);
    assert.strictEqual(remainingSynth.length, 0, 'Concluded drill synthetic incidents must be archived/cleaned up');
  });
});
