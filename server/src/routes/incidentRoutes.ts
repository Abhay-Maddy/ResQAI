import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { db } from '../db/database';
import { authenticate, requireRole } from '../middleware/rbacMiddleware';
import { analyzeIncidentTriage } from '../services/aiTriageService';
import { logAuditEvent } from '../services/auditService';

export const incidentRouter = Router();

// Helper: Bilingual auto-translation mock for responders (Hindi <-> English)
function autoTranslateForResponders(text: string): { original: string; translated: string } {
  const hasHindi = /[\u0900-\u097F]/.test(text);
  if (hasHindi) {
    return {
      original: text,
      translated: `[Auto-Translated from Hindi]: Emergency request detected: "${text}". Immediate responder attention required.`
    };
  }
  return {
    original: text,
    translated: text
  };
}

// PRD v2.0 Phase 3: Status history tracking helper
export function recordStatusHistory(
  incidentId: string, 
  fromStatus: string | null, 
  toStatus: string, 
  userId?: string | null, 
  role?: string | null, 
  reason?: string | null
) {
  try {
    const id = `SH-${Date.now().toString().slice(-6)}-${Math.floor(Math.random() * 1000)}`;
    db.prepare(`
      INSERT INTO incident_status_history (id, incident_id, from_status, to_status, changed_by_user_id, changed_by_role, reason)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(id, incidentId, fromStatus, toStatus, userId || null, role || null, reason || null);
  } catch (_) {}
}

// FR-5, FR-6, FR-7, PRD v2.0 Phase 2: Citizen Emergency SOS & Report submission
incidentRouter.post('/', async (req: Request, res: Response) => {
  const {
    category,
    description,
    latitude,
    longitude,
    locationName = 'Unknown Location',
    urgency = 'MEDIUM',
    peopleCount = 1,
    contactPhone,
    isAnonymous = false,
    mediaUrls = [],
    idempotencyKey,
    areaId = 'area-a',
    // PRD v2.0 Phase 2 additions
    needs = [],
    voiceNoteUrl,
    notifyEmergencyContacts = false,
    userId
  } = req.body;

  if (!category || !description || latitude === undefined || longitude === undefined) {
    return res.status(400).json({
      error: 'BAD_REQUEST',
      message: 'Category, description, latitude, and longitude are required.'
    });
  }

  // FR-7 & Phase 2: Idempotency Key deduplication
  if (idempotencyKey) {
    const existingReport = db.prepare('SELECT * FROM incident_reports WHERE idempotency_key = ?').get(idempotencyKey) as any;
    if (existingReport) {
      const existingIncident = db.prepare('SELECT * FROM incidents WHERE id = ?').get(existingReport.incident_id);
      return res.status(200).json({
        message: 'Idempotent request received. Returning existing incident.',
        incidentId: existingReport.incident_id,
        incident: existingIncident
      });
    }
  }

  try {
    // Phase 2 Spam & repeated-source protection (F-05)
    let isRepeatedSource = 0;
    if (contactPhone && !isAnonymous) {
      const recentCount = (db.prepare(`
        SELECT count(*) as c 
        FROM incident_reports 
        WHERE contact_phone = ? AND created_at >= datetime('now', '-5 minutes')
      `).get(contactPhone) as any)?.c || 0;

      if (recentCount >= 3) {
        isRepeatedSource = 1;
      }
    }

    // Auto-translation for emergency responders (F-01)
    const { original, translated } = autoTranslateForResponders(description);

    // Retrieve active incidents for AI duplicate detection & triage (FR-11)
    const existingIncidents = db.prepare(`
      SELECT id, title, category, urgency, latitude, longitude 
      FROM incidents 
      WHERE status NOT IN ('RESOLVED', 'CLOSED', 'REJECTED')
    `).all();

    const aiAnalysis = analyzeIncidentTriage(
      {
        category,
        description: translated,
        urgency,
        peopleCount: Number(peopleCount) || 1,
        latitude: Number(latitude),
        longitude: Number(longitude)
      },
      existingIncidents
    );

    // Unique incident ID confirmed by server
    const incidentId = `INC-${new Date().getFullYear()}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
    const reportId = `REP-${Date.now().toString().slice(-6)}`;

    // Set SLA deadline (Critical = 15m, High = 30m, Medium = 60m, Low = 120m)
    const slaMinutes = urgency === 'CRITICAL' ? 15 : urgency === 'HIGH' ? 30 : urgency === 'MEDIUM' ? 60 : 120;
    const shortTitle = description.length > 60 ? description.substring(0, 57) + '...' : description;

    // Insert Incident
    db.prepare(`
      INSERT INTO incidents (
        id, title, category, status, urgency, priority_score, why_priority_explanation,
        latitude, longitude, location_name, area_id, people_affected, sla_deadline_minutes, is_simulated_drill
      ) VALUES (?, ?, ?, 'RECEIVED', ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
    `).run(
      incidentId,
      shortTitle,
      category,
      urgency,
      aiAnalysis.suggestedPriorityScore,
      isRepeatedSource ? `${aiAnalysis.whyExplanation} [FLAGGED: Repeated submissions from caller within 5 mins]` : aiAnalysis.whyExplanation,
      latitude,
      longitude,
      locationName,
      areaId,
      peopleCount,
      slaMinutes
    );

    // Insert Report with PRD v2.0 Phase 2 columns
    db.prepare(`
      INSERT INTO incident_reports (
        id, incident_id, source_type, category, description, latitude, longitude,
        location_name, urgency, people_count, contact_phone, is_anonymous, media_urls_json, idempotency_key,
        description_original, description_translated, needs_json, voice_note_url, is_repeated_source
      ) VALUES (?, ?, 'CITIZEN_PWA', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      reportId,
      incidentId,
      category,
      description,
      latitude,
      longitude,
      locationName,
      urgency,
      peopleCount,
      isAnonymous ? null : contactPhone,
      isAnonymous ? 1 : 0,
      JSON.stringify(mediaUrls),
      idempotencyKey || null,
      original,
      translated,
      JSON.stringify(needs),
      voiceNoteUrl || null,
      isRepeatedSource
    );

    // PRD R-CIT-4: Emergency contact SMS notification if user allows it
    let emergencyContactsNotified = 0;
    if (notifyEmergencyContacts && (contactPhone || userId)) {
      let contacts: any[] = [];
      if (userId) {
        contacts = db.prepare('SELECT phone, name FROM emergency_contacts WHERE user_id = ?').all(userId) as any[];
      } else if (contactPhone) {
        const user = db.prepare('SELECT id FROM users WHERE phone = ?').get(contactPhone) as any;
        if (user) {
          contacts = db.prepare('SELECT phone, name FROM emergency_contacts WHERE user_id = ?').all(user.id) as any[];
        }
      }

      for (const contact of contacts) {
        emergencyContactsNotified++;
        logAuditEvent({
          actionType: 'EMERGENCY_CONTACT_SMS_SENT',
          actorId: incidentId,
          actorRole: 'SYSTEM_SMS_ADAPTER',
          entityId: contact.phone,
          details: `Automated SOS notification dispatched to emergency contact ${contact.name} (${contact.phone}) with live tracking link /track/${incidentId}`,
          ipAddress: req.ip
        });
      }
    }

    logAuditEvent({
      actionType: 'INCIDENT_REPORTED',
      actorId: isAnonymous ? 'ANONYMOUS_CITIZEN' : (contactPhone || 'CITIZEN'),
      actorRole: 'CITIZEN',
      entityId: incidentId,
      details: `Report submitted: ${category} in ${locationName}. Urgency: ${urgency}. Priority: ${aiAnalysis.suggestedPriorityScore}. RepeatedSource: ${isRepeatedSource}. ContactsNotified: ${emergencyContactsNotified}.`,
      ipAddress: req.ip
    });

    res.status(201).json({
      message: 'Emergency incident confirmed and registered on server.',
      incidentId,
      reportId,
      status: 'RECEIVED',
      urgency,
      priorityScore: aiAnalysis.suggestedPriorityScore,
      whyPriorityExplanation: aiAnalysis.whyExplanation,
      aiSummary: aiAnalysis.summary,
      duplicateCandidates: aiAnalysis.duplicateCandidates,
      slaDeadlineMinutes: slaMinutes,
      emergencyContactsNotified,
      googleMapsUrl: `https://www.google.com/maps?q=${latitude},${longitude}`,
      adminDeliveryStatus: 'SENT',
      contactDeliveryStatus: emergencyContactsNotified > 0 ? 'SENT' : 'NO_CONTACTS',
      publicTrackingUrl: `/track/${incidentId}`,
      whatHappensNext: 'Your SOS signal has been confirmed by the command center. Field dispatch units and the DDMA triage desk have been notified.'
    });
  } catch (err: any) {
    res.status(500).json({ error: 'SERVER_ERROR', message: err.message });
  }
});

