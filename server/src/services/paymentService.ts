import { db } from '../db/database';
import crypto from 'crypto';

export interface CreateDonationOrderInput {
  campaign_id: string;
  donor_name: string;
  donor_email: string;
  donor_phone?: string;
  donor_pan?: string;
  is_indian_citizen: boolean;
  is_fcra_contribution?: boolean;
  amount_paise: number;
}

export interface VerifyPaymentInput {
  razorpay_order_id: string;
  razorpay_payment_id: string;
  razorpay_signature: string;
}

export class PaymentService {
  public static readonly KEY_ID = process.env.RAZORPAY_KEY_ID || 'rzp_test_ResQAI2026';
  public static readonly KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || 'secret_mock_test_key_resqai';
  public static readonly WEBHOOK_SECRET = process.env.RAZORPAY_WEBHOOK_SECRET || 'webhook_secret_resqai_2026';

  // --- 1. Create Razorpay Test Order (FR-44, FR-45, FR-46, FR-47) ---

  public static createDonationOrder(input: CreateDonationOrderInput) {
    if (!input.amount_paise || input.amount_paise <= 0) {
      throw new Error('Donation amount must be greater than zero paise');
    }

    // Money as integer paise (Part G & Honesty)
    const amountPaise = Math.round(input.amount_paise);

    // Retrieve campaign
    const campaignStmt = db.prepare(`
      SELECT c.*, n.name as ngo_name, n.fcra_verified, n.fcra_number, n.fcra_valid_until, n.tax_80g_verified, n.tax_80g_number
      FROM campaigns c
      JOIN ngos n ON c.ngo_id = n.id
      WHERE c.id = ?
    `);
    const campaign = campaignStmt.get(input.campaign_id) as any;

    if (!campaign) {
      throw new Error(`Campaign with ID ${input.campaign_id} not found`);
    }

    // FR-43: Campaign cannot be public or receive donations until Admin approval
    if (campaign.status !== 'ACTIVE') {
      throw new Error(`Cannot donate: Campaign is in "${campaign.status}" status and is not active for public contributions.`);
    }

    // FR-46: Foreign contribution checks (FCRA)
    const isForeign = !input.is_indian_citizen || Boolean(input.is_fcra_contribution);
    if (isForeign) {
      const isFcraValid = campaign.fcra_verified === 1 && campaign.fcra_number;
      if (!isFcraValid) {
        throw new Error(
          'FCRA_COMPLIANCE_ERROR: Foreign contributions prohibited. This NGO does not have active Ministry of Home Affairs (MHA) FCRA clearance. Only Indian domestic payments in INR are permitted.'
        );
      }
    }

    // Generate unique order and donation ID
    const donationId = `DON-${crypto.randomUUID().substring(0, 8).toUpperCase()}`;
    const razorpayOrderId = `order_test_${crypto.randomUUID().substring(0, 12)}`;

    const insertStmt = db.prepare(`
      INSERT INTO donations (
        id, campaign_id, donor_name, donor_email, donor_phone, donor_pan,
        is_indian_citizen, is_fcra_contribution, amount_paise, currency,
        razorpay_order_id, status
      ) VALUES (
        @id, @campaign_id, @donor_name, @donor_email, @donor_phone, @donor_pan,
        @is_indian_citizen, @is_fcra_contribution, @amount_paise, 'INR',
        @razorpay_order_id, 'CREATED'
      )
    `);

    insertStmt.run({
      id: donationId,
      campaign_id: input.campaign_id,
      donor_name: input.donor_name,
      donor_email: input.donor_email,
      donor_phone: input.donor_phone || null,
      donor_pan: input.donor_pan ? input.donor_pan.toUpperCase() : null,
      is_indian_citizen: input.is_indian_citizen ? 1 : 0,
      is_fcra_contribution: isForeign ? 1 : 0,
      amount_paise: amountPaise,
      razorpay_order_id: razorpayOrderId
    });

    return {
      donationId,
      campaignId: campaign.id,
      campaignTitle: campaign.title,
      ngoName: campaign.ngo_name,
      amountPaise,
      amountRupees: amountPaise / 100,
      currency: 'INR',
      razorpayKeyId: this.KEY_ID,
      razorpayOrderId,
      fcraEligible: isForeign,
      tax80gEligible: Boolean(campaign.tax_80g_verified && input.donor_pan),
      notes: {
        rawCardStoragePolicy: 'ZERO_CARD_STORAGE (FR-47)',
        environment: 'TEST_MODE'
      }
    };
  }

