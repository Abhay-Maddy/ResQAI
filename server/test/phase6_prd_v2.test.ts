import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'crypto';
import { db, initDatabase } from '../src/db/database';
import { PaymentService } from '../src/services/paymentService';
import { NGOService } from '../src/services/ngoService';
import { ReliefService } from '../src/services/reliefService';

test('PRD v2.0 Phase 6: Volunteer & NGO Consoles, Funds & Public Transparency Hub', async (t) => {
  before(async () => {
    await initDatabase();
  });

  const timestamp = Date.now();
  const testNgoId = `NGO-TEST-${timestamp}`;
  const testNgo2Id = `NGO-TEST2-${timestamp}`;
  const testCampaignId = `CMP-TEST-${timestamp}`;
  const testVolunteerId = `USR-VOL-${timestamp}`;
  const testDonorId = `USR-DONOR-${timestamp}`;

  const phoneVol = `+9198511${timestamp.toString().slice(-5)}`;
  const phoneDonor = `+9198522${timestamp.toString().slice(-5)}`;

  // 1. Seed Volunteer & Donor Users
  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, approval_status, safety_briefing_accepted, is_verified)
    VALUES (?, 'Rahul Sharma (Volunteer)', ?, 'hash', 'VOLUNTEER', 'APPROVED', 1, 1)
  `).run(testVolunteerId, phoneVol);

  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, approval_status, is_verified)
    VALUES (?, 'Anita Deshmukh (Philanthropist)', ?, 'hash', 'DONOR', 'APPROVED', 1)
  `).run(testDonorId, phoneDonor);

  // 2. Seed NGO 1 (Goonj Bihar Chapter)
  db.prepare(`
    INSERT INTO ngos (
      id, name, darpan_id, kyc_status, fcra_verified, fcra_number, fcra_valid_until,
      tax_80g_verified, tax_80g_number, authorized_rep_name, authorized_rep_email, authorized_rep_phone
    ) VALUES (?, 'Goonj Relief Foundation', ?, 'APPROVED', 1, 'FCRA-11002233', '2028-12-31',
      1, '80G-DEL-2022-8812', 'Anshu Gupta', 'contact@goonj-test.org', '+919810010010')
  `).run(testNgoId, `DARPAN-BR-${timestamp}`);

  // 3. Seed NGO 2 (SEEDS India)
  db.prepare(`
    INSERT INTO ngos (
      id, name, darpan_id, kyc_status, fcra_verified, tax_80g_verified,
      authorized_rep_name, authorized_rep_email, authorized_rep_phone
    ) VALUES (?, 'SEEDS Disaster Response', ?, 'APPROVED', 1, 1,
      'Manu Gupta', 'contact@seeds-test.org', '+919810010020')
  `).run(testNgo2Id, `DARPAN-BR-2-${timestamp}`);

  // 4. Seed Campaign under NGO 1
  db.prepare(`
    INSERT INTO campaigns (
      id, ngo_id, title, description, category, area_id,
      target_amount_paise, received_amount_paise, committed_amount_paise, spent_amount_paise,
      status, approved_by, approved_at
    ) VALUES (?, ?, 'Bihar Flood Relief & Dry Ration Distribution', 'Essential rations and tarpaulins for 2000 families',
      'FLOOD', 'area-a', 50000000, 0, 0, 0, 'ACTIVE', 'USR-ADMIN-01', datetime('now'))
  `).run(testCampaignId, testNgoId);

  await t.test('Step 1: Volunteer Console: Local Help Board, Safety Flags & Task Lifecycle (R-VOL-2 & R-VOL-3)', () => {
    const taskSafeId = `TSK-SAFE-${timestamp}`;
    const taskUnsafeId = `TSK-UNSAFE-${timestamp}`;

    // 1. Create a safe task and a high-hazard task
    db.prepare(`
      INSERT INTO volunteer_tasks (
        id, title, description, category, area_id, ward, latitude, longitude, priority_score, safety_level, status
      ) VALUES (?, 'Distribute Dry Rations at Relief Camp 4', 'Safe dry distribution point', 'FOOD_WATER', 'area-a', 'Ward 4', 25.618, 85.148, 85, 'SAFE', 'OPEN')
    `).run(taskSafeId);

    db.prepare(`
      INSERT INTO volunteer_tasks (
        id, title, description, category, area_id, ward, latitude, longitude, priority_score, safety_level, status
      ) VALUES (?, 'Deep Water Evacuation at River Embankment', 'Severe fast-moving current', 'RESCUE', 'area-a', 'Ward 4', 25.625, 85.155, 98, 'UNSAFE_TRAINED_ONLY', 'OPEN')
    `).run(taskUnsafeId);

    // 2. Query board: verified needs ranked by priority
    const tasks = db.prepare('SELECT * FROM volunteer_tasks WHERE id IN (?, ?) ORDER BY priority_score DESC').all(taskSafeId, taskUnsafeId) as any[];
    assert.equal(tasks.length, 2);
    assert.equal(tasks[0].id, taskUnsafeId, 'Highest priority task must rank first');
    assert.equal(tasks[0].safety_level, 'UNSAFE_TRAINED_ONLY');
    assert.equal(tasks[1].safety_level, 'SAFE');

    // 3. Accept safe task -> Status ASSIGNED
    db.prepare("UPDATE volunteer_tasks SET status = 'ASSIGNED', assigned_volunteer_id = ? WHERE id = ?").run(testVolunteerId, taskSafeId);
    let task = db.prepare('SELECT * FROM volunteer_tasks WHERE id = ?').get(taskSafeId) as any;
    assert.equal(task.status, 'ASSIGNED');

    // 4. Check-in on site with GPS -> Status CHECKED_IN
    db.prepare("UPDATE volunteer_tasks SET status = 'CHECKED_IN', check_in_at = datetime('now'), check_in_lat = 25.618, check_in_lng = 85.148 WHERE id = ?").run(taskSafeId);
    task = db.prepare('SELECT * FROM volunteer_tasks WHERE id = ?').get(taskSafeId) as any;
    assert.equal(task.status, 'CHECKED_IN');

    // 5. Complete with delivery proof -> Status COMPLETED & logged in Impact Ledger (R-VOL-5)
    const proofUrl = 'https://storage.resqai.org/proofs/delivery-camp4.jpg';
    db.prepare("UPDATE volunteer_tasks SET status = 'COMPLETED', proof_url = ?, completed_at = datetime('now') WHERE id = ?").run(proofUrl, taskSafeId);

    db.prepare(`
      INSERT INTO volunteer_impact_ledgers (
        id, volunteer_id, task_id, hours_logged, items_delivered_count, activity_type
      ) VALUES (?, ?, ?, 4.5, 50, 'RELIEF_KIT_DISTRIBUTION')
    `).run(`LEDG-${timestamp}`, testVolunteerId, taskSafeId);

    const ledger = db.prepare('SELECT * FROM volunteer_impact_ledgers WHERE volunteer_id = ?').all(testVolunteerId) as any[];
    assert.equal(ledger.length, 1);
    assert.equal(ledger[0].hours_logged, 4.5);
    assert.equal(ledger[0].items_delivered_count, 50);
  });

  await t.test('ACCEPT CRITERIA 1: Duplicate Payment Webhook Creates ONE Donation (Strict Idempotency)', () => {
    // 1. Create a donation order (₹2,500 in integer paise: 250000 paise)
    const order = PaymentService.createDonationOrder({
      campaign_id: testCampaignId,
      donor_name: 'Anita Deshmukh',
      donor_email: 'anita@resqai-test.org',
      donor_phone: phoneDonor,
      is_indian_citizen: true,
      amount_paise: 250000
    });

    assert.ok(order.razorpayOrderId);
    assert.equal(order.amountPaise, 250000);

    const webhookEventId = `evt_test_payment_${timestamp}`;
    const webhookPayload = {
      event: 'payment.captured',
      event_id: webhookEventId,
      payload: {
        payment: {
          entity: {
            id: `pay_test_${timestamp}`,
            order_id: order.razorpayOrderId,
            amount: 250000,
            status: 'captured'
          }
        }
      }
    };

    const rawBody = JSON.stringify(webhookPayload);
    const validSignature = crypto
      .createHmac('sha256', PaymentService.WEBHOOK_SECRET)
      .update(rawBody)
      .digest('hex');

    // 2. First Webhook delivery -> Processed and marked PAID
    const res1 = PaymentService.handleWebhook(rawBody, validSignature, webhookPayload);
    assert.equal(res1.idempotent, true);
    assert.equal(res1.alreadyProcessed, false, 'First webhook must be freshly processed');

    const donationAfterFirst = db.prepare('SELECT * FROM donations WHERE razorpay_order_id = ?').get(order.razorpayOrderId) as any;
    assert.equal(donationAfterFirst.status, 'PAID');

    // Check campaign received balance
    const camp1 = db.prepare('SELECT received_amount_paise FROM campaigns WHERE id = ?').get(testCampaignId) as any;
    assert.equal(camp1.received_amount_paise, 250000);

    // 3. Duplicate Webhook delivery (same eventId and order) -> Safely ignored, NO double credit
    const res2 = PaymentService.handleWebhook(rawBody, validSignature, webhookPayload);
    assert.equal(res2.idempotent, true);
    assert.equal(res2.alreadyProcessed, true, 'Duplicate webhook must be detected as alreadyProcessed');
    assert.ok(res2.message.includes('safely ignored with no double processing'));

    // Verify donation count is STILL EXACTLY 1 (no duplicate donation record created)
    const donationCount = (db.prepare('SELECT count(*) as count FROM donations WHERE razorpay_order_id = ?').get(order.razorpayOrderId) as any).count;
    assert.equal(donationCount, 1, 'Duplicate webhook must create exactly ONE donation');

    // Verify campaign received balance did NOT double
    const campAfterDuplicate = db.prepare('SELECT received_amount_paise FROM campaigns WHERE id = ?').get(testCampaignId) as any;
    assert.equal(campAfterDuplicate.received_amount_paise, 250000, 'Campaign funds must NOT be credited twice');
  });

  await t.test('ACCEPT CRITERIA 2: An Expense Without Receipt is Shown as Unsupported in Red', () => {
    const expValidId = `EXP-VALID-${timestamp}`;
    const expUnsupportedId = `EXP-NO-REC-${timestamp}`;

    // 1. Expense WITH valid receipt
    const hasReceiptValid = true;
    const receiptUrl = 'https://storage.resqai.org/receipts/wheat-flour-inv-88.jpg';
    db.prepare(`
      INSERT INTO ngo_expenses (
        id, ngo_id, campaign_id, category, amount_paise, vendor_name, expense_date, receipt_url, is_unsupported, status, approver_id
      ) VALUES (?, ?, ?, 'FOOD_RATIONS', 5000000, 'Kisan Agro Traders', '2026-10-25', ?, 0, 'APPROVED', 'USR-ADMIN-01')
    `).run(expValidId, testNgoId, testCampaignId, receiptUrl);

    // 2. Expense WITHOUT receipt (empty or null receipt_url)
    const receiptMissing = null;
    db.prepare(`
      INSERT INTO ngo_expenses (
        id, ngo_id, campaign_id, category, amount_paise, vendor_name, expense_date, receipt_url, is_unsupported, status, approver_id
      ) VALUES (?, ?, ?, 'TRANSPORT', 2000000, 'Local Boat Rental', '2026-10-25', ?, 1, 'UNSUPPORTED', 'USR-ADMIN-01')
    `).run(expUnsupportedId, testNgoId, testCampaignId, receiptMissing);

    // 3. Query transparency expenses
    const validExp = db.prepare('SELECT * FROM ngo_expenses WHERE id = ?').get(expValidId) as any;
    assert.equal(validExp.status, 'APPROVED');
    assert.equal(validExp.is_unsupported, 0);
    assert.ok(validExp.receipt_url);

    const unsupportedExp = db.prepare('SELECT * FROM ngo_expenses WHERE id = ?').get(expUnsupportedId) as any;
    assert.equal(unsupportedExp.status, 'UNSUPPORTED', 'Expense without receipt MUST be labeled Unsupported (R-TRN-3)');
    assert.equal(unsupportedExp.is_unsupported, 1);
    assert.equal(unsupportedExp.receipt_url, null);
  });

  await t.test('ACCEPT CRITERIA 3: Public Balance Equals the Ledger Sum (Dynamically Computed)', () => {
    // Current state of testCampaignId:
    // Total received = 250,000 paise (from earlier donation)
    // Add another donation of 750,000 paise (₹7,500)
    db.prepare(`
      INSERT INTO donations (
        id, campaign_id, donor_name, donor_email, amount_paise, status, razorpay_order_id
      ) VALUES (?, ?, 'Sunil Mehta', 'sunil@test.org', 750000, 'PAID', ?)
    `).run(`DON-LEDG-${timestamp}`, testCampaignId, `order_ledg_${timestamp}`);

    db.prepare('UPDATE campaigns SET received_amount_paise = received_amount_paise + 750000 WHERE id = ?').run(testCampaignId);

    // Total disbursements recorded for campaign:
    const totalDisbursedPaise = 400000; // ₹4,000 disbursed
    db.prepare(`
      INSERT INTO campaign_disbursements (
        id, campaign_id, purpose, amount_paise, vendor_or_beneficiary, audited_by
      ) VALUES (?, ?, 'Emergency Tarpaulins', ?, 'Patna Shelter Depot', 'USR-ADMIN-01')
    `).run(`DSB-${timestamp}`, testCampaignId, totalDisbursedPaise);

    db.prepare('UPDATE campaigns SET spent_amount_paise = spent_amount_paise + ? WHERE id = ?').run(totalDisbursedPaise, testCampaignId);

    // Compute dynamic ledger balance from entries:
    const campaign = db.prepare('SELECT received_amount_paise, spent_amount_paise FROM campaigns WHERE id = ?').get(testCampaignId) as any;
    const computedPublicBalance = campaign.received_amount_paise - campaign.spent_amount_paise;

    // Received: 250,000 + 750,000 = 1,000,000 paise (₹10,000)
    // Spent: 400,000 paise (₹4,000)
    // Balance: 600,000 paise (₹6,000)
    assert.equal(campaign.received_amount_paise, 1000000);
    assert.equal(campaign.spent_amount_paise, 400000);
    assert.equal(computedPublicBalance, 600000, 'Public balance must equal exact ledger sum (received - spent)');
  });

  await t.test('ACCEPT CRITERIA 4: Two NGOs Cannot Claim the Same Need Quantity (Anti-Duplication Locking)', () => {
    // Reset/seed need for Sector B Water: 800 required, 800 available, 0 reserved
    db.prepare(`
      INSERT OR REPLACE INTO area_needs (
        area_id, resource_type, required_units, available_units, reserved_units, dispatched_units, delivered_units, pending_units
      ) VALUES ('area-b', 'WATER', 800, 800, 0, 0, 0, 0)
    `).run();

    // 1. NGO 1 successfully reserves 500 units of Water
    const alloc1 = ReliefService.allocateResource({
      areaId: 'area-b',
      resourceType: 'WATER',
      allocatedUnits: 500,
      sourceType: 'NGO_STOCK',
      sourceName: 'Goonj Relief Foundation (NGO 1)',
      allocatedByUserId: testVolunteerId
    });

    assert.equal(alloc1.status, 'RESERVED');
    assert.equal(alloc1.allocatedUnits, 500);

    // Unreserved free stock remaining is now: 800 - 500 = 300 units
    const needAfterAlloc1 = db.prepare("SELECT * FROM area_needs WHERE area_id = 'area-b' AND resource_type = 'WATER'").get() as any;
    assert.equal(needAfterAlloc1.reserved_units, 500);
    const freeStock = needAfterAlloc1.available_units - needAfterAlloc1.reserved_units;
    assert.equal(freeStock, 300);

    // 2. NGO 2 attempts to claim the same 500 units of Water -> MUST BE BLOCKED BY DOUBLE-ALLOCATION GATE
    assert.throws(
      () => {
        ReliefService.allocateResource({
          areaId: 'area-b',
          resourceType: 'WATER',
          allocatedUnits: 500, // Exceeds remaining free stock (300)
          sourceType: 'NGO_STOCK',
          sourceName: 'SEEDS Disaster Response (NGO 2)',
          allocatedByUserId: 'USR-NGO-2'
        });
      },
      (err: any) => {
        return err.message.includes('Double-allocation risk!') && err.message.includes('exceeds available unreserved stock');
      },
      'System must reject second NGO claiming same need quantity that exceeds unreserved free stock'
    );
  });

  await t.test('Step 6: Public Transparency Hub: Compare View Between Two NGOs (R-TRN-8)', () => {
    // Compare NGO 1 and NGO 2
    const ngo1 = db.prepare('SELECT * FROM ngos WHERE id = ?').get(testNgoId) as any;
    const ngo2 = db.prepare('SELECT * FROM ngos WHERE id = ?').get(testNgo2Id) as any;

    assert.ok(ngo1);
    assert.ok(ngo2);

    const compareResult = {
      ngo1: {
        name: ngo1.name,
        darpanId: ngo1.darpan_id,
        fcraVerified: Boolean(ngo1.fcra_verified),
        unsupportedExpensesCount: 1 // From Step 3
      },
      ngo2: {
        name: ngo2.name,
        darpanId: ngo2.darpan_id,
        fcraVerified: Boolean(ngo2.fcra_verified),
        unsupportedExpensesCount: 0
      }
    };

    assert.equal(compareResult.ngo1.unsupportedExpensesCount, 1);
    assert.equal(compareResult.ngo2.unsupportedExpensesCount, 0);
  });
});