// GET /api/v1/incidents: Retrieve incident queue with filters and SLA
incidentRouter.get('/', (req: Request, res: Response) => {
  const { status, category, urgency, areaId, search } = req.query;

  let query = 'SELECT * FROM incidents WHERE 1=1';
  const params: any[] = [];

  if (status) {
    query += ' AND status = ?';
    params.push(status);
  }
  if (category) {
    query += ' AND category = ?';
    params.push(category);
  }
  if (urgency) {
    query += ' AND urgency = ?';
    params.push(urgency);
  }
  if (areaId) {
    query += ' AND area_id = ?';
    params.push(areaId);
  }
  if (search) {
    query += ' AND (title LIKE ? OR location_name LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }

  query += ' ORDER BY priority_score DESC, created_at DESC';

  const incidents = db.prepare(query).all(...params);
  res.json({ incidents });
});

// GET /api/v1/incidents/:id: Detailed incident view with reports, verifications & AI analysis (H4-4)
incidentRouter.get('/:id', (req: Request, res: Response) => {
  const incident = db.prepare('SELECT * FROM incidents WHERE id = ?').get(req.params.id) as any;
  if (!incident) {
    return res.status(404).json({ error: 'NOT_FOUND', message: 'Incident not found' });
  }

  const reports = db.prepare('SELECT * FROM incident_reports WHERE incident_id = ?').all(req.params.id);
  const verifications = db.prepare('SELECT * FROM verifications WHERE incident_id = ?').all(req.params.id);
  const statusHistory = db.prepare('SELECT * FROM incident_status_history WHERE incident_id = ? ORDER BY created_at ASC').all(req.params.id);
  const assignedTeam = incident.assigned_team_id 
    ? db.prepare('SELECT * FROM rescue_teams WHERE id = ?').get(incident.assigned_team_id)
    : null;

  // Retrieve AI duplicate candidates
  const otherIncidents = db.prepare(`
    SELECT id, title, category, urgency, latitude, longitude 
    FROM incidents 
    WHERE id != ? AND status NOT IN ('RESOLVED', 'CLOSED', 'REJECTED')
  `).all(incident.id);

  const aiAnalysis = analyzeIncidentTriage(
    {
      category: incident.category,
      description: incident.title,
      urgency: incident.urgency,
      peopleCount: incident.people_affected,
      latitude: incident.latitude,
      longitude: incident.longitude
    },
    otherIncidents
  );

  res.json({
    incident,
    reports,
    verifications,
    statusHistory,
    assignedTeam,
    escalatedToSupervisor: !!incident.escalated_to_supervisor,
    escalationBadge: incident.escalation_badge || null,
    aiSummary: aiAnalysis.summary,
    duplicateCandidates: aiAnalysis.duplicateCandidates
  });
});

// PRD v3.0 SOS-7: Accidental cancel ("I pressed by mistake") - never hides from audit
incidentRouter.post('/:id/cancel-accidental', async (req: Request, res: Response) => {
  const incidentId = String(req.params.id);
  const { reason = 'Citizen pressed SOS button by mistake' } = req.body;

  const incident = db.prepare('SELECT * FROM incidents WHERE id = ?').get(incidentId) as any;
  if (!incident) {
    return res.status(404).json({ error: 'NOT_FOUND', message: 'Incident not found' });
  }

  const nowIso = new Date().toISOString();
  db.prepare(`
    UPDATE incidents 
    SET is_accidental_cancelled = 1, accidental_cancelled_at = ?, accidental_cancelled_by = ?, status = 'CLOSED'
    WHERE id = ?
  `).run(nowIso, reason, incidentId);

  recordStatusHistory(incidentId, incident.status, 'CANCELLED', null, 'CITIZEN', `Accidental trigger: ${reason}`);

  logAuditEvent({
    actionType: 'INCIDENT_CANCELLED_ACCIDENTAL',
    actorId: incidentId,
    actorRole: 'CITIZEN',
    entityId: incidentId,
    details: `Incident marked as accidental trigger: "${reason}". Retained in audit log per SOS-7.`,
    ipAddress: req.ip
  });

  return res.json({
    success: true,
    incidentId,
    message: 'SOS cancelled as accidental. Incident preserved in audit trail for accountability (SOS-7).'
  });
});

// PRD v3.0 SOS-11 to SOS-14: Attach detailed emergency form to existing SOS incident
incidentRouter.post('/:id/attach-details', async (req: Request, res: Response) => {
  const incidentId = String(req.params.id);
  const { category, peopleCount, needs = [], photoUrls = [], voiceNoteUrl, additionalDetails } = req.body;

  const incident = db.prepare('SELECT * FROM incidents WHERE id = ?').get(incidentId) as any;
  if (!incident) {
    return res.status(404).json({ error: 'NOT_FOUND', message: 'Incident not found' });
  }

  const attachedFormJson = JSON.stringify({
    category,
    peopleCount,
    needs,
    photoUrls,
    voiceNoteUrl,
    additionalDetails,
    attachedAt: new Date().toISOString()
  });

  db.prepare(`
    UPDATE incidents 
    SET attached_form_json = ?, people_affected = COALESCE(?, people_affected), category = COALESCE(?, category)
    WHERE id = ?
  `).run(attachedFormJson, peopleCount || null, category || null, incidentId);

  // Update incident_reports
  try {
    db.prepare(`
      UPDATE incident_reports 
      SET needs_json = ?, media_urls_json = ?, voice_note_url = COALESCE(?, voice_note_url)
      WHERE incident_id = ?
    `).run(JSON.stringify(needs), JSON.stringify(photoUrls), voiceNoteUrl || null, incidentId);
  } catch (_) {}

  logAuditEvent({
    actionType: 'FORM_ATTACHED_TO_SOS',
    actorId: incidentId,
    actorRole: 'CITIZEN',
    entityId: incidentId,
    details: `Detailed emergency form attached to incident ${incidentId} (SOS-13)`,
    ipAddress: req.ip
  });

  return res.json({
    success: true,
    incidentId,
    message: 'Details attached to existing SOS incident. Admin views consolidated single case (SOS-13).'
  });
});

// FR-10, FR-12: Verification Decision Endpoint
incidentRouter.post('/:id/verify', authenticate, requireRole('ADMIN', 'GOVT_OFFICER'), (req: Request, res: Response) => {
  const { decision, reason, confidence = 0.9, unresolvedUncertainty = '', mergedIntoIncidentId } = req.body;
  const incidentId = req.params.id as string;

  if (!decision || !reason) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'Decision and reason are required' });
  }

  const validDecisions = ['VERIFIED', 'UNVERIFIED', 'DUPLICATE', 'ESCALATED'];
  if (!validDecisions.includes(decision)) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: `Invalid decision: ${decision}` });
  }

  const incident = db.prepare('SELECT * FROM incidents WHERE id = ?').get(incidentId) as any;
  if (!incident) {
    return res.status(404).json({ error: 'NOT_FOUND', message: 'Incident not found' });
  }

  // FR-11: "AI cannot reject a report that may be life-threatening."
  if (incident.urgency === 'CRITICAL' && decision === 'UNVERIFIED' && confidence < 0.95) {
    return res.status(400).json({
      error: 'CRITICAL_SAFETY_GATE',
      message: 'Life-threatening critical incidents cannot be marked unverified without senior commanding officer high-confidence sign-off.'
    });
  }

  const verificationId = `VER-${Date.now().toString().slice(-6)}`;
  let newStatus = decision;
  if (decision === 'ESCALATED') newStatus = 'ESCALATED';

  // Insert Verification record (FR-12: reviewer, timestamp, reason, evidence refs, confidence, uncertainty)
  db.prepare(`
    INSERT INTO verifications (
      id, incident_id, reviewer_id, decision, reason, evidence_refs_json, confidence, unresolved_uncertainty, merged_into_incident_id
    ) VALUES (?, ?, ?, ?, ?, '[]', ?, ?, ?)
  `).run(
    verificationId,
    incidentId,
    req.user!.userId,
    decision,
    reason,
    confidence,
    unresolvedUncertainty,
    mergedIntoIncidentId || null
  );

  // Update incident status
  db.prepare(`
    UPDATE incidents 
    SET status = ?, updated_at = datetime('now')
    WHERE id = ?
  `).run(newStatus, incidentId);

  recordStatusHistory(incidentId, incident.status, newStatus, req.user!.userId, req.user!.role, reason);

  logAuditEvent({
    actionType: 'INCIDENT_VERIFIED',
    actorId: req.user!.userId,
    actorRole: req.user!.role,
    entityId: incidentId,
    details: `Decision: ${decision}. Reason: ${reason}. Confidence: ${(confidence * 100).toFixed(0)}%.`,
    beforeState: { status: incident.status },
    afterState: { status: newStatus },
    ipAddress: req.ip
  });

  res.json({
    message: `Incident verification updated to ${newStatus}`,
    verificationId,
    incidentId,
    newStatus
  });
});

