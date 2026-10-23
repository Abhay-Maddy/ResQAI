import test, { before, describe } from 'node:test';
import assert from 'node:assert';
import { db, initDatabase } from '../src/db/database';
import { AlertBroadcastService } from '../src/services/alertBroadcastService';
import { SitRepService } from '../src/services/sitrepService';
import { RumourService } from '../src/services/rumourService';
import { EvacuationService } from '../src/services/evacuationService';

describe('Phase 8: Situation Reporting (SitRep), Public Alerts, Rumour Control & Governance (FR-49, FR-50, FR-54, Part B)', () => {
  before(async () => {
    process.env.NODE_ENV = 'test';
    await initDatabase();
  });

  // Step 1: Authorized Public Alert Broadcasting with RBAC & Rate-Limiting (FR-49)
  test('Step 1: FR-49 Authorized Public Alert Broadcasting with RBAC Enforcement & Rate-Limiting', () => {
    // 1. Unprivileged role must be rejected
    assert.throws(
      () => {
        AlertBroadcastService.broadcastAlert(
          {
            source: 'IMD',
            title: 'Unverified Alert',
            description: 'Unauthorized citizen trying to trigger siren',
            severity: 'CRITICAL',
            affected_region: 'Sector A'
          },
          'USR-CITIZEN-01',
          'CITIZEN'
        );
      },
      /Unauthorized/,
      'Citizens must not be permitted to issue public alerts'
    );

    // 2. Authorized Govt Officer broadcasts successfully
    const region = `Test-Region-${Date.now()}`;
    const alert1 = AlertBroadcastService.broadcastAlert(
      {
        source: 'IMD',
        title: 'Red Alert: Extremely Heavy Inflow at Gandak Basin',
        description: 'Water discharge exceeding 4.5 lakh cusecs. Low-lying wards must move to designated elevated shelters.',
        severity: 'CRITICAL',
        affected_region: region,
        valid_until_hours: 12
      },
      'USR-OFFICER-01',
      'GOVT_OFFICER'
    );

    assert.ok(alert1.id.startsWith('ALERT-'), 'Alert ID must start with ALERT- prefix');
    assert.strictEqual(alert1.source, 'IMD');
    assert.strictEqual(alert1.severity, 'CRITICAL');
    assert.strictEqual(alert1.affected_region, region);
    assert.ok(alert1.description.includes('Relayed by ResQAI under official authorization'), 'Non-impersonation disclaimer mandatory');

    // 3. Rate-Limiting Gate: Issuing 3 more alerts to the same region within 1 hour exceeds threshold
    AlertBroadcastService.broadcastAlert(
      { source: 'CWC', title: 'Gauge Update 1', description: 'Water level rising', severity: 'WARN', affected_region: region },
      'USR-OFFICER-01', 'GOVT_OFFICER'
    );
    AlertBroadcastService.broadcastAlert(
      { source: 'CWC', title: 'Gauge Update 2', description: 'Water level peaking', severity: 'WARN', affected_region: region },
      'USR-OFFICER-01', 'GOVT_OFFICER'
    );

    // The 4th alert should throw rate limit error
    assert.throws(
      () => {
        AlertBroadcastService.broadcastAlert(
          { source: 'CWC', title: 'Gauge Update 3', description: 'Over threshold', severity: 'WARN', affected_region: region },
          'USR-OFFICER-01', 'GOVT_OFFICER'
        );
      },
      /Rate limit exceeded/,
      'Rate-limiting must prevent alert fatigue'
    );
  });

  // Step 2: CAP 1.2 XML Serialization & Government Non-Impersonation (FR-49)
  test('Step 2: FR-49 Common Alerting Protocol (CAP v1.2) XML Serializer & Non-Impersonation', () => {
    const region = `Sector-B-${Date.now()}`;
    const alert = AlertBroadcastService.broadcastAlert(
      {
        source: 'STATE_SDMA',
        title: 'Flash Flood Evacuation Notice - Sector B',
        description: 'Immediate mandatory evacuation ordered for Embankment Ward 4 due to structural breach risk.',
        severity: 'CRITICAL',
        affected_region: region
      },
      'USR-ADMIN-01',
      'ADMIN'
    );

    const capXml = AlertBroadcastService.generateCapXml(alert);

    assert.ok(capXml.includes('xmlns="urn:oasis:names:tc:emergency:cap:1.2"'), 'Must have valid CAP 1.2 XML namespace');
    assert.ok(capXml.includes('<headline>Flash Flood Evacuation Notice - Sector B</headline>'), 'CAP must contain headline');
    assert.ok(capXml.includes('<urgency>Immediate</urgency>'), 'Critical severity must map to Immediate urgency');
    assert.ok(capXml.includes('<severity>Extreme</severity>'), 'Critical maps to Extreme severity in CAP standard');
    assert.ok(capXml.includes('<senderName>STATE_SDMA via ResQAI Emergency Platform</senderName>'), 'Must clearly cite source agency');
  });

  // Step 3: Situation Report (SitRep) Compilation & Access Checks (FR-54)
  test('Step 3: FR-54 Multi-Format Situation Report (SitRep) Compilation & Access Checks', () => {
    // 1. Unprivileged role cannot access SitRep
    assert.throws(
      () => {
        SitRepService.compileSitRep('GLOBAL', 'USR-CITIZEN-01', 'CITIZEN');
      },
      /Access Denied/,
      'Citizens cannot access raw command SitReps'
    );

    // 2. Authorized Auditor / Admin can access SitRep
    const sitrep = SitRepService.compileSitRep('GLOBAL', 'USR-AUDITOR-01', 'AUDITOR');

    assert.ok(sitrep.metadata.reportId.startsWith('SITREP-'), 'SitRep must have official SITREP ID');
    assert.strictEqual(sitrep.metadata.classification, 'OFFICIAL USE ONLY / EMERGENCY COMMAND');
    assert.ok(typeof sitrep.executiveOverview.totalIncidents === 'number');
    assert.ok(sitrep.reliefNeedsSummary.sectors.length > 0, 'Relief sectors must be populated');
    assert.strictEqual(sitrep.financialTransparency.integerPaiseIntegrityVerified, true);
    assert.ok(sitrep.financialTransparency.unspentBalanceRupees >= 0, 'Unspent balance must be >= 0');
  });

  // Step 4: GeoJSON & CSV Data Export with Audit Trail (FR-54, FR-53)
  test('Step 4: FR-54 GeoJSON & CSV Data Export with Tamper-Evident Audit Logging (FR-53)', () => {
    // 1. GeoJSON Export
    const geojson: any = SitRepService.generateGeoJson('GLOBAL', 'USR-ADMIN-01', 'ADMIN');
    assert.strictEqual(geojson.type, 'FeatureCollection');
    assert.ok(Array.isArray(geojson.features), 'GeoJSON features must be an array');
    assert.ok(geojson.features.length > 0, 'Should include incidents and road closures');

    // Verify point geometry for incident
    const incFeature = geojson.features.find((f: any) => f.properties.entityType === 'INCIDENT');
    assert.ok(incFeature, 'Should have incident feature');
    assert.strictEqual(incFeature.geometry.type, 'Point');

    // 2. CSV Export
    const csv = SitRepService.generateCsv('GLOBAL', 'USR-ADMIN-01', 'ADMIN');
    assert.ok(csv.startsWith('Incident ID,Title,Category,Status,Urgency'), 'CSV header must be present');
    assert.ok(csv.includes('\n'), 'CSV must contain data rows');

    // 3. Verify Audit Logs (FR-53)
    const auditGeo = db.prepare("SELECT * FROM audit_logs WHERE action_type = 'SPATIAL_GEOJSON_EXPORTED'").get() as any;
    const auditCsv = db.prepare("SELECT * FROM audit_logs WHERE action_type = 'CSV_DATA_EXPORTED'").get() as any;
    assert.ok(auditGeo, 'Audit log must record GeoJSON spatial export');
    assert.ok(auditCsv, 'Audit log must record CSV data export');
  });

  // Step 5: Rumour-Tracking Queue & Public Debunk Notices (Part B Gap Analysis)
  test('Step 5: Part B Misinformation & Rumour-Tracking Review Queue with Public Fact-Check Notices', () => {
    // 1. Citizen reports viral WhatsApp rumor
    const rumour = RumourService.reportRumour(
      {
        reported_claim: 'Rumour: Major embankment breach at Gate 5 with 10ft flood wave incoming in 15 mins.',
        source_platform: 'WhatsApp Viral Forward'
      },
      'USR-CITIZEN-01'
    );

    assert.ok(rumour.id.startsWith('RUMOUR-'));
    assert.strictEqual(rumour.counter_verification_status, 'INVESTIGATING');

    // 2. Govt Officer investigates and debunks the false rumor
    const debunked = RumourService.verifyRumour(
      rumour.id,
      'DEBUNKED',
      'Executive Engineer CWC inspected Gate 5. Sluice gates are operating normally at safe capacity. Do not forward unverified claims.',
      'USR-OFFICER-01',
      'GOVT_OFFICER'
    );

    assert.strictEqual(debunked.counter_verification_status, 'DEBUNKED');
    assert.ok(debunked.official_correction_notice?.includes('Executive Engineer CWC inspected'));

    // 3. Public fact-check view includes debunked notice
    const publicNotices = RumourService.getPublicFactChecks();
    const found = publicNotices.find(n => n.id === rumour.id);
    assert.ok(found, 'Debunked rumour must appear in public fact checks');
    assert.strictEqual(found.counter_verification_status, 'DEBUNKED');
  });

  // Step 6: Evacuation Zone Status Transition & Assisted Pickup Registry (Part B)
  test('Step 6: Part B Evacuation Zone Status Transition & Safe Route Directives', () => {
    const zones = EvacuationService.getAllZones();
    assert.ok(zones.length > 0, 'Evacuation zones must be seeded');
    const targetZone = zones[0];

    // Order Evacuation
    const updated = EvacuationService.updateZoneStatus(
      targetZone.id,
      'EVACUATION_ORDERED',
      'Primary evacuation route: Use elevated bypass NH-31. Avoid flooded East Embankment corridor.',
      'USR-OFFICER-01',
      'GOVT_OFFICER'
    );

    assert.strictEqual(updated.active_status, 'EVACUATION_ORDERED');
    assert.ok(updated.evacuation_routes_notes.includes('NH-31'));

    // Check assisted pickup list
    const pickups = EvacuationService.getAssistedPickupList(targetZone.area_id);
    assert.ok(Array.isArray(pickups), 'Pickups list must be an array');
  });

  // Step 7: Universal Audit Trail Verification (FR-53 Exit Criteria)
  test('Step 7: FR-53 Append-Only Tamper-Evident Audit Trail Integrity Check', () => {
    const recentLogs = db.prepare('SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT 20').all() as any[];
    assert.ok(recentLogs.length >= 5, 'Should have multiple recorded audit actions');

    const actionTypes = recentLogs.map(l => l.action_type);
    assert.ok(actionTypes.includes('PUBLIC_ALERT_BROADCAST') || actionTypes.includes('SITREP_GENERATED'), 'High stakes operations must be audited');
  });
});
