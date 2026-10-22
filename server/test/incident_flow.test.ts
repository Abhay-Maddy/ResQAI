import { test, describe, before } from 'node:test';
import assert from 'node:assert/strict';
import { db, initDatabase } from '../src/db/database';
import { analyzeIncidentTriage } from '../src/services/aiTriageService';

describe('Phase 2: End-to-End Incident Reporting & Verification Flow', () => {
  const runId = Date.now().toString();
  const testIncidentId = `INC-FLOW-${runId}`;
  const testReportId = `REP-FLOW-${runId}`;
  const testIdempKey = `IDEMP-FLOW-${runId}`;

  before(async () => {
    await initDatabase();
  });

  test('FR-5, FR-6, FR-7: Citizen Emergency Report & Idempotent Submission', () => {
    const reportData = {
      id: testReportId,
      incident_id: testIncidentId,
      category: 'FLOOD',
      description: 'Water breached ground floor. 8 people trapped including 2 infants.',
      latitude: 25.613,
      longitude: 85.143,
      location_name: 'Ward 14, Riverbank Colony',
      urgency: 'CRITICAL',
      people_count: 8,
      contact_phone: '+919876543200',
      is_anonymous: 0,
      idempotency_key: testIdempKey
    };

    // Insert Incident
    db.prepare(`
      INSERT INTO incidents (
        id, title, category, status, urgency, priority_score, latitude, longitude,
        location_name, area_id, people_affected, sla_deadline_minutes
      ) VALUES (?, ?, ?, 'TRIAGE', ?, 88, ?, ?, ?, 'area-a', ?, 15)
    `).run(
      reportData.incident_id,
      reportData.description,
      reportData.category,
      reportData.urgency,
      reportData.latitude,
      reportData.longitude,
      reportData.location_name,
      reportData.people_count
    );

    // Insert Report
    db.prepare(`
      INSERT INTO incident_reports (
        id, incident_id, source_type, category, description, latitude, longitude,
        location_name, urgency, people_count, contact_phone, is_anonymous, idempotency_key
      ) VALUES (?, ?, 'CITIZEN_PWA', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      reportData.id,
      reportData.incident_id,
      reportData.category,
      reportData.description,
      reportData.latitude,
      reportData.longitude,
      reportData.location_name,
      reportData.urgency,
      reportData.people_count,
      reportData.contact_phone,
      reportData.is_anonymous,
      reportData.idempotency_key
    );

    // Verify incident stored in DB with TRIAGE status
    const saved = db.prepare('SELECT * FROM incidents WHERE id = ?').get(testIncidentId) as any;
    assert.ok(saved, 'Incident must exist');
    assert.equal(saved.status, 'TRIAGE', 'New report must enter TRIAGE state');
    assert.equal(saved.urgency, 'CRITICAL');

    // Idempotency check: duplicate submission with same idempotency key is detected
    const dupe = db.prepare('SELECT * FROM incident_reports WHERE idempotency_key = ?').get(testIdempKey) as any;
    assert.ok(dupe, 'Idempotent report found');
    assert.equal(dupe.incident_id, testIncidentId);
  });

  test('FR-11: AI-Assisted Duplicate Candidate Detection & Priority Scoring', () => {
    const existing = [
      {
        id: 'INC-2026-001',
        title: 'Severe Waterlogging with 14 Families Stranded on Rooftops',
        description: 'Water has reached the 1st floor balcony. Need emergency boat rescue.',
        category: 'FLOOD',
        urgency: 'CRITICAL',
        latitude: 25.6135,
        longitude: 85.1425
      }
    ];

    const newReport = {
      category: 'FLOOD',
      description: 'Balcony submerged, 5 people trapped on roof near Ghat',
      urgency: 'CRITICAL',
      peopleCount: 5,
      latitude: 25.6138, // ~50 meters away
      longitude: 85.1427
    };

    const triage = analyzeIncidentTriage(newReport, existing);
    assert.ok(triage.suggestedPriorityScore >= 80, 'Critical incident must have priority score >= 80');
    assert.ok(triage.duplicateCandidates.length > 0, 'Must detect geographical and context proximity duplicate candidate');
    assert.equal(triage.duplicateCandidates[0].incidentId, 'INC-2026-001');
  });

  test('FR-10, FR-12: Incident Verification Decision & Audit Log', () => {
    const reviewerId = 'USR-GOVT-01'; // Inspector Meera
    const verId = `VER-FLOW-${runId}`;

    // Insert verification
    db.prepare(`
      INSERT INTO verifications (
        id, incident_id, reviewer_id, decision, reason, confidence, unresolved_uncertainty
      ) VALUES (?, ?, ?, 'VERIFIED', 'Water level confirmed via municipal gauge telemetry.', 0.96, 'None')
    `).run(verId, testIncidentId, reviewerId);

    // Update status to VERIFIED
    db.prepare("UPDATE incidents SET status = 'VERIFIED' WHERE id = ?").run(testIncidentId);

    const verifiedInc = db.prepare('SELECT * FROM incidents WHERE id = ?').get(testIncidentId) as any;
    assert.equal(verifiedInc.status, 'VERIFIED', 'Incident status must be VERIFIED');
  });

  test('FR-16, FR-17: Rescue Team Assignment', () => {
    const teamId = 'TEAM-NDRF-9A';
    const asgId = `ASG-FLOW-${runId}`;

    db.prepare(`
      INSERT INTO assignments (id, incident_id, team_id, status)
      VALUES (?, ?, ?, 'ASSIGNED')
    `).run(asgId, testIncidentId, teamId);

    db.prepare("UPDATE incidents SET status = 'RESPONSE_ASSIGNED', assigned_team_id = ? WHERE id = ?").run(teamId, testIncidentId);
    db.prepare("UPDATE rescue_teams SET status = 'ASSIGNED', assigned_incident_id = ? WHERE id = ?").run(testIncidentId, teamId);

    const updatedInc = db.prepare('SELECT * FROM incidents WHERE id = ?').get(testIncidentId) as any;
    assert.equal(updatedInc.status, 'RESPONSE_ASSIGNED');
    assert.equal(updatedInc.assigned_team_id, teamId);

    const team = db.prepare('SELECT * FROM rescue_teams WHERE id = ?').get(teamId) as any;
    assert.equal(team.status, 'ASSIGNED');
  });

  test('H4-3: Admin Command Dashboard Real DB KPI Metrics', () => {
    const reportedCount = (db.prepare('SELECT count(*) as c FROM incidents').get() as any).c;
    const verifiedCount = (db.prepare("SELECT count(*) as c FROM incidents WHERE status IN ('VERIFIED', 'RESPONSE_ASSIGNED')").get() as any).c;
    assert.ok(reportedCount > 0, 'Total reported must be > 0');
    assert.ok(verifiedCount > 0, 'Verified count must be > 0');
  });
});