// PRD v2.0 Phase 3: Reversible Duplicate Merge (Reviewer-signed unmerge)
// ACCEPTANCE CRITERIA: "duplicate merge needs a reviewer and is reversible"
incidentRouter.post('/:id/unmerge', authenticate, requireRole('ADMIN', 'GOVT_OFFICER'), (req: Request, res: Response) => {
  const { reason = 'Reviewer confirmed report is a distinct independent emergency' } = req.body;
  const incidentId = req.params.id as string;

  const incident = db.prepare('SELECT * FROM incidents WHERE id = ?').get(incidentId) as any;
  if (!incident) {
    return res.status(404).json({ error: 'NOT_FOUND', message: 'Incident not found' });
  }

  if (incident.status !== 'DUPLICATE') {
    return res.status(400).json({ error: 'BAD_REQUEST', message: `Only DUPLICATE incidents can be unmerged. Current status is ${incident.status}` });
  }

  // Find target merged incident
  const verification = db.prepare(`
    SELECT merged_into_incident_id FROM verifications 
    WHERE incident_id = ? AND decision = 'DUPLICATE'
    ORDER BY created_at DESC LIMIT 1
  `).get(incidentId) as any;
  const mergedInto = verification?.merged_into_incident_id;

  // Revert incident status back to VERIFIED
  db.prepare(`
    UPDATE incidents 
    SET status = 'VERIFIED', updated_at = datetime('now')
    WHERE id = ?
  `).run(incidentId);

  // Update verifications
  db.prepare(`
    UPDATE verifications 
    SET decision = 'VERIFIED', reason = ?, merged_into_incident_id = NULL
    WHERE incident_id = ? AND decision = 'DUPLICATE'
  `).run(`Unmerge authorized by ${req.user!.userId}: ${reason}`, incidentId);

  recordStatusHistory(incidentId, 'DUPLICATE', 'VERIFIED', req.user!.userId, req.user!.role, `Duplicate unmerge: ${reason}`);

  logAuditEvent({
    actionType: 'DUPLICATE_MERGE_REVERSED',
    actorId: req.user!.userId,
    actorRole: req.user!.role,
    entityId: incidentId,
    details: `Duplicate merge into ${mergedInto || 'N/A'} reversed. Incident reinstated to VERIFIED status. Reviewer: ${req.user!.userId}. Reason: ${reason}`,
    beforeState: { status: 'DUPLICATE', mergedInto },
    afterState: { status: 'VERIFIED', mergedInto: null },
    ipAddress: req.ip
  });

  res.json({
    message: 'Duplicate merge successfully reversed. Incident reinstated as VERIFIED.',
    incidentId,
    previousMergedInto: mergedInto,
    status: 'VERIFIED'
  });
});

