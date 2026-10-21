# ResQAI — Emergency Response & Needs-Based Relief Coordination Platform

> **Vision:** One trusted platform that predicts disaster risk, verifies emergencies, coordinates rescue, and sends the *right relief to the right place*, with every rupee and every decision auditable.  
> **PRD Source of Truth:** `ResQAI PRD v1.0` (FR-1 through FR-54).

---

## 🚀 Execution Roadmap & Phase Status Tracker

| Phase | Milestone / Focus | Status | Key Deliverables & Exit Criteria |
| :--- | :--- | :---: | :--- |
| **Phase 0** | **PRD, Repo, Design System, Seed Plan** |  **COMPLETED** | Design tokens (PRD H2), i18n (FR-1/Part L#1), TruthBadge (Part L#2), unified types (Part G & L#4), Model Card & Limitations (Part L#9), Seed plan (E6). |
| **Phase 1** | **Auth, RBAC, DB & Core Backend** |  **COMPLETED** | Argon2id hashing (FR-1), Refresh-token rotation & session revocation (FR-1), 7 Roles with jurisdiction scopes (FR-2), Server-side authorization (FR-3), 2FA gate (FR-4), SQLite/Postgres schema (Part G & L#4), Tamper-evident AuditLog (FR-53). **Exit criteria: Role tests green (8/8 passed)**. |
| **Phase 2** | **Reporting, Verification & Command Dashboard** | ⏳ *Next* | Citizen SOS form (3-step), offline queue, verification workflow with AI duplicate detection, Admin command dashboard with real DB metrics. |
| **Phase 3** | **Live GIS Map, Layers & Responder View** | ⏳ *Upcoming* | Multi-layer map (Official, ML zones, Incidents, Teams, Shelters), road closure routing, field responder mobile view. |
| **Phase 4** | **Needs Matrix & Smart Donation Allocation** | ⏳ *Upcoming* | Signature feature: Needs matrix, shortage detector, donor redirect engine (Area A/B/C worked example). |
| **Phase 5** | **Flood ML Early Warning & Monitoring** | ⏳ *Upcoming* | XGBoost flood baseline, SHAP explainability factors, data freshness gating, monitoring curves. |
| **Phase 6** | **NGO Portal, Razorpay Test Donations & PWA Sync** | ⏳ *Upcoming* | NGO KYC & campaign approval, Razorpay test mode webhook verification, full offline PWA service worker. |
| **Phase 7** | **Case Management, SMS Adapter, Missing Persons & Drills** | ⏳ *Upcoming* | Field-level masking, DPDP consent logs, SMS parser adapter, missing person registry, synthetic drill simulation. |

---

## 🎨 Phase 0 Deliverables Summary

1. **Design System & Tokens (`client/src/design-system/tokens.css`):**
   - Exact color tokens from PRD H2: `navy-900`, `surface`, `card`, `text`, `info`, `safe`, `warn`, `critical`, `neutral`, `ml`.
   - Light and Dark theme modes with full contrast (WCAG 2.2 AA).
   - 8-pt spacing grid, 12px cards, 8px inputs, 48px minimum touch targets.
2. **i18n Localization Engine (`client/src/i18n/`):**
   - Full Hindi (`hi.json`) and English (`en.json`) string files. No hardcoded text.
   - `I18nProvider` with persistent language preference and font switching (Inter / Noto Sans Devanagari).
3. **Truth-Label Badge Component (`client/src/components/TruthBadge.tsx`):**
   - 6 standardized truth badges: `OFFICIAL WARNING`, `ML ASSESSMENT`, `VERIFIED INCIDENT`, `UNVERIFIED REPORT`, `DEMO DATA`, `STALE DATA`.
   - Distinct shapes, borders (dashed for ML), and stripe watermarks for demo data.
4. **Unified Domain Schemas (`client/src/types/index.ts`):**
   - All 35+ core entities including Part L additions: `RumourReport`, `RoadClosure`, `EvacuationZone`, `ConsentRecord`, `DrillSession`, `MissingPersonRecord`.
5. **Seeded Demo Scenarios & Worked Example (`client/src/services/seedData.ts` & `docs/seed-plan.md`):**
   - Sector A (100% food covered, 20% medicine -> redirect food offers to medicine).
   - Sector B (0% water -> prioritize water tankers).
   - Sector C (90%+ covered -> monitor only).
6. **Documentation Requirements:**
   - [`docs/model-card.md`](file:///c:/Users/abhay/OneDrive/Desktop/Disaster%20Mangement/docs/model-card.md): Flood ML Model Card (provenance, FNR/FPR, calibration, SHAP).
   - [`docs/limitations.md`](file:///c:/Users/abhay/OneDrive/Desktop/Disaster%20Mangement/docs/limitations.md): Operational limitations & non-goals.
   - [`docs/seed-plan.md`](file:///c:/Users/abhay/OneDrive/Desktop/Disaster%20Mangement/docs/seed-plan.md): Test fixtures and seed plan.

---

## 🛠 Local Setup & Running

```bash
# Client
cd client
npm install
npm run dev

# Server
cd server
npm install
npm run dev
```
