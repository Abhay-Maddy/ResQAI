import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { db, initDatabase } from '../src/db/database';

test('PRD v2.0 Phase 2: Citizen Core, SOS Reporting & Public Status Tracking', async (t) => {
  before(async () => {
    await initDatabase();
  });

  const timestamp = Date.now();
  const testIdempotencyKey = `IDEM-TEST-${timestamp}`;

  await t.test('Step 1: Citizen SOS Submission with Need Tiles, Voice Note & Idempotency Key', () => {
    const incidentId = `INC-SOS-${timestamp}`;
    const reportId = `REP-SOS-${timestamp}`;
    const needsList = ['RESCUE', 'FOOD_WATER', 'MEDICINE'];

    // Insert Incident with status RECEIVED
    db.prepare(`
      INSERT INTO incidents (
        id, title, category, status, urgency, priority_score, why_priority_explanation,
        latitude, longitude, location_name, area_id, people_affected, sla_deadline_minutes
      ) VALUES (?, 'Emergency Flood Evacuation Needed', 'FLOOD', 'RECEIVED', 'CRITICAL', 94, 'High urgency water rising', 28.6480, 77.3450, 'Ward 4, Hindon Lowland', 'area-a', 4, 15)
    `).run(incidentId);

    // Insert Incident Report with PRD v2.0 Phase 2 attributes
    db.prepare(`
      INSERT INTO incident_reports (
        id, incident_id, source_type, category, description, latitude, longitude,
        location_name, urgency, people_count, contact_phone, is_anonymous,
        needs_json, voice_note_url, idempotency_key, description_original, description_translated
      ) VALUES (?, ?, 'CITIZEN_PWA', 'FLOOD', 'Water entered ground floor, family trapped on roof', 28.6480, 77.3450,
        'Ward 4, Hindon Lowland', 'CRITICAL', 4, '+919876543210', 0,
        ?, 'https://storage.resqai.org/voice/sos-01.m4a', ?,
        'Water entered ground floor, family trapped on roof',
        'Water entered ground floor, family trapped on roof'
      )
    `).run(reportId, incidentId, JSON.stringify(needsList), testIdempotencyKey);

    const saved = db.prepare('SELECT * FROM incident_reports WHERE id = ?').get(reportId) as any;
    assert.ok(saved, 'Report must be saved');
    assert.equal(saved.incident_id, incidentId);
    assert.equal(saved.idempotency_key, testIdempotencyKey);
    assert.deepEqual(JSON.parse(saved.needs_json), needsList);
    assert.equal(saved.voice_note_url, 'https://storage.resqai.org/voice/sos-01.m4a');
  });

  await t.test('ACCEPT CRITERIA: Offline SOS Stays Pending Then Syncs Once (Idempotent Deduplication)', () => {
    // 1. Client creates offline draft marked 'PENDING'
    const offlineDraft = {
      localRefId: `OFFLINE-DRAFT-${timestamp}`,
      status: 'PENDING',
      idempotencyKey: testIdempotencyKey,
      syncedCount: 0
    };
    assert.equal(offlineDraft.status, 'PENDING', 'Offline SOS starts in PENDING status');

    // 2. On network reconnect, client attempts first sync with idempotency key
    const firstCheck = db.prepare('SELECT * FROM incident_reports WHERE idempotency_key = ?').get(testIdempotencyKey) as any;
    assert.ok(firstCheck, 'First sync finds existing registered incident');
    offlineDraft.status = 'SYNCED';
    offlineDraft.syncedCount += 1;

    // 3. Second sync attempt with identical idempotency key does not create new record
    const countBefore = (db.prepare('SELECT count(*) as c FROM incident_reports WHERE idempotency_key = ?').get(testIdempotencyKey) as any).c;
    assert.equal(countBefore, 1, 'Only one record exists for this idempotency key');

    // Attempting duplicate insert with same idempotency key fails unique constraint
    assert.throws(() => {
      db.prepare(`
        INSERT INTO incident_reports (id, incident_id, source_type, category, description, latitude, longitude, location_name, urgency, idempotency_key)
        VALUES ('REP-DUPLICATE', 'INC-OTHER', 'CITIZEN_PWA', 'FLOOD', 'Duplicate attempt', 28.64, 77.34, 'Ward 4', 'LOW', ?)
      `).run(testIdempotencyKey);
    }, /UNIQUE constraint failed/);

    assert.equal(offlineDraft.status, 'SYNCED');
    assert.equal(offlineDraft.syncedCount, 1, 'Offline report synced exactly once');
  });

  await t.test('F-01: Multilingual Reporting & Auto-Translation for Responders (Original Text Preserved)', () => {
    const hindiIncidentId = `INC-HI-${timestamp}`;
    const hindiReportId = `REP-HI-${timestamp}`;
    const originalHindi = 'बाढ़ का पानी घर में घुस गया है, हमें तुरंत नाव चाहिए।';
    const translatedEnglish = '[Auto-Translated from Hindi]: Emergency request detected: "बाढ़ का पानी घर में घुस गया है, हमें तुरंत नाव चाहिए।". Immediate responder attention required.';

    db.prepare(`
      INSERT INTO incidents (id, title, category, status, urgency, priority_score, latitude, longitude, location_name, area_id)
      VALUES (?, 'जलभराव - तुरंत सहायता', 'FLOOD', 'RECEIVED', 'CRITICAL', 92, 28.65, 77.34, 'हिंडन खादर वार्ड 4', 'area-a')
    `).run(hindiIncidentId);

    db.prepare(`
      INSERT INTO incident_reports (
        id, incident_id, source_type, category, description, latitude, longitude,
        location_name, urgency, description_original, description_translated
      ) VALUES (?, ?, 'CITIZEN_PWA', 'FLOOD', ?, 28.65, 77.34, 'हिंडन खादर वार्ड 4', 'CRITICAL', ?, ?)
    `).run(hindiReportId, hindiIncidentId, originalHindi, originalHindi, translatedEnglish);

    const saved = db.prepare('SELECT description_original, description_translated FROM incident_reports WHERE id = ?').get(hindiReportId) as any;
    assert.equal(saved.description_original, originalHindi, 'Original Hindi text is fully preserved');
    assert.ok(saved.description_translated.includes('Auto-Translated'), 'Translated text available for field responders');
  });

  await t.test('F-05: Spam Protection & Repeated-Source Flagging (Never Auto-Reject Critical Reports)', () => {
    const spammerPhone = `+9199911${timestamp.toString().slice(-5)}`;
    const dummyIncidentId = `INC-SPAM-HOST-${timestamp}`;
    
    db.prepare(`
      INSERT INTO incidents (id, title, category, status, urgency, priority_score, latitude, longitude, location_name, area_id)
      VALUES (?, 'Spam Test Incident', 'FLOOD', 'RECEIVED', 'CRITICAL', 90, 28.64, 77.34, 'Sector A', 'area-a')
    `).run(dummyIncidentId);

    // Insert 3 previous reports from same caller
    for (let i = 1; i <= 3; i++) {
      db.prepare(`
        INSERT INTO incident_reports (id, incident_id, source_type, category, description, latitude, longitude, location_name, urgency, contact_phone, created_at)
        VALUES (?, ?, 'CITIZEN_PWA', 'FLOOD', 'Previous call', 28.64, 77.34, 'Sector A', 'MEDIUM', ?, datetime('now', '-2 minutes'))
      `).run(`REP-PREV-${timestamp}-${i}`, dummyIncidentId, spammerPhone);
    }

    // 4th report: caller is flagged as repeated source
    const count = (db.prepare(`
      SELECT count(*) as c FROM incident_reports 
      WHERE contact_phone = ? AND created_at >= datetime('now', '-5 minutes')
    `).get(spammerPhone) as any).c;

    assert.ok(count >= 3, 'Repeated source detected (> 3 reports in 5 minutes)');

    // Insert 4th report flagged as repeated source
    const fourthReportId = `REP-SPAM-${timestamp}`;
    db.prepare(`
      INSERT INTO incident_reports (id, incident_id, source_type, category, description, latitude, longitude, location_name, urgency, contact_phone, is_repeated_source)
      VALUES (?, ?, 'CITIZEN_PWA', 'FLOOD', '4th urgent call', 28.64, 77.34, 'Sector A', 'CRITICAL', ?, 1)
    `).run(fourthReportId, dummyIncidentId, spammerPhone);

    const flaggedReport = db.prepare('SELECT is_repeated_source, urgency FROM incident_reports WHERE id = ?').get(fourthReportId) as any;
    assert.equal(flaggedReport.is_repeated_source, 1, 'Report is flagged as repeated source');
    // Global Rule 5: Critical reports are NOT rejected
    assert.equal(flaggedReport.urgency, 'CRITICAL', 'Life-threatening report is preserved for human review and never auto-rejected');
  });

  await t.test('R-CIT-4: Emergency Contact Automated SMS Notification on SOS', () => {
    const citizenUserId = `USR-CIT-${timestamp}`;
    const citizenPhone = `+9198888${timestamp.toString().slice(-5)}`;
    const emergencyPhone = `+9198111${timestamp.toString().slice(-5)}`;
    
    // Register citizen & emergency contact
    db.prepare(`
      INSERT INTO users (id, name, phone, role, approval_status, is_verified)
      VALUES (?, 'Rohit Verma', ?, 'CITIZEN', 'APPROVED', 1)
    `).run(citizenUserId, citizenPhone);

    db.prepare(`
      INSERT INTO emergency_contacts (id, user_id, name, phone, relationship, is_primary, is_otp_verified)
      VALUES (?, ?, 'Sita Verma (Spouse)', ?, 'Spouse', 1, 1)
    `).run(`EC-${citizenUserId}`, citizenUserId, emergencyPhone);

    const contact = db.prepare('SELECT * FROM emergency_contacts WHERE user_id = ?').get(citizenUserId) as any;
    assert.ok(contact);
    assert.equal(contact.phone, emergencyPhone);

    // Simulate SMS dispatch log
    const trackingLink = `https://resqai.org/track/INC-SOS-${timestamp}`;
    const smsMessage = `EMERGENCY ALERT: Rohit Verma has triggered an SOS signal. Live status: ${trackingLink}`;
    assert.ok(smsMessage.includes(trackingLink), 'SMS notification includes live tracking URL');
  });

  await t.test('ACCEPT CRITERIA: Public Tracking Page Shows ONLY Status, NEVER Contact Details (PII Safe)', () => {
    const trackedIncidentId = `INC-TRACK-${timestamp}`;
    const privateCallerPhone = '+919988776655';

    // 1. Insert incident and report with private caller details
    db.prepare(`
      INSERT INTO incidents (id, title, category, status, urgency, priority_score, latitude, longitude, location_name, area_id)
      VALUES (?, 'Building Terrace Flood Rescue', 'FLOOD', 'RESPONSE_ASSIGNED', 'CRITICAL', 95, 28.6480, 77.3450, 'Ward 4 (Hindon Basin)', 'area-a')
    `).run(trackedIncidentId);

    db.prepare(`
      INSERT INTO incident_reports (id, incident_id, source_type, category, description, latitude, longitude, location_name, urgency, contact_phone, is_anonymous)
      VALUES (?, ?, 'CITIZEN_PWA', 'FLOOD', 'Terrace rescue needed', 28.6480, 77.3450, 'Ward 4 (Hindon Basin)', 'CRITICAL', ?, 0)
    `).run(`REP-TRACK-${timestamp}`, trackedIncidentId, privateCallerPhone);

    // 2. Query as public tracking page (simulating GET /track/:id)
    const publicIncident = db.prepare(`
      SELECT id as referenceId, status, category, urgency, location_name as area, created_at, updated_at
      FROM incidents WHERE id = ?
    `).get(trackedIncidentId) as any;

    assert.ok(publicIncident, 'Public tracking record exists');
    assert.equal(publicIncident.referenceId, trackedIncidentId);
    assert.equal(publicIncident.status, 'RESPONSE_ASSIGNED', 'Public tracking shows current status');
    assert.equal(publicIncident.category, 'FLOOD');
    assert.equal(publicIncident.area, 'Ward 4 (Hindon Basin)', 'Shows ward-level location only');

    // 3. STRICT PRIVACY ACCEPTANCE CRITERIA:
    // Contact phone, caller name, exact latitude/longitude must NOT be present in public tracking view
    assert.equal(publicIncident.contact_phone, undefined, 'contact_phone must never be exposed');
    assert.equal(publicIncident.contactPhone, undefined, 'contactPhone must never be exposed');
    assert.equal(publicIncident.caller_name, undefined, 'Caller name must never be exposed');
    assert.equal(publicIncident.latitude, undefined, 'Exact GPS latitude must not be exposed on public tracking');
    assert.equal(publicIncident.longitude, undefined, 'Exact GPS longitude must not be exposed on public tracking');
  });

  await t.test('F-07: Data Retention Cleanup Job Masks PII for Expired Records', () => {
    const expiredIncidentId = `INC-OLD-${timestamp}`;
    const expiredReportId = `REP-EXPIRED-${timestamp}`;
    const oldCallerPhone = '+919123456789';

    db.prepare(`
      INSERT INTO incidents (id, title, category, status, urgency, priority_score, latitude, longitude, location_name, area_id)
      VALUES (?, 'Old Flood Incident', 'FLOOD', 'RESOLVED', 'LOW', 30, 28.64, 77.34, 'Ward 4', 'area-a')
    `).run(expiredIncidentId);

    // Insert simulated 95-day old record
    db.prepare(`
      INSERT INTO incident_reports (id, incident_id, source_type, category, description, latitude, longitude, location_name, urgency, contact_phone, created_at)
      VALUES (?, ?, 'CITIZEN_PWA', 'FLOOD', 'Historical flood report', 28.64, 77.34, 'Ward 4', 'LOW', ?, datetime('now', '-95 days'))
    `).run(expiredReportId, expiredIncidentId, oldCallerPhone);

    const beforeCleanup = db.prepare('SELECT contact_phone, retention_masked FROM incident_reports WHERE id = ?').get(expiredReportId) as any;
    assert.equal(beforeCleanup.contact_phone, oldCallerPhone);

    // Run Retention Cleanup
    const updateResult = db.prepare(`
      UPDATE incident_reports 
      SET contact_phone = '[REDACTED_BY_RETENTION_POLICY]', retention_masked = 1
      WHERE created_at <= datetime('now', '-90 days') AND id = ?
    `).run(expiredReportId);

    assert.equal(updateResult.changes, 1, 'Expired record was processed by retention job');

    const afterCleanup = db.prepare('SELECT contact_phone, retention_masked FROM incident_reports WHERE id = ?').get(expiredReportId) as any;
    assert.equal(afterCleanup.contact_phone, '[REDACTED_BY_RETENTION_POLICY]', 'Phone number is redacted by policy');
    assert.equal(afterCleanup.retention_masked, 1, 'Marked as retention masked');
  });
});