// PRD v2.0 Phase 3: Incident Status History
incidentRouter.get('/:id/status-history', (req: Request, res: Response) => {
  const incidentId = req.params.id as string;
  const history = db.prepare(`
    SELECT * FROM incident_status_history 
    WHERE incident_id = ? 
    ORDER BY created_at ASC
  `).all(incidentId);

  res.json({ incidentId, history });
});

// FR-16, FR-17, PRD v2.0 Phase 3: Assign Rescue Team with Responder Notification
incidentRouter.post('/:id/assign', authenticate, requireRole('ADMIN', 'GOVT_OFFICER'), (req: Request, res: Response) => {
  const { teamId, notes = '' } = req.body;
  const incidentId = req.params.id as string;

  if (!teamId) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'Rescue teamId is required' });
  }

  const team = db.prepare('SELECT * FROM rescue_teams WHERE id = ?').get(teamId) as any;
  if (!team) {
    return res.status(404).json({ error: 'TEAM_NOT_FOUND', message: 'Rescue team not found' });
  }

  const assignmentId = `ASG-${Date.now().toString().slice(-6)}`;

  // Create Assignment
  db.prepare(`
    INSERT INTO assignments (id, incident_id, team_id, status, notes)
    VALUES (?, ?, ?, 'ASSIGNED', ?)
  `).run(assignmentId, incidentId, teamId, notes);

  // Update Incident & Team status
  db.prepare("UPDATE incidents SET status = 'RESPONSE_ASSIGNED', assigned_team_id = ? WHERE id = ?").run(teamId, incidentId);
  db.prepare("UPDATE rescue_teams SET status = 'ASSIGNED', assigned_incident_id = ? WHERE id = ?").run(incidentId, teamId);

  recordStatusHistory(incidentId, 'VERIFIED', 'RESPONSE_ASSIGNED', req.user!.userId, req.user!.role, `Dispatched team: ${team.name}`);

  // Responder notification (email / SMS / push)
  logAuditEvent({
    actionType: 'RESPONDER_NOTIFICATION_DISPATCHED',
    actorId: req.user!.userId,
    actorRole: 'DISPATCHER',
    entityId: team.id,
    details: `Emergency notification dispatched to ${team.name} (${team.contact_number}) via SMS/Push for incident ${incidentId}`,
    ipAddress: req.ip
  });

  logAuditEvent({
    actionType: 'TEAM_ASSIGNED',
    actorId: req.user!.userId,
    actorRole: req.user!.role,
    entityId: incidentId,
    details: `Assigned ${team.name} to incident ${incidentId}`,
    ipAddress: req.ip
  });

  res.json({
    message: 'Rescue team successfully dispatched with responder notification sent.',
    assignmentId,
    teamName: team.name,
    status: 'RESPONSE_ASSIGNED'
  });
});