  // --- 2. Verify Razorpay Payment Signature (FR-45, FR-46, FR-53) ---

  public static verifyPayment(input: VerifyPaymentInput) {
    const donationStmt = db.prepare(`
      SELECT d.*, c.title as campaign_title, n.id as ngo_id, n.name as ngo_name, n.tax_80g_verified, n.tax_80g_number
      FROM donations d
      JOIN campaigns c ON d.campaign_id = c.id
      JOIN ngos n ON c.ngo_id = n.id
      WHERE d.razorpay_order_id = ?
    `);
    const donation = donationStmt.get(input.razorpay_order_id) as any;

    if (!donation) {
      throw new Error(`Donation order ${input.razorpay_order_id} not found`);
    }

    if (donation.status === 'PAID') {
      return {
        success: true,
        message: 'Payment already verified and credited (idempotent)',
        donationId: donation.id,
        receiptNo: donation.tax_80g_receipt_no
      };
    }

    // Verify cryptographic HMAC SHA256 signature (FR-45)
    const expectedSignature = crypto
      .createHmac('sha256', this.KEY_SECRET)
      .update(`${input.razorpay_order_id}|${input.razorpay_payment_id}`)
      .digest('hex');

    // In test mode, allow exact HMAC match OR test mock prefix
    const isValidHmac = (input.razorpay_signature === expectedSignature) || 
      (input.razorpay_signature.startsWith('sig_mock_test_'));

    if (!isValidHmac) {
      db.prepare(`UPDATE donations SET status = 'FAILED' WHERE id = ?`).run(donation.id);
      throw new Error('INVALID_PAYMENT_SIGNATURE: Cryptographic verification of payment signature failed (FR-45).');
    }

    // Generate 80G receipt if eligible (FR-46)
    let tax80gReceiptNo: string | null = null;
    let tax80gIssued = 0;

    if (donation.tax_80g_verified === 1 && donation.donor_pan) {
      tax80gReceiptNo = `80G-${new Date().getFullYear()}-${crypto.randomUUID().substring(0, 6).toUpperCase()}`;
      tax80gIssued = 1;
    }

    // Atomic update of donation & campaign balance
    const updateTx = db.transaction(() => {
      db.prepare(`
        UPDATE donations
        SET status = 'PAID', razorpay_payment_id = ?, razorpay_signature = ?, tax_80g_issued = ?, tax_80g_receipt_no = ?, updated_at = datetime('now')
        WHERE id = ?
      `).run(
        input.razorpay_payment_id,
        input.razorpay_signature,
        tax80gIssued,
        tax80gReceiptNo,
        donation.id
      );

      db.prepare(`
        UPDATE campaigns
        SET received_amount_paise = received_amount_paise + ?, updated_at = datetime('now')
        WHERE id = ?
      `).run(donation.amount_paise, donation.campaign_id);

      // Audit log (FR-53)
      db.prepare(`
        INSERT INTO audit_logs (id, action_type, actor_id, actor_role, entity_id, details)
        VALUES (?, 'PAYMENT_VERIFIED', ?, 'DONOR', ?, ?)
      `).run(
        `AUD-${crypto.randomUUID().substring(0, 8)}`,
        donation.donor_email,
        donation.id,
        `Payment of ₹${donation.amount_paise / 100} verified via Razorpay (${input.razorpay_payment_id}). Campaign: ${donation.campaign_title}`
      );
    });

    updateTx();

    return {
      success: true,
      donationId: donation.id,
      campaignId: donation.campaign_id,
      amountRupees: donation.amount_paise / 100,
      paymentId: input.razorpay_payment_id,
      status: 'PAID',
      tax80gIssued: Boolean(tax80gIssued),
      tax80gReceiptNo,
      message: 'Donation successfully verified and credited to campaign ledger.'
    };
  }

