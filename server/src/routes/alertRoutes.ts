import { Router, Request, Response } from 'express';
import { AlertBroadcastService } from '../services/alertBroadcastService';

export const alertRouter = Router();

// POST /api/v1/alerts/broadcast - Issue authorized public alert (FR-49)
alertRouter.post('/broadcast', (req: Request, res: Response) => {
  try {
    const actorRole = (req.headers['x-user-role'] as string) || req.body.role || 'GOVT_OFFICER';
    const actorId = (req.headers['x-user-id'] as string) || req.body.officer_id || 'USR-OFFICER-01';

    const alert = AlertBroadcastService.broadcastAlert(
      {
        source: req.body.source,
        title: req.body.title,
        description: req.body.description,
        severity: req.body.severity,
        affected_region: req.body.affected_region,
        valid_until_hours: req.body.valid_until_hours
      },
      actorId,
      actorRole
    );

    res.status(201).json({ success: true, alert });
  } catch (error: any) {
    const status = error.message?.includes('Unauthorized')
      ? 403
      : error.message?.includes('Rate limit')
      ? 429
      : 400;
    res.status(status).json({ success: false, error: error.message });
  }
});

// GET /api/v1/alerts/active - List active public alerts
alertRouter.get('/active', (req: Request, res: Response) => {
  try {
    const region = req.query.region as string;
    const alerts = AlertBroadcastService.getActiveAlerts(region);
    res.json({ success: true, alerts });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/alerts/:id/cap - Get CAP 1.2 XML feed for alert
alertRouter.get('/:id/cap', (req: Request, res: Response) => {
  try {
    const alert = AlertBroadcastService.getAlertById(req.params.id);
    if (!alert) {
      return res.status(404).send('Alert not found');
    }

    const xml = AlertBroadcastService.generateCapXml(alert);
    res.setHeader('Content-Type', 'application/xml');
    res.send(xml);
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});
