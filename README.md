# ResQAI — Unified Disaster Response & Transparent Relief Platform (PRD v3.0)

[![Backend Tests](https://img.shields.io/badge/Backend%20Tests-146%2F146%20Passing-brightgreen)](docs/test_report.md)
[![Frontend Tests](https://img.shields.io/badge/Frontend%20Tests-35%2F35%20Passing-brightgreen)](docs/test_report.md)
[![Architecture](https://img.shields.io/badge/Architecture-Node.js%20%7C%20SQLite%20WAL%20%7C%20Flutter-blue)](docs/architecture.md)
[![PRD Version](https://img.shields.io/badge/PRD-v3.0%20Verified-blueviolet)](docs/AUDIT.md)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)](docker-compose.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

> **ResQAI** is a unified, offline-first disaster response and transparent relief coordination platform built for **Citizens, Volunteers, NGOs, and Government Authorities**.  
> Designed for high-stress disaster operations with strict adherence to human-in-the-loop safety, non-PII privacy protection, tamper-evident financial ledgers, and explainable AI.

---

## 🚀 Core Features

- **Emergency SOS & Citizen Support:** Guided emergency reporting, voice notes, Hindi translation, duplicate detection, and real-time status tracking.
- **Disaster Operations & Dispatch:** Incident verification, responder assignment, shelter capacity monitoring, and automated escalation workflows.
- **AI-Powered Hazard Intelligence:** Location-aware warnings, flood-risk inference, anomaly detection, SHAP explainability, and stale-data safeguards.
- **Damage Claims & Relief Distribution:** Multi-tier verification, appeals, delivery evidence, and privacy-preserving public summaries.
- **Volunteer & NGO Coordination:** Local help board, relief campaigns, task management, and donation tracking.
- **Transparent Financial Ledger:** Integer-paise accounting, hash-linked records, expenditure tracking, and duplicate-allocation protection.
- **Government Command Dashboard:** Jurisdiction-level monitoring, official verification, targeted notices, and inter-district mutual-aid coordination.
- **Low-Bandwidth Communication:** SMS triage, duplicate-message suppression, speech-to-text workflows, and SMS-friendly alerts.
- **Explainable AI & Research Tools:** Priority analysis, what-if scenarios, communication-blackout detection, and fact-based situation summaries.
- **In-App Auto-Update & Three-Line Navigation:** Streamlined version check and reactive updates with an intuitive 3-line drawer menu.

---

## 🛡️ Core Operational Principles

1. **Human-in-the-Loop AI:** AI models assist with scoring, clustering, anomaly detection, and recommendations. Authorized humans retain responsibility for consequential decisions.
2. **Fail Visibly:** Telemetry older than 4 hours triggers `STALE DATA` safe mode. Sudden drops in emergency reporting (>75%) during active hazards are flagged as `COMMUNICATIONS_BLACKOUT_SUSPECTED` — never marked safe. Compromised routes are stamped `CAUTION: NOT VERIFIED SAFE`.
3. **Strict Non-PII Exposure:** Aggregates $< 5$ appear as `"fewer than 5"`. Public views omit victim phone numbers and exact street addresses.
4. **Integer Paise Accounting:** All relief grants, SDRF allocations, and NGO campaign donations are calculated and stored in integer paise with append-only hash chains.
5. **Persistent Life-Safety:** The red 112 emergency banner persists across all views (*"If life is in immediate danger, call 112"*).

---

## 📦 PRD v3.0 Feature Matrix (Verified 100% Green)

| Section | Feature Area | Key Implementation & Requirements | Verification Status |
|---|---|---|:---:|
| **Section 1** | Code Audit & Decontamination | Systematic codebase cleanup, removing placeholder dead files and dead ends (`docs/AUDIT.md`, `docs/CLEANUP_REPORT.md`, `docs/KEPT_ON_PURPOSE.md`) | Verified Clean |
| **Section 2** | Maps & Live Location | User blue dot with pulsing accuracy ring, recenter button, reverse geocoded banner ("Near: ..."), location fallback banner, shelter/hospital/unit overlays | `MAP-1..8` (Verified) |
| **Section 3** | Live Weather Telemetry | `GET /api/v1/weather?lat=&lon=`, Open-Meteo keyless fallback, 10-minute coordinate cache, feels-like, wind, humidity, rain probability, severe alerts, stale badge | `WX-1..5` (Verified) |
| **Section 4 & 5** | SOS Enhancements & Two Ways to Help | Side-by-side: Big Instant SOS (double confirmation) & Fill Emergency Form; parallel SMS delivery receipts (Admin + Contacts), 1-tap "I pressed by mistake" (`/cancel-accidental`) | `SOS-1..14` (Verified) |
| **Section 6** | Notifications Pipeline | In-app bell with real unread badge count, device registration, and multi-channel test trigger (`/api/v1/notifications/test` delivering across In-App, Push & SMS) | `NTF-1..10` (Verified) |
| **Section 7** | OTP Engine & Verification | 6-digit numeric OTP, HMAC-SHA256 hashed storage, 5-minute expiry, single-use invalidation, 30s resend cooldown, 5/hour cap, 15-minute lock on 5 failures | `OTP-1..9` (Verified) |
| **Section 8** | Protected Routes & Route Guards | Client-side & server-side route guards, public route whitelist (`/`, `/login`, `/transparency*`, `/citizen/sos`), role privilege enforcement (`AccessDeniedScreen` 403), `Cache-Control: no-store` | `SEC-1..6` (Verified) |
| **Section 9** | Delete Account Danger Zone | DPDP data export (`/api/v1/auth/export-data`), Admin Handover check for NGO/Govt, Password + OTP + typing DELETE, 7-day grace period, non-destructive audit anonymization (`ANON_USER_xxxx`) | `DEL-1..8` (Verified) |
| **Section 10** | UI/UX Tokens & 112 Banner | Exact PRD tokens (`#0B1F3A`, `#14233B`, `#EF4444`, `#3B82F6`, `#10B981`), 48px touch targets, 12px radii, persistent top red 112 safety strip | `UX-1..14` (Verified) |

---

## 🧪 Automated Test Results

The project test suite reports **181 passing automated tests**.

| Test Suite | Results | Status |
|---|---:|:---:|
| Backend (Node.js / TypeScript) | 146 / 146 | Passing |
| Flutter Frontend (Widgets, Flows, Routing) | 35 / 35 | Passing |
| **Total** | **181 / 181** | **100% Green** |

See the [Automated Test Report](docs/test_report.md) for details.

---

## 🚀 Quick Start

### 1. Prerequisites
- **Node.js**: v18+ (tested on Node 20/22/24)
- **Flutter SDK**: v3.13+ or higher
- **SQLite3**: Bundled automatically via `better-sqlite3`

### 2. Backend Server Setup
```bash
cd server
npm install
npm run build
npm start
```
The server will start at `http://localhost:5000` with the SQLite database pre-seeded with test roles and coordinates.

### 3. Frontend App Setup
```bash
# In the root repository folder
flutter pub get
flutter run -d chrome       # For Web
# or
flutter run                 # For Android / Desktop
```

---

## 📚 Technical Documentation

- **[Code Audit & Known Bug Catalog](docs/AUDIT.md)** — Audit of bugs, root causes, severity, and resolution status.
- **[Code Cleanup & Decontamination Report](docs/CLEANUP_REPORT.md)** — Catalog of audited assets, safe removals, and dev adapter configurations.
- **[Explicitly Kept on Purpose](docs/KEPT_ON_PURPOSE.md)** — Rationale for all retained demonstration modules, mock telephonies, and offline datasets.
- **[System Architecture & ER Diagram](docs/architecture.md)** — Architectural component diagram, data flows, and full Mermaid ER diagram.
- **[API Specification](docs/api_documentation.md)** — Comprehensive REST API reference across all v1 route controllers.
- **[System Limitations & Risk Register](docs/limitations.md)** — Disclosure of non-goals, scientific refusals, and operational constraints.
- **[AI Model Card](docs/model-card.md)** — Calibrated hydrologic early warning baseline, SHAP explainability, and ground-truth feedback.
- **[Evaluator Demo Script](docs/demo_script.md)** — Step-by-step role-based demonstration script for evaluators and judges.

---

**ResQAI — Coordinating response. Protecting communities. Making relief accountable.**
