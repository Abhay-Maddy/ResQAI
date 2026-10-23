import { Router, Request, Response } from 'express';
import { MissingPersonService } from '../services/missingPersonService';

const router = Router();

// GET /api/v1/missing-persons — List with Child Protection Filter (FR-41)
router.get('/', (req: Request, res: Response) => {
  try {
    const { status, publicOnly } = req.query;
    const records = MissingPersonService.getAllMissingPersons({
      status: status as string,
      publicOnly: publicOnly === 'true' || publicOnly === '1'
    });
    res.json({ success: true, count: records.length, data: records });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/missing-persons/:id
router.get('/:id', (req: Request, res: Response) => {
  try {
    const record = MissingPersonService.getById(req.params.id);
    if (!record) {
      return res.status(404).json({ success: false, error: 'Record not found' });
    }
    res.json({ success: true, data: record });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/missing-persons — Report Missing Person with Child Protection (FR-41)
router.post('/', (req: Request, res: Response) => {
  try {
    const {
      full_name, age, gender, last_known_location, last_seen_time,
      shelter_id, child_protection_consent_verified, actorId
    } = req.body;

    if (!full_name || age === undefined || !gender || !last_known_location || !last_seen_time) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: full_name, age, gender, last_known_location, last_seen_time'
      });
    }

    const record = MissingPersonService.reportMissingPerson(
      {
        full_name,
        age: Number(age),
        gender,
        last_known_location,
        last_seen_time,
        reported_by_user_id: actorId || 'USR-CITIZEN-01',
        shelter_id,
        child_protection_consent_verified: Boolean(child_protection_consent_verified)
      },
      actorId || 'USR-CITIZEN-01'
    );

    res.status(201).json({
      success: true,
      message: 'Missing person report registered in safe registry (FR-41)',
      data: record
    });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// PATCH /api/v1/missing-persons/:id/safe-and-well — Safe-and-Well Check-in (FR-41)
router.patch('/:id/safe-and-well', (req: Request, res: Response) => {
  try {
    const { status, shelter_id, actorId } = req.body;
    if (!status || !['FOUND_SAFE', 'AT_SHELTER', 'HOSPITALIZED'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Must be FOUND_SAFE, AT_SHELTER, or HOSPITALIZED'
      });
    }

    const updated = MissingPersonService.updateSafeAndWellStatus(
      req.params.id,
      status,
      shelter_id,
      actorId || 'USR-ADMIN-01'
    );

    res.json({
      success: true,
      message: `Safe-and-well check-in recorded: ${status}`,
      data: updated
    });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

export default router;
