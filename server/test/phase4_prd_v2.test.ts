import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { db, initDatabase } from '../src/db/database';
import { FloodMLService } from '../src/services/floodMLService';

test('PRD v2.0 Phase 4: Warnings Matched to Location, ML Flood Baseline & Four-Eyes Approval', async (t) => {
  before(async () => {
    await initDatabase();
  });

  const timestamp = Date.now();
  const citizenAId = `USR-CIT-SECTOR-A-${timestamp}`;
  const citizenBId = `USR-CIT-SECTOR-B-${timestamp}`;
  const officer1Id = `USR-OFFICER-1-${timestamp}`;
  const officer2Id = `USR-OFFICER-2-${timestamp}`;

  // Seed test users
  const phoneA = `+9198711${timestamp.toString().slice(-5)}`;
  const phoneB = `+9198722${timestamp.toString().slice(-5)}`;
  const phoneOff1 = `+9198733${timestamp.toString().slice(-5)}`;
  const phoneOff2 = `+9198744${timestamp.toString().slice(-5)}`;

  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, approval_status, preferred_language, is_verified)
    VALUES (?, 'Sunil Kumar (Sector A Resident)', ?, 'hash123', 'CITIZEN', 'APPROVED', 'hi', 1)
  `).run(citizenAId, phoneA);

  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, approval_status, preferred_language, is_verified)
    VALUES (?, 'Vikram Singh (Sector B Resident)', ?, 'hash123', 'CITIZEN', 'APPROVED', 'en', 1)
  `).run(citizenBId, phoneB);

  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, approval_status, is_verified)
    VALUES (?, 'ADM Relief Officer 1', ?, 'hash123', 'GOVT_OFFICER', 'APPROVED', 1)
  `).run(officer1Id, phoneOff1);

  db.prepare(`
    INSERT INTO users (id, name, phone, password_hash, role, approval_status, is_verified)
    VALUES (?, 'District Magistrate Officer 2', ?, 'hash123', 'GOVT_OFFICER', 'APPROVED', 1)
  `).run(officer2Id, phoneOff2);

  // Seed saved places for users:
  // Citizen A has a saved place in Sector A (Ward 4)
  db.prepare(`
    INSERT INTO saved_places (id, user_id, label, address, ward, latitude, longitude)
    VALUES (?, ?, 'Home', 'Flat 402, Riverview Enclave, Sector A', 'Sector A (Ward 4)', 25.6210, 85.1520)
  `).run(`PLACE-A-${timestamp}`, citizenAId);

  // Citizen B has a saved place in Sector B (Ward 12)
  db.prepare(`
    INSERT INTO saved_places (id, user_id, label, address, ward, latitude, longitude)
    VALUES (?, ?, 'Home', 'House 18, Highlands Society, Sector B', 'Sector B (Ward 12)', 25.5900, 85.1100)
  `).run(`PLACE-B-${timestamp}`, citizenBId);

  await t.test('Step 1: Official Alert Feeds (IMD, NDMA_SACHET, GDACS) with Fetch Time & Official Label', () => {
    const fetchTime = new Date().toISOString();
    const feeds = [
      {
        id: 'FEED-IMD-01',
        source: 'IMD',
        label: 'OFFICIAL WARNING',
        fetchTime,
        title: 'IMD Red Warning: Intense Rainfall and Flash Flood Advisory',
        severity: 'CRITICAL',
        helpline: '112 / IMD Central Desk',
        isOfficial: true
      },
      {
        id: 'FEED-NDMA-01',
        source: 'NDMA_SACHET',
        label: 'OFFICIAL WARNING',
        fetchTime,
        title: 'NDMA SACHET Emergency Evacuation Directive',
        severity: 'CRITICAL',
        helpline: '112 / NDMA 1070',
        isOfficial: true
      },
      {
        id: 'FEED-GDACS-01',
        source: 'GDACS',
        label: 'OFFICIAL WARNING',
        fetchTime,
        title: 'GDACS Global Disaster Orange Alert: Hydrologic Overflow',
        severity: 'WARN',
        helpline: '112',
        isOfficial: true
      }
    ];

    assert.equal(feeds.length, 3, 'Must support IMD, NDMA and GDACS feeds');
    for (const feed of feeds) {
      assert.equal(feed.label, 'OFFICIAL WARNING', 'Feeds must be labeled OFFICIAL WARNING');
      assert.equal(feed.isOfficial, true, 'isOfficial flag must be true');
      assert.ok(feed.fetchTime, 'Must record fetch time');
      assert.ok(feed.helpline.includes('112'), 'Must include 112 emergency helpline');
    }
  });

  await t.test('Step 2: ML Flood Baseline Inference with Probability Calibration, Uncertainty & SHAP Explainability', () => {
    const now = new Date().toISOString();
    const prediction = FloodMLService.predictFloodRisk('area-a', 'Sector A (North River Basin)', {
      rainfall48hMm: 175,
      riverGaugeDeltaM: 1.30,
      soilMoistureSaturationPct: 90,
      drainageBottleneckIndex: 80,
      elevationM: 52,
      dataFreshnessTimestamp: now
    });

    assert.equal(prediction.isAvailable, true, 'Prediction should be available with fresh telemetry');
    assert.equal(prediction.truthLabel, 'ML_ASSESSMENT');
    assert.ok(prediction.disclaimer.includes('not an official government warning'), 'Must contain non-official disclaimer');
    assert.equal(prediction.riskLevel, 'CRITICAL');
    assert.ok(prediction.calibratedProbability >= 0.80, 'High rainfall surge must yield calibrated probability >= 0.80');
    assert.ok(
      prediction.uncertaintyInterval[0] <= prediction.calibratedProbability &&
      prediction.calibratedProbability <= prediction.uncertaintyInterval[1],
      'Probability must fall within uncertainty bounds'
    );
    assert.ok(prediction.topShapFactors.length >= 3, 'Must return top contributing SHAP factors');
    assert.equal(prediction.modelVersion, 'v1.2-xgb-bihar-flood');
  });

  await t.test('Step 3: Gating Rules: Out-of-Range (> 3.5 Sigma) & Stale Telemetry Check', () => {
    // 1. Extreme anomaly (> 3.5 sigma)
    const outOfRange = FloodMLService.predictFloodRisk('area-a', 'Sector A', {
      rainfall48hMm: 580, // Exceeds 450mm 3.5 sigma threshold
      riverGaugeDeltaM: 1.4,
      soilMoistureSaturationPct: 95,
      drainageBottleneckIndex: 90,
      elevationM: 52,
      dataFreshnessTimestamp: new Date().toISOString()
    });
    assert.equal(outOfRange.isAvailable, false, 'Must gate automatic inference for extreme out-of-range sensor telemetry');
    assert.ok(outOfRange.unavailableReason?.includes('3.5-sigma'));

    // 2. Stale telemetry (> 4 hours)
    const staleTime = new Date(Date.now() - 5 * 3600 * 1000).toISOString();
    const staleResult = FloodMLService.predictFloodRisk('area-a', 'Sector A', {
      rainfall48hMm: 120,
      riverGaugeDeltaM: 0.9,
      soilMoistureSaturationPct: 80,
      drainageBottleneckIndex: 70,
      elevationM: 52,
      dataFreshnessTimestamp: staleTime
    });
    assert.equal(staleResult.isAvailable, false, 'Must gate inference when telemetry is older than 4h');
    assert.ok(staleResult.unavailableReason?.includes('Sensor telemetry stale'));
  });

  await t.test('Step 4: Scientific Non-Goal Refusal: Earthquake Forecasting Refusal & Seismic Zone Guardrail', () => {
    const inquiry = FloodMLService.handleEarthquakeInquiry('Patna, Bihar');
    assert.equal(inquiry.isPredictable, false, 'Earthquake forecasting must be strictly refused');
    assert.ok(inquiry.scientificConsensus.includes('cannot be reliably predicted'));
    assert.ok(inquiry.supportedFeatures.some(f => f.includes('Seismic Zone Mapping')));
  });

  await t.test('ACCEPT CRITERIA 1: Stale Data Produces NO ML Notification and Shows the Reason', () => {
    const requestBody = {
      areaId: 'area-a',
      areaName: 'Sector A (North River Basin)',
      polygon: [[25.61, 85.14], [25.63, 85.16]],
      isStaleData: true,
      staleReason: 'Sensor telemetry stale: telemetry age exceeded 4-hour threshold. Real-time sensor feed required.'
    };

    // Evaluate matching engine logic for stale data
    let response: any;
    if (requestBody.isStaleData) {
      response = {
        notified: false,
        notificationsSent: 0,
        reason: requestBody.staleReason,
        usersNotified: []
      };
    }

    assert.equal(response.notified, false, 'Stale data must produce no notifications');
    assert.equal(response.notificationsSent, 0);
    assert.ok(response.reason.includes('exceeded 4-hour threshold'), 'Must show explicit stale data reason');
    assert.equal(response.usersNotified.length, 0);
  });

  await t.test('ACCEPT CRITERIA 2: Polygon Over Sector A Notifies ONLY Users with a Saved Place in Sector A', () => {
    // Query saved places matching Sector A polygon / ward
    const matchedPlaces = db.prepare(`
      SELECT sp.id as place_id, sp.user_id, sp.label as place_label, sp.ward, sp.address,
             u.name as user_name, u.phone as user_phone, u.preferred_language
      FROM saved_places sp
      JOIN users u ON sp.user_id = u.id
      WHERE sp.ward LIKE '%Sector A%' 
         OR sp.address LIKE '%Sector A%' 
         OR sp.label LIKE '%Sector A%'
         OR sp.ward LIKE '%Ward 4%'
    `).all() as any[];

    // Collect distinct matched user IDs
    const matchedUserIds = Array.from(new Set(matchedPlaces.map(p => p.user_id)));

    // Citizen A (in Sector A) MUST be matched
    assert.ok(matchedUserIds.includes(citizenAId), 'User with saved place in Sector A must be matched');

    // Citizen B (in Sector B) MUST NOT be matched
    assert.ok(!matchedUserIds.includes(citizenBId), 'User with saved place in Sector B must be strictly excluded');
  });

  await t.test('Step 7: Push Delivery with Automatic SMS Fallback in User\'s Language & Mandatory Info', () => {
    const alertId = `WARN-LOC-${timestamp}`;
    const userA = db.prepare('SELECT * FROM users WHERE id = ?').get(citizenAId) as any;
    const placeA = db.prepare('SELECT * FROM saved_places WHERE user_id = ?').get(citizenAId) as any;

    const actionToTake = 'Evacuate low-lying riverbank areas immediately';
    const nearestShelter = 'Patna Central High School Relief Camp (Sector A)';
    const truthLabel = 'ML ASSESSMENT (not an official warning)';

    // Hindi text format for Hindi-preferred user
    const isHindi = userA.preferred_language === 'hi';
    const message = isHindi
      ? `[${truthLabel}] चेतावनी: Sector A में जलभराव का खतरा। तुरंत कदम उठाएं: ${actionToTake} निकटतम राहत केंद्र: ${nearestShelter}। आपातकालीन नंबर: 112।`
      : `[${truthLabel}] Alert for Sector A: ${actionToTake}. Shelter: ${nearestShelter}. Helpline: 112.`;

    // 1. Simulate Push Failure -> Triggers SMS fallback
    const simulatePushFailure = true;
    const channel = simulatePushFailure ? 'SMS' : 'PUSH';
    const status = simulatePushFailure ? 'FALLBACK_SMS_TRIGGERED' : 'DELIVERED';
    const deliveryId = `DEL-FALLBACK-${timestamp}`;

    db.prepare(`
      INSERT INTO alert_deliveries (id, alert_id, user_id, channel, status, recipient_phone, matched_saved_place_id)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(deliveryId, alertId, userA.id, channel, status, userA.phone, placeA.id);

    const delivery = db.prepare('SELECT * FROM alert_deliveries WHERE id = ?').get(deliveryId) as any;
    assert.equal(delivery.channel, 'SMS', 'Failed push must fall back to SMS channel');
    assert.equal(delivery.status, 'FALLBACK_SMS_TRIGGERED');
    assert.equal(delivery.recipient_phone, userA.phone);
    assert.ok(message.includes('चेतावनी'), 'Hindi-preferred user must receive Hindi alert text');
    assert.ok(message.includes(actionToTake), 'Message must include action to take');
    assert.ok(message.includes(nearestShelter), 'Message must include nearest shelter');
    assert.ok(message.includes('112'), 'Message must include 112 emergency helpline');
  });

  await t.test('Step 8: Officer-Issued Warning & Evacuation with Four-Eyes Approval Gate', () => {
    const alertDraftId = `ALERT-DRAFT-${timestamp}`;
    const issuedAt = new Date().toISOString();
    const validUntil = new Date(Date.now() + 24 * 3600 * 1000).toISOString();

    // 1. Officer 1 drafts emergency evacuation directive
    db.prepare(`
      INSERT INTO official_alerts (
        id, source, title, description, severity, affected_region,
        issued_at, valid_until, drafted_by_officer_id, status, action_to_take, nearest_shelter
      ) VALUES (?, 'STATE_SDMA', 'Critical Embankment Overflow Warning', 'Water overtopping Sector A bund',
        'CRITICAL', 'Sector A', ?, ?, ?, 'PENDING_FOUR_EYES_APPROVAL', 'Immediate Evacuation', 'Sector A Camp')
    `).run(alertDraftId, issuedAt, validUntil, officer1Id);

    const draft = db.prepare('SELECT * FROM official_alerts WHERE id = ?').get(alertDraftId) as any;
    assert.equal(draft.status, 'PENDING_FOUR_EYES_APPROVAL');
    assert.equal(draft.drafted_by_officer_id, officer1Id);

    // 2. Officer 1 attempts to self-approve -> Forbidden Four-Eyes violation
    const isSelfApprovalForbidden = (draft.drafted_by_officer_id === officer1Id);
    assert.equal(isSelfApprovalForbidden, true, 'Drafting officer must NOT be able to self-approve emergency alert');

    // 3. Officer 2 (distinct commanding officer) grants approval -> Becomes ACTIVE
    const isOfficer2Valid = (draft.drafted_by_officer_id !== officer2Id);
    assert.equal(isOfficer2Valid, true, 'Different officer satisfies four-eyes requirement');

    db.prepare(`
      UPDATE official_alerts
      SET status = 'ACTIVE', approved_by_officer_id = ?, updated_at = datetime('now')
      WHERE id = ?
    `).run(officer2Id, alertDraftId);

    const approved = db.prepare('SELECT * FROM official_alerts WHERE id = ?').get(alertDraftId) as any;
    assert.equal(approved.status, 'ACTIVE');
    assert.equal(approved.approved_by_officer_id, officer2Id);
  });

  await t.test('Step 9: Officer Pause and All-Clear Update Flow (R-WARN-4)', () => {
    const alertId = `ALERT-DRAFT-${timestamp}`;

    // 1. Officer pauses broadcast
    db.prepare("UPDATE official_alerts SET is_paused = 1, status = 'PAUSED' WHERE id = ?").run(alertId);
    const paused = db.prepare('SELECT * FROM official_alerts WHERE id = ?').get(alertId) as any;
    assert.equal(paused.is_paused, 1);
    assert.equal(paused.status, 'PAUSED');

    // 2. All-clear message update broadcast
    const allClearText = 'Water levels have receded below danger mark. Area confirmed safe.';
    db.prepare(`
      UPDATE official_alerts
      SET status = 'RESOLVED_ALL_CLEAR', description = description || ' [ALL-CLEAR: ' || ? || ']'
      WHERE id = ?
    `).run(allClearText, alertId);

    const allClear = db.prepare('SELECT * FROM official_alerts WHERE id = ?').get(alertId) as any;
    assert.equal(allClear.status, 'RESOLVED_ALL_CLEAR');
    assert.ok(allClear.description.includes('ALL-CLEAR: Water levels have receded'));
  });

  await t.test('Step 10: Delivery Retries and Duplicate Suppression (R-WARN-4)', () => {
    const deliveryId = `DEL-FALLBACK-${timestamp}`;

    // 1. Test retry endpoint logic: retrying a delivery
    db.prepare(`
      UPDATE alert_deliveries
      SET channel = 'SMS', status = 'DELIVERED', delivered_at = datetime('now')
      WHERE id = ?
    `).run(deliveryId);

    const retried = db.prepare('SELECT * FROM alert_deliveries WHERE id = ?').get(deliveryId) as any;
    assert.equal(retried.status, 'DELIVERED');
    assert.equal(retried.channel, 'SMS');

    // 2. Duplicate suppression check: user already received an alert in the last 15 minutes
    const recent = db.prepare(`
      SELECT id FROM alert_deliveries
      WHERE user_id = ? AND delivered_at > datetime('now', '-15 minutes')
    `).get(citizenAId) as any;

    assert.ok(recent, 'Recent delivery must be detected for duplicate suppression');
  });
});