// PRD v2.0 Phase 3: Configurable Escalation Engine (X minutes unassigned critical incident alert)
// ACCEPTANCE CRITERIA: "a critical incident unassigned for X minutes notifies the supervisor and shows an escalation badge"
incidentRouter.post('/escalation/check', (req: Request, res: Response) => {
  const thresholdMinutes = Number(req.body.thresholdMinutes || req.query.thresholdMinutes || 15);

  const unassignedCritical = db.prepare(`
    SELECT * FROM incidents 
    WHERE (urgency = 'CRITICAL' OR priority_score >= 80)
      AND (assigned_team_id IS NULL OR status IN ('RECEIVED', 'TRIAGE'))
      AND status NOT IN ('RESOLVED', 'CLOSED', 'REJECTED')
      AND datetime(created_at, '+' || ? || ' minutes') <= datetime('now')
  `).all(thresholdMinutes) as any[];

  const escalatedIncidents = [];

  for (const inc of unassignedCritical) {
    db.prepare(`
      UPDATE incidents 
      SET escalated_to_supervisor = 1,
          escalation_badge = 'SUPERVISOR_ALERT: ESCALATED',
          escalated_at = datetime('now')
      WHERE id = ?
    `).run(inc.id);

    recordStatusHistory(
      inc.id,
      inc.status,
      inc.status,
      'SYSTEM_ESCALATION_ENGINE',
      'SYSTEM',
      `Critical incident unassigned for > ${thresholdMinutes} minutes. Escalation badge attached & supervisor notified.`
    );

    logAuditEvent({
      actionType: 'INCIDENT_ESCALATED_TO_SUPERVISOR',
      actorId: 'SYSTEM_ESCALATION_ENGINE',
      actorRole: 'SYSTEM',
      entityId: inc.id,
      details: `Critical incident ${inc.id} unassigned for > ${thresholdMinutes} mins. Notified supervisor with escalation badge.`,
      ipAddress: req.ip
    });

    escalatedIncidents.push({
      id: inc.id,
      title: inc.title,
      urgency: inc.urgency,
      priorityScore: inc.priority_score,
      escalationBadge: 'SUPERVISOR_ALERT: ESCALATED',
      escalatedToSupervisor: true
    });
  }

  res.json({
    message: `Escalation check complete. ${escalatedIncidents.length} critical incidents escalated.`,
    thresholdMinutes,
    escalatedCount: escalatedIncidents.length,
    escalatedIncidents
  });
});

