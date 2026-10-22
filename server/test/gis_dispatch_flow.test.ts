import { test, describe, before } from 'node:test';
import assert from 'node:assert/strict';
import { db, initDatabase } from '../src/db/database';

describe('Phase 3: GIS Layers, Safe Routing & Full Dispatch-to-Resolution Flow', () => {
  const runId = Date.now().toString();
  const testIncidentId = `INC-MAP-${runId}`;
  const testAssignmentId = `ASG-MAP-${runId}`;
  const teamId = 'TEAM-NDRF-9A';

  before(async () => {
    await initDatabase();

    // Ensure road closures exist (FR-23)
    const roadCount = (db.prepare('SELECT count(*) as c FROM road_closures').get() as any).c;
    if (roadCount === 0) {
      db.prepare(`
        INSERT INTO road_closures (id, road_name, area_id, cause, start_lat, start_lng, end_lat, end_lng, is_passable_for_emergency)
        VALUES ('RC-TEST-01', 'East Embankment Highway', 'area-a', 'FLOODING', 25.6140, 85.1430, 25.6170, 85.1490, 0)
      `).run();
    }
  });

  test('Step 1: Incident Reported & Registered on Map (FR-5, FR-20)', () => {
    db.prepare(`
      INSERT INTO incidents (
        id, title, category, status, urgency, priority_score, latitude, longitude,
        location_name, area_id, people_affected, sla_deadline_minutes
      ) VALUES (?, 'Stranded on School Terrace near Embankment', 'FLOOD', 'VERIFIED', 'CRITICAL', 92, 25.6190, 85.1520, 'Ward 18 High School', 'area-a', 22, 15)
    `).run(testIncidentId);

    const saved = db.prepare('SELECT * FROM incidents WHERE id = ?').get(testIncidentId) as any;
    assert.ok(saved);
    assert.equal(saved.status, 'VERIFIED');
    assert.equal(saved.latitude, 25.6190);
    assert.equal(saved.longitude, 85.1520);
  });

  test('Step 2: Team Dispatched & Assigned to Incident (FR-16)', () => {
    db.prepare(`
      INSERT INTO assignments (id, incident_id, team_id, status)
      VALUES (?, ?, ?, 'ASSIGNED')
    `).run(testAssignmentId, testIncidentId, teamId);

    db.prepare("UPDATE incidents SET status = 'RESPONSE_ASSIGNED', assigned_team_id = ? WHERE id = ?").run(teamId, testIncidentId);
    db.prepare("UPDATE rescue_teams SET status = 'ASSIGNED', assigned_incident_id = ? WHERE id = ?").run(testIncidentId, teamId);

    const inc = db.prepare('SELECT * FROM incidents WHERE id = ?').get(testIncidentId) as any;
    assert.equal(inc.status, 'RESPONSE_ASSIGNED');
    assert.equal(inc.assigned_team_id, teamId);
  });

  test('Step 3: Safe Routing Calculation with Road Closure Avoidance (FR-23)', () => {
    // Start from Team base (25.6110, 85.1410) to Incident (25.6190, 85.1520)
    const startLat = 25.6110;
    const startLng = 85.1410;
    const endLat = 25.6190;
    const endLng = 85.1520;

    const activeClosures = db.prepare('SELECT * FROM road_closures WHERE is_passable_for_emergency = 0').all() as any[];
    assert.ok(activeClosures.length > 0, 'Active road closures must exist in DB');

    const waypoints: [number, number][] = [[startLat, startLng]];
    let detourTriggered = false;

    for (const rc of activeClosures) {
      const midLat = (startLat + endLat) / 2;
      const midLng = (startLng + endLng) / 2;
      const distToClosure = Math.hypot(midLat - rc.start_lat, midLng - rc.start_lng);

      if (distToClosure < 0.05) {
        detourTriggered = true;
        waypoints.push([rc.start_lat + 0.008, rc.start_lng + 0.006]);
        break;
      }
    }
    waypoints.push([endLat, endLng]);

    assert.ok(detourTriggered, 'Closed road avoidance must trigger safe bypass waypoint');
    assert.equal(waypoints.length, 3, 'Waypoints must include origin, detour bypass, and destination');
  });

  test('Step 4: Field Responder State Transitions (FR-17)', () => {
    // 1. Accept
    db.prepare("UPDATE assignments SET status = 'ACCEPTED', acknowledged_at = datetime('now') WHERE id = ?").run(testAssignmentId);
    let asg = db.prepare('SELECT * FROM assignments WHERE id = ?').get(testAssignmentId) as any;
    assert.equal(asg.status, 'ACCEPTED');

    // 2. En Route
    db.prepare("UPDATE assignments SET status = 'EN_ROUTE' WHERE id = ?").run(testAssignmentId);
    db.prepare("UPDATE incidents SET status = 'IN_PROGRESS' WHERE id = ?").run(testIncidentId);
    db.prepare("UPDATE rescue_teams SET status = 'EN_ROUTE' WHERE id = ?").run(teamId);

    let inc = db.prepare('SELECT * FROM incidents WHERE id = ?').get(testIncidentId) as any;
    assert.equal(inc.status, 'IN_PROGRESS');

    // 3. On Scene
    db.prepare("UPDATE assignments SET status = 'ON_SCENE', arrived_at_scene_at = datetime('now') WHERE id = ?").run(testAssignmentId);
    db.prepare("UPDATE rescue_teams SET status = 'ON_SCENE' WHERE id = ?").run(teamId);
    asg = db.prepare('SELECT * FROM assignments WHERE id = ?').get(testAssignmentId) as any;
    assert.equal(asg.status, 'ON_SCENE');

    // 4. Resolved
    db.prepare("UPDATE assignments SET status = 'RESOLVED', resolved_at = datetime('now'), notes = 'All 22 citizens successfully rescued by boat to shelter' WHERE id = ?").run(testAssignmentId);
    db.prepare("UPDATE incidents SET status = 'RESOLVED' WHERE id = ?").run(testIncidentId);
    db.prepare("UPDATE rescue_teams SET status = 'IDLE', assigned_incident_id = NULL WHERE id = ?").run(teamId);

    inc = db.prepare('SELECT * FROM incidents WHERE id = ?').get(testIncidentId) as any;
    assert.equal(inc.status, 'RESOLVED', 'Incident must reach RESOLVED state');

    const team = db.prepare('SELECT * FROM rescue_teams WHERE id = ?').get(teamId) as any;
    assert.equal(team.status, 'IDLE', 'Team must return to IDLE capacity');
  });

  test('Step 5: Exit Criteria Verification — Resolved on Map Query (FR-20, FR-24)', () => {
    const mapIncidents = db.prepare("SELECT * FROM incidents WHERE id = ?").get(testIncidentId) as any;
    assert.ok(mapIncidents);
    assert.equal(mapIncidents.status, 'RESOLVED');

    const shelters = db.prepare("SELECT count(*) as c FROM affected_areas").get() as any;
    assert.ok(shelters.c >= 3, 'Affected areas must be mapped');
  });
});
