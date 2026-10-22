# ResQAI — Emergency Response & Needs-Based Relief Coordination Platform

> **Vision:** One trusted platform that predicts disaster risk, verifies emergencies, coordinates rescue, and sends the *right relief to the right place*, with every rupee and every decision auditable.  
> **PRD Source of Truth:** `ResQAI PRD v1.0` (FR-1 through FR-54).

---

## 🚀 Execution Roadmap & Phase Status Tracker

| Phase | Milestone / Focus | Status | Key Deliverables & Exit Criteria |
| :--- | :--- | :---: | :--- |
| **Phase 0** | **PRD, Repo, Design System, Seed Plan** |  **COMPLETED** | Design tokens (PRD H2), i18n (FR-1/Part L#1), TruthBadge (Part L#2), unified types (Part G & L#4), Model Card & Limitations (Part L#9), Seed plan (E6). |
| **Phase 1** | **Auth, RBAC, DB & Core Backend** |  **COMPLETED** | Argon2id hashing (FR-1), Refresh-token rotation & session revocation (FR-1), 7 Roles with jurisdiction scopes (FR-2), Server-side authorization (FR-3), 2FA gate (FR-4), SQLite/Postgres schema (Part G & L#4), Tamper-evident AuditLog (FR-53). **Exit criteria: Role tests green (8/8 passed)**. |
| **Phase 2** | **Reporting, Verification & Command Dashboard** |  **COMPLETED** | Normal Login/Register modal with Citizen ID creation & Admin official portal; Citizen 3-step SOS reporting (FR-5, FR-8); AI Duplicate scoring & priority triage (FR-11); Verification workflow (FR-10, FR-12); Admin Command Dashboard with 8 DB KPI cards (H4-3); Main Admin Master Role Management; Universal Dashboard Switcher. **Exit criteria: End-to-end incident flow demo (13/13 tests green)**. |
| **Phase 3** | **Live GIS Map, Layers & Responder View** |  **COMPLETED** | Multi-layer Leaflet GIS map with 7 togglable layers and distinct shape encoding (PRD H2: Square official alerts, circle verified, hollow unverified, triangle teams, house shelters, red striped closed roads, hatched purple ML risk polygons); Closed-Road Avoidance Safe Routing Engine (FR-23); Field Responder Console with 48px+ touch targets and 1-tap state progression (`Accept` → `En Route` → `On Scene` → `Resolved`, FR-15-19, H4-7); Offline route caching. **Exit criteria: Full dispatch and safe route loop (18/18 tests green)**. |
| **Phase 4** | **Needs Matrix & Smart Donation Allocation** | ⏳ *Next* | Signature feature: Needs matrix, shortage detector, donor redirect engine (Area A/B/C worked example). |
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

## 🗺️ Phase 3 Deliverables Summary

1. **Multi-Layer Live GIS Tactical Map Engine (`client/src/components/LiveGISMap.tsx`, `server/src/routes/gisRoutes.ts`):**
   - 7 independent togglable geospatial layers per PRD H4-5: Official Warnings, Verified Incidents, Unverified Reports, ML Hazard Predictions, Rescue Teams, Safe Shelters, Road Closures.
   - PRD H2 Marker Shape Language: Square (Official), Circle Filled (Verified), Circle Hollow (Unverified), Triangle (Teams), House (Shelters), Red Polyline (Road Closures), Hatched Purple Polygon (ML Risk Zones).
   - Bottom-left persistent interactive truth legend.
   - Interactive entity inspect cards with live metadata and actions.
2. **Closed-Road Avoidance Safe Routing Engine (FR-23):**
   - Detects impassable flooded corridors (e.g., East Embankment Highway).
   - Dynamically calculates bypass waypoints across elevated ridge corridors.
   - Computes distance and ETA metrics.
3. **Field Responder Operations Console (`client/src/components/ResponderTaskView.tsx`):**
   - Glove-friendly 48px+ touch targets and high-contrast UI (PRD H4-7).
   - Dynamic 1-tap state transition loop: `Accept` → `En Route` → `On Scene` → `Resolved`.
   - Automatic sync with incident status and rescue team capacity.
   - Turn-by-turn road avoidance guidance, 1-tap resource requests and hazard reports, offline route caching.
4. **End-to-End Test Suite (`server/test/gis_dispatch_flow.test.ts`):**
   - 18/18 tests green across Auth, Incident Flow, and GIS Dispatch Lifecycle.

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
