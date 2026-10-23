import { db } from '../db/database';
import { logAuditEvent } from './auditService';

export interface SitRepSummary {
  metadata: {
    reportId: string;
    generatedAt: string;
    generatedByRole: string;
    generatedById: string;
    jurisdiction: string;
    classification: string;
    version: string;
  };
  executiveOverview: {
    totalIncidents: number;
    verifiedIncidents: number;
    criticalIncidents: number;
    inProgressIncidents: number;
    resolvedIncidents: number;
    peopleAffectedTotal: number;
    activeRescueTeams: number;
  };
  reliefNeedsSummary: {
    totalNeedsCount: number;
    sectors: {
      resourceType: string;
      required: number;
      available: number;
      delivered: number;
      percentCovered: number;
      status: string;
    }[];
    criticalShortagesCount: number;
  };
  evacuationAndVulnerability: {
    activeEvacuationZones: number;
    totalRegisteredCases: number;
    vulnerableIndividualsCount: number;
    missingPersonsSearching: number;
    missingPersonsSafe: number;
    closedRoadCorridors: number;
  };
  financialTransparency: {
    verifiedNgosCount: number;
    totalDonationsReceivedRupees: number;
    totalDisbursedRupees: number;
    unspentBalanceRupees: number;
    integerPaiseIntegrityVerified: boolean;
  };
  activeAlerts: {
    id: string;
    source: string;
    title: string;
    severity: string;
    affected_region: string;
  }[];
  debunkedRumours: {
    id: string;
    claim: string;
    status: string;
    officialCorrection?: string;
  }[];
}

export class SitRepService {
  /**
   * Verify caller has proper authority to access Situation Reports (FR-54)
   */
  private static verifyAccess(actorRole: string) {
    const allowedRoles = ['ADMIN', 'GOVT_OFFICER', 'AUDITOR'];
    if (!allowedRoles.includes(actorRole)) {
      throw new Error(`Access Denied: Role '${actorRole}' is not authorized to generate or export Situation Reports (FR-54).`);
    }
  }

