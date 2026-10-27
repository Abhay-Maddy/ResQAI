# ResQAI — Unified Disaster Response & Transparent Relief Platform (PRD v2.0)

[![Backend Tests](https://img.shields.io/badge/Backend%20Tests-133%2F133%20Passing-brightgreen)](docs/test_report.md)
[![Frontend Tests](https://img.shields.io/badge/Frontend%20Tests-28%2F28%20Passing-brightgreen)](docs/test_report.md)
[![Architecture](https://img.shields.io/badge/Architecture-Node.js%20%7C%20SQLite%20WAL%20%7C%20Flutter-blue)](docs/architecture.md)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)](docker-compose.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

> **ResQAI** is a unified, offline-first disaster response and transparent relief coordination platform built for **Citizens**, **Volunteers**, **NGOs**, and **Government Authorities**.  
> Designed for high-stress disaster operations with strict adherence to human-in-the-loop safety, non-PII privacy protection, tamper-evident financial ledgers, and explainable AI.

---

## ⚠️ Core Operational Principles

1. **AI Only Assists, Humans Decide:** AI models only score, cluster, flag anomalies, and suggest allocations. A named, accountable human verifies claims, sanctions aid, authorizes budgets, and dispatches rescue battalions.
2. **Fail Visibly:** Telemetry older than 4 hours triggers `STALE DATA` safe mode. Sudden drops in emergency reporting (>75%) during active hazards are flagged as `COMMUNICATIONS_BLACKOUT_SUSPECTED` — never marked safe. Compromised routes are stamped `CAUTION: NOT VERIFIED SAFE`.
3. **Strict Non-PII Exposure:** Aggregates $< 5$ appear as `"fewer than 5"`. Public views omit victim phone numbers and exact street addresses.
4. **Integer Paise Accounting:** All relief grants, SDRF allocations, and NGO campaign donations are calculated and stored in integer paise with append-only hash chains.

---

## 🚀 Quick Start

### Option A: Docker Compose (Recommended)
Spin up the entire backend and database with persistent storage in one command:
```bash
docker compose up --build
```
API will be live at `http://localhost:5000/api/v1/system/health`.

### Option B: Local Development
```bash
# 1. Install and start server
cd server
npm install
npm run build
npm start

# 2. Run backend automated verification suite (133 tests)
npm test

# 3. In root directory, run frontend automated verification suite (28 tests)
cd ..
flutter test
```

---

## 🔐 Pre-Seeded Test Credentials

| Role | Phone | Password | Quick PIN | Access Scope |
|---|---|---|---|---|
| **Master Admin** | `+919999900000` | `Admin@ResQAI2026` | `1234` | Omni-Dashboard Switcher, System Controls |
| **Citizen (A)** | `+919876543210` | `Citizen@123` | `1234` | SOS Wizard, Claims, Status Tracking |
| **Volunteer (A)** | `+919876543211` | `Volunteer@123` | `1234` | Local Help Board, Community Verification |
| **NGO Lead** | `+919876543212` | `NgoLead@123` | `1234` | Campaigns, Integer Ledger, Relief Tasks |
| **Govt Officer** | `+919876543213` | `Officer@123` | `1234` | Official Verification, Sanctions, Command |

---

## 📦 PRD v2.0 Implementation Matrix (100% Complete)

| Phase | Description | Key Modules & Endpoints | Test Suite |
|---|---|---|:---:|
| **Phase 1** | Accounts, Persistent Login & RBAC Gating | 30-day persistent session, rotating refresh tokens, 4-digit PIN unlock, 5-attempt lockout, re-auth challenges, role gating (Citizen, Volunteer, NGO, Govt, Master Admin Omni-Switcher) | `phase1_prd_v2.test.ts` (14/14) |
| **Phase 2** | Citizen Core & SOS Wizard | Wizard intake, need tiles, voice notes, idempotency keys, auto-translation preserving original Hindi, anti-spam repeat source detector, emergency contact SMS | `phase2_prd_v2.test.ts` (8/8) |
| **Phase 3** | Operations & Dispatcher Workflow | Verification queue with reversible unmerge, status history audit, team assignment, responder state machine, supervisor escalation badge, live shelter capacity board | `phase3_prd_v2.test.ts` (10/10) |
| **Phase 4** | Warnings Matched to Location | Official feeds (IMD, NDMA_SACHET, GDACS), ML flood baseline inference, Platt calibration, SHAP attribution, 3.5σ anomaly gating, >4h stale telemetry gating, saved-places matching, 4-eyes approval gate | `phase4_prd_v2.test.ts` (11/11) |
| **Phase 5** | Damage Claims, Multi-Tier Verification & Aid | Completeness meter (never auto-rejects), volunteer conflict-of-interest check, community vs official truth labels, delivery proof gate (OTP / signature photo), appeals to independent officer, <5 privacy masking | `phase5_prd_v2.test.ts` (10/10) |
| **Phase 6** | Volunteer/NGO Consoles & Transparency | Local help board (`UNSAFE_TRAINED_ONLY`), impact ledger, Darpan ID check, campaign approval gate, Razorpay test mode idempotency, dynamic public balance (`received - spent`), unsupported expense flags, anti-duplication double-allocation lock | `phase6_prd_v2.test.ts` (7/7) |
| **Phase 7** | Government Command & Watch Panel | Jurisdiction crisis overview, Connect-and-Inform role-targeted notices, delivered/failed tracking, watch panel detecting ignored areas, NGO suspension with recorded reason, dataset import with review/rollback, inter-district mutual aid | `phase7_prd_v2.test.ts` (7/7) |
| **Phase 8** | Research Features & Explainability | What-if priority delta with stored formula, silent-zone blackout alert (>75% drop during active hazard), situation summary synthesized strictly from relational facts, route caution ("NOT VERIFIED SAFE"), responder feedback loop | `phase8_prd_v2.test.ts` (8/8) |
| **Phase 9** | Low-Bandwidth SMS & Voice Gateway | Structured inbound SMS triage, 5-minute anti-spam deduplication (`DUPLICATE_IGNORED`), Speech-to-Text voice note transcription preserving raw audio link for dispatchers, 160-char SMS payload formatter | `phase9_prd_v2.test.ts` (7/7) |

---

## 📚 Technical Documentation

- **[System Architecture & ER Diagram](docs/architecture.md)** — Architectural component diagram, data flows, and full Mermaid ER diagram.
- **[API Specification](docs/api_documentation.md)** — Comprehensive REST API reference across all v1 route controllers.
- **[Automated Test Verification Report](docs/test_report.md)** — 161 automated tests (133 backend + 28 frontend) passing 100% green.
- **[System Limitations & Risk Register](docs/limitations.md)** — Disclosure of non-goals, scientific refusals, and operational constraints.
- **[AI Model Card](docs/model-card.md)** — Calibrated hydrologic early warning baseline, SHAP explainability, and ground-truth feedback.
- **[Evaluator Demo Script](docs/demo_script.md)** — Step-by-step role-based demonstration script for evaluators and judges.
