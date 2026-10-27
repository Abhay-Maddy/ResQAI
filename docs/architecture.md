# ResQAI Architecture & Data Model (PRD v2.0)

## 1. High-Level System Architecture

```mermaid
flowchart TD
    subgraph Clients["Clients & Field Ingestion Channels"]
        CIT["Citizen Mobile / PWA<br/>(SOS Wizard, Damage Claims, Status Tracking)"]
        VOL["Volunteer Mobile Console<br/>(Help Board, Field Verification, Impact)"]
        NGO["NGO Console & Explorer<br/>(Needs Claiming, Expense Logging, Ledgers)"]
        GOV["Government Command Center<br/>(District Oversight, Broadcasts, SDRF Accounting)"]
        SMS["SMS & WhatsApp Gateway<br/>(160-Char Low-Bandwidth Inbound Reports)"]
        VOICE["112 Voice Note Ingestion<br/>(Hindi/Regional STT & Raw Audio Archival)"]
    end

    subgraph Gateway["API Gateway & Middleware Layer"]
        CORS["CORS & Rate Limiter"]
        AUTH["Argon2id + JWT + Rotating Refresh Tokens<br/>(30-Day Session, 4-Digit PIN, 5-Attempt Lockout)"]
        RBAC["Role-Based Access Control (RBAC)<br/>(Citizen, Volunteer, NGO, Govt, Master Admin)"]
        DPDP["DPDP Privacy Minimization Filter<br/>(Masking <5 Counts, Strict Reference IDs)"]
    end

    subgraph CoreServices["ResQAI Application Services (Node.js / Express / TypeScript)"]
        INC_SRV["Incident Triage & Idempotent Ingestion Engine"]
        VERIF_SRV["Multi-Tier Verification Service<br/>(Community Verified / Officially Verified)"]
        PRIO_ENG["Deterministic Priority Score & What-If Engine"]
        DISP_SRV["Dispatch & Safe Routing Engine<br/>(Route Caution: 'NOT VERIFIED SAFE')"]
        FLOOD_ML["Flood Early Warning & Calibration Service<br/>(Platt Calibration, SHAP Attribution, 3.5σ Anomaly Guard)"]
        SZ_SRV["Silent-Zone Blackout Detector<br/>(>75% Drop Flagged as Blackout, Never Safe)"]
        SITREP_SRV["Relational Fact Synthesizer<br/>(Zero Synthetic Hallucinations)"]
        FIN_SRV["Double-Entry Ledger & Anti-Duplication Locking<br/>(Integer Paise Math, Razorpay Idempotency)"]
        GOV_SRV["Connect-and-Inform & Watch Panel<br/>(Targeted Role-Filtered Broadcasts)"]
    end

    subgraph DataStore["Persistence & Storage Engine"]
        SQLITE[("SQLite Database in WAL Mode<br/>(Full Foreign Keys, Strict Constraints)")]
        AUDIT[("Tamper-Evident SHA-256 Hash Chain Audit Logs")]
        MEDIA[("Static Audio & Photo Evidence Store")]
    end

    Clients --> Gateway
    Gateway --> CoreServices
    CoreServices --> DataStore
```

---

## 2. Entity-Relationship (ER) Diagram

```mermaid
erDiagram
    USERS ||--o{ USER_SESSIONS : maintains
    USERS ||--o{ EMERGENCY_CONTACTS : registers
    USERS ||--o{ SAVED_PLACES : configures
    USERS ||--o{ INCIDENTS : reports
    USERS ||--o{ DAMAGE_CLAIMS : files
    USERS ||--o{ DONATIONS : contributes

    INCIDENTS ||--o{ INCIDENT_REPORTS : aggregates
    INCIDENTS ||--o{ VERIFICATIONS : receives
    INCIDENTS ||--o{ ASSIGNMENTS : triggers
    INCIDENTS ||--o{ INCIDENT_STATUS_HISTORY : audits

    RESCUE_TEAMS ||--o{ ASSIGNMENTS : dispatched_to

    DAMAGE_CLAIMS ||--o{ DAMAGE_VERIFICATIONS : verified_by
    DAMAGE_CLAIMS ||--o{ AID_PLANS : sanctioned_under
    DAMAGE_CLAIMS ||--o{ CLAIM_APPEALS : appealed_with

    NGOS ||--o{ CAMPAIGNS : runs
    CAMPAIGNS ||--o{ DONATIONS : collects
    CAMPAIGNS ||--o{ CAMPAIGN_DISBURSEMENTS : spends
    NGOS ||--o{ NGO_EXPENSES : logs
    NGOS ||--o{ NGO_COVERAGE_AREAS : claims

    AFFECTED_AREAS ||--o{ AREA_NEEDS : identifies
    AREA_NEEDS ||--o{ RESOURCE_ALLOCATIONS : fulfills
    AFFECTED_AREAS ||--o{ ROAD_CLOSURES : tracks
    AFFECTED_AREAS ||--o{ EVACUATION_ZONES : designates
    AFFECTED_AREAS ||--o{ SHELTERS : operates

    OFFICIAL_ALERTS ||--o{ ALERT_DELIVERIES : dispatches
    TARGETED_NOTICES ||--o{ NOTICE_DELIVERIES : transmits

    USERS {
        string id PK
        string phone UK
        string name
        string role
        string approval_status
        string pin_hash
        int failed_pin_attempts
        int locked_until
    }

    INCIDENTS {
        string id PK
        string category
        string status
        string urgency
        int priority_score
        float latitude
        float longitude
        string location_name
        int people_affected
    }

    DAMAGE_CLAIMS {
        string id PK
        string claimant_id FK
        string severity
        float estimated_value
        string ward
        string status
        float evidence_strength_score
        int is_high_value
    }

    AID_PLANS {
        string id PK
        string claim_id FK
        int cash_amount_paise
        string aid_type
        string delivery_otp
        string status
    }

    SHELTERS {
        string id PK
        string name
        string area_id FK
        int total_capacity
        int occupied
        string status
    }

    SILENT_ZONE_EVENTS {
        string id PK
        string area_id
        float baseline_rate_per_hour
        float observed_rate_per_hour
        float drop_percentage
        string status
    }

    VOICE_NOTES {
        string id PK
        string caller_phone
        string audio_url
        string transcript_text
        float confidence_score
        string generated_incident_id FK
        string status
    }
```

---

## 3. Core Architectural Guardrails

1. **Human-in-the-Loop Imperative:** AI algorithms only score, classify, and surface potential duplicates or blackouts. Named authorized humans make all triage dispatch, verification, entitlement sanctions, and payout decisions.
2. **DPDP Compliance & Data Minimization:** Public statistics aggregate counts $< 5$ as "fewer than 5". Reference IDs are randomized without exposing citizen phone numbers or full home addresses.
3. **Integer Arithmetic:** All monetary transactions (donations, SDRF grants, damage payouts) are computed and stored as integer paise to eliminate floating-point rounding errors.
4. **Idempotency Everywhere:** Payment webhooks, incident submissions, and SMS gateways employ strict de-duplication locks to guarantee at-most-once processing.

