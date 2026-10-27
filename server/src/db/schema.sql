-- ResQAI Relational Schema — strictly aligned with PRD Part G, Part E1, and Part L Item 4

PRAGMA foreign_keys = ON;

-- 1. Users Table (FR-1, FR-2, FR-4)
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  password_hash TEXT,
  role TEXT NOT NULL CHECK(role IN ('CITIZEN', 'ADMIN', 'GOVT_OFFICER', 'RESPONDER', 'NGO', 'DONOR', 'AUDITOR', 'VOLUNTEER', 'GOVERNMENT_MEMBER')),
  jurisdiction_region_id TEXT,
  preferred_language TEXT DEFAULT 'en',
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

-- 6b. Resource Allocations & Reservations (PRD E6, FR-26, FR-28, FR-29)
CREATE TABLE IF NOT EXISTS resource_allocations (
  id TEXT PRIMARY KEY,
  area_id TEXT NOT NULL REFERENCES affected_areas(id),
  resource_type TEXT NOT NULL CHECK(resource_type IN ('FOOD', 'WATER', 'MEDICINE', 'SHELTER_KITS', 'BOATS', 'PERSONNEL')),
  allocated_units INTEGER NOT NULL,
  source_type TEXT NOT NULL CHECK(source_type IN ('NGO_STOCK', 'DONOR_PLEDGE', 'CENTRAL_DEPOT', 'GOVT_BUFFER')),
  source_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'RESERVED' CHECK(status IN ('RESERVED', 'DISPATCHED', 'DELIVERED', 'CANCELLED')),
  priority_score REAL NOT NULL DEFAULT 50.0,
  score_factors_json TEXT DEFAULT '{}',
  allocated_by_user_id TEXT REFERENCES users(id),
  override_reason TEXT,
  delivery_confirmation_type TEXT CHECK(delivery_confirmation_type IN ('PHOTO', 'OTP', 'SIGNATURE')),
  delivery_confirmation_ref TEXT,
  delivered_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 6c. Donor Pledges & Smart Matching (PRD E6, FR-27, FR-31)
CREATE TABLE IF NOT EXISTS donor_pledges (
  id TEXT PRIMARY KEY,
  donor_name TEXT NOT NULL,
  donor_contact TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  offered_units INTEGER NOT NULL,
  target_area_id TEXT NOT NULL REFERENCES affected_areas(id),
  redirected_from_area_id TEXT REFERENCES affected_areas(id),
  redirect_reason TEXT,
  status TEXT NOT NULL DEFAULT 'PLEDGED' CHECK(status IN ('PLEDGED', 'ALLOCATED', 'FULFILLED', 'REJECTED')),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 6d. Resource Shortage & Expiry Alerts (PRD E6, FR-30)
CREATE TABLE IF NOT EXISTS resource_alerts (
  id TEXT PRIMARY KEY,
  area_id TEXT NOT NULL REFERENCES affected_areas(id),
  resource_type TEXT NOT NULL,
  alert_type TEXT NOT NULL CHECK(alert_type IN ('CRITICAL_SHORTAGE', 'EXPIRY_WARNING', 'OVER_SUPPLY_WARNING')),
  message TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
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
  cap_feed_id TEXT,
  updated_at TEXT
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

CREATE TABLE IF NOT EXISTS shelters (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  area_id TEXT REFERENCES affected_areas(id),
  location_name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  total_capacity INTEGER NOT NULL DEFAULT 500,
  occupied INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK(status IN ('OPEN', 'FULL', 'CLOSED')),
  facilities_json TEXT DEFAULT '["DRINKING_WATER", "MEDICAL_KIT", "CHARGING_STATION"]',
  contact_phone TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
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

-- 13. Phase 6: NGOs & KYC (FR-42, FR-46)
CREATE TABLE IF NOT EXISTS ngos (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  darpan_id TEXT,
  fcra_number TEXT,
  fcra_valid_until TEXT,
  fcra_verified INTEGER DEFAULT 0,
  tax_80g_number TEXT,
  tax_80g_valid_until TEXT,
  tax_80g_verified INTEGER DEFAULT 0,
  authorized_rep_name TEXT NOT NULL,
  authorized_rep_email TEXT NOT NULL,
  authorized_rep_phone TEXT NOT NULL,
  kyc_status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION' CHECK(kyc_status IN ('PENDING_VERIFICATION', 'APPROVED', 'REJECTED', 'SUSPENDED')),
  kyc_notes TEXT,
  documents_json TEXT DEFAULT '[]',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 14. Phase 6: Campaigns & Approval Gate (FR-43, FR-44)
CREATE TABLE IF NOT EXISTS campaigns (
  id TEXT PRIMARY KEY,
  ngo_id TEXT NOT NULL REFERENCES ngos(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL CHECK(category IN ('FLOOD', 'MEDICAL', 'SHELTER', 'FOOD', 'RECOVERY', 'GENERAL')),
  area_id TEXT NOT NULL REFERENCES affected_areas(id),
  target_amount_paise INTEGER NOT NULL,
  received_amount_paise INTEGER NOT NULL DEFAULT 0,
  committed_amount_paise INTEGER NOT NULL DEFAULT 0,
  spent_amount_paise INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'DRAFT' CHECK(status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'PAUSED', 'COMPLETED', 'REJECTED')),
  approved_by TEXT REFERENCES users(id),
  approved_at TEXT,
  beneficiary_count INTEGER DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 15. Phase 6: Donations & Razorpay Integration (FR-44, FR-45, FR-46, FR-47)
CREATE TABLE IF NOT EXISTS donations (
  id TEXT PRIMARY KEY,
  campaign_id TEXT NOT NULL REFERENCES campaigns(id),
  donor_name TEXT NOT NULL,
  donor_email TEXT NOT NULL,
  donor_phone TEXT,
  donor_pan TEXT,
  is_indian_citizen INTEGER NOT NULL DEFAULT 1,
  is_fcra_contribution INTEGER NOT NULL DEFAULT 0,
  amount_paise INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'INR',
  razorpay_order_id TEXT UNIQUE,
  razorpay_payment_id TEXT UNIQUE,
  razorpay_signature TEXT,
  status TEXT NOT NULL DEFAULT 'CREATED' CHECK(status IN ('CREATED', 'PAID', 'FAILED', 'REFUNDED')),
  tax_80g_issued INTEGER DEFAULT 0,
  tax_80g_receipt_no TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 16. Phase 6: Campaign Disbursements & Transparent Ledger (FR-44, FR-53)
CREATE TABLE IF NOT EXISTS campaign_disbursements (
  id TEXT PRIMARY KEY,
  campaign_id TEXT NOT NULL REFERENCES campaigns(id),
  purpose TEXT NOT NULL,
  amount_paise INTEGER NOT NULL,
  vendor_or_beneficiary TEXT NOT NULL,
  proof_receipt_url TEXT,
  disbursed_at TEXT NOT NULL DEFAULT (datetime('now')),
  audited_by TEXT REFERENCES users(id)
);

-- 17. Phase 6: Webhook Idempotency Registry (FR-45)
CREATE TABLE IF NOT EXISTS processed_webhooks (
  event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  payment_id TEXT,
  processed_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 18. Phase 7: Affected-Person Case Management (FR-38, FR-39, FR-40)
CREATE TABLE IF NOT EXISTS person_cases (
  id TEXT PRIMARY KEY,
  household_head_name TEXT NOT NULL,
  contact_phone TEXT,
  area_id TEXT NOT NULL REFERENCES affected_areas(id),
  shelter_id TEXT,
  household_size INTEGER NOT NULL DEFAULT 1,
  vulnerability_flags_json TEXT DEFAULT '[]',
  needs_summary TEXT,
  entitlement_ration_kits INTEGER NOT NULL DEFAULT 1,
  entitlement_water_litres INTEGER NOT NULL DEFAULT 20,
  entitlement_medical_kits INTEGER NOT NULL DEFAULT 0,
  received_ration_kits INTEGER NOT NULL DEFAULT 0,
  received_water_litres INTEGER NOT NULL DEFAULT 0,
  received_medical_kits INTEGER NOT NULL DEFAULT 0,
  caseworker_id TEXT REFERENCES users(id),
  caseworker_notes TEXT,
  dpdp_consent_captured INTEGER DEFAULT 1,
  is_merged INTEGER DEFAULT 0,
  merged_into_case_id TEXT,
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK(status IN ('OPEN', 'IN_ASSISTANCE', 'REHABILITATED', 'CLOSED')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 19. Phase 7: Case Assistance Logs (FR-38, FR-53)
CREATE TABLE IF NOT EXISTS case_assistance_logs (
  id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL REFERENCES person_cases(id) ON DELETE CASCADE,
  assistance_type TEXT NOT NULL CHECK(assistance_type IN ('RATION_KIT', 'WATER_SUPPLY', 'MEDICAL_AID', 'TEMPORARY_SHELTER', 'CASH_ASSISTANCE')),
  quantity INTEGER NOT NULL,
  distribution_point TEXT NOT NULL,
  distributed_by_user_id TEXT REFERENCES users(id),
  recipient_signature_or_otp TEXT,
  timestamp TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 20. Phase 7: SMS Gateway Inbound Messages & Parser Logs (FR-48, FR-50)
CREATE TABLE IF NOT EXISTS inbound_sms_messages (
  id TEXT PRIMARY KEY,
  sender_phone TEXT NOT NULL,
  raw_message TEXT NOT NULL,
  parsed_category TEXT,
  parsed_location TEXT,
  parsed_urgency TEXT,
  parsed_people_count INTEGER,
  parsed_needs TEXT,
  generated_incident_id TEXT REFERENCES incidents(id),
  delivery_status TEXT NOT NULL DEFAULT 'PROCESSED' CHECK(delivery_status IN ('RECEIVED', 'PROCESSED', 'PARSE_FAILED', 'DUPLICATE_IGNORED')),
  provider_error TEXT,
  received_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS voice_notes (
  id TEXT PRIMARY KEY,
  caller_phone TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  duration_seconds INTEGER DEFAULT 0,
  language TEXT NOT NULL DEFAULT 'hi-IN',
  transcript_text TEXT NOT NULL,
  confidence_score REAL NOT NULL DEFAULT 0.90,
  parsed_category TEXT,
  parsed_location TEXT,
  parsed_urgency TEXT,
  parsed_people_count INTEGER DEFAULT 1,
  generated_incident_id TEXT REFERENCES incidents(id),
  status TEXT NOT NULL DEFAULT 'PROCESSED' CHECK(status IN ('RECORDED', 'TRANSCRIBED', 'PROCESSED', 'FAILED')),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 21. PRD v2.0 Phase 1: Emergency Contacts (R-CIT-1)
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  relationship TEXT,
  is_primary INTEGER DEFAULT 0,
  is_otp_verified INTEGER DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 22. PRD v2.0 Phase 1: Saved Places (R-CIT-3, max 5 per user)
CREATE TABLE IF NOT EXISTS saved_places (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label TEXT NOT NULL, -- 'Home', 'Work', 'Family', 'Other'
  address TEXT NOT NULL,
  ward TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 23. PRD v2.0 Phase 1: User Devices & Remote Sign-Out (R-AUTH-4)
CREATE TABLE IF NOT EXISTS user_devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  device_name TEXT NOT NULL,
  user_agent TEXT,
  ip_address TEXT,
  last_active_at TEXT NOT NULL DEFAULT (datetime('now')),
  is_revoked INTEGER DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, device_id)
);

-- 24. PRD v2.0 Phase 5: Damage Claims, Verifications, Aid Plans & Appeals (R-DMG-1 to R-DMG-8)
CREATE TABLE IF NOT EXISTS damage_claims (
  id TEXT PRIMARY KEY,
  claimant_id TEXT NOT NULL REFERENCES users(id),
  disaster_id TEXT,
  loss_types TEXT NOT NULL,
  severity TEXT NOT NULL CHECK(severity IN ('MINOR', 'MODERATE', 'SEVERE', 'TOTAL_LOSS')),
  estimated_value REAL NOT NULL,
  household_size INTEGER NOT NULL,
  household_address TEXT NOT NULL,
  ward TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  incident_date TEXT NOT NULL,
  photo_urls TEXT DEFAULT '[]',
  video_urls TEXT DEFAULT '[]',
  documents_json TEXT DEFAULT '[]',
  evidence_strength_score REAL DEFAULT 0,
  evidence_suggestions TEXT DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'SUBMITTED' CHECK(status IN ('SUBMITTED', 'PENDING', 'ASSIGNED', 'UNDER_REVIEW', 'COMMUNITY_VERIFIED', 'OFFICIALLY_VERIFIED', 'PARTLY_VERIFIED', 'NOT_VERIFIABLE_NOW', 'NEEDS_FOLLOW_UP', 'AID_SANCTIONED', 'DELIVERED', 'APPEALED', 'REJECTED')),
  is_high_value INTEGER DEFAULT 0,
  assigned_volunteer_id TEXT REFERENCES users(id),
  assigned_officer_id TEXT REFERENCES users(id),
  is_offline_draft INTEGER DEFAULT 0,
  sync_status TEXT DEFAULT 'SYNCED',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS damage_verifications (
  id TEXT PRIMARY KEY,
  claim_id TEXT NOT NULL REFERENCES damage_claims(id) ON DELETE CASCADE,
  verifier_id TEXT NOT NULL REFERENCES users(id),
  verifier_role TEXT NOT NULL CHECK(verifier_role IN ('VOLUNTEER', 'GOVT_OFFICER', 'ADMIN')),
  conflict_of_interest_declared INTEGER NOT NULL DEFAULT 1,
  outcome TEXT NOT NULL CHECK(outcome IN ('VERIFIED', 'PARTLY_VERIFIED', 'NOT_VERIFIABLE_NOW', 'NEEDS_FOLLOW_UP')),
  truth_label TEXT NOT NULL CHECK(truth_label IN ('COMMUNITY_VERIFIED', 'OFFICIALLY_VERIFIED')),
  notes TEXT NOT NULL,
  photos_json TEXT DEFAULT '[]',
  gps_latitude REAL,
  gps_longitude REAL,
  gps_timestamp TEXT,
  verified_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS aid_plans (
  id TEXT PRIMARY KEY,
  claim_id TEXT NOT NULL REFERENCES damage_claims(id) ON DELETE CASCADE,
  sanctioning_officer_id TEXT NOT NULL REFERENCES users(id),
  aid_type TEXT NOT NULL CHECK(aid_type IN ('CASH_DBT', 'RELIEF_KIT', 'TEMPORARY_SHELTER', 'RECONSTRUCTION_REPAIR')),
  amount_paise INTEGER DEFAULT 0,
  items_description TEXT,
  delivery_status TEXT NOT NULL DEFAULT 'PENDING_DELIVERY' CHECK(delivery_status IN ('PENDING_DELIVERY', 'DELIVERED')),
  delivery_proof_type TEXT CHECK(delivery_proof_type IN ('RECEIVER_OTP', 'SIGNATURE_PLUS_PHOTO', NULL)),
  delivery_proof_url TEXT,
  delivery_otp TEXT,
  delivery_otp_verified INTEGER DEFAULT 0,
  delivered_by_user_id TEXT,
  delivered_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS claim_appeals (
  id TEXT PRIMARY KEY,
  claim_id TEXT NOT NULL REFERENCES damage_claims(id) ON DELETE CASCADE,
  claimant_id TEXT NOT NULL REFERENCES users(id),
  original_decision_officer_id TEXT NOT NULL,
  appeal_reason TEXT NOT NULL,
  additional_evidence_urls TEXT DEFAULT '[]',
  appealed_to_officer_id TEXT NOT NULL,
  appeal_status TEXT NOT NULL DEFAULT 'PENDING_REVIEW' CHECK(appeal_status IN ('PENDING_REVIEW', 'UPHELD', 'OVERTURNED')),
  appeal_notes TEXT,
  resolved_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 25. PRD v2.0 Phase 6: Volunteer & NGO Consoles, Funds & Transparency Hub (R-VOL, R-NGO, R-TRN)
CREATE TABLE IF NOT EXISTS volunteer_tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL CHECK(category IN ('RESCUE', 'FOOD_WATER', 'MEDICINE', 'SHELTER', 'DAMAGE_VERIFICATION')),
  area_id TEXT NOT NULL,
  ward TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  priority_score REAL DEFAULT 50,
  safety_level TEXT NOT NULL CHECK(safety_level IN ('SAFE', 'CAUTION', 'UNSAFE_TRAINED_ONLY')),
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK(status IN ('OPEN', 'ASSIGNED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED')),
  assigned_volunteer_id TEXT REFERENCES users(id),
  check_in_at TEXT,
  check_in_lat REAL,
  check_in_lng REAL,
  proof_url TEXT,
  completed_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS volunteer_impact_ledgers (
  id TEXT PRIMARY KEY,
  volunteer_id TEXT NOT NULL REFERENCES users(id),
  task_id TEXT REFERENCES volunteer_tasks(id),
  hours_logged REAL NOT NULL DEFAULT 0,
  items_delivered_count INTEGER DEFAULT 0,
  activity_type TEXT NOT NULL,
  area_name TEXT,
  verified_by_user_id TEXT,
  logged_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ngo_expenses (
  id TEXT PRIMARY KEY,
  ngo_id TEXT NOT NULL REFERENCES ngos(id),
  campaign_id TEXT REFERENCES campaigns(id),
  category TEXT NOT NULL CHECK(category IN ('FOOD_RATIONS', 'MEDICAL_SUPPLIES', 'SHELTER_MATERIALS', 'TRANSPORT', 'EQUIPMENT', 'OTHER')),
  amount_paise INTEGER NOT NULL,
  vendor_name TEXT NOT NULL,
  expense_date TEXT NOT NULL,
  area_id TEXT,
  receipt_url TEXT,
  is_unsupported INTEGER DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'APPROVED' CHECK(status IN ('APPROVED', 'UNSUPPORTED', 'Unsupported', 'FLAGGED')),
  approver_id TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ngo_coverage_areas (
  id TEXT PRIMARY KEY,
  ngo_id TEXT NOT NULL REFERENCES ngos(id),
  area_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('HELPED', 'IN_PROGRESS', 'NOT_YET_HELPED')),
  people_reached INTEGER DEFAULT 0,
  supplies_delivered_json TEXT DEFAULT '[]',
  proof_urls_json TEXT DEFAULT '[]',
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 26. PRD v2.0 Phase 7: Government Command & Connect-and-Inform (R-GOV-1 to R-GOV-10)
CREATE TABLE IF NOT EXISTS targeted_notices (
  id TEXT PRIMARY KEY,
  sender_officer_id TEXT NOT NULL REFERENCES users(id),
  target_group TEXT NOT NULL CHECK(target_group IN ('PUBLIC', 'RESCUE_TEAMS', 'DOCTORS_AND_HOSPITALS', 'NGOS', 'VOLUNTEERS', 'LOCAL_BODIES')),
  target_district TEXT NOT NULL,
  target_ward TEXT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  priority TEXT NOT NULL CHECK(priority IN ('NORMAL', 'URGENT', 'EMERGENCY')),
  total_targeted INTEGER DEFAULT 0,
  delivered_count INTEGER DEFAULT 0,
  failed_count INTEGER DEFAULT 0,
  sent_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS notice_deliveries (
  id TEXT PRIMARY KEY,
  notice_id TEXT NOT NULL REFERENCES targeted_notices(id) ON DELETE CASCADE,
  recipient_user_id TEXT NOT NULL REFERENCES users(id),
  recipient_name TEXT NOT NULL,
  recipient_role TEXT NOT NULL,
  recipient_district TEXT NOT NULL,
  recipient_phone TEXT,
  channel TEXT NOT NULL CHECK(channel IN ('PUSH', 'SMS', 'IN_APP')),
  status TEXT NOT NULL CHECK(status IN ('DELIVERED', 'FAILED')),
  delivered_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS government_sdrf_allocations (
  id TEXT PRIMARY KEY,
  district TEXT NOT NULL,
  fiscal_year TEXT NOT NULL,
  allocated_budget_paise INTEGER NOT NULL,
  released_budget_paise INTEGER NOT NULL,
  spent_budget_paise INTEGER NOT NULL DEFAULT 0,
  approved_by_officer_id TEXT NOT NULL REFERENCES users(id),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS government_datasets (
  id TEXT PRIMARY KEY,
  uploaded_by_officer_id TEXT NOT NULL REFERENCES users(id),
  dataset_name TEXT NOT NULL,
  district TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('PENDING_REVIEW', 'APPROVED', 'ROLLED_BACK')),
  total_rows INTEGER NOT NULL DEFAULT 0,
  duplicate_rows INTEGER NOT NULL DEFAULT 0,
  imported_records_json TEXT DEFAULT '[]',
  column_mapping_json TEXT DEFAULT '{}',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS inter_district_requests (
  id TEXT PRIMARY KEY,
  requesting_district TEXT NOT NULL,
  target_district TEXT NOT NULL,
  requesting_officer_id TEXT NOT NULL REFERENCES users(id),
  resource_type TEXT NOT NULL,
  requested_quantity INTEGER NOT NULL,
  urgency TEXT NOT NULL CHECK(urgency IN ('ROUTINE', 'HIGH', 'CRITICAL')),
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING', 'APPROVED', 'DISPATCHED', 'REJECTED')),
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 27. PRD v2.0 Phase 8: Research Features (Silent Zones & Prediction Feedback)
CREATE TABLE IF NOT EXISTS silent_zone_events (
  id TEXT PRIMARY KEY,
  area_id TEXT NOT NULL,
  ward TEXT,
  baseline_rate_per_hour REAL NOT NULL,
  observed_rate_per_hour REAL NOT NULL,
  drop_percentage REAL NOT NULL,
  hazard_status TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'SUSPECTED_BLACKOUT',
  flagged_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ai_prediction_feedback (
  id TEXT PRIMARY KEY,
  prediction_id TEXT NOT NULL,
  responder_id TEXT NOT NULL REFERENCES users(id),
  is_accurate INTEGER NOT NULL,
  field_ground_truth TEXT NOT NULL,
  water_depth_observed_m REAL,
  feedback_at TEXT NOT NULL DEFAULT (datetime('now'))
);



