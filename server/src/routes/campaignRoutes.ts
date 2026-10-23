import { Router, Request, Response } from 'express';
import { NGOService } from '../services/ngoService';

const router = Router();

// GET /api/v1/campaigns — List campaigns
router.get('/', (req: Request, res: Response) => {
  try {
    const { status, category, area_id, publicOnly } = req.query;
    const campaigns = NGOService.getAllCampaigns({
      status: status as string,
      category: category as string,
      area_id: area_id as string,
      publicOnly: publicOnly === 'true' || publicOnly === '1'
    });
    res.json({ success: true, count: campaigns.length, data: campaigns });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/campaigns/:id — Get campaign details
router.get('/:id', (req: Request, res: Response) => {
  try {
    const campaign = NGOService.getCampaignById(req.params.id);
    if (!campaign) {
      return res.status(404).json({ success: false, error: 'Campaign not found' });
    }
    res.json({ success: true, data: campaign });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/campaigns — Create campaign (FR-43: Starts in PENDING_APPROVAL)
router.post('/', (req: Request, res: Response) => {
  try {
    const { ngo_id, title, description, category, area_id, target_amount_paise, beneficiary_count } = req.body;

    if (!ngo_id || !title || !description || !category || !area_id || !target_amount_paise) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: ngo_id, title, description, category, area_id, target_amount_paise'
      });
    }

    const campaign = NGOService.createCampaign({
      ngo_id,
      title,
      description,
      category,
      area_id,
      target_amount_paise: Number(target_amount_paise),
      beneficiary_count: beneficiary_count ? Number(beneficiary_count) : 0
    });

    res.status(201).json({
      success: true,
      message: 'Campaign submitted for administrative review (FR-43)',
      data: campaign
    });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// PATCH /api/v1/campaigns/:id/status — Admin Approval Gate (FR-43)
router.patch('/:id/status', (req: Request, res: Response) => {
  try {
    const { status, actorId } = req.body;
    if (!status || !['ACTIVE', 'REJECTED', 'PAUSED', 'COMPLETED'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Must be ACTIVE, REJECTED, PAUSED, or COMPLETED'
      });
    }

    const updated = NGOService.updateCampaignStatus(req.params.id, status, actorId || 'USR-ADMIN-01');
    res.json({
      success: true,
      message: `Campaign status updated to ${status}. ${status === 'ACTIVE' ? 'Campaign is now public for donations.' : ''}`,
      data: updated
    });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// GET /api/v1/campaigns/:id/ledger — Transparent Financial Ledger (FR-44)
router.get('/:id/ledger', (req: Request, res: Response) => {
  try {
    const ledger = NGOService.getCampaignLedger(req.params.id);
    res.json({ success: true, data: ledger });
  } catch (error: any) {
    res.status(404).json({ success: false, error: error.message });
  }
});

// POST /api/v1/campaigns/:id/disbursements — Record Impact Disbursement (FR-44, FR-53)
router.post('/:id/disbursements', (req: Request, res: Response) => {
  try {
    const { purpose, amount_paise, vendor_or_beneficiary, proof_receipt_url, actorId } = req.body;

    if (!purpose || !amount_paise || !vendor_or_beneficiary) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: purpose, amount_paise, vendor_or_beneficiary'
      });
    }

    const updatedLedger = NGOService.recordDisbursement(
      {
        campaign_id: req.params.id,
        purpose,
        amount_paise: Number(amount_paise),
        vendor_or_beneficiary,
        proof_receipt_url
      },
      actorId || 'USR-ADMIN-01'
    );

    res.status(201).json({
      success: true,
      message: 'Disbursement recorded and verified against campaign ledger',
      data: updatedLedger
    });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

export default router;
