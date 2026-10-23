import test, { before, describe } from 'node:test';
import assert from 'node:assert';
import { db, initDatabase } from '../src/db/database';
import { NGOService } from '../src/services/ngoService';
import { PaymentService } from '../src/services/paymentService';
import crypto from 'crypto';

describe('Phase 6: NGO KYC, Campaign Approval, Razorpay Test Donations & Transparent Ledger (FR-42 to FR-47)', () => {
  before(async () => {
    process.env.NODE_ENV = 'test';
    await initDatabase();
  });

  // Step 1: NGO KYC Registration & Verification (FR-42, FR-46)
  test('Step 1: FR-42 NGO Registration, Document Upload & Administrative KYC Approval Gate', () => {
    const newNGO = NGOService.registerNGO({
      name: 'Pratibha Disaster Relief Trust',
      darpan_id: 'MH/2023/0448192',
      fcra_number: 'FCRA-091122334',
      fcra_valid_until: '2028-12-31',
      tax_80g_number: 'AABCP1122DF20231',
      tax_80g_valid_until: '2027-03-31',
      authorized_rep_name: 'Anjali Deshmukh',
      authorized_rep_email: 'anjali@pratibhatrust.org',
      authorized_rep_phone: '+919822110099',
      documents: [
        { type: 'DARPAN_CERTIFICATE', url: '/kyc/pratibha_darpan.pdf' },
        { type: 'TAX_80G_CERTIFICATE', url: '/kyc/pratibha_80g.pdf' },
        { type: 'FCRA_REGISTRATION', url: '/kyc/pratibha_fcra.pdf' }
      ]
    }) as any;

    assert.ok(newNGO.id.startsWith('NGO-'), 'NGO should receive a unique NGO- ID');
    assert.strictEqual(newNGO.kyc_status, 'PENDING_VERIFICATION', 'New NGO must start in PENDING_VERIFICATION');
    assert.strictEqual(newNGO.fcra_verified, 1, 'FCRA valid details flagged as verified');
    assert.strictEqual(newNGO.tax_80g_verified, 1, '80G tax exemption flagged as verified');

    // Admin approves KYC
    const approvedNGO = NGOService.updateNGOStatus(
      newNGO.id,
      'APPROVED',
      'USR-ADMIN-01',
      'DARPAN and MHA FCRA registration verified against official portal.'
    ) as any;

    assert.strictEqual(approvedNGO.kyc_status, 'APPROVED', 'NGO status must transition to APPROVED');

    // Verify audit log entry exists (FR-53)
    const audit = db.prepare("SELECT * FROM audit_logs WHERE entity_id = ? AND action_type = 'NGO_KYC_UPDATED'").get(newNGO.id) as any;
    assert.ok(audit, 'Audit log must record NGO KYC verification');
    assert.strictEqual(audit.action_type, 'NGO_KYC_UPDATED');
  });

  // Step 2: Campaign Submission & Admin Approval Gate (FR-43)
  test('Step 2: FR-43 Campaign Cannot Be Public Until Admin Approval Gate', () => {
    // NGO creates a new campaign
    const campaign = NGOService.createCampaign({
      ngo_id: 'NGO-RAPID-01',
      title: 'Monsoon Clean Water & Hygiene Pack Distribution',
      description: 'Distribution of 5,000 hygiene packs with sanitary pads, chlorine tablets, and soap in flooded river hamlets.',
      category: 'MEDICAL',
      area_id: 'area-a',
      target_amount_paise: 30000000, // ₹3,00,000
      beneficiary_count: 500
    }) as any;

    assert.ok(campaign.id.startsWith('CMP-'), 'Campaign must receive CMP- ID');
    assert.strictEqual(campaign.status, 'PENDING_APPROVAL', 'Campaign must start in PENDING_APPROVAL');

    // Public query must NOT return pending campaign
    const publicCampaignsBefore = NGOService.getAllCampaigns({ publicOnly: true }) as any[];
    const isPublicBefore = publicCampaignsBefore.some((c: any) => c.id === campaign.id);
    assert.strictEqual(isPublicBefore, false, 'Pending campaign must NOT be visible to public donors');

    // Admin approves campaign
    const approvedCampaign = NGOService.updateCampaignStatus(campaign.id, 'ACTIVE', 'USR-ADMIN-01') as any;
    assert.strictEqual(approvedCampaign.status, 'ACTIVE', 'Campaign must transition to ACTIVE');
    assert.ok(approvedCampaign.approved_at, 'Campaign must have approved_at timestamp');

    // Public query now DOES return the campaign
    const publicCampaignsAfter = NGOService.getAllCampaigns({ publicOnly: true }) as any[];
    const isPublicAfter = publicCampaignsAfter.some((c: any) => c.id === campaign.id);
    assert.strictEqual(isPublicAfter, true, 'Approved campaign must now be visible to public donors');
  });

  // Step 3: Razorpay Test Mode Order Creation, HMAC Signature Verification & Ledger Update (FR-44, FR-45)
  test('Step 3: FR-44 & FR-45 Razorpay Test Mode Order Creation, Server-Side HMAC Signature Verification & Integer Paise Ledger', () => {
    const campaignId = 'CMP-FLOOD-01';
    const donationAmountPaise = 250000; // ₹2,500.00

    const initialLedger = NGOService.getCampaignLedger(campaignId);
    const initialReceived = initialLedger.ledger.receivedPaise;

    // 1. Create Order
    const order = PaymentService.createDonationOrder({
      campaign_id: campaignId,
      donor_name: 'Rohit Kulkarni',
      donor_email: 'rohit.k@example.com',
      donor_phone: '+919822446688',
      donor_pan: 'ABCDE5678R',
      is_indian_citizen: true,
      amount_paise: donationAmountPaise
    });

    assert.ok(order.razorpayOrderId.startsWith('order_test_'), 'Order ID must have order_test_ prefix');
    assert.strictEqual(order.amountPaise, donationAmountPaise, 'Amount must be exactly 250000 paise');
    assert.strictEqual(order.amountRupees, 2500, 'Rupee conversion must equal 2500');
    assert.strictEqual(order.currency, 'INR');

    // 2. Verify Payment with Valid Signature
    const paymentId = `pay_test_${crypto.randomUUID().substring(0, 10)}`;
    const validSignature = crypto
      .createHmac('sha256', PaymentService.KEY_SECRET)
      .update(`${order.razorpayOrderId}|${paymentId}`)
      .digest('hex');

    const verifyResult = PaymentService.verifyPayment({
      razorpay_order_id: order.razorpayOrderId,
      razorpay_payment_id: paymentId,
      razorpay_signature: validSignature
    });

    assert.strictEqual(verifyResult.success, true);
    assert.strictEqual(verifyResult.status, 'PAID');
    assert.ok(verifyResult.tax80gReceiptNo?.startsWith('80G-'), 'Eligible donor receives 80G receipt number');

    // 3. Verify Campaign Ledger updated in database
    const updatedLedger = NGOService.getCampaignLedger(campaignId);
    assert.strictEqual(
      updatedLedger.ledger.receivedPaise,
      initialReceived + donationAmountPaise,
      'Campaign received_amount_paise must increase by exact integer paise'
    );
  });

  // Step 4: Webhook Signature & Idempotent Event Handling (FR-45)
  test('Step 4: FR-45 Webhook HMAC Verification & Strict Idempotency Gate (Duplicate Delivery Prevention)', () => {
    const eventId = `evt_test_${crypto.randomUUID().substring(0, 8)}`;
    const mockOrder = PaymentService.createDonationOrder({
      campaign_id: 'CMP-MED-02',
      donor_name: 'Suresh Raina',
      donor_email: 'suresh@example.com',
      is_indian_citizen: true,
      amount_paise: 100000 // ₹1,000
    });

    const mockPaymentId = `pay_hook_${crypto.randomUUID().substring(0, 8)}`;
    const payload = {
      event_id: eventId,
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: mockPaymentId,
            order_id: mockOrder.razorpayOrderId,
            amount: 100000,
            status: 'captured'
          }
        }
      }
    };

    const rawBody = JSON.stringify(payload);
    const validSignature = crypto
      .createHmac('sha256', PaymentService.WEBHOOK_SECRET)
      .update(rawBody)
      .digest('hex');

    // First webhook delivery
    const result1 = PaymentService.handleWebhook(rawBody, validSignature, payload);
    assert.strictEqual(result1.alreadyProcessed, false, 'First webhook delivery must be processed');
    assert.strictEqual(result1.eventId, eventId);

    // Duplicate webhook delivery with identical event_id
    const result2 = PaymentService.handleWebhook(rawBody, validSignature, payload);
    assert.strictEqual(result2.idempotent, true, 'Second webhook must be identified as idempotent');
    assert.strictEqual(result2.alreadyProcessed, true, 'Second webhook must NOT re-process');

    // Verify donation record is marked PAID
    const donation = db.prepare('SELECT * FROM donations WHERE razorpay_order_id = ?').get(mockOrder.razorpayOrderId) as any;
    assert.strictEqual(donation.status, 'PAID');
  });

  // Step 5: FCRA Foreign Contribution Legal Gate (FR-46)
  test('Step 5: FR-46 Foreign Contribution (FCRA) Compliance Check & 80G Statutory Exemption Rule', () => {
    // 1. Attempt foreign contribution to Gramin Seva Samiti (NGO-SEVA-02: No FCRA clearance)
    assert.throws(
      () => {
        PaymentService.createDonationOrder({
          campaign_id: 'CMP-MED-02', // NGO-SEVA-02 has fcra_verified = 0
          donor_name: 'John Miller (USA)',
          donor_email: 'john.miller@example.org',
          is_indian_citizen: false, // Foreign citizen
          is_fcra_contribution: true,
          amount_paise: 500000
        });
      },
      /FCRA_COMPLIANCE_ERROR/,
      'Must strictly reject foreign donations when NGO lacks MHA FCRA registration'
    );

    // 2. Foreign contribution to Rapid Relief Foundation (NGO-RAPID-01: Verified FCRA clearance)
    const foreignOrder = PaymentService.createDonationOrder({
      campaign_id: 'CMP-FLOOD-01', // NGO-RAPID-01 has fcra_verified = 1
      donor_name: 'David Smith (UK)',
      donor_email: 'david.smith@example.co.uk',
      is_indian_citizen: false,
      is_fcra_contribution: true,
      amount_paise: 1000000 // ₹10,000
    });

    assert.ok(foreignOrder.razorpayOrderId, 'Foreign contribution permitted when NGO has verified FCRA registration');
    assert.strictEqual(foreignOrder.fcraEligible, true);
  });

  // Step 6: Transparent Ledger Disbursements & Zero Card Storage (FR-44, FR-47)
  test('Step 6: FR-44 Transparent Ledger Disbursements & FR-47 Zero Raw Card Storage Compliance', () => {
    const campaignId = 'CMP-FLOOD-01';
    let ledgerBefore = NGOService.getCampaignLedger(campaignId);
    let unspentBefore = ledgerBefore.ledger.unspentBalancePaise;

    if (unspentBefore < 1000000) {
      // Ensure sufficient unspent balance for repeatable test runs
      db.prepare('UPDATE campaigns SET current_amount_paise = current_amount_paise + 5000000 WHERE id = ?').run(campaignId);
      ledgerBefore = NGOService.getCampaignLedger(campaignId);
      unspentBefore = ledgerBefore.ledger.unspentBalancePaise;
    }

    // Disburse funds with receipt reference
    const disbursementAmountPaise = 250000; // ₹2,500
    const updatedLedger = NGOService.recordDisbursement(
      {
        campaign_id: campaignId,
        purpose: 'Emergency water purification sachets (10,000 units) for relief camp 2',
        amount_paise: disbursementAmountPaise,
        vendor_or_beneficiary: 'PureHealth Water Solutions Ltd',
        proof_receipt_url: '/receipts/inv-purehealth-771.pdf'
      },
      'USR-ADMIN-01'
    );

    assert.strictEqual(
      updatedLedger.ledger.spentPaise,
      ledgerBefore.ledger.spentPaise + disbursementAmountPaise,
      'Spent amount must increment by exact disbursement'
    );
    assert.strictEqual(
      updatedLedger.ledger.unspentBalancePaise,
      unspentBefore - disbursementAmountPaise,
      'Unspent balance must decrement by exact disbursement'
    );

    // Attempt disbursement exceeding unspent balance -> must throw
    assert.throws(
      () => {
        NGOService.recordDisbursement(
          {
            campaign_id: campaignId,
            purpose: 'Excessive disbursement attempt',
            amount_paise: updatedLedger.ledger.unspentBalancePaise + 1000000,
            vendor_or_beneficiary: 'Unknown'
          },
          'USR-ADMIN-01'
        );
      },
      /Insufficient unspent campaign balance/,
      'Cannot disburse beyond unspent campaign balance'
    );

    // FR-47 Zero Card Storage Check: verify no table contains card columns
    const columns = db.prepare("PRAGMA table_info('donations')").all() as any[];
    const columnNames = columns.map(c => c.name.toLowerCase());
    const forbidden = ['card_number', 'pan_card_cvv', 'cvv', 'card_exp', 'card_expiry'];
    for (const f of forbidden) {
      assert.strictEqual(columnNames.includes(f), false, `Database must never store raw card attribute: ${f}`);
    }
  });
});
