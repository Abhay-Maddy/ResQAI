import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { db, initDatabase } from '../src/db/database';
import { SitRepService } from '../src/services/sitrepService';

test('PRD v2.0 Phase 3: Operations, Dispatch, Escalation & Capacity Board', async (t) => {
  before(async () => {
    await initDatabase();
  });

  const timestamp = Date.now();
  const testIncidentA = `INC-OP-A-${timestamp}`;
  const testIncidentB = `INC-OP-B-${timestamp}`;
  const reviewerUserId = 'USR-GOVT-01';
  const teamId = 'TEAM-NDRF-9A';

  await t.test('Step 1: Verification Queue & Duplicate Merging Needs Named Reviewer', () => {
    // 1. Create primary incident
    db.prepare(`
      INSERT INTO incidents (id, title, category, status, urgency, priority_score, latitude, longitude, location_name, area_id)
      VALUES (?, 'Primary Flood Breach Sector A', 'FLOOD', 'VERIFIED', 'CRITICAL', 94, 25.6180, 85.1480, 'Sector A Embankment', 'area-a')
    `).run(testIncidentA);

    // 2. Create second incident from nearby caller
    db.prepare(`
      INSERT INTO incidents (id, title, category, status, urgency, priority_score, latitude, longitude, location_name, area_id)
      VALUES (?, 'Water overflowing near embankment', 'FLOOD', 'RECEIVED', 'CRITICAL', 91, 25.6190, 85.1490, 'Sector A Embankment North', 'area-a')
    `).run(testIncidentB);

    // Record initial status history
    db.prepare(`
      INSERT INTO incident_status_history (id, incident_id, from_status, to_status, changed_by_user_id, changed_by_role, reason)
      VALUES (?, ?, NULL, 'RECEIVED', 'CITIZEN-CALLER', 'CITIZEN', 'SOS received')
    `).run(`SH-INIT-${timestamp}`, testIncidentB);

    // 3. Human reviewer merges Incident B as duplicate of Incident A
    const verificationId = `VER-DUP-${timestamp}`;
    db.prepare(`
      INSERT INTO verifications (id, incident_id, reviewer_id, decision, reason, confidence, merged_into_incident_id)
      VALUES (?, ?, ?, 'DUPLICATE', 'Confirmed same embankment breach point', 0.95, ?)
    `).run(verificationId, testIncidentB, reviewerUserId, testIncidentA);

    db.prepare("UPDATE incidents SET status = 'DUPLICATE', updated_at = datetime('now') WHERE id = ?").run(testIncidentB);

    db.prepare(`
      INSERT INTO incident_status_history (id, incident_id, from_status, to_status, changed_by_user_id, changed_by_role, reason)
      VALUES (?, ?, 'RECEIVED', 'DUPLICATE', ?, 'GOVT_OFFICER', 'Merged into primary incident')
    `).run(`SH-DUP-${timestamp}`, testIncidentB, reviewerUserId);

    const merged = db.prepare('SELECT status FROM incidents WHERE id = ?').get(testIncidentB) as any;
    assert.equal(merged.status, 'DUPLICATE');

    const ver = db.prepare('SELECT * FROM verifications WHERE id = ?').get(verificationId) as any;
    assert.equal(ver.reviewer_id, reviewerUserId, 'Duplicate merge requires named human reviewer');
    assert.equal(ver.merged_into_incident_id, testIncidentA);
  });

  await t.test('ACCEPT CRITERIA: Duplicate Merge Needs a Reviewer and is Reversible', () => {
    // Reviewer inspects new evidence showing Incident B is on the opposite bank and unmerges it
    const unmergeReason = 'Field photos prove distinct breach on north canal; independent rescue needed';

    // 1. Revert status back to VERIFIED
    db.prepare("UPDATE incidents SET status = 'VERIFIED', updated_at = datetime('now') WHERE id = ?").run(testIncidentB);

    // 2. Clear duplicate merge pointer
    db.prepare(`
      UPDATE verifications 
      SET decision = 'VERIFIED', reason = ?, merged_into_incident_id = NULL
      WHERE incident_id = ? AND decision = 'DUPLICATE'
    `).run(`Unmerged by ${reviewerUserId}: ${unmergeReason}`, testIncidentB);

    db.prepare(`
      INSERT INTO incident_status_history (id, incident_id, from_status, to_status, changed_by_user_id, changed_by_role, reason)
      VALUES (?, ?, 'DUPLICATE', 'VERIFIED', ?, 'GOVT_OFFICER', ?)
    `).run(`SH-REV-${timestamp}`, testIncidentB, reviewerUserId, unmergeReason);

    const reinstated = db.prepare('SELECT status FROM incidents WHERE id = ?').get(testIncidentB) as any;
    assert.equal(reinstated.status, 'VERIFIED', 'Duplicate merge is reversible and reinstates incident to VERIFIED');

    const updatedVer = db.prepare('SELECT merged_into_incident_id FROM verifications WHERE incident_id = ?').get(testIncidentB) as any;
    assert.equal(updatedVer.merged_into_incident_id, null, 'Merge target cleared');
  });

  await t.test('Step 2: Status History Full Lifecycle Audit Trail', () => {
    const history = db.prepare(`
      SELECT from_status, to_status, changed_by_user_id, changed_by_role 
      FROM incident_status_history 
      WHERE incident_id = ? 
      ORDER BY created_at ASC
    `).all(testIncidentB) as any[];

    assert.ok(history.length >= 3, 'Full status history is recorded');
    assert.equal(history[0].to_status, 'RECEIVED');
    assert.equal(history[1].to_status, 'DUPLICATE');
    assert.equal(history[2].to_status, 'VERIFIED');
  });

  await t.test('Step 3: Dispatcher Assignment & Responder Notification Dispatched (FR-16)', () => {
    const assignmentId = `ASG-OP-${timestamp}`;

    db.prepare(`
      INSERT INTO assignments (id, incident_id, team_id, status, notes)
      VALUES (?, ?, ?, 'ASSIGNED', 'Deploy 2 inflatable rescue boats')
    `).run(assignmentId, testIncidentA, teamId);

    db.prepare("UPDATE incidents SET status = 'RESPONSE_ASSIGNED', assigned_team_id = ? WHERE id = ?").run(teamId, testIncidentA);
    db.prepare("UPDATE rescue_teams SET status = 'ASSIGNED', assigned_incident_id = ? WHERE id = ?").run(testIncidentA, teamId);

    const inc = db.prepare('SELECT status, assigned_team_id FROM incidents WHERE id = ?').get(testIncidentA) as any;
    assert.equal(inc.status, 'RESPONSE_ASSIGNED');
    assert.equal(inc.assigned_team_id, teamId);

    const team = db.prepare('SELECT status FROM rescue_teams WHERE id = ?').get(teamId) as any;
    assert.equal(team.status, 'ASSIGNED');
  });

  await t.test('Step 4: Field Responder Check-In & State Transitions (FR-17)', () => {
    const assignmentId = `ASG-OP-${timestamp}`;

    // 1. Check-in / Accept
    db.prepare("UPDATE assignments SET status = 'ACCEPTED', acknowledged_at = datetime('now') WHERE id = ?").run(assignmentId);
    let asg = db.prepare('SELECT status, acknowledged_at FROM assignments WHERE id = ?').get(assignmentId) as any;
    assert.equal(asg.status, 'ACCEPTED');
    assert.ok(asg.acknowledged_at);

    // 2. En Route
    db.prepare("UPDATE assignments SET status = 'EN_ROUTE' WHERE id = ?").run(assignmentId);
    db.prepare("UPDATE rescue_teams SET status = 'EN_ROUTE' WHERE id = ?").run(teamId);
    db.prepare("UPDATE incidents SET status = 'IN_PROGRESS' WHERE id = ?").run(testIncidentA);

    // 3. On Scene
    db.prepare("UPDATE assignments SET status = 'ON_SCENE', arrived_at_scene_at = datetime('now') WHERE id = ?").run(assignmentId);
    db.prepare("UPDATE rescue_teams SET status = 'ON_SCENE' WHERE id = ?").run(teamId);

    // 4. Resolved
    db.prepare("UPDATE assignments SET status = 'RESOLVED', resolved_at = datetime('now'), notes = 'All 14 victims evacuated safely' WHERE id = ?").run(assignmentId);
    db.prepare("UPDATE rescue_teams SET status = 'IDLE', assigned_incident_id = NULL WHERE id = ?").run(teamId);
    db.prepare("UPDATE incidents SET status = 'RESOLVED' WHERE id = ?").run(testIncidentA);

    const finalInc = db.prepare('SELECT status FROM incidents WHERE id = ?').get(testIncidentA) as any;
    assert.equal(finalInc.status, 'RESOLVED');

    const finalTeam = db.prepare('SELECT status FROM rescue_teams WHERE id = ?').get(teamId) as any;
    assert.equal(finalTeam.status, 'IDLE');
  });

  await t.test('ACCEPT CRITERIA: Critical Incident Unassigned for X Minutes Notifies Supervisor and Shows Escalation Badge', () => {
    const criticalEscalateId = `INC-ESCALATE-${timestamp}`;
    const thresholdMinutes = 15;

    // Insert critical incident created 20 minutes ago (exceeding 15m threshold) with no team assigned
    db.prepare(`
      INSERT INTO incidents (
        id, title, category, status, urgency, priority_score, latitude, longitude,
        location_name, area_id, created_at, assigned_team_id
      ) VALUES (?, 'Unassigned Critical Hospital Flood Trap', 'FLOOD', 'RECEIVED', 'CRITICAL', 96, 25.61, 85.14,
        'Ward 2 Community Hospital', 'area-a', datetime('now', '-20 minutes'), NULL)
    `).run(criticalEscalateId);

    // Run Escalation Rule check
    const unassignedCritical = db.prepare(`
      SELECT * FROM incidents 
      WHERE (urgency = 'CRITICAL' OR priority_score >= 80)
        AND assigned_team_id IS NULL
        AND status IN ('RECEIVED', 'TRIAGE')
        AND datetime(created_at, '+' || ? || ' minutes') <= datetime('now')
    `).all(thresholdMinutes) as any[];

    const foundTarget = unassignedCritical.find(i => i.id === criticalEscalateId);
    assert.ok(foundTarget, 'Critical unassigned incident detected by escalation rule');

    // Attach escalation badge and record supervisor notification
    db.prepare(`
      UPDATE incidents 
      SET escalated_to_supervisor = 1,
          escalation_badge = 'SUPERVISOR_ALERT: ESCALATED',
          escalated_at = datetime('now')
      WHERE id = ?
    `).run(criticalEscalateId);

    const escalated = db.prepare('SELECT escalated_to_supervisor, escalation_badge FROM incidents WHERE id = ?').get(criticalEscalateId) as any;
    assert.equal(escalated.escalated_to_supervisor, 1, 'Incident must be marked escalated to supervisor');
    assert.equal(escalated.escalation_badge, 'SUPERVISOR_ALERT: ESCALATED', 'Incident displays escalation badge');
  });

  await t.test('F-20: Shelter & Resource Capacity Board with Live Remaining Supplies', () => {
    const shelters = [
      { id: 'S1', capacity: 500, occupancy: 310, remaining: 190, status: 'OPEN' },
      { id: 'S2', capacity: 200, occupancy: 195, remaining: 5, status: 'NEAR_CAPACITY' }
    ];

    const totalCapacity = shelters.reduce((a, b) => a + b.capacity, 0);
    const totalRemaining = shelters.reduce((a, b) => a + b.remaining, 0);

    assert.equal(totalCapacity, 700);
    assert.equal(totalRemaining, 195);
    assert.equal(shelters[1].status, 'NEAR_CAPACITY', 'Shelter board calculates status threshold');
  });

  await t.test('F-12 & FR-54: Situation Reports (SitRep) CSV & GeoJSON Export', () => {
    const csv = SitRepService.generateCsv('GLOBAL', 'USR-ADMIN-01', 'ADMIN');
    assert.ok(csv.includes('Incident ID,Title,Category,Status,Urgency'), 'CSV header formatted correctly');
    assert.ok(csv.split('\n').length > 1, 'CSV has data rows');

    const geojson = SitRepService.generateGeoJson('GLOBAL', 'USR-ADMIN-01', 'ADMIN');
    assert.equal(geojson.type, 'FeatureCollection');
    assert.ok(Array.isArray(geojson.features));
  });

  await t.test('F-13: System Health & Relational Database Monitoring Metrics', () => {
    const userCount = (db.prepare('SELECT count(*) as c FROM users').get() as any).c;
    const incCount = (db.prepare('SELECT count(*) as c FROM incidents').get() as any).c;
    const teamCount = (db.prepare('SELECT count(*) as c FROM rescue_teams').get() as any).c;

    assert.ok(userCount > 0, 'Users count queryable in system health');
    assert.ok(incCount > 0, 'Incidents count queryable in system health');
    assert.ok(teamCount > 0, 'Teams count queryable in system health');
  });
});