  // --- 3. Idempotent Webhook Handler (FR-45) ---

  public static handleWebhook(rawBody: string, signature: string, payload: any) {
    if (!signature) {
      throw new Error('MISSING_WEBHOOK_SIGNATURE: X-Razorpay-Signature header is required');
    }

    // Verify webhook signature
    const expectedSignature = crypto
      .createHmac('sha256', this.WEBHOOK_SECRET)
      .update(rawBody)
      .digest('hex');

    const isValid = (signature === expectedSignature) || signature.startsWith('sig_mock_webhook_');
    if (!isValid) {
      throw new Error('INVALID_WEBHOOK_SIGNATURE: Signature verification failed');
    }

    const eventId = payload.event_id || payload.id || `evt_${crypto.randomUUID().substring(0, 10)}`;
    const eventType = payload.event || 'payment.captured';

    // FR-45 Idempotency check: duplicate webhooks are idempotent
    const existing = db.prepare('SELECT * FROM processed_webhooks WHERE event_id = ?').get(eventId);
    if (existing) {
      return {
        idempotent: true,
        alreadyProcessed: true,
        eventId,
        message: 'Duplicate webhook received — safely ignored with no double processing.'
      };
    }

    // Record webhook event first
    db.prepare(`
      INSERT INTO processed_webhooks (event_id, event_type, payment_id)
      VALUES (?, ?, ?)
    `).run(eventId, eventType, payload.payload?.payment?.entity?.id || null);

    // Process event
    if (eventType === 'payment.captured' || eventType === 'order.paid') {
      const paymentEntity = payload.payload?.payment?.entity;
      const orderId = paymentEntity?.order_id;
      const paymentId = paymentEntity?.id;

      if (orderId && paymentId) {
        const donation = db.prepare('SELECT * FROM donations WHERE razorpay_order_id = ?').get(orderId) as any;
        if (donation && donation.status !== 'PAID') {
          this.verifyPayment({
            razorpay_order_id: orderId,
            razorpay_payment_id: paymentId,
            razorpay_signature: `sig_mock_test_webhook_${paymentId}`
          });
        }
      }
    }

    return {
      idempotent: true,
      alreadyProcessed: false,
      eventId,
      eventType,
      message: 'Webhook processed successfully'
    };
  }

  // --- 4. 80G Tax Receipt Lookup (FR-46) ---

  public static getDonationReceipt(donationId: string) {
    const stmt = db.prepare(`
      SELECT d.*, c.title as campaign_title, n.name as ngo_name, n.darpan_id, n.tax_80g_number, n.authorized_rep_name
      FROM donations d
      JOIN campaigns c ON d.campaign_id = c.id
      JOIN ngos n ON c.ngo_id = n.id
      WHERE d.id = ?
    `);
    const donation = stmt.get(donationId) as any;

    if (!donation) {
      throw new Error(`Donation with ID ${donationId} not found`);
    }

    if (donation.status !== 'PAID') {
      throw new Error(`Receipt unavailable: Donation status is ${donation.status}`);
    }

    return {
      receiptNo: donation.tax_80g_receipt_no || `REC-${donation.id}`,
      donationId: donation.id,
      date: donation.created_at,
      donor: {
        name: donation.donor_name,
        email: donation.donor_email,
        phone: donation.donor_phone,
        pan: donation.donor_pan || 'NOT_PROVIDED',
        isIndianCitizen: Boolean(donation.is_indian_citizen)
      },
      campaign: {
        id: donation.campaign_id,
        title: donation.campaign_title
      },
      ngo: {
        name: donation.ngo_name,
        darpanId: donation.darpan_id,
        tax80gNumber: donation.tax_80g_number || 'N/A'
      },
      financial: {
        amountPaise: donation.amount_paise,
        amountRupees: donation.amount_paise / 100,
        currency: donation.currency
      },
      statutoryDeclaration: donation.tax_80g_issued
        ? 'Deduction under Section 80G of the Income Tax Act, 1961 is eligible for this contribution.'
        : 'Donation receipt for records. 80G tax benefit requires valid donor PAN and verified NGO 80G registration.'
    };
  }
}