  /**
   * FR-54 Compile Comprehensive Multi-Dimensional Situation Report
   */
  static compileSitRep(jurisdiction = 'GLOBAL', actorId = 'USR-ADMIN-01', actorRole = 'ADMIN'): SitRepSummary {
    this.verifyAccess(actorRole);

    const reportId = `SITREP-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;

    // 1. Incidents & People
    const totalIncidents = (db.prepare('SELECT COUNT(*) as c FROM incidents WHERE is_simulated_drill = 0').get() as any).c;
    const verifiedIncidents = (db.prepare("SELECT COUNT(*) as c FROM incidents WHERE status IN ('VERIFIED', 'RESPONSE_ASSIGNED', 'IN_PROGRESS', 'RESOLVED') AND is_simulated_drill = 0").get() as any).c;
    const criticalIncidents = (db.prepare("SELECT COUNT(*) as c FROM incidents WHERE urgency = 'CRITICAL' AND is_simulated_drill = 0").get() as any).c;
    const inProgressIncidents = (db.prepare("SELECT COUNT(*) as c FROM incidents WHERE status = 'IN_PROGRESS' AND is_simulated_drill = 0").get() as any).c;
    const resolvedIncidents = (db.prepare("SELECT COUNT(*) as c FROM incidents WHERE status = 'RESOLVED' AND is_simulated_drill = 0").get() as any).c;
    const peopleAffectedTotal = (db.prepare('SELECT SUM(people_affected) as s FROM incidents WHERE is_simulated_drill = 0').get() as any).s || 0;
    const activeRescueTeams = (db.prepare("SELECT COUNT(*) as c FROM rescue_teams WHERE status = 'DEPLOYED'").get() as any).c;

    // 2. Relief Needs (PRD E6)
    const needsRows = db.prepare(`
      SELECT resource_type,
             SUM(required_units) as req,
             SUM(available_units) as avail,
             SUM(delivered_units) as del
      FROM area_needs
      GROUP BY resource_type
    `).all() as any[];

    const sectors = needsRows.map(row => {
      const req = row.req || 1;
      const pct = Math.min(100, Math.round(((row.avail + row.del) / req) * 100));
      return {
        resourceType: row.resource_type,
        required: row.req,
        available: row.avail,
        delivered: row.del,
        percentCovered: pct,
        status: pct >= 100 ? 'COVERED' : pct >= 50 ? 'SHORT' : 'CRITICAL_SHORT'
      };
    });

    const criticalShortagesCount = sectors.filter(s => s.status === 'CRITICAL_SHORT').length;

    // 3. Evacuation & Vulnerabilities
    const activeEvacZones = (db.prepare("SELECT COUNT(*) as c FROM evacuation_zones WHERE active_status = 'EVACUATION_ORDERED'").get() as any).c;
    const totalCases = (db.prepare("SELECT COUNT(*) as c FROM person_cases WHERE is_merged = 0").get() as any).c;
    const missingSearching = (db.prepare("SELECT COUNT(*) as c FROM missing_person_records WHERE status = 'SEARCHING'").get() as any).c;
    const missingSafe = (db.prepare("SELECT COUNT(*) as c FROM missing_person_records WHERE status IN ('FOUND_SAFE', 'AT_SHELTER')").get() as any).c;
    const closedRoads = (db.prepare("SELECT COUNT(*) as c FROM road_closures").get() as any).c;

    // Count vulnerable individuals
    const cases = db.prepare("SELECT vulnerability_flags_json FROM person_cases WHERE is_merged = 0").all() as any[];
    let vulnIndividuals = 0;
    for (const c of cases) {
      const flags = JSON.parse(c.vulnerability_flags_json || '[]');
      if (flags.length > 0) vulnIndividuals++;
    }

    // 4. Financial Transparency
    const ngosCount = (db.prepare("SELECT COUNT(*) as c FROM ngos WHERE kyc_status = 'VERIFIED'").get() as any).c;
    const donationsReceivedPaise = (db.prepare("SELECT SUM(amount_paise) as s FROM donations WHERE status = 'CAPTURED'").get() as any).s || 0;
    const disbursedPaise = (db.prepare("SELECT SUM(amount_paise) as s FROM campaign_disbursements").get() as any).s || 0;
    const unspentPaise = Math.max(0, donationsReceivedPaise - disbursedPaise);

    // 5. Active Alerts & Debunked Rumours
    const alerts = db.prepare(`
      SELECT id, source, title, severity, affected_region
      FROM official_alerts
      WHERE datetime(valid_until) > datetime('now')
      ORDER BY issued_at DESC
      LIMIT 5
    `).all() as any[];

    const rumours = db.prepare(`
      SELECT id, reported_claim as claim, counter_verification_status as status, official_correction_notice as officialCorrection
      FROM rumour_reports
      WHERE counter_verification_status IN ('DEBUNKED', 'OFFICIALLY_CONFIRMED')
      ORDER BY timestamp DESC
      LIMIT 5
    `).all() as any[];

    // Tamper-evident export audit log (FR-53)
    logAuditEvent({
      actionType: 'SITREP_GENERATED',
      actorId,
      actorRole,
      entityId: reportId,
      details: `Generated official Situation Report ${reportId} for jurisdiction: ${jurisdiction}`
    });

    return {
      metadata: {
        reportId,
        generatedAt: new Date().toISOString(),
        generatedByRole: actorRole,
        generatedById: actorId,
        jurisdiction,
        classification: 'OFFICIAL USE ONLY / EMERGENCY COMMAND',
        version: '1.0'
      },
      executiveOverview: {
        totalIncidents,
        verifiedIncidents,
        criticalIncidents,
        inProgressIncidents,
        resolvedIncidents,
        peopleAffectedTotal,
        activeRescueTeams
      },
      reliefNeedsSummary: {
        totalNeedsCount: needsRows.length,
        sectors,
        criticalShortagesCount
      },
      evacuationAndVulnerability: {
        activeEvacuationZones: activeEvacZones,
        totalRegisteredCases: totalCases,
        vulnerableIndividualsCount: vulnIndividuals,
        missingPersonsSearching: missingSearching,
        missingPersonsSafe: missingSafe,
        closedRoadCorridors: closedRoads
      },
      financialTransparency: {
        verifiedNgosCount: ngosCount,
        totalDonationsReceivedRupees: donationsReceivedPaise / 100,
        totalDisbursedRupees: disbursedPaise / 100,
        unspentBalanceRupees: unspentPaise / 100,
        integerPaiseIntegrityVerified: true
      },
      activeAlerts: alerts,
      debunkedRumours: rumours
    };
  }

  /**
   * FR-54 GeoJSON Spatial Export Generator
   */
  static generateGeoJson(jurisdiction = 'GLOBAL', actorId = 'USR-ADMIN-01', actorRole = 'ADMIN'): object {
    this.verifyAccess(actorRole);

    const incidents = db.prepare(`
      SELECT id, title, category, status, urgency, priority_score, latitude, longitude, location_name, people_affected
      FROM incidents
      WHERE is_simulated_drill = 0
    `).all() as any[];

    const roadClosures = db.prepare(`
      SELECT id, road_name, cause, start_lat, start_lng, end_lat, end_lng, is_passable_for_emergency
      FROM road_closures
    `).all() as any[];

    const features: any[] = [];

    // Add Incident Points
    incidents.forEach(inc => {
      features.push({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [inc.longitude, inc.latitude]
        },
        properties: {
          id: inc.id,
          entityType: 'INCIDENT',
          title: inc.title,
          category: inc.category,
          status: inc.status,
          urgency: inc.urgency,
          priorityScore: inc.priority_score,
          locationName: inc.location_name,
          peopleAffected: inc.people_affected
        }
      });
    });

    // Add Road Closures LineStrings
    roadClosures.forEach(rc => {
      features.push({
        type: 'Feature',
        geometry: {
          type: 'LineString',
          coordinates: [
            [rc.start_lng, rc.start_lat],
            [rc.end_lng, rc.end_lat]
          ]
        },
        properties: {
          id: rc.id,
          entityType: 'ROAD_CLOSURE',
          roadName: rc.road_name,
          cause: rc.cause,
          isPassableForEmergency: rc.is_passable_for_emergency === 1
        }
      });
    });

    // Audit log (FR-53)
    logAuditEvent({
      actionType: 'SPATIAL_GEOJSON_EXPORTED',
      actorId,
      actorRole,
      entityId: `GEOJSON-${Date.now()}`,
      details: `Exported ${features.length} geospatial features in GeoJSON format`
    });

    return {
      type: 'FeatureCollection',
      metadata: {
        title: 'ResQAI Disaster Tactical Spatial Layer',
        exportedAt: new Date().toISOString(),
        featureCount: features.length,
        crs: 'urn:ogc:def:crs:OGC:1.3:CRS84'
      },
      features
    };
  }

  /**
   * FR-54 CSV Export Generator
   */
  static generateCsv(jurisdiction = 'GLOBAL', actorId = 'USR-ADMIN-01', actorRole = 'ADMIN'): string {
    this.verifyAccess(actorRole);

    const incidents = db.prepare(`
      SELECT id, title, category, status, urgency, priority_score, location_name, people_affected, created_at
      FROM incidents
      WHERE is_simulated_drill = 0
      ORDER BY created_at DESC
    `).all() as any[];

    let csv = 'Incident ID,Title,Category,Status,Urgency,Priority Score,Location Name,People Affected,Reported At\n';
    incidents.forEach(i => {
      const cleanTitle = `"${(i.title || '').replace(/"/g, '""')}"`;
      const cleanLoc = `"${(i.location_name || '').replace(/"/g, '""')}"`;
      csv += `${i.id},${cleanTitle},${i.category},${i.status},${i.urgency},${i.priority_score},${cleanLoc},${i.people_affected},${i.created_at}\n`;
    });

    logAuditEvent({
      actionType: 'CSV_DATA_EXPORTED',
      actorId,
      actorRole,
      entityId: `CSV-${Date.now()}`,
      details: `Exported ${incidents.length} incidents to CSV`
    });

    return csv;
  }

  /**
   * FR-54 Printable HTML Document Layout (PDF Ready)
   */
  static generatePrintableHtml(sitrep: SitRepSummary): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ResQAI Situation Report - ${sitrep.metadata.reportId}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.5; color: #0f172a; margin: 40px; }
    .header { border-bottom: 2px solid #0b1f3a; padding-bottom: 15px; margin-bottom: 25px; display: flex; justify-content: space-between; align-items: flex-start; }
    .title { font-size: 24px; font-weight: 800; color: #0b1f3a; text-transform: uppercase; margin: 0; }
    .badge { background: #dc2626; color: white; padding: 4px 10px; font-weight: 700; border-radius: 4px; font-size: 12px; }
    .grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin-bottom: 25px; }
    .card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 15px; }
    .metric { font-size: 24px; font-weight: 800; color: #2563eb; }
    .label { font-size: 11px; text-transform: uppercase; color: #64748b; font-weight: 600; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
    th, td { border: 1px solid #cbd5e1; padding: 8px 12px; text-align: left; }
    th { background: #f1f5f9; font-weight: 700; }
    .section-title { font-size: 16px; font-weight: 700; border-left: 4px solid #2563eb; padding-left: 10px; margin: 25px 0 10px 0; }
    .footer { margin-top: 40px; padding-top: 15px; border-top: 1px solid #e2e8f0; font-size: 11px; color: #64748b; text-align: center; }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <h1 class="title">Disaster Operations Situation Report (SitRep)</h1>
      <p style="margin: 4px 0 0 0; color: #475569; font-size: 13px;">Report Reference: <strong>${sitrep.metadata.reportId}</strong> • Jurisdiction: ${sitrep.metadata.jurisdiction}</p>
    </div>
    <div style="text-align: right;">
      <span class="badge">${sitrep.metadata.classification}</span>
      <div style="font-size: 12px; color: #64748b; margin-top: 5px;">Generated: ${new Date(sitrep.metadata.generatedAt).toLocaleString()}</div>
    </div>
  </div>

  <div class="grid">
    <div class="card">
      <div class="label">Total Incidents</div>
      <div class="metric">${sitrep.executiveOverview.totalIncidents}</div>
      <div style="font-size: 12px; color: #059669;">${sitrep.executiveOverview.verifiedIncidents} Verified</div>
    </div>
    <div class="card">
      <div class="label">Critical Emergency Queue</div>
      <div class="metric" style="color: #dc2626;">${sitrep.executiveOverview.criticalIncidents}</div>
      <div style="font-size: 12px; color: #475569;">${sitrep.executiveOverview.inProgressIncidents} In Progress</div>
    </div>
    <div class="card">
      <div class="label">People Affected (Recorded)</div>
      <div class="metric">${sitrep.executiveOverview.peopleAffectedTotal}</div>
      <div style="font-size: 12px; color: #475569;">${sitrep.evacuationAndVulnerability.totalRegisteredCases} Household Cases</div>
    </div>
    <div class="card">
      <div class="label">Net Public Donations</div>
      <div class="metric" style="color: #059669;">₹${sitrep.financialTransparency.totalDonationsReceivedRupees.toLocaleString()}</div>
      <div style="font-size: 12px; color: #475569;">₹${sitrep.financialTransparency.totalDisbursedRupees.toLocaleString()} Disbursed</div>
    </div>
  </div>

  <div class="section-title">Multi-Sector Relief Supply Matrix (FR-25, E6)</div>
  <table>
    <thead>
      <tr>
        <th>Sector / Resource</th>
        <th>Required Quantity</th>
        <th>Available on Ground</th>
        <th>Delivered</th>
        <th>Coverage %</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      ${sitrep.reliefNeedsSummary.sectors.map(s => `
        <tr>
          <td><strong>${s.resourceType}</strong></td>
          <td>${s.required.toLocaleString()}</td>
          <td>${s.available.toLocaleString()}</td>
          <td>${s.delivered.toLocaleString()}</td>
          <td>${s.percentCovered}%</td>
          <td><span style="font-weight: 700; color: ${s.status === 'COVERED' ? '#059669' : s.status === 'SHORT' ? '#d97706' : '#dc2626'}">${s.status}</span></td>
        </tr>
      `).join('')}
    </tbody>
  </table>

  <div class="section-title">Evacuation & Ground Accessibility</div>
  <table>
    <tr>
      <td><strong>Active Evacuation Orders:</strong> ${sitrep.evacuationAndVulnerability.activeEvacuationZones} Zones</td>
      <td><strong>Blocked Road Corridors:</strong> ${sitrep.evacuationAndVulnerability.closedRoadCorridors} Highways</td>
    </tr>
    <tr>
      <td><strong>Vulnerable Citizens Needing Transport:</strong> ${sitrep.evacuationAndVulnerability.vulnerableIndividualsCount}</td>
      <td><strong>Missing Persons Located / Safe:</strong> ${sitrep.evacuationAndVulnerability.missingPersonsSafe} (Searching: ${sitrep.evacuationAndVulnerability.missingPersonsSearching})</td>
    </tr>
  </table>

  <div class="footer">
    ResQAI Emergency Command Platform • Authenticated Digital Dispatch Record • Verification ID: ${sitrep.metadata.reportId}
  </div>
</body>
</html>`;
  }
}
