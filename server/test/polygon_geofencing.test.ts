import { test, describe, before } from 'node:test';
import assert from 'node:assert';
import { initDatabase } from '../src/db/database';
import { PolygonGeofenceService } from '../src/services/polygonGeofenceService';

describe('True Polygon GIS Geofencing & Inundation Corridors', () => {
  before(async () => {
    await initDatabase();
  });

  test('Step 1: Point inside North Canal Inundation Basin is accurately detected', () => {
    // Point inside the polygon: lat: 25.6150, lng: 85.1450
    const check = PolygonGeofenceService.checkGeofence({ lat: 25.6150, lng: 85.1450 });
    assert.strictEqual(check.insideHazard, true);
    assert.strictEqual(check.matchingZone?.id, 'ZONE-NORTH-CANAL-FLOOD');
    assert.strictEqual(check.matchingZone?.severity, 'CRITICAL');
    assert.strictEqual(check.matchingZone?.waterDepthMeters, 2.1);
  });

  test('Step 2: Elevated safe point outside any flood polygon is identified as SAFE', () => {
    // Point on safe elevated ridge: lat: 25.6500, lng: 85.2000
    const check = PolygonGeofenceService.checkGeofence({ lat: 25.6500, lng: 85.2000 });
    assert.strictEqual(check.insideHazard, false);
  });

  test('Step 3: Route crossing flood basin triggers hazard intersection warning', () => {
    const origin = { lat: 25.6000, lng: 85.1300 };
    const destination = { lat: 25.6300, lng: 85.1600 };

    const intersection = PolygonGeofenceService.doesRouteIntersectHazard(origin, destination);
    assert.strictEqual(intersection.intersects, true);
    assert.strictEqual(intersection.hazardZone?.id, 'ZONE-NORTH-CANAL-FLOOD');
  });

  test('Step 4: Safe corridor calculation routes around the inundation polygon', () => {
    const origin = { lat: 25.6000, lng: 85.1300 };
    const destination = { lat: 25.6300, lng: 85.1600 };

    const corridor = PolygonGeofenceService.computeSafeCorridor(origin, destination);
    assert.strictEqual(corridor.hazardAvoided, true);
    assert.strictEqual(corridor.waypoints.length, 3); // origin -> elevated bypass -> destination
    assert.ok(corridor.cautionNotice.includes('Follow elevated bypass corridor'));
  });
});
