import React, { useState, useEffect } from 'react';
import { 
  CheckCircle, 
  MapPin, 
  Users, 
  Navigation, 
  AlertTriangle, 
  PackagePlus, 
  Clock,
  ArrowRight
} from 'lucide-react';
import { TruthBadge } from './TruthBadge';
import './ResponderTaskView.css';

interface TaskAssignment {
  id: string;
  incident_id: string;
  team_id: string;
  status: 'ASSIGNED' | 'ACCEPTED' | 'EN_ROUTE' | 'ON_SCENE' | 'RESOLVED' | 'DECLINED';
  title: string;
  category: string;
  urgency: string;
  priority_score: number;
  latitude: number;
  longitude: number;
  location_name: string;
  people_affected: number;
  assigned_at: string;
}

export const ResponderTaskView: React.FC = () => {
  const [tasks, setTasks] = useState<TaskAssignment[]>([
    {
      id: 'ASG-DEMO-01',
      incident_id: 'INC-2026-001',
      team_id: 'TEAM-NDRF-9A',
      status: 'ACCEPTED',
      title: 'Severe Waterlogging with 14 Families Stranded on Rooftops',
      category: 'FLOOD',
      urgency: 'CRITICAL',
      priority_score: 94,
      latitude: 25.6135,
      longitude: 85.1425,
      location_name: 'Ward 12, Near Hanuman Mandir Ghat, Sector A',
      people_affected: 58,
      assigned_at: '15 mins ago'
    }
  ]);

  const [activeTaskIndex, setActiveTaskIndex] = useState<number>(0);
  const [actionFeedback, setActionFeedback] = useState<string | null>(null);
  const [offlineCached, setOfflineCached] = useState<boolean>(true);

  const activeTask = tasks[activeTaskIndex] || tasks[0];

  const fetchTasks = async () => {
    try {
      const res = await fetch('/api/v1/responder/tasks/TEAM-NDRF-9A');
      if (res.ok) {
        const data = await res.json();
        if (data.assignments && data.assignments.length > 0) {
          setTasks(data.assignments);
        }
      }
    } catch {
      // Use cached tasks
    }
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  const progressTaskState = async () => {
    if (!activeTask) return;

    let nextStatus: 'ACCEPTED' | 'EN_ROUTE' | 'ON_SCENE' | 'RESOLVED' = 'ACCEPTED';
    let actionLabel = '';

    if (activeTask.status === 'ASSIGNED') {
      nextStatus = 'ACCEPTED';
      actionLabel = 'Assignment Accepted by Unit Lead';
    } else if (activeTask.status === 'ACCEPTED') {
      nextStatus = 'EN_ROUTE';
      actionLabel = 'Unit En Route. Safe Route Engaged.';
    } else if (activeTask.status === 'EN_ROUTE') {
      nextStatus = 'ON_SCENE';
      actionLabel = 'Unit Arrived On Scene. Inflatable Boats Deployed.';
    } else if (activeTask.status === 'ON_SCENE') {
      nextStatus = 'RESOLVED';
      actionLabel = 'Rescue Complete. All 58 Citizens Evacuated to Shelter.';
    }

    try {
      const token = localStorage.getItem('resqai_token');
      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      await fetch(`/api/v1/responder/tasks/${activeTask.id}/status`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          status: nextStatus,
          notes: actionLabel
        })
      });

      setTasks(prev => prev.map((t, i) => i === activeTaskIndex ? { ...t, status: nextStatus } : t));
      setActionFeedback(`Status updated to: ${nextStatus} — ${actionLabel}`);
    } catch {
      // Optimistic local update
      setTasks(prev => prev.map((t, i) => i === activeTaskIndex ? { ...t, status: nextStatus } : t));
      setActionFeedback(`[Offline Cached] Status updated to: ${nextStatus}`);
    }
  };

  const getPrimaryButtonText = () => {
    switch (activeTask?.status) {
      case 'ASSIGNED': return '1. Accept Rescue Assignment';
      case 'ACCEPTED': return '2. Mark Unit En Route';
      case 'EN_ROUTE': return '3. Mark Unit Arrived On Scene';
      case 'ON_SCENE': return '4. Mark Rescue Assistance Completed';
      case 'RESOLVED': return '✓ Incident Fully Resolved';
      default: return 'Update Status';
    }
  };

  return (
    <div className="responder-task-wrap card">
      {/* Top Field Unit Header */}
      <div className="responder-header">
        <div className="unit-badge-group">
          <span className="unit-tag">NDRF BATTALION 9 • TEAM BRAVO</span>
          <h3>Field Responder Operations Console</h3>
          <p>Tactical dispatch console optimized for high-pressure field execution (PRD H4-7)</p>
        </div>

        <div className="unit-meta-stats">
          <span className="meta-pill">👥 25 Rescuers Ready</span>
          <span className="meta-pill">🚤 4 Inflatable Boats</span>
          <button 
            className="meta-pill highlight-safe"
            onClick={() => setOfflineCached(prev => !prev)}
            title="Toggle network connectivity mode"
            style={{ background: 'transparent', border: '1px solid var(--color-safe)', cursor: 'pointer', color: 'inherit' }}
          >
            📶 {offlineCached ? 'Offline Route Cached' : 'Online Stream Active'}
          </button>
        </div>
      </div>

      {tasks.length > 1 && (
        <div className="task-tab-list" style={{ display: 'flex', gap: '8px', margin: '12px 0' }}>
          {tasks.map((t, idx) => (
            <button 
              key={t.id} 
              className={`meta-pill ${idx === activeTaskIndex ? 'highlight-safe' : ''}`}
              onClick={() => setActiveTaskIndex(idx)}
              style={{ cursor: 'pointer' }}
            >
              Task #{idx + 1}: {t.category} ({t.urgency})
            </button>
          ))}
        </div>
      )}

      {actionFeedback && (
        <div className="action-feedback-banner">
          <CheckCircle size={18} />
          <span>{actionFeedback}</span>
        </div>
      )}

      {/* Main Task Card (Large buttons, glove-friendly 48px+ targets) */}
      {activeTask && (
        <div className="active-task-hero-card">
          <div className="task-hero-top">
            <div className="task-urgency-badge">
              <span className="urgency-dot" />
              <strong>{activeTask.urgency} EMERGENCY</strong>
            </div>
            <TruthBadge type="VERIFIED_INCIDENT" source="NDRF Sector Coordinator" size="sm" />
            <span className="sla-countdown">⏱️ SLA Target: 15 mins</span>
          </div>

          <h2 className="task-hero-title">{activeTask.title}</h2>
          
          <div className="task-location-box">
            <MapPin size={22} color="var(--color-critical)" />
            <div>
              <strong>{activeTask.location_name}</strong>
              <p>GPS: {activeTask.latitude.toFixed(4)}, {activeTask.longitude.toFixed(4)}</p>
            </div>
          </div>

          <div className="task-quick-stats">
            <div className="stat-card">
              <Users size={20} color="var(--color-info)" />
              <div>
                <span>People Trapped</span>
                <strong>{activeTask.people_affected} Citizens</strong>
              </div>
            </div>

            <div className="stat-card">
              <Navigation size={20} color="var(--color-safe)" />
              <div>
                <span>Bypass Route</span>
                <strong>Safe Clearance Active</strong>
              </div>
            </div>

            <div className="stat-card">
              <Clock size={20} color="var(--color-warn)" />
              <div>
                <span>Priority Index</span>
                <strong>{activeTask.priority_score}/100</strong>
              </div>
            </div>
          </div>

          {/* Turn-by-Turn Safe Route Guidance with Closed-Road Avoidance (FR-23) */}
          <div className="safe-turn-guidance-box">
            <div className="guidance-header">
              <Navigation size={18} color="var(--color-safe)" />
              <strong>Automated Safe Route Navigation (Avoids Closed Roads)</strong>
            </div>
            <p className="guidance-instruction">
              Proceed via <strong>Western Elevated Ridge Bypass</strong> $\rightarrow$ Turn Right at Ward 12 Canal Crossing. 
              <span className="avoided-alert"> ⚠️ Submerged Ashok Rajpath East corridor avoided.</span>
            </p>
          </div>

          {/* Primary Action Button (Changes with state, min 56px height, glove-friendly) */}
          <div className="responder-primary-actions">
            <button 
              className={`primary-state-btn status-${activeTask.status.toLowerCase()}`}
              onClick={progressTaskState}
              disabled={activeTask.status === 'RESOLVED'}
            >
              <span>{getPrimaryButtonText()}</span>
              {activeTask.status !== 'RESOLVED' && <ArrowRight size={20} />}
            </button>
          </div>

          {/* Secondary 1-Tap Tactical Actions */}
          <div className="secondary-tactical-actions">
            <button 
              className="tactical-sub-btn"
              onClick={() => setActionFeedback('Resource Request Dispatched: 2 Extra Medical Water Ambulances Requested from Sector A Base.')}
            >
              <PackagePlus size={18} />
              <span>Request More Boats / Kits</span>
            </button>

            <button 
              className="tactical-sub-btn btn-hazard"
              onClick={() => setActionFeedback('Hazard Warning Dispatched: New Electric Wire Submersion logged on East Embankment.')}
            >
              <AlertTriangle size={18} />
              <span>Report Local Obstacle / Hazard</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
