
# ResQAI — Unified Disaster Response & Transparent Relief Platform

![Backend Tests](https://img.shields.io/badge/Backend_Tests-133%2F133_Passing-brightgreen)
![Frontend Tests](https://img.shields.io/badge/Frontend_Tests-28%2F28_Passing-brightgreen)
![Architecture](https://img.shields.io/badge/Node.js%20%7C%20SQLite%20WAL%20%7C%20Flutter-blue)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)
![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)

> **ResQAI** is an offline-first disaster response and transparent relief coordination platform built for **Citizens, Volunteers, NGOs, and Government Authorities**.
>
> It combines emergency reporting, responder coordination, AI-assisted hazard intelligence, relief distribution, and financial transparency in a unified platform designed for high-stress disaster operations.

---

## 🚀 Core Features

- **Emergency SOS & Citizen Support:** Guided emergency reporting, voice notes, Hindi translation, duplicate detection, and status tracking.
- **Disaster Operations & Dispatch:** Incident verification, responder assignment, shelter capacity monitoring, and escalation workflows.
- **AI-Powered Hazard Intelligence:** Location-aware warnings, flood-risk inference, anomaly detection, SHAP explainability, and stale-data safeguards.
- **Damage Claims & Relief Distribution:** Multi-tier verification, appeals, delivery evidence, and privacy-preserving public summaries.
- **Volunteer & NGO Coordination:** Local help board, relief campaigns, task management, and donation tracking.
- **Transparent Financial Ledger:** Integer-paise accounting, hash-linked records, expenditure tracking, and duplicate-allocation protection.
- **Government Command Dashboard:** Jurisdiction-level monitoring, official verification, targeted notices, and inter-district mutual-aid coordination.
- **Low-Bandwidth Communication:** SMS triage, duplicate-message suppression, speech-to-text workflows, and SMS-friendly alerts.
- **Explainable AI & Research Tools:** Priority analysis, what-if scenarios, communication-blackout detection, and fact-based situation summaries.

## 🛡️ Core Operational Principles

1. **Human-in-the-Loop AI:** AI assists with scoring, clustering, anomaly detection, and recommendations. Authorized humans retain responsibility for consequential decisions.
2. **Fail Visibly:** Telemetry older than four hours triggers `STALE DATA`. Reporting drops exceeding 75% during active hazards can trigger `COMMUNICATIONS_BLACKOUT_SUSPECTED`. Routes are marked `CAUTION: NOT VERIFIED SAFE` when appropriate.
3. **Privacy by Design:** Public views omit victim phone numbers and exact street addresses. Aggregates below five are displayed as `fewer than 5`.
4. **Financial Integrity:** Relief grants, allocations, and donations use integer paise and append-only, hash-linked ledger records.

## 🏗️ Technology Stack

| Component | Technology |
|---|---|
| Mobile Application | Flutter, Dart |
| Backend | Node.js |
| Database | SQLite with WAL |
| API | REST API (`/api/v1`) |
| AI/ML | Risk inference, anomaly detection, explainability |
| Payments | Razorpay test mode |
| Communication | SMS and speech-to-text integrations |
| Deployment | Docker, Docker Compose |
| Testing | Backend automated tests, Flutter tests |

## ⚡ Quick Start

### Option A: Docker Compose (Recommended)

```bash
docker compose up --build
```

API health check:

`http://localhost:5000/api/v1/system/health`

### Option B: Local Development

**1. Start the backend**

```bash
cd server
npm install
npm run build
npm start
```

**2. Run backend tests**

```bash
npm test
```

**3. Run Flutter tests**

From the project root:

```bash
flutter pub get
flutter test
```

## 🔐 Demo Credentials

For local development and evaluation only.

| Role | Phone | Password |
|---|---|---|
| Master Admin | `+919999900000` | `Admin@ResQAI2026` |
| Citizen | `+919876543210` | `Citizen@123` |
| Volunteer | `+919876543211` | `Volunteer@123` |
| NGO Lead | `+919876543212` | `NgoLead@123` |
| Government Officer | `+919876543213` | `Officer@123` |

**Quick PIN:** `1234` for the supplied demo accounts.

> **Security:** Replace demo credentials and secrets before deployment. Never use these credentials in a publicly accessible production environment.

## 🧪 Test Results

The current project documentation reports **161 passing automated tests**.

| Test Suite | Results |
|---|---:|
| Backend | 133/133 |
| Flutter Frontend | 28/28 |
| **Total** | **161/161** |

See the [Automated Test Report](docs/test_report.md) for details.

## 📚 Documentation

- [System Architecture & ER Diagram](docs/architecture.md)
- [API Specification](docs/api_documentation.md)
- [Automated Test Report](docs/test_report.md)
- [System Limitations & Risk Register](docs/limitations.md)
- [AI Model Card](docs/model-card.md)
- [Evaluator Demo Script](docs/demo_script.md)

## 📋 Implementation Status

**PRD Version:** 2.0

The implementation matrix covers nine phases:

1. Accounts, Persistent Login & Role-Based Access Control
2. Citizen Core & SOS Wizard
3. Operations & Dispatcher Workflow
4. Location-Aware Hazard Warnings
5. Damage Claims, Verification & Aid
6. Volunteer/NGO Consoles & Transparency
7. Government Command & Monitoring
8. Research Features & Explainability
9. Low-Bandwidth SMS & Voice Gateway

Refer to the project documentation and test reports for implementation details and verification.


**ResQAI — Coordinating response. Protecting communities. Making relief accountable.**
