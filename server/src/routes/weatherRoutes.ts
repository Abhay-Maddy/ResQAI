import { Router, Request, Response } from 'express';
import { fetchLiveWeather } from '../services/weatherService';

export const weatherRouter = Router();

/**
 * GET /api/v1/weather?lat=&lon=
 * Aligned with PRD v3.0 WX-1 through WX-5
 */
weatherRouter.get('/', async (req: Request, res: Response) => {
  try {
    const defaultLat = parseFloat(process.env.FALLBACK_LATITUDE || '28.6480');
    const defaultLon = parseFloat(process.env.FALLBACK_LONGITUDE || '77.3450');
    const latStr = (req.query.lat as string) || String(defaultLat);
    const lonStr = (req.query.lon as string) || String(defaultLon);

    const lat = parseFloat(latStr);
    const lon = parseFloat(lonStr);

    if (isNaN(lat) || isNaN(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      return res.status(400).json({
        error: 'INVALID_COORDINATES',
        message: 'Coordinates must be valid numbers: lat (-90 to 90), lon (-180 to 180)',
      });
    }

    const weather = await fetchLiveWeather(lat, lon);
    return res.json(weather);
  } catch (error: any) {
    return res.status(503).json({
      error: 'WEATHER_SERVICE_UNAVAILABLE',
      message: error.message,
      isStale: true,
      lastUpdated: null,
    });
  }
});

