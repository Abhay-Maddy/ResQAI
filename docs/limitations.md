# ResQAI: System Limitations, Boundaries & Risk Boundaries (PRD v2.0)

This document defines the architectural, operational, scientific, and ethical boundaries of the ResQAI platform in accordance with PRD v2.0 Section 13 (Risk Register) and Section 14 (Deployment Guidelines).

---

## 1. Scientific & Ethical Non-Goals

1. **No Earthquake Time/Location Prediction (FR-36):**
   - ResQAI does **not** attempt short-term prediction of earthquake timing or exact epicenters, as no scientific consensus or verified geophysical method exists.
   - For seismic hazards, ResQAI strictly displays historical seismic hazard zonation maps (Zone II to V) and building exposure vulnerability indices. Any user prompt asking for earthquake predictions is met with an explicit scientific refusal.

2. **No Autonomous Dispatch, Aid Denial, or Disbursement:**
   - The AI **never** executes automated dispatch of physical rescue teams, denies emergency aid, or rejects citizen damage claims.
   - Every physical deployment, claim verification, entitlement sanction, and relief delivery requires an explicit, named human decision-maker.

3. **No Replacement of Official Feeds or 112 (FR-19, FR-49):**
   - ResQAI aggregates and mirrors official feeds from IMD, NDMA SACHET, and GDACS; it does **not** replace the emergency 112 helpline.
   - A persistent banner is permanently displayed on all citizen surfaces: *"If life is in immediate danger, call 112 directly."*

4. **Zero Hallucination Relational Briefings (F-19):**
   - Situation summaries are synthesized strictly from database relational rows (`incidents`, `damage_claims`, `shelters`, `official_alerts`). ResQAI never queries generative LLMs with ungrounded prompts to prevent catastrophic misinformation during a crisis.

---

## 2. Operational Boundaries & Fail-Visibly Guardrails

1. **Silent-Zone Blackout Presumption (F-17):**
   - A sudden drop in incident reports (> 75% drop from baseline) during an active flood or storm must **NEVER** be interpreted as an area being safe or recovered.
   - The system automatically tags such sectors with **`COMMUNICATIONS_BLACKOUT_SUSPECTED`** to prioritize drone or foot-patrol reconnaissance.

2. **Telemetry Freshness & Out-of-Range Guardrails (FR-35):**
   - If hydrological or weather telemetry is older than 4 hours, all risk inference enters **`STALE_SAFE_MODE`** and displays a yellow `STALE DATA` warning badge.
   - Sensor inputs exceeding 3.5 standard deviations ($\sigma$) from historical records are gated for sensor malfunction verification before warning publication.

3. **Hazard-Aware Route Caution (F-22):**
   - ResQAI does **not** generate unverified alternative routes across compromised terrain.
   - Any passage through closed roads or flooded bridges is explicitly stamped: **`CAUTION: NOT VERIFIED SAFE`**.

4. **Multi-Tier Verification & Conflict-of-Interest (Phase 5):**
   - Volunteers cannot verify damage claims for their own households.
   - Claims above ₹100,000 require dual inspection: Volunteer community verification (`COMMUNITY_VERIFIED`) followed by Government revenue officer verification (`OFFICIALLY_VERIFIED`).
   - Aid delivery cannot transition to `DELIVERED` without digital proof: either a verified delivery OTP or a geotagged photo with a recipient signature.

---

## 3. Data Privacy & DPDP Compliance (FR-39)

1. **Small Count Masking (< 5 Counts):**
   - In all public dashboards and transparency explorer views, aggregated incident or damage claim counts fewer than 5 are masked as `"fewer than 5"` to protect victim anonymity.

2. **Field-Level Masking:**
   - Phone numbers, Aadhaar/Ration card references, and house numbers are strictly accessible only by authorized caseworkers and officers.
   - Every access to unmasked citizen data is recorded in a tamper-evident SHA-256 hash-chained audit log.