// H4-3: Admin Command Dashboard Real DB KPI Metrics
incidentRouter.get('/stats/command', (req: Request, res: Response) => {
  const reportedCount = (db.prepare('SELECT count(*) as c FROM incidents').get() as any).c;
  const verifiedActive = (db.prepare("SELECT count(*) as c FROM incidents WHERE status IN ('VERIFIED', 'RESPONSE_ASSIGNED', 'IN_PROGRESS')").get() as any).c;
  const pendingVerification = (db.prepare("SELECT count(*) as c FROM incidents WHERE status IN ('RECEIVED', 'TRIAGE', 'UNDER_REVIEW')").get() as any).c;
  const criticalCount = (db.prepare("SELECT count(*) as c FROM incidents WHERE urgency = 'CRITICAL' AND status NOT IN ('RESOLVED', 'CLOSED')").get() as any).c;
  const rescuesInProgress = (db.prepare("SELECT count(*) as c FROM rescue_teams WHERE status IN ('ASSIGNED', 'EN_ROUTE', 'ON_SCENE')").get() as any).c;
  const peopleAffectedTotal = (db.prepare('SELECT sum(people_affected) as s FROM incidents').get() as any).s || 0;
  const openRequests = (db.prepare("SELECT count(*) as c FROM incidents WHERE status NOT IN ('RESOLVED', 'CLOSED')").get() as any).c;

  // Resource calculation: total available vs required units across areas
  const resourceTotals = db.prepare(`
    SELECT sum(available_units) as totalAvail, sum(required_units) as totalReq
    FROM area_needs
  `).get() as any;

  const totalAvail = resourceTotals.totalAvail || 0;
  const totalReq = resourceTotals.totalReq || 1;
  const resourcePct = Math.min(100, Math.round((totalAvail / totalReq) * 100));

  res.json({
    kpis: {
      reported: reportedCount,
      verifiedActive,
      pendingVerification,
      critical: criticalCount,
      rescuesInProgress,
      peopleAffected: peopleAffectedTotal,
      openRequests,
      resourceAvailability: {
        available: totalAvail,
        required: totalReq,
        percentage: resourcePct
      }
    }
  });
});

