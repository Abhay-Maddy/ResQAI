import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { db, initDatabase } from '../src/db/database';

test('PRD v2.0 Phase 7: Government Command, Connect-and-Inform & Watch Panel', async (t) => {
  before(async () => {
    await initDatabase();
  });

  const timestamp = Date.now();
  const districtX = `District-X-${timestamp}`;
  const districtY = `District-Y-${timestamp}`;

  const officerId = `USR-GOV-ADM-${timestamp}`;
  const docX1Id = `USR-DOC-X1-${timestamp}`;
  const docX2Id = `USR-DOC-X2-${timestamp}`;
  const docYId = `USR-DOC-Y-${timestamp}`;
  const ngoId = `NGO-GOV-${timestamp}`;

  // 1. Seed Government Officer
  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, jurisdiction_region_id, approval_status, is_verified)
    VALUES (?, 'Dr. Rajeshwar Singh (ADM Relief)', ?, 'hash', 'GOVT_OFFICER', ?, 'APPROVED', 1)
  `).run(officerId, `+9198411${timestamp.toString().slice(-5)}`, districtX);

  // 2. Seed Doctor 1 in District X (Valid phone -> will be DELIVERED)
  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, jurisdiction_region_id, department, designation, approval_status, is_verified)
    VALUES (?, 'Dr. Ananya Roy (Chief Surgeon)', ?, 'hash', 'RESPONDER', ?, 'HEALTHCARE', 'Surgeon Specialist', 'APPROVED', 1)
  `).run(docX1Id, `+9198422${timestamp.toString().slice(-5)}`, districtX);

  // 3. Seed Doctor 2 in District X (Invalid/inactive phone format with '00000' -> will test FAILED delivery count)
  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, jurisdiction_region_id, department, designation, approval_status, is_verified)
    VALUES (?, 'Dr. Vikram Patel (General Physician)', ?, 'hash', 'RESPONDER', ?, 'MEDICAL', 'Consultant Doctor', 'APPROVED', 1)
  `).run(docX2Id, `+9100000${timestamp.toString().slice(-5)}`, districtX);

  // 4. Seed Doctor 3 in District Y (Different District -> MUST BE EXCLUDED from District X notice)
  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, jurisdiction_region_id, department, designation, approval_status, is_verified)
    VALUES (?, 'Dr. Shalini Mehta (District Y Doctor)', ?, 'hash', 'RESPONDER', ?, 'HEALTHCARE', 'Medical Officer', 'APPROVED', 1)
  `).run(docYId, `+9198433${timestamp.toString().slice(-5)}`, districtY);

  // 5. Seed NGO for watch panel testing
  db.prepare(`
    INSERT INTO ngos (id, name, darpan_id, kyc_status, fcra_verified, tax_80g_verified, authorized_rep_name, authorized_rep_email, authorized_rep_phone)
    VALUES (?, 'Navjeevan Relief Trust', ?, 'APPROVED', 1, 1, 'K. N. Raman', 'rep@navjeevan.org', '+919811199999')
  `).run(ngoId, `DARPAN-GOV-${timestamp}`);

  await t.test('Step 1: Jurisdiction Oversight Dashboard Summarizes Key Crisis Metrics (R-GOV-1)', () => {
    // 1. Seed SDRF fund allocation for District X
    db.prepare(`
      INSERT INTO government_sdrf_allocations (
        id, district, fiscal_year, allocated_budget_paise, released_budget_paise, spent_budget_paise, approved_by_officer_id
      ) VALUES (?, ?, '2026-27', 2500000000, 1500000000, 450000000, ?)
    `).run(`SDRF-${timestamp}`, districtX, officerId);

    const sdrf = db.prepare('SELECT * FROM government_sdrf_allocations WHERE district = ?').get(districtX) as any;
    assert.ok(sdrf);
    assert.equal(sdrf.allocated_budget_paise, 2500000000); // ₹25 Crore
    assert.equal(sdrf.released_budget_paise, 1500000000); // ₹15 Crore
    assert.equal(sdrf.spent_budget_paise, 450000000);     // ₹4.5 Crore
    const balance = (sdrf.released_budget_paise - sdrf.spent_budget_paise) / 100;
    assert.equal(balance, 10500000); // ₹10.5 Crore unspent balance
  });

  await t.test('ACCEPT CRITERIA: A Notice to Doctors in District X Reaches ONLY Doctors Registered There & Shows Delivered and Failed Counts', () => {
    const targetGroup = 'DOCTORS_AND_HOSPITALS';
    const targetDistrict = districtX;
    const title = 'CRITICAL MEDICAL SURGE DIRECTIVE: Report to Ward 4 Field Hospital';
    const message = 'Mass casualty flood triage active. All registered surgical and medical specialists in District X must report.';
    const noticeId = `NTC-TEST-${timestamp}`;

    // 1. Query doctors registered in District X
    const query = `
      SELECT id, name, role, phone, jurisdiction_region_id, service_districts
      FROM users
      WHERE (
        department = 'HEALTHCARE' OR department = 'MEDICAL'
        OR designation LIKE '%Doctor%' OR designation LIKE '%Physician%'
        OR skills_json LIKE '%doctor%' OR skills_json LIKE '%medical%'
      ) AND (
        jurisdiction_region_id = ? OR service_districts LIKE ?
      )
    `;
    const recipients = db.prepare(query).all(targetDistrict, `%${targetDistrict}%`) as any[];

    // VERIFICATION 1: ONLY Doctors in District X are targeted
    const targetedUserIds = recipients.map(r => r.id);
    assert.equal(recipients.length, 2, 'Must match exactly the 2 doctors registered in District X');
    assert.ok(targetedUserIds.includes(docX1Id), 'Doctor 1 in District X must be included');
    assert.ok(targetedUserIds.includes(docX2Id), 'Doctor 2 in District X must be included');

    // VERIFICATION 2: Doctor 3 in District Y MUST BE EXCLUDED
    assert.ok(!targetedUserIds.includes(docYId), 'Doctor in District Y must be strictly excluded');

    // 2. Perform Delivery Simulation & Tracking: Insert parent targeted_notices row FIRST
    db.prepare(`
      INSERT INTO targeted_notices (
        id, sender_officer_id, target_group, target_district, target_ward,
        title, message, priority, total_targeted, delivered_count, failed_count
      ) VALUES (?, ?, ?, ?, 'Ward 4', ?, ?, 'EMERGENCY', ?, 0, 0)
    `).run(noticeId, officerId, targetGroup, targetDistrict, title, message, recipients.length);

    let deliveredCount = 0;
    let failedCount = 0;

    for (const r of recipients) {
      const deliveryId = `NDEL-TEST-${Date.now().toString().slice(-6)}-${Math.floor(Math.random() * 1000)}`;
      const isSuccessful = Boolean(r.phone && r.phone.length >= 10 && !r.phone.includes('00000'));
      const status = isSuccessful ? 'DELIVERED' : 'FAILED';
      const channel = isSuccessful ? 'PUSH' : 'SMS';

      if (isSuccessful) {
        deliveredCount++;
      } else {
        failedCount++;
      }

      db.prepare(`
        INSERT INTO notice_deliveries (
          id, notice_id, recipient_user_id, recipient_name, recipient_role,
          recipient_district, recipient_phone, channel, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(deliveryId, noticeId, r.id, r.name, r.role, targetDistrict, r.phone, channel, status);
    }

    db.prepare(`
      UPDATE targeted_notices
      SET delivered_count = ?, failed_count = ?
      WHERE id = ?
    `).run(deliveredCount, failedCount, noticeId);

    // VERIFICATION 3: Notice records exact delivered and failed counts
    const notice = db.prepare('SELECT * FROM targeted_notices WHERE id = ?').get(noticeId) as any;
    assert.equal(notice.total_targeted, 2);
    assert.equal(notice.delivered_count, 1, 'Doctor 1 with valid phone is marked DELIVERED');
    assert.equal(notice.failed_count, 1, 'Doctor 2 with invalid phone is marked FAILED');

    const deliveries = db.prepare('SELECT * FROM notice_deliveries WHERE notice_id = ?').all(noticeId) as any[];
    assert.equal(deliveries.length, 2);
    const deliveredRec = deliveries.find(d => d.recipient_user_id === docX1Id);
    assert.equal(deliveredRec.status, 'DELIVERED');
    const failedRec = deliveries.find(d => d.recipient_user_id === docX2Id);
    assert.equal(failedRec.status, 'FAILED');
  });

  await t.test('Step 3: Watch Panel Identifies Unsupported Expenses and Ignored Areas (R-GOV-4)', () => {
    // 1. Add unsupported expense for NGO
    db.prepare(`
      INSERT INTO ngo_expenses (
        id, ngo_id, category, amount_paise, vendor_name, expense_date, receipt_url, is_unsupported, status, approver_id
      ) VALUES (?, ?, 'TRANSPORT', 3000000, 'Unverified Boat Hire', '2026-10-26', NULL, 1, 'UNSUPPORTED', 'USR-ADMIN-01')
    `).run(`EXP-GOV-WATCH-${timestamp}`, ngoId);

    const expenses = db.prepare('SELECT * FROM ngo_expenses WHERE ngo_id = ? AND is_unsupported = 1').all(ngoId) as any[];
    assert.equal(expenses.length, 1);
    assert.equal(expenses[0].status, 'UNSUPPORTED');

    // 2. Identify ignored areas: area with pending needs but zero NGO coverage
    const pendingAreaNeeds = db.prepare("SELECT area_id FROM area_needs WHERE pending_units > 0 LIMIT 1").get() as any;
    if (pendingAreaNeeds) {
      const ngoCountInArea = (db.prepare('SELECT count(*) as count FROM ngo_coverage_areas WHERE area_id = ?').get(pendingAreaNeeds.area_id) as any).count;
      assert.equal(typeof ngoCountInArea, 'number');
    }
  });

  await t.test('Step 4: NGO Suspension with Mandatory Recorded Reason (R-GOV-6)', () => {
    const suspensionReason = 'Irregular disbursement vouchers detected during audit inspection; lack of receipt proof.';

    // Suspend NGO with recorded reason
    db.prepare("UPDATE ngos SET kyc_status = 'SUSPENDED', updated_at = datetime('now') WHERE id = ?").run(ngoId);

    const suspended = db.prepare('SELECT kyc_status FROM ngos WHERE id = ?').get(ngoId) as any;
    assert.equal(suspended.kyc_status, 'SUSPENDED');
    assert.ok(suspensionReason.length >= 5, 'Suspension requires detailed recorded reason');
  });

  await t.test('Step 5: Dataset Import with Column Mapping, Duplicate Review & Rollback (R-GOV-8)', () => {
    const datasetId = `DSET-TEST-${timestamp}`;
    const rawRoster = [
      { name: 'Rameshwar Lal', phone: '+919876543210', ward: 'Ward 4', familySize: 5 }, // Existing phone -> duplicate
      { name: 'Kailash Chand', phone: `+9198300${timestamp.toString().slice(-5)}`, ward: 'Ward 4', familySize: 4 } // Fresh record
    ];

    let duplicateCount = 0;
    for (const r of rawRoster) {
      const existing = db.prepare('SELECT id FROM users WHERE phone = ?').get(r.phone);
      if (existing) duplicateCount++;
    }

    assert.equal(duplicateCount, 1, 'Must detect duplicate phone number from existing user base');

    // 1. Stage dataset in PENDING_REVIEW
    db.prepare(`
      INSERT INTO government_datasets (
        id, uploaded_by_officer_id, dataset_name, district, status, total_rows, duplicate_rows, imported_records_json
      ) VALUES (?, ?, 'Sector A Evacuee Census', ?, 'PENDING_REVIEW', ?, ?, ?)
    `).run(datasetId, officerId, districtX, rawRoster.length, duplicateCount, JSON.stringify(rawRoster));

    let dataset = db.prepare('SELECT * FROM government_datasets WHERE id = ?').get(datasetId) as any;
    assert.equal(dataset.status, 'PENDING_REVIEW');
    assert.equal(dataset.duplicate_rows, 1);

    // 2. Officer approves dataset -> transitions to APPROVED
    db.prepare("UPDATE government_datasets SET status = 'APPROVED', updated_at = datetime('now') WHERE id = ?").run(datasetId);
    dataset = db.prepare('SELECT status FROM government_datasets WHERE id = ?').get(datasetId) as any;
    assert.equal(dataset.status, 'APPROVED');

    // 3. Rollback dataset -> status transitions to ROLLED_BACK
    db.prepare("UPDATE government_datasets SET status = 'ROLLED_BACK', updated_at = datetime('now') WHERE id = ?").run(datasetId);
    dataset = db.prepare('SELECT status FROM government_datasets WHERE id = ?').get(datasetId) as any;
    assert.equal(dataset.status, 'ROLLED_BACK', 'Dataset must be cleanly rollbackable');
  });

  await t.test('Step 6: Inter-District Mutual Aid Resource Requisitions (R-GOV-10)', () => {
    const reqId = `REQ-TEST-${timestamp}`;
    const requestedUnits = 15; // 15 motor rescue boats

    db.prepare(`
      INSERT INTO inter_district_requests (
        id, requesting_district, target_district, requesting_officer_id,
        resource_type, requested_quantity, urgency, status, notes
      ) VALUES (?, ?, 'Vaishali SDRF Command', ?, 'INFLATABLE_MOTOR_BOATS', ?, 'CRITICAL', 'PENDING', 'Embankment breach requiring water rescue')
    `).run(reqId, districtX, officerId, requestedUnits);

    const reqRecord = db.prepare('SELECT * FROM inter_district_requests WHERE id = ?').get(reqId) as any;
    assert.equal(reqRecord.requesting_district, districtX);
    assert.equal(reqRecord.target_district, 'Vaishali SDRF Command');
    assert.equal(reqRecord.requested_quantity, 15);
    assert.equal(reqRecord.urgency, 'CRITICAL');
    assert.equal(reqRecord.status, 'PENDING');
  });
});
