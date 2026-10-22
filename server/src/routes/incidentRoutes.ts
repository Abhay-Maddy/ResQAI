import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { db } from '../db/database';
import { authenticate, requireRole } from '../middleware/rbacMiddleware';
import { analyzeIncidentTriage } from '../services/aiTriageService';
import { logAuditEvent } from '../services/auditService';

export const incidentRouter = Router();

// FR-5, FR-6, FR-7: Citizen Emergency Report submission
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
    areaId = 'area-a'
  } = req.body;

  if (!category || !description || latitude === undefined || longitude === undefined) {
    return res.status(400).json({
      error: 'BAD_REQUEST',
      message: 'Category, description, latitude, and longitude are required.'
    });
  }

  // FR-7: Idempotency Key deduplication
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
    // Retrieve active incidents for AI duplicate detection & triage (FR-11)
    const existingIncidents = db.prepare(`
      SELECT id, title, category, urgency, latitude, longitude 
      FROM incidents 
      WHERE status NOT IN ('RESOLVED', 'CLOSED', 'REJECTED')
    `).all();

    const aiAnalysis = analyzeIncidentTriage(
      {
        category,
        description,
        urgency,
        peopleCount: Number(peopleCount) || 1,
        latitude: Number(latitude),
        longitude: Number(longitude)
      },
      existingIncidents
    );

    // FR-6: Return unique incident ID only after server confirmation
    const incidentId = `INC-${new Date().getFullYear()}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
    const reportId = `REP-${Date.now().toString().slice(-6)}`;

    // Set SLA deadline (e.g. Critical = 15m, High = 30m, Medium = 60m, Low = 120m)
    const slaMinutes = urgency === 'CRITICAL' ? 15 : urgency === 'HIGH' ? 30 : urgency === 'MEDIUM' ? 60 : 120;

    const shortTitle = description.length > 60 ? description.substring(0, 57) + '...' : description;

    // Insert Incident
    db.prepare(`
      INSERT INTO incidents (
        id, title, category, status, urgency, priority_score, why_priority_explanation,
        latitude, longitude, location_name, area_id, people_affected, sla_deadline_minutes, is_simulated_drill
      ) VALUES (?, ?, ?, 'TRIAGE', ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
    `).run(
      incidentId,
      shortTitle,
      category,
      urgency,
      aiAnalysis.suggestedPriorityScore,
      aiAnalysis.whyExplanation,
      latitude,
      longitude,
      locationName,
      areaId,
      peopleCount,
      slaMinutes
    );

    // Insert Report
    db.prepare(`
      INSERT INTO incident_reports (
        id, incident_id, source_type, category, description, latitude, longitude,
        location_name, urgency, people_count, contact_phone, is_anonymous, media_urls_json, idempotency_key
      ) VALUES (?, ?, 'CITIZEN_PWA', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
      idempotencyKey || null
    );

    logAuditEvent({
      actionType: 'INCIDENT_REPORTED',
      actorId: isAnonymous ? 'ANONYMOUS_CITIZEN' : (contactPhone || 'CITIZEN'),
      actorRole: 'CITIZEN',
      entityId: incidentId,
      details: `Report submitted: ${category} in ${locationName}. Urgency: ${urgency}. Priority: ${aiAnalysis.suggestedPriorityScore}.`,
      ipAddress: req.ip
    });

    res.status(201).json({
      message: 'Emergency incident confirmed and registered on server.',
      incidentId,
      reportId,
      status: 'TRIAGE',
      urgency,
      priorityScore: aiAnalysis.suggestedPriorityScore,
      whyPriorityExplanation: aiAnalysis.whyExplanation,
      aiSummary: aiAnalysis.summary,
      duplicateCandidates: aiAnalysis.duplicateCandidates,
      slaDeadlineMinutes: slaMinutes,
      whatHappensNext: 'Your report has entered the rapid triage queue. A designated disaster officer and AI verifier will corroborate the evidence within minutes.'
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
    assignedTeam,
    aiSummary: aiAnalysis.summary,
    duplicateCandidates: aiAnalysis.duplicateCandidates
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

// FR-16, FR-17: Assign Rescue Team
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

  logAuditEvent({
    actionType: 'TEAM_ASSIGNED',
    actorId: req.user!.userId,
    actorRole: req.user!.role,
    entityId: incidentId,
    details: `Assigned ${team.name} to incident ${incidentId}`,
    ipAddress: req.ip
  });

  res.json({
    message: 'Rescue team successfully dispatched',
    assignmentId,
    teamName: team.name,
    status: 'RESPONSE_ASSIGNED'
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
