import { Router, Request, Response } from 'express';
import { DrillService } from '../services/drillService';

const router = Router();

// GET /api/v1/drills — List drill sessions (Part L Item 7)
router.get('/', (_req: Request, res: Response) => {
  try {
    const drills = DrillService.getActiveDrills();
    res.json({ success: true, count: drills.length, data: drills });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/drills/start — Start Synthetic Drill Session
router.post('/start', (req: Request, res: Response) => {
  try {
    const { drill_name, scenario_type, actorId } = req.body;
    if (!drill_name || !scenario_type) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: drill_name, scenario_type'
      });
    }

    const session = DrillService.startDrill(
      drill_name,
      scenario_type,
      actorId || 'USR-ADMIN-01'
    );

    res.status(201).json({
      success: true,
      message: 'Synthetic drill session initiated with watermarked test incidents (Part L Item 7)',
      data: session
    });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

// POST /api/v1/drills/:id/conclude — Conclude Drill Session & Archive
router.post('/:id/conclude', (req: Request, res: Response) => {
  try {
    const { actorId } = req.body;
    const session = DrillService.concludeDrill(req.params.id, actorId || 'USR-ADMIN-01');
    res.json({
      success: true,
      message: 'Drill session concluded and synthetic incidents safely cleaned up',
      data: session
    });
  } catch (error: any) {
    res.status(400).json({ success: false, error: error.message });
  }
});

export default router;
