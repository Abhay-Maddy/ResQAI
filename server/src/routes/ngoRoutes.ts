import { Router, Request, Response } from 'express';
import { NGOService } from '../services/ngoService';

const router = Router();

// GET /api/v1/ngos — List NGOs
router.get('/', (req: Request, res: Response) => {
  try {
    const kyc_status = req.query.kyc_status as string;
    const ngos = NGOService.getAllNGOs({ kyc_status });
    res.json({ success: true, count: ngos.length, data: ngos });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/ngos/:id — Get NGO details
router.get('/:id', (req: Request, res: Response) => {
  try {
    const ngo = NGOService.getNGOById(req.params.id);
    if (!ngo) {
      return res.status(404).json({ success: false, error: 'NGO not found' });
    }
    res.json({ success: true, data: ngo });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/ngos — Register NGO
router.post('/', (req: Request, res: Response) => {
  try {
    const {
      name, darpan_id, fcra_number, fcra_valid_until,
      tax_80g_number, tax_80g_valid_until,
      authorized_rep_name, authorized_rep_email, authorized_rep_phone,
      documents
    } = req.body;

    if (!name || !darpan_id || !authorized_rep_name || !authorized_rep_email || !authorized_rep_phone) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: name, darpan_id, authorized_rep_name, authorized_rep_email, authorized_rep_phone'
      });
    }

    const ngo = NGOService.registerNGO({
      name, darpan_id, fcra_number, fcra_valid_until,
      tax_80g_number, tax_80g_valid_until,
      authorized_rep_name, authorized_rep_email, authorized_rep_phone,
      documents
    });

    res.status(201).json({ success: true, message: 'NGO registered successfully for KYC verification', data: ngo });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// PATCH /api/v1/ngos/:id/status — Admin update NGO KYC status (FR-42)
router.patch('/:id/status', (req: Request, res: Response) => {
  try {
    const { status, notes, actorId } = req.body;
    if (!status || !['APPROVED', 'REJECTED', 'SUSPENDED'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Must be APPROVED, REJECTED, or SUSPENDED'
      });
    }

    const updated = NGOService.updateNGOStatus(req.params.id, status, actorId || 'USR-ADMIN-01', notes);
    res.json({ success: true, message: `NGO KYC status updated to ${status}`, data: updated });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

export default router;
