import { Router, Request, Response } from 'express';
import { SitRepService } from '../services/sitrepService';

export const sitrepRouter = Router();

// GET /api/v1/sitrep - Compile official SitRep
sitrepRouter.get('/', (req: Request, res: Response) => {
  try {
    const actorRole = (req.headers['x-user-role'] as string) || (req.query.role as string) || 'ADMIN';
    const actorId = (req.headers['x-user-id'] as string) || 'USR-ADMIN-01';
    const jurisdiction = (req.query.jurisdiction as string) || 'GLOBAL';

    const sitrep = SitRepService.compileSitRep(jurisdiction, actorId, actorRole);
    res.json({ success: true, sitrep });
  } catch (error: any) {
    const status = error.message?.includes('Access Denied') ? 403 : 500;
    res.status(status).json({ success: false, error: error.message });
  }
});

// GET /api/v1/sitrep/geojson - Export spatial GeoJSON
sitrepRouter.get('/geojson', (req: Request, res: Response) => {
  try {
    const actorRole = (req.headers['x-user-role'] as string) || (req.query.role as string) || 'ADMIN';
    const actorId = (req.headers['x-user-id'] as string) || 'USR-ADMIN-01';
    const jurisdiction = (req.query.jurisdiction as string) || 'GLOBAL';

    const geojson = SitRepService.generateGeoJson(jurisdiction, actorId, actorRole);
    res.setHeader('Content-Type', 'application/geo+json');
    res.setHeader('Content-Disposition', 'attachment; filename="resqai_tactical_layer.geojson"');
    res.json(geojson);
  } catch (error: any) {
    const status = error.message?.includes('Access Denied') ? 403 : 500;
    res.status(status).json({ success: false, error: error.message });
  }
});

// GET /api/v1/sitrep/csv - Export CSV
sitrepRouter.get('/csv', (req: Request, res: Response) => {
  try {
    const actorRole = (req.headers['x-user-role'] as string) || (req.query.role as string) || 'ADMIN';
    const actorId = (req.headers['x-user-id'] as string) || 'USR-ADMIN-01';
    const jurisdiction = (req.query.jurisdiction as string) || 'GLOBAL';

    const csv = SitRepService.generateCsv(jurisdiction, actorId, actorRole);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="resqai_incidents.csv"');
    res.send(csv);
  } catch (error: any) {
    const status = error.message?.includes('Access Denied') ? 403 : 500;
    res.status(status).json({ success: false, error: error.message });
  }
});

// GET /api/v1/sitrep/print - Printable HTML
sitrepRouter.get('/print', (req: Request, res: Response) => {
  try {
    const actorRole = (req.headers['x-user-role'] as string) || (req.query.role as string) || 'ADMIN';
    const actorId = (req.headers['x-user-id'] as string) || 'USR-ADMIN-01';
    const jurisdiction = (req.query.jurisdiction as string) || 'GLOBAL';

    const sitrep = SitRepService.compileSitRep(jurisdiction, actorId, actorRole);
    const html = SitRepService.generatePrintableHtml(sitrep);
    res.setHeader('Content-Type', 'text/html');
    res.send(html);
  } catch (error: any) {
    const status = error.message?.includes('Access Denied') ? 403 : 500;
    res.status(status).json({ success: false, error: error.message });
  }
});
