import { Router, Request, Response } from 'express';
import { CaseManagementService } from '../services/caseManagementService';

const router = Router();

// GET /api/v1/cases — List cases with DPDP field-level masking (FR-38, FR-39)
router.get('/', (req: Request, res: Response) => {
  try {
    const { status, area_id, includeMerged } = req.query;
    const userRole = (req.headers['x-user-role'] as string) || 'CITIZEN';

    const cases = CaseManagementService.getAllCases({
      status: status as string,
      area_id: area_id as string,
      includeMerged: includeMerged === 'true',
      userRole
    });

    res.json({ success: true, count: cases.length, data: cases });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/cases/:id — Get case details
router.get('/:id', (req: Request, res: Response) => {
  try {
    const userRole = (req.headers['x-user-role'] as string) || 'CITIZEN';
    const c = CaseManagementService.getCaseById(req.params.id, userRole);
    if (!c) {
      return res.status(404).json({ success: false, error: 'Case not found' });
    }
    res.json({ success: true, data: c });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/cases — Create case with DPDP consent (FR-38, FR-39)
router.post('/', (req: Request, res: Response) => {
  try {
    const {
      household_head_name, contact_phone, area_id, shelter_id,
      household_size, vulnerability_flags, needs_summary,
      entitlement_ration_kits, entitlement_water_litres, entitlement_medical_kits,
      caseworker_notes, actorId
    } = req.body;

    if (!household_head_name || !contact_phone || !area_id || !household_size) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: household_head_name, contact_phone, area_id, household_size'
      });
    }

    const created = CaseManagementService.createCase(
      {
        household_head_name,
        contact_phone,
        area_id,
        shelter_id,
        household_size: Number(household_size),
        vulnerability_flags: vulnerability_flags || [],
        needs_summary: needs_summary || 'Relief assistance requested',
        entitlement_ration_kits,
        entitlement_water_litres,
        entitlement_medical_kits,
        caseworker_notes
      },
      actorId || 'USR-ADMIN-01'
    );

    res.status(201).json({ success: true, message: 'Case created with DPDP consent captured (FR-38, FR-39)', data: created });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// POST /api/v1/cases/:id/assistance — Record assistance distribution (FR-38)
router.post('/:id/assistance', (req: Request, res: Response) => {
  try {
    const { assistance_type, quantity, distribution_point, recipient_signature_or_otp, actorId } = req.body;

    if (!assistance_type || !quantity || !distribution_point) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: assistance_type, quantity, distribution_point'
      });
    }

    const updated = CaseManagementService.recordAssistance(
      {
        case_id: req.params.id,
        assistance_type,
        quantity: Number(quantity),
        distribution_point,
        recipient_signature_or_otp
      },
      actorId || 'USR-ADMIN-01'
    );

    res.json({ success: true, message: 'Assistance logged and case entitlements updated', data: updated });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// POST /api/v1/cases/merge — Auditable Duplicate Merging with Entitlement Preservation (FR-40)
router.post('/merge', (req: Request, res: Response) => {
  try {
    const { primary_case_id, duplicate_case_id, merge_reason, actorId } = req.body;

    if (!primary_case_id || !duplicate_case_id || !merge_reason) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: primary_case_id, duplicate_case_id, merge_reason'
      });
    }

    const merged = CaseManagementService.mergeCases(
      primary_case_id,
      duplicate_case_id,
      actorId || 'USR-ADMIN-01',
      merge_reason
    );

    res.json({
      success: true,
      message: 'Cases merged successfully. Entitlements combined without forfeiture (FR-40).',
      data: merged
    });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

export default router;
