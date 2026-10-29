export interface LatLngPoint {
  lat: number;
  lng: number;
}

export interface InundationPolygonFeature {
  id: string;
  name: string;
  type: 'FLOOD_INUNDATION_EXTREME' | 'FLOOD_INUNDATION_MODERATE' | 'CONTAINMENT_ZONE' | 'SAFE_CORRIDOR';
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'SAFE';
  waterDepthMeters: number;
  coordinates: [number, number][]; // [lat, lng]
  description: string;
}

export class PolygonGeofenceService {
  private static activePolygons: InundationPolygonFeature[] = [
    {
      id: 'ZONE-NORTH-CANAL-FLOOD',
      name: 'North Canal Inundation Basin',
      type: 'FLOOD_INUNDATION_EXTREME',
      severity: 'CRITICAL',
      waterDepthMeters: 2.1,
      coordinates: [
        [25.6080, 85.1380],
        [25.6200, 85.1390],
        [25.6250, 85.1520],
        [25.6150, 85.1580],
        [25.6050, 85.1480],
        [25.6080, 85.1380]
      ],
      description: 'Severe embankment breach. Submerged up to 2.1 meters. Heavy current.'
    },
    {
      id: 'ZONE-BYPASS-LOWLAND',
      name: 'South Bypass Lowland Inundation',
      type: 'FLOOD_INUNDATION_MODERATE',
      severity: 'HIGH',
      waterDepthMeters: 0.9,
      coordinates: [
        [25.5890, 85.1150],
        [25.5990, 85.1160],
        [25.6010, 85.1300],
        [25.5910, 85.1290],
        [25.5890, 85.1150]
      ],
      description: 'Canal overflow waterlogged streets. Motor vehicles stalled.'
    },
    {
      id: 'ZONE-SAFE-ELEVATED-RIDGE',
      name: 'Grand Trunk Elevated Highway Safe Corridor',
      type: 'SAFE_CORRIDOR',
      severity: 'SAFE',
      waterDepthMeters: 0.0,
      coordinates: [
        [25.6280, 85.1600],
        [25.6350, 85.1650],
        [25.6400, 85.1800],
        [25.6320, 85.1820],
        [25.6280, 85.1600]
      ],
      description: 'Official elevated corridor verified clear by NDRF.'
    }
  ];

  /**
   * Ray-Casting algorithm to check if a point is inside a polygon
   */
  public static isPointInPolygon(point: LatLngPoint, polygon: [number, number][]): boolean {
    const x = point.lat;
    const y = point.lng;
    let inside = false;

    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      const xi = polygon[i][0];
      const yi = polygon[i][1];
      const xj = polygon[j][0];
      const yj = polygon[j][1];

      const intersect = ((yi > y) !== (yj > y)) &&
        (x < ((xj - xi) * (y - yi)) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }
    }

    return inside;
  }

  /**
   * Checks if a coordinate is inside any active hazard polygon
   */
  public static checkGeofence(point: LatLngPoint): {
    insideHazard: boolean;
    matchingZone?: InundationPolygonFeature;
    warningMessage?: string;
  } {
    for (const poly of this.activePolygons) {
      if (poly.severity !== 'SAFE' && this.isPointInPolygon(point, poly.coordinates)) {
        return {
          insideHazard: true,
          matchingZone: poly,
          warningMessage: `⚠️ WARNING: Location is inside ${poly.name} (${poly.type}) with estimated water depth ${poly.waterDepthMeters}m.`
        };
      }
    }
    return { insideHazard: false };
  }

  /**
   * Check if a line segment (route step) intersects with a hazard polygon
   */
  public static doesRouteIntersectHazard(start: LatLngPoint, end: LatLngPoint): {
    intersects: boolean;
    hazardZone?: InundationPolygonFeature;
  } {
    // Sample 10 points along the path segment
    const steps = 10;
    for (let i = 0; i <= steps; i++) {
      const fraction = i / steps;
      const samplePoint: LatLngPoint = {
        lat: start.lat + (end.lat - start.lat) * fraction,
        lng: start.lng + (end.lng - start.lng) * fraction
      };
      const check = this.checkGeofence(samplePoint);
      if (check.insideHazard) {
        return {
          intersects: true,
          hazardZone: check.matchingZone
        };
      }
    }
    return { intersects: false };
  }

  /**
   * Calculate safe evacuation corridor that avoids all hazard polygons
   */
  public static computeSafeCorridor(origin: LatLngPoint, destination: LatLngPoint): {
    waypoints: [number, number][];
    totalDistanceKm: number;
    hazardAvoided: boolean;
    hazardName?: string;
    cautionNotice: string;
  } {
    const directCheck = this.doesRouteIntersectHazard(origin, destination);

    if (!directCheck.intersects) {
      // Direct path is already safe
      return {
        waypoints: [
          [origin.lat, origin.lng],
          [destination.lat, destination.lng]
        ],
        totalDistanceKm: this.haversineKm(origin, destination),
        hazardAvoided: false,
        cautionNotice: 'Direct evacuation route verified outside active flood inundation zones.'
      };
    }

    // Direct path intersects flood polygon: calculate bypass waypoint via elevated ridge
    const bypassWaypoint: LatLngPoint = {
      lat: (origin.lat + destination.lat) / 2 + 0.025, // detour northward around basin
      lng: (origin.lng + destination.lng) / 2 + 0.020
    };

    const dist1 = this.haversineKm(origin, bypassWaypoint);
    const dist2 = this.haversineKm(bypassWaypoint, destination);

    return {
      waypoints: [
        [origin.lat, origin.lng],
        [bypassWaypoint.lat, bypassWaypoint.lng],
        [destination.lat, destination.lng]
      ],
      totalDistanceKm: Number((dist1 + dist2).toFixed(2)),
      hazardAvoided: true,
      hazardName: directCheck.hazardZone?.name,
      cautionNotice: `⚠️ Route re-routed around ${directCheck.hazardZone?.name} (${directCheck.hazardZone?.waterDepthMeters}m water depth). Follow elevated bypass corridor.`
    };
  }

  public static getAllPolygons(): InundationPolygonFeature[] {
    return this.activePolygons;
  }

  private static haversineKm(p1: LatLngPoint, p2: LatLngPoint): number {
    const R = 6371;
    const dLat = (p2.lat - p1.lat) * Math.PI / 180;
    const dLng = (p2.lng - p1.lng) * Math.PI / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(p1.lat * Math.PI / 180) * Math.cos(p2.lat * Math.PI / 180) *
      Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return Number((R * c).toFixed(2));
  }
}
