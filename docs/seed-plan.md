# ResQAI Seed Data & Simulation Plan (Phase 0)

## Overview
This document specifies the synthetic demo seed dataset and drill simulation fixtures designed for testing, automated validation, and hackathon demonstration according to PRD Part D (Synthetic Seed Data watermarked DEMO), Part E6 (Worked Example), and Part L Item 5 & 7.

---

## 1. Needs-Based Allocation Worked Example (PRD E6 & H4-6)

The seed dataset contains three operational sectors in the Patna district pilot zone:

| Area | Food Coverage | Water Coverage | Medicine Coverage | System Action / Expected Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Sector A** (North River Basin) | **100%** (500/500 kits) | **80%** (800/1000 L) | **20%** (60/300 kits) | Food offers **redirected**. Prompt donors: *"Medicines urgently needed – Area A"*. |
| **Sector B** (Lowland Colony) | **40%** (160/400 kits) | **0%** (0/800 L) | **60%** (120/200 kits) | **Water tankers prioritized**. Nearest safe logistics team suggested. |
| **Sector C** (Elevated Ridge) | **95%** (190/200 kits) | **90%** (450/500 L) | **90%** (90/100 kits) | **Monitor only**. No immediate shortages flagged. |

---

## 2. Seed Incidents & Verification Workflow Fixtures

1. **INC-2026-001 (Critical Rooftop Stranded):**
   - **Status:** `TRIAGE`
   - **Urgency:** `CRITICAL`
   - **Priority Score:** `94`
   - **SLA Countdown:** 18 minutes remaining.
   - **Verification State:** Unreviewed; requires dispatcher review modal with reason + confidence input.

2. **INC-2026-002 (Drinking Water Pipeline Outage):**
   - **Status:** `VERIFIED`
   - **Urgency:** `HIGH`
   - **Assigned Team:** `SDRF Quick Response Unit 4` (`TEAM-SDRF-04`).
   - **Verification State:** Verified by Inspector Meera with water test reference document.

3. **INC-2026-003 (Eastern Bypass Tree Fall):**
   - **Status:** `UNVERIFIED`
   - **Urgency:** `LOW`
   - **Priority Score:** `38`
   - **Verification State:** Flagged as low urgency with alternate route available.

---

## 3. Watermarked Synthetic Drill Mode (PRD Part L Item 7)
- **Active Session:** `DRILL-2026-DEMO` ("Operation Jal-Suraksha 2026")
- All drill incidents and GIS markers display the **`DEMO DATA`** truth badge (diagonal stripe styling) to prevent confusion with real incidents.
