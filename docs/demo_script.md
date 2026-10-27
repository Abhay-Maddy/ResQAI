# ResQAI Evaluator Demo Script & Walkthrough (PRD v2.0)

This script provides an interactive step-by-step walkthrough of the ResQAI platform across all five primary roles: **Citizen**, **Volunteer**, **NGO Coordinator**, **Government Revenue Officer**, and **Super Admin**.

---

## Pre-requisites & Quick Start

1. Start the ResQAI Backend & Database:
   ```bash
   cd server
   npm start
   # API running at http://localhost:5000
   ```
2. Or start via Docker Compose:
   ```bash
   docker compose up --build
   ```
3. Run the automated verification test suites:
   ```bash
   cd server && npm test      # 133 tests passing (100% green)
   flutter test               # 28 tests passing (100% green)
   ```

---

## Seed Accounts for Testing

| Role | Phone | Password | Quick PIN | Access Scope |
|---|---|---|---|---|
| **Master Admin** | `+919999900000` | `Admin@ResQAI2026` | `1234` | Omni-Dashboard Switcher, System Controls |
| **Citizen (A)** | `+919876543210` | `Citizen@123` | `1234` | SOS Wizard, Claims, Status Tracking |
| **Volunteer (A)** | `+919876543211` | `Volunteer@123` | `1234` | Local Help Board, Community Verification |
| **NGO Lead** | `+919876543212` | `NgoLead@123` | `1234` | Campaigns, Integer Ledger, Relief Tasks |
| **Govt Officer** | `+919876543213` | `Officer@123` | `1234` | Official Verification, Sanctions, Command |

---

## Walkthrough Scenarios

### Scenario 1: Citizen SOS Report & Offline Fallback (Phase 2 & 9)
1. **Submit Emergency Report:**
   - Citizen opens PWA / App, clicks **SOS Emergency**.
   - Selects **Flooding & Inundation**, adds 4 trapped persons, and clicks **Record Voice Note**.
   - Citizen submits; system generates ticket `INC-SMS-XXXX` and returns 15-minute SLA countdown.
2. **Offline Fallback Simulation:**
   - When mobile data drops to 0 bars, click **Send via Offline SMS**.
   - App formats structured SMS string under 160 characters:
     `RESQAI SOS FLOOD P:4 LOC:Kankarbagh Ward 12 NEED:boat,food`
   - Submits to 112 gateway. System deduplicates within 5 minutes (`DUPLICATE_IGNORED` on double-tap).

---

### Scenario 2: Operations Dispatch, What-If & Silent Zones (Phase 3 & 8)
1. **Explainable Priority & What-If Hypothesis (F-14):**
   - Dispatcher opens Incident Queue, views baseline score `45`.
   - Clicks **What-If Hypothesis**: toggles *"Rising Water Confirmed"* and *"Infant Trapped"*.
   - Score immediately updates to `75 (+30 pts)` with explicit factor breakdown according to the stored formula.
2. **Silent-Zone Blackout Detection (F-17):**
   - Incident rate from Sector A drops from $12.0\text{ reports/hr}$ to $0.5\text{ reports/hr}$ (96% drop) while river sensor remains above danger level.
   - System triggers **`SILENT-ZONE ALERT: COMMUNICATIONS_BLACKOUT_SUSPECTED`**. Dispatcher mobilizes radio patrol.
3. **Hazard-Aware Route Caution (F-22):**
   - Dispatcher routes team; system identifies collapsed North Canal Bridge and stamps route:
     `CAUTION: NOT VERIFIED SAFE`.

---

### Scenario 3: Damage Claim, Multi-Tier Inspection & Official Sanction (Phase 5)
1. **File Damage Claim:**
   - Citizen files claim with Aadhaar, ration card, and photo evidence. Completeness meter scores 80%.
2. **Volunteer Conflict-of-Interest Check:**
   - Volunteer Kavita attempts to verify her own family claim; system blocks with `CONFLICT_OF_INTEREST`.
   - Independent volunteer inspects neighbor's home, confirms damage $\rightarrow$ stamps `[COMMUNITY_VERIFIED]`.
3. **Government Inspection & Sanction:**
   - Revenue Officer Rajesh conducts physical audit $\rightarrow$ upgrades to `[OFFICIALLY_VERIFIED]`.
   - Sanctions ₹75,000 official DBT aid package and issues delivery OTP `772914`.
4. **Delivery Proof Gate:**
   - Case worker delivers kit and enters OTP $\rightarrow$ status transitions to `DELIVERED`.

---

### Scenario 4: Transparent NGO Ledger & Anti-Duplication Locking (Phase 6)
1. **Public Transparency Hub:**
   - Citizen opens Public Transparency Explorer; views verified NGOs.
   - Balances are computed in real time from ledger entries: $\text{Balance} = \text{Received} - \text{Spent}$.
2. **Missing Receipt Flag:**
   - NGO logs ₹45,000 for tarpaulins without an invoice voucher.
   - System highlights expenditure in **Red** with `[UNSUPPORTED EXPENSE]` warning badge.
3. **Double-Allocation Lock (FR-28):**
   - NGO A reserves 150 water filtration kits for Sector B.
   - NGO B attempts to claim the same 150 kits $\rightarrow$ system rejects with double-allocation lock.
4. **Compare View:**
   - Side-by-side comparison of 2 NGOs displaying transparent overhead percentages and verified receipts.

---

### Scenario 5: Government Command, Connect-and-Inform & Mutual Aid (Phase 7)
1. **Jurisdiction Crisis Overview:**
   - District Magistrate opens Government Command Console showing active flood zones, SDRF expenditure, and shelter capacity.
2. **Targeted Role Broadcast:**
   - Officer drafts emergency directive to **DOCTORS_AND_HOSPITALS** in District Patna.
   - Broadcast delivers strictly to certified medical personnel, showing delivered: 14, failed: 0.
3. **Inter-District Mutual Aid Requisition:**
   - District A requests 5 motorized rescue boats from adjacent District B with recorded authorization.

