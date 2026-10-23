import { db } from '../db/database';
import crypto from 'crypto';

export class DrillService {
  // Part L Item 7: Synthetic Drill Simulation Engine
  public static getActiveDrills() {
    return db.prepare('SELECT * FROM drill_sessions ORDER BY started_at DESC').all();
  }

  public static startDrill(
    drillName: string,
    scenarioType: 'URBAN_FLASH_FLOOD' | 'CATEGORY_4_CYCLONE',
    actorId: string
  ) {
    const drillId = `DRILL-${new Date().getFullYear()}-${crypto.randomUUID().substring(0, 6).toUpperCase()}`;

    // Insert Drill Session
    db.prepare(`
      INSERT INTO drill_sessions (id, drill_name, scenario_type, started_at, status, is_watermarked_synthetic, total_synthetic_incidents)
      VALUES (?, ?, ?, datetime('now'), 'ACTIVE', 1, 3)
    `).run(drillId, drillName, scenarioType);

    // Inject 3 synthetic watermarked incidents
    const insertInc = db.prepare(`
      INSERT INTO incidents (
        id, title, category, status, urgency, priority_score,
        latitude, longitude, location_name, area_id, people_affected,
        created_at, updated_at, sla_deadline_minutes, is_simulated_drill
      ) VALUES (
        @id, @title, @category, 'RECEIVED', @urgency, @priority_score,
        @latitude, @longitude, @location_name, @area_id, @people_affected,
        datetime('now'), datetime('now'), 15, 1
      )
    `);

    const syntheticIncidents = [
      {
        id: `INC-SYNTH-${drillId}-01`,
        title: `[SIMULATED DRILL] Flash Flood at Embankment Gate 4`,
        category: 'FLOOD',
        urgency: 'CRITICAL',
        priority_score: 95.0,
        latitude: 25.612,
        longitude: 85.143,
        location_name: 'Simulated Flood Zone - Gate 4',
        area_id: 'area-a',
        people_affected: 20
      },
      {
        id: `INC-SYNTH-${drillId}-02`,
        title: `[SIMULATED DRILL] Structural Wall Collapse at School Shelter`,
        category: 'OTHER',
        urgency: 'HIGH',
        priority_score: 85.0,
        latitude: 25.618,
        longitude: 85.150,
        location_name: 'Simulated Shelter Ward 3',
        area_id: 'area-a',
        people_affected: 8
      },
      {
        id: `INC-SYNTH-${drillId}-03`,
        title: `[SIMULATED DRILL] Power Line Failure & Submersion`,
        category: 'FIRE',
        urgency: 'MEDIUM',
        priority_score: 65.0,
        latitude: 25.605,
        longitude: 85.138,
        location_name: 'Simulated Substation North',
        area_id: 'area-a',
        people_affected: 0
      }
    ];

    for (const inc of syntheticIncidents) {
      insertInc.run(inc);
    }

    // Audit log (FR-53)
    db.prepare(`
      INSERT INTO audit_logs (id, action_type, actor_id, actor_role, entity_id, details)
      VALUES (?, 'DRILL_STARTED', ?, 'ADMIN', ?, ?)
    `).run(
      `AUD-${crypto.randomUUID().substring(0, 8)}`,
      actorId,
      drillId,
      `Synthetic drill "${drillName}" started with 3 watermarked training incidents (Part L Item 7)`
    );

    return db.prepare('SELECT * FROM drill_sessions WHERE id = ?').get(drillId);
  }

  public static concludeDrill(drillId: string, actorId: string) {
    db.prepare(`
      UPDATE drill_sessions
      SET status = 'CONCLUDED', ended_at = datetime('now')
      WHERE id = ?
    `).run(drillId);

    // Remove synthetic incidents
    db.prepare(`DELETE FROM incidents WHERE is_simulated_drill = 1 AND id LIKE ?`).run(`%${drillId}%`);

    // Audit log
    db.prepare(`
      INSERT INTO audit_logs (id, action_type, actor_id, actor_role, entity_id, details)
      VALUES (?, 'DRILL_CONCLUDED', ?, 'ADMIN', ?, ?)
    `).run(
      `AUD-${crypto.randomUUID().substring(0, 8)}`,
      actorId,
      drillId,
      `Drill session ${drillId} concluded and synthetic drill records archived.`
    );

    return db.prepare('SELECT * FROM drill_sessions WHERE id = ?').get(drillId);
  }
}
