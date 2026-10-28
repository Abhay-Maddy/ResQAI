import { db } from '../db/database';
import crypto from 'crypto';
import { logAuditEvent } from './auditService';
import { broadcastAlertToCitizens } from './notificationService';

export interface AlertBroadcastInput {
  source: 'IMD' | 'CWC' | 'NDMA_SACHET' | 'STATE_SDMA';
  title: string;
  description: string;
  severity: 'CRITICAL' | 'WARN' | 'INFO';
  affected_region: string;
  valid_until_hours?: number;
}

export interface OfficialAlertRecord {
  id: string;
  source: string;
  title: string;
  description: string;
  severity: string;
  affected_region: string;
  issued_at: string;
  valid_until: string;
  cap_feed_id?: string;
  is_active?: boolean;
}

export class AlertBroadcastService {
  /**
   * FR-49 Authorized Public Alert Broadcasting with Rate-Limiting & Government Non-Impersonation
   */
  static broadcastAlert(
    input: AlertBroadcastInput,
    actorId: string,
    actorRole: string
  ): OfficialAlertRecord {
    // 1. Strict Server-Side Authorization Gate (FR-3, FR-49)
    if (!['ADMIN', 'GOVT_OFFICER'].includes(actorRole)) {
      throw new Error(`Unauthorized: Role '${actorRole}' is not permitted to broadcast official public alerts.`);
    }

    // 2. Rate-Limiting Gate: Max 3 public alerts per region per hour to prevent alert fatigue
    const recentAlerts = db.prepare(`
      SELECT COUNT(*) as count FROM official_alerts
      WHERE affected_region = ?
      AND datetime(issued_at) >= datetime('now', '-1 hour')
    `).get(input.affected_region) as { count: number };

    if (recentAlerts && recentAlerts.count >= 3) {
      throw new Error(
        `Rate limit exceeded: Maximum 3 alerts per hour reached for region '${input.affected_region}'. Please coordinate with District Disaster Management Authority.`
      );
    }

    const alertId = `ALERT-${new Date().getFullYear()}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
    const capFeedId = `urn:oid:2.49.0.0.356.0.${alertId}`;
    const validUntilHours = input.valid_until_hours || (input.severity === 'CRITICAL' ? 6 : 24);

    // Non-impersonation guarantee: strictly cite source agency
    const disclaimer = ` [Relayed by ResQAI under official authorization of ${input.source}. For immediate life emergencies, call 112.]`;
    const finalDescription = input.description.includes('Relayed by ResQAI')
      ? input.description
      : input.description + disclaimer;

    const issuedAt = new Date().toISOString();
    const validUntil = new Date(Date.now() + validUntilHours * 3600 * 1000).toISOString();

    db.prepare(`
      INSERT INTO official_alerts (
        id, source, title, description, severity, affected_region,
        issued_at, valid_until, cap_feed_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      alertId,
      input.source,
      input.title,
      finalDescription,
      input.severity,
      input.affected_region,
      issuedAt,
      validUntil,
      capFeedId
    );

    // Audit log (FR-53)
    logAuditEvent({
      actionType: 'PUBLIC_ALERT_BROADCAST',
      actorId,
      actorRole,
      entityId: alertId,
      details: `Broadcasted ${input.severity} alert for ${input.affected_region} sourced from ${input.source}: "${input.title}"`
    });

    broadcastAlertToCitizens({
      title: '🚨 ' + input.severity + ': ' + input.title,
      body: finalDescription,
      type: 'OFFICIAL_ALERT',
      severity: input.severity,
      data: { alertId, source: input.source, affectedRegion: input.affected_region }
    }).catch(() => { });

    return {
      id: alertId,
      source: input.source,
      title: input.title,
      description: finalDescription,
      severity: input.severity,
      affected_region: input.affected_region,
      issued_at: issuedAt,
      valid_until: validUntil,
      cap_feed_id: capFeedId,
      is_active: true
    };
  }

  /**
   * Get active alerts
   */
  static getActiveAlerts(region?: string): OfficialAlertRecord[] {
    let query = `
      SELECT *, datetime(valid_until) > datetime('now') as is_active
      FROM official_alerts
      WHERE datetime(valid_until) > datetime('now')
    `;
    const params: any[] = [];

    if (region && region !== 'GLOBAL') {
      query += ` AND (affected_region = ? OR affected_region = 'GLOBAL')`;
      params.push(region);
    }

    query += ` ORDER BY issued_at DESC`;

    return db.prepare(query).all(...params) as OfficialAlertRecord[];
  }

  /**
   * Get Alert by ID
   */
  static getAlertById(id: string): OfficialAlertRecord | null {
    return (db.prepare('SELECT * FROM official_alerts WHERE id = ?').get(id) as OfficialAlertRecord) || null;
  }

  /**
   * FR-49 Common Alerting Protocol (CAP v1.2) XML Serializer
   */
  static generateCapXml(alert: OfficialAlertRecord): string {
    const urgency = alert.severity === 'CRITICAL' ? 'Immediate' : alert.severity === 'WARN' ? 'Expected' : 'Future';
    const severity = alert.severity === 'CRITICAL' ? 'Extreme' : alert.severity === 'WARN' ? 'Severe' : 'Moderate';

    return `<?xml version="1.0" encoding="UTF-8"?>
<alert xmlns="urn:oasis:names:tc:emergency:cap:1.2">
  <identifier>${alert.cap_feed_id || alert.id}</identifier>
  <sender>resqai.org@gov.in</sender>
  <sent>${alert.issued_at}</sent>
  <status>Actual</status>
  <msgType>Alert</msgType>
  <scope>Public</scope>
  <info>
    <category>Safety</category>
    <event>${alert.title}</event>
    <urgency>${urgency}</urgency>
    <severity>${severity}</severity>
    <certainty>Observed</certainty>
    <eventCode>
      <valueName>DisasterType</valueName>
      <value>Flood/Weather</value>
    </eventCode>
    <expires>${alert.valid_until}</expires>
    <senderName>${alert.source} via ResQAI Emergency Platform</senderName>
    <headline>${alert.title}</headline>
    <description>${alert.description}</description>
    <area>
      <areaDesc>${alert.affected_region}</areaDesc>
    </area>
  </info>
</alert>`;
  }
}