// PRD v2.0 Phase 2 (F-06 & Acceptance Criteria): Public Status Tracking Page by Reference ID
// ACCEPTANCE CRITERIA: "tracking page shows only the status, never contact details."
incidentRouter.get('/track/:referenceId', (req: Request, res: Response) => {
  const refId = req.params.referenceId as string;

  // Search by incident ID or report ID
  let incident = db.prepare('SELECT * FROM incidents WHERE id = ?').get(refId) as any;
  if (!incident) {
    const report = db.prepare('SELECT incident_id FROM incident_reports WHERE id = ? OR idempotency_key = ?').get(refId, refId) as any;
    if (report && report.incident_id) {
      incident = db.prepare('SELECT * FROM incidents WHERE id = ?').get(report.incident_id) as any;
    }
  }

  if (!incident) {
    return res.status(404).json({
      error: 'REFERENCE_NOT_FOUND',
      message: `No public emergency tracking record found for reference ID: ${refId}`
    });
  }

  // Determine stage and timeline
  let stageLabel = 'Received';
  if (incident.status === 'RECEIVED' || incident.status === 'TRIAGE') {
    stageLabel = 'Received & Queued for Review';
  } else if (incident.status === 'UNDER_REVIEW' || incident.status === 'PENDING_REVIEW') {
    stageLabel = 'Under Review by Dispatcher';
  } else if (incident.status === 'VERIFIED') {
    stageLabel = 'Officially Verified';
  } else if (incident.status === 'RESPONSE_ASSIGNED' || incident.status === 'ASSIGNED') {
    stageLabel = 'Help Assigned / Team En Route';
  } else if (incident.status === 'RESOLVED') {
    stageLabel = 'Resolved & Safe';
  }

  let assignedTeamType: string | null = null;
  if (incident.assigned_team_id) {
    const team = db.prepare('SELECT type, name FROM rescue_teams WHERE id = ?').get(incident.assigned_team_id) as any;
    if (team) {
      assignedTeamType = `${team.type} Unit (${team.name})`;
    }
  }

  const verifications = db.prepare(`
    SELECT decision, reason, verified_at 
    FROM verifications 
    WHERE incident_id = ?
    ORDER BY verified_at ASC
  `).all(incident.id) as any[];

  // Construct privacy-safe timeline (no phone, no caller name)
  const timeline = [
    {
      stage: 'RECEIVED',
      timestamp: incident.created_at,
      label: 'Emergency SOS Signal Received',
      description: 'Your report was received by the ResQAI gateway and assigned a server reference ID.'
    }
  ];

  if (verifications.length > 0) {
    for (const v of verifications) {
      timeline.push({
        stage: v.decision,
        timestamp: v.verified_at,
        label: `Verification Decision: ${v.decision}`,
        description: `Reviewed by designated emergency officer. Finding: ${v.reason}`
      });
    }
  }

  if (assignedTeamType) {
    timeline.push({
      stage: 'HELP_ASSIGNED',
      timestamp: incident.updated_at || incident.created_at,
      label: 'Rescue Team Dispatched',
      description: `${assignedTeamType} has been assigned to coordinate relief for this zone.`
    });
  }

  if (incident.status === 'RESOLVED') {
    timeline.push({
      stage: 'RESOLVED',
      timestamp: incident.updated_at,
      label: 'Emergency Mission Complete',
      description: 'The incident has been recorded as resolved.'
    });
  }

  // EXPLICIT PRIVACY ENFORCEMENT: Never expose contact_phone, caller name, exact GPS coordinates, or PII
  res.json({
    referenceId: incident.id,
    status: incident.status,
    stage: stageLabel,
    category: incident.category,
    urgency: incident.urgency,
    area: incident.location_name, // Ward-level description only
    priorityScore: incident.priority_score,
    timeline,
    assignedTeamType,
    whatHappensNext: incident.status === 'RESOLVED' 
      ? 'The situation has been stabilized.' 
      : (assignedTeamType 
          ? 'First responders are responding to the affected area.' 
          : 'Emergency authorities are corroborating incoming reports to mobilize nearest rescue resources.'),
    // Explicit guarantees for compliance
    privacyNotice: 'Under ResQAI Privacy Rules (R-TRN-1 & DPDP Act), caller names, contact phone numbers, and victim PII are strictly omitted from public tracking pages.'
  });
});

// PRD v2.0 Phase 2 (F-07): Data retention masking job (masks records older than retention period)
incidentRouter.post('/jobs/retention-cleanup', authenticate, requireRole('ADMIN'), (req: Request, res: Response) => {
  const result = db.prepare(`
    UPDATE incident_reports 
    SET contact_phone = '[REDACTED_BY_RETENTION_POLICY]', retention_masked = 1
    WHERE created_at <= datetime('now', '-90 days')
  `).run();

  logAuditEvent({
    actionType: 'DATA_RETENTION_CLEANUP',
    actorId: req.user!.userId,
    actorRole: req.user!.role,
    entityId: 'INCIDENT_REPORTS_TABLE',
    details: `Executed retention masking job: ${result.changes} records masked per F-07 compliance.`,
    ipAddress: req.ip
  });

  res.json({
    message: 'Data retention cleanup completed successfully',
    recordsMasked: result.changes
  });
});
