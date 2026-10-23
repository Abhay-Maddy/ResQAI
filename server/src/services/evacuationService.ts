import { db } from '../db/database';
import { logAuditEvent } from './auditService';

export interface EvacuationZoneRecord {
  id: string;
  zone_name: string;
  area_id: string;
  urgency_level: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  safe_shelter_ids_json: string;
  evacuation_routes_notes: string;
  pickup_points_notes?: string;
  active_status: 'STANDBY' | 'EVACUATION_ORDERED' | 'ALL_CLEAR';
}

export class EvacuationService {
  /**
   * Get all evacuation zones (with automatic seed fallback)
   */
  static getAllZones(): EvacuationZoneRecord[] {
    let zones = db.prepare('SELECT * FROM evacuation_zones ORDER BY id ASC').all() as EvacuationZoneRecord[];
    if (zones.length === 0) {
      const defaultZones = [
        {
          id: 'ZONE-01',
          zone_name: 'Sector A Lowland Riverine Ward 4-7',
          area_id: 'area-a',
          urgency_level: 'HIGH',
          safe_shelter_ids_json: JSON.stringify(['SHELTER-A1']),
          evacuation_routes_notes: 'Primary route via NH-31 Elevated Bypass corridor. East Embankment Highway is closed.',
          pickup_points_notes: 'Danapur Primary School Gate, Railway Colony Hall',
          active_status: 'STANDBY'
        },
        {
          id: 'ZONE-02',
          zone_name: 'Sector B Floodplain Inundation Basin',
          area_id: 'area-b',
          urgency_level: 'CRITICAL',
          safe_shelter_ids_json: JSON.stringify(['SHELTER-B1']),
          evacuation_routes_notes: 'Northern High Ridge Causeway to Higher Ground.',
          pickup_points_notes: 'Main Chowk Bus Stand, Old Post Office',
          active_status: 'STANDBY'
        },
        {
          id: 'ZONE-03',
          zone_name: 'Sector C Highland Safe Buffer',
          area_id: 'area-c',
          urgency_level: 'LOW',
          safe_shelter_ids_json: JSON.stringify(['SHELTER-C1']),
          evacuation_routes_notes: 'Standard District Roads passable.',
          pickup_points_notes: 'District Sports Complex Terminal',
          active_status: 'ALL_CLEAR'
        }
      ];

      const stmt = db.prepare(`
        INSERT INTO evacuation_zones (
          id, zone_name, area_id, urgency_level, safe_shelter_ids_json,
          evacuation_routes_notes, pickup_points_notes, active_status
        ) VALUES (
          @id, @zone_name, @area_id, @urgency_level, @safe_shelter_ids_json,
          @evacuation_routes_notes, @pickup_points_notes, @active_status
        )
      `);

      for (const z of defaultZones) {
        stmt.run(z);
      }
      zones = db.prepare('SELECT * FROM evacuation_zones ORDER BY id ASC').all() as EvacuationZoneRecord[];
    }
    return zones;
  }

  /**
   * Update evacuation zone status (e.g. order evacuation during imminent flood crest)
   */
  static updateZoneStatus(
    zoneId: string,
    activeStatus: 'STANDBY' | 'EVACUATION_ORDERED' | 'ALL_CLEAR',
    routeNotes: string,
    officerId: string,
    officerRole: string
  ): EvacuationZoneRecord {
    if (!['ADMIN', 'GOVT_OFFICER'].includes(officerRole)) {
      throw new Error(`Unauthorized: Role '${officerRole}' cannot modify evacuation zone status.`);
    }

    const existing = db.prepare('SELECT * FROM evacuation_zones WHERE id = ?').get(zoneId) as EvacuationZoneRecord;
    if (!existing) {
      throw new Error(`Evacuation zone '${zoneId}' not found.`);
    }

    db.prepare(`
      UPDATE evacuation_zones
      SET active_status = ?,
          evacuation_routes_notes = ?
      WHERE id = ?
    `).run(activeStatus, routeNotes, zoneId);

    logAuditEvent({
      actionType: 'EVACUATION_ZONE_STATUS_CHANGE',
      actorId: officerId,
      actorRole: officerRole,
      entityId: zoneId,
      details: `Evacuation zone ${zoneId} status changed from ${existing.active_status} to ${activeStatus}. Directives: ${routeNotes}`,
      beforeState: existing,
      afterState: { ...existing, active_status: activeStatus, evacuation_routes_notes: routeNotes }
    });

    return {
      ...existing,
      active_status: activeStatus,
      evacuation_routes_notes: routeNotes
    };
  }

  /**
   * Get vulnerable individuals in this zone requiring assisted evacuation (FR-38, Part B)
   */
  static getAssistedPickupList(areaId?: string) {
    let query = `
      SELECT id, household_head_name, contact_phone, area_id, shelter_id,
             household_size, vulnerability_flags_json, needs_summary, status
      FROM person_cases
      WHERE status != 'CLOSED' AND is_merged = 0
    `;
    const params: any[] = [];

    if (areaId) {
      query += ` AND area_id = ?`;
      params.push(areaId);
    }

    const rows = db.prepare(query).all(...params) as any[];
    
    // Filter to cases having vulnerable members (ELDERLY, DISABLED, INFANT, PREGNANT)
    return rows.map(r => ({
      ...r,
      vulnerability_flags: JSON.parse(r.vulnerability_flags_json || '[]')
    })).filter(r => 
      r.vulnerability_flags.some((f: string) => ['ELDERLY', 'DISABLED', 'INFANT', 'PREGNANT', 'CHRONIC_MEDICAL'].includes(f))
    );
  }
}
