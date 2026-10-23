import { Router, Request, Response } from 'express';
import { RumourService } from '../services/rumourService';

export const rumourRouter = Router();

// POST /api/v1/rumours - Submit rumour report
rumourRouter.post('/', (req: Request, res: Response) => {
  try {
    const reporterId = (req.headers['x-user-id'] as string) || req.body.reporter_id || 'USR-CITIZEN-01';
    const rumour = RumourService.reportRumour(
      {
        reported_claim: req.body.reported_claim,
        source_platform: req.body.source_platform
      },
      reporterId
    );
    res.status(201).json({ success: true, rumour });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// POST /api/v1/rumours/:id/verify - Verify / debunk rumour
rumourRouter.post('/:id/verify', (req: Request, res: Response) => {
  try {
    const actorRole = (req.headers['x-user-role'] as string) || req.body.role || 'GOVT_OFFICER';
    const actorId = (req.headers['x-user-id'] as string) || req.body.officer_id || 'USR-OFFICER-01';

    const rumour = RumourService.verifyRumour(
      req.params.id,
      req.body.decision,
      req.body.correction_notice,
      actorId,
      actorRole
    );
    res.json({ success: true, rumour });
  } catch (error: any) {
    const status = error.message?.includes('Unauthorized') ? 403 : 400;
    res.status(status).json({ success: false, error: error.message });
  }
});

// GET /api/v1/rumours - List all rumours (review queue)
rumourRouter.get('/', (req: Request, res: Response) => {
  try {
    const status = req.query.status as string;
    const rumours = RumourService.getAllRumours(status);
    res.json({ success: true, rumours });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/rumours/public - Public fact checks
rumourRouter.get('/public', (_req: Request, res: Response) => {
  try {
    const factChecks = RumourService.getPublicFactChecks();
    res.json({ success: true, factChecks });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});
