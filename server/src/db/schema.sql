-- ResQAI Relational Schema — strictly aligned with PRD Part G, Part E1, and Part L Item 4

PRAGMA foreign_keys = ON;

-- 1. Users Table (FR-1, FR-2, FR-4)
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  password_hash TEXT,
  role TEXT NOT NULL CHECK(role IN ('CITIZEN', 'ADMIN', 'GOVT_OFFICER', 'RESPONDER', 'NGO', 'DONOR', 'AUDITOR')),
  jurisdiction_region_id TEXT,
  is_verified INTEGER DEFAULT 0,
  two_factor_enabled INTEGER DEFAULT 0,
  two_factor_secret TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. Sessions & Refresh Token Rotation (FR-1: refresh-token rotation; session revocation)
CREATE TABLE IF NOT EXISTS user_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token_hash TEXT NOT NULL UNIQUE,
  user_agent TEXT,
  ip_address TEXT,
  is_revoked INTEGER DEFAULT 0,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  last_used_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 3. OTP Codes (FR-1: Email / Phone OTP login)
CREATE TABLE IF NOT EXISTS otp_codes (
  id TEXT PRIMARY KEY,
  identifier TEXT NOT NULL, -- email or phone
  otp_code TEXT NOT NULL,
  purpose TEXT NOT NULL CHECK(purpose IN ('LOGIN', 'REGISTER', 'TWO_FACTOR')),
  attempts INTEGER DEFAULT 0,
  is_used INTEGER DEFAULT 0,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 4. Audit Log Table (FR-53: Tamper-evident, append-only audit log)
CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY,
  action_type TEXT NOT NULL,
  actor_id TEXT NOT NULL,
  actor_role TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  details TEXT NOT NULL,
  before_state_json TEXT,
  after_state_json TEXT,
  ip_address TEXT,
  timestamp TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 5. Affected Areas (PRD E6)
CREATE TABLE IF NOT EXISTS affected_areas (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  district TEXT NOT NULL,
  state TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  polygon_geojson TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 6. Resource Inventory & Needs Matrix (PRD E6 & FR-25)
CREATE TABLE IF NOT EXISTS area_needs (
  id TEXT PRIMARY KEY,
  area_id TEXT NOT NULL REFERENCES affected_areas(id) ON DELETE CASCADE,
  resource_type TEXT NOT NULL CHECK(resource_type IN ('FOOD', 'WATER', 'MEDICINE', 'SHELTER_KITS', 'BOATS', 'PERSONNEL')),
  required_units INTEGER NOT NULL DEFAULT 0,
  available_units INTEGER NOT NULL DEFAULT 0,
  reserved_units INTEGER NOT NULL DEFAULT 0,
  dispatched_units INTEGER NOT NULL DEFAULT 0,
  delivered_units INTEGER NOT NULL DEFAULT 0,
  pending_units INTEGER NOT NULL DEFAULT 0,
  last_verified TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(area_id, resource_type)
);

-- 7. Incidents & Reports (PRD E2, E3, FR-5, FR-10)
CREATE TABLE IF NOT EXISTS incidents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL CHECK(category IN ('FLOOD', 'CYCLONE', 'LANDSLIDE', 'HEATWAVE', 'FIRE', 'MEDICAL', 'ANIMAL_LIVESTOCK', 'OTHER')),
  status TEXT NOT NULL DEFAULT 'RECEIVED' CHECK(status IN ('RECEIVED', 'TRIAGE', 'UNDER_REVIEW', 'VERIFIED', 'UNVERIFIED', 'DUPLICATE', 'RESPONSE_ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'ESCALATED', 'REJECTED')),
  urgency TEXT NOT NULL CHECK(urgency IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
  priority_score INTEGER NOT NULL DEFAULT 50,
  why_priority_explanation TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  location_name TEXT NOT NULL,
  area_id TEXT REFERENCES affected_areas(id),
  people_affected INTEGER NOT NULL DEFAULT 1,
  sla_deadline_minutes INTEGER NOT NULL DEFAULT 30,
  is_simulated_drill INTEGER DEFAULT 0,
  assigned_team_id TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS incident_reports (
  id TEXT PRIMARY KEY,
  incident_id TEXT REFERENCES incidents(id) ON DELETE SET NULL,
  source_type TEXT NOT NULL CHECK(source_type IN ('CITIZEN_PWA', 'SMS_ADAPTER', 'CALL_112', 'SOCIAL_MONITOR', 'SYNTHETIC_DRILL')),
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  location_name TEXT NOT NULL,
  urgency TEXT NOT NULL,
  people_count INTEGER NOT NULL DEFAULT 1,
  contact_phone TEXT,
  is_anonymous INTEGER DEFAULT 0,
  media_urls_json TEXT DEFAULT '[]',
  idempotency_key TEXT UNIQUE,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 8. Verifications (FR-10, FR-12)
CREATE TABLE IF NOT EXISTS verifications (
  id TEXT PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  reviewer_id TEXT NOT NULL REFERENCES users(id),
  decision TEXT NOT NULL CHECK(decision IN ('VERIFIED', 'UNVERIFIED', 'DUPLICATE', 'ESCALATED')),
  reason TEXT NOT NULL,
  evidence_refs_json TEXT DEFAULT '[]',
  confidence REAL NOT NULL CHECK(confidence >= 0 AND confidence <= 1.0),
  unresolved_uncertainty TEXT,
  merged_into_incident_id TEXT REFERENCES incidents(id),
  timestamp TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 9. Rescue Teams & Assignments (FR-16, FR-17)
CREATE TABLE IF NOT EXISTS rescue_teams (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('NDRF', 'SDRF', 'CIVIL_DEFENSE', 'COMMUNITY_VOLUNTEER')),
  status TEXT NOT NULL DEFAULT 'IDLE' CHECK(status IN ('IDLE', 'ASSIGNED', 'EN_ROUTE', 'ON_SCENE', 'RESOLVING', 'RESTING')),
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  capacity INTEGER NOT NULL DEFAULT 10,
  skills_json TEXT DEFAULT '[]',
  contact_number TEXT NOT NULL,
  jurisdiction_area TEXT NOT NULL,
  assigned_incident_id TEXT REFERENCES incidents(id)
);

CREATE TABLE IF NOT EXISTS assignments (
  id TEXT PRIMARY KEY,
  incident_id TEXT NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  team_id TEXT NOT NULL REFERENCES rescue_teams(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'ASSIGNED' CHECK(status IN ('ASSIGNED', 'ACCEPTED', 'EN_ROUTE', 'ON_SCENE', 'RESOLVED', 'DECLINED')),
  assigned_at TEXT NOT NULL DEFAULT (datetime('now')),
  acknowledged_at TEXT,
  arrived_at_scene_at TEXT,
  resolved_at TEXT,
  notes TEXT,
  escalated_to_supervisor INTEGER DEFAULT 0
);

-- 10. Official Alerts (FR-49)
CREATE TABLE IF NOT EXISTS official_alerts (
  id TEXT PRIMARY KEY,
  source TEXT NOT NULL CHECK(source IN ('IMD', 'CWC', 'NDMA_SACHET', 'STATE_SDMA')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  severity TEXT NOT NULL CHECK(severity IN ('CRITICAL', 'WARN', 'INFO')),
  affected_region TEXT NOT NULL,
  issued_at TEXT NOT NULL,
  valid_until TEXT NOT NULL,
  cap_feed_id TEXT
);

-- 11. Hazard Predictions (FR-32, FR-33, FR-35)
CREATE TABLE IF NOT EXISTS hazard_predictions (
  id TEXT PRIMARY KEY,
  hazard_type TEXT NOT NULL CHECK(hazard_type IN ('FLOOD', 'HEAVY_RAIN', 'HEATWAVE', 'CYCLONE_EXPOSURE')),
  region_id TEXT NOT NULL REFERENCES affected_areas(id),
  region_name TEXT NOT NULL,
  time_window_hours INTEGER NOT NULL,
  risk_level TEXT NOT NULL CHECK(risk_level IN ('CRITICAL', 'HIGH', 'MODERATE', 'LOW')),
  calibrated_probability REAL NOT NULL,
  uncertainty_lower REAL NOT NULL,
  uncertainty_upper REAL NOT NULL,
  top_shap_factors_json TEXT NOT NULL,
  data_freshness_timestamp TEXT NOT NULL,
  model_version TEXT NOT NULL,
  is_available INTEGER DEFAULT 1,
  unavailable_reason TEXT
);

-- 12. PRD Part L Item 4 Tables:
-- (RumourReport, RoadClosure, EvacuationZone, ConsentRecord, DrillSession, MissingPersonRecord)
CREATE TABLE IF NOT EXISTS rumour_reports (
  id TEXT PRIMARY KEY,
  reported_claim TEXT NOT NULL,
  source_platform TEXT NOT NULL,
  counter_verification_status TEXT NOT NULL CHECK(counter_verification_status IN ('DEBUNKED', 'OFFICIALLY_CONFIRMED', 'INVESTIGATING')),
  official_correction_notice TEXT,
  timestamp TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS road_closures (
  id TEXT PRIMARY KEY,
  road_name TEXT NOT NULL,
  area_id TEXT NOT NULL REFERENCES affected_areas(id),
  cause TEXT NOT NULL CHECK(cause IN ('FLOODING', 'LANDSLIDE', 'BRIDGE_DAMAGE')),
  start_lat REAL NOT NULL,
  start_lng REAL NOT NULL,
  end_lat REAL NOT NULL,
  end_lng REAL NOT NULL,
  is_passable_for_emergency INTEGER DEFAULT 0,
  reported_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS evacuation_zones (
  id TEXT PRIMARY KEY,
  zone_name TEXT NOT NULL,
  area_id TEXT NOT NULL REFERENCES affected_areas(id),
  urgency_level TEXT NOT NULL CHECK(urgency_level IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
  safe_shelter_ids_json TEXT DEFAULT '[]',
  evacuation_routes_notes TEXT NOT NULL,
  pickup_points_notes TEXT,
  active_status TEXT NOT NULL DEFAULT 'STANDBY' CHECK(active_status IN ('STANDBY', 'EVACUATION_ORDERED', 'ALL_CLEAR'))
);

-- Missing Persons with Child Protection Controls (FR-41 & Part L #4)
CREATE TABLE IF NOT EXISTS missing_person_records (
  id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  age INTEGER NOT NULL,
  gender TEXT NOT NULL,
  last_known_location TEXT NOT NULL,
  last_seen_time TEXT NOT NULL,
  reported_by_user_id TEXT NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'SEARCHING' CHECK(status IN ('SEARCHING', 'FOUND_SAFE', 'AT_SHELTER', 'HOSPITALIZED')),
  shelter_id TEXT,
  is_child INTEGER DEFAULT 0,
  child_protection_consent_verified INTEGER DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Drill Session Table (Part L Item 7 & 4)
CREATE TABLE IF NOT EXISTS drill_sessions (
  id TEXT PRIMARY KEY,
  drill_name TEXT NOT NULL,
  scenario_type TEXT NOT NULL,
  started_at TEXT NOT NULL DEFAULT (datetime('now')),
  ended_at TEXT,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE', 'CONCLUDED')),
  is_watermarked_synthetic INTEGER DEFAULT 1,
  total_synthetic_incidents INTEGER DEFAULT 0
);

-- Consent Records (DPDP Act 2023 - FR-39 & Part L #4)
CREATE TABLE IF NOT EXISTS consent_records (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id),
  incident_id TEXT REFERENCES incidents(id),
  purpose TEXT NOT NULL CHECK(purpose IN ('EMERGENCY_RESCUE', 'DONATION_FCRA', 'MEDICAL_LOG', 'SHELTER_REGISTRATION')),
  dpdp_consent_captured INTEGER DEFAULT 1,
  ip_hash TEXT,
  timestamp TEXT NOT NULL DEFAULT (datetime('now'))
);
