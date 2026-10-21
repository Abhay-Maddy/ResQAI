# ResQAI: System Limitations, Boundaries & Risk Boundaries

This document defines the architectural, operational, and ethical limitations of the ResQAI platform in accordance with PRD Part C.3 (Non-Goals) and Part K (Risk Register).

---

## 1. Non-Goals (v1)

1. **No Earthquake Time/Location Prediction (FR-36):**
   - ResQAI does **not** attempt short-term prediction of earthquakes, as no scientific consensus or reliable geophysical methodology exists for short-term earthquake prediction.
   - For seismic hazards, ResQAI strictly provides historical seismic hazard zonation maps (Zone II to V), building exposure vulnerability metrics, and rapid post-event ShakeMap impact assessment.

2. **No Replacement of Official Alert Systems or 112 (FR-19, FR-49):**
   - ResQAI is a decision-support and multi-agency coordination system; it does **not** replace the National Disaster Management Authority (NDMA), SACHET CAP feeds, or the police/fire/ambulance 112 Emergency Response Support System (ERSS).
   - A persistent banner is permanently displayed on all citizen surfaces: *"If life is in immediate danger, call 112 directly."*

3. **No Autonomous Dispatch or Spending (FR-19, FR-31):**
   - The system **never** dispatches physical emergency rescue units autonomously. Human dispatchers and team commanders must acknowledge and authorize every physical deployment.
   - The system **never** auto-spends or disburses donor funds without explicit dual-authorization and server-side cryptographic verification.

4. **No Single Universal ML Model for All Disasters (FR-32):**
   - Disaster physics vary drastically. ResQAI deploys dedicated, hazard-specific models (e.g., hydrological models for riverine/urban flood, heat-stress biometeorological models for heatwaves, wind-field dissipation models for cyclones) rather than a fragile "one size fits all" AI model.

---

## 2. Operational Limitations & Degraded Modes

1. **Zero-Connectivity & Degraded Mode (FR-51, FR-52):**
   - In total network blackout, the Citizen PWA operates offline. SOS reports are buffered in encrypted local storage (`localStorage`/`IndexedDB`) with exponential sync backoff.
   - The user is transparently informed: *"Offline — report stored locally. Not yet received by responders."*
   
2. **Data Freshness Thresholds (FR-22, FR-35):**
   - If telemetry or GIS layers exceed freshness thresholds (e.g., > 15 minutes for live operations, > 4 hours for hydrological sensors), layers are visually striped and tagged with the **`STALE DATA`** badge.
   - Predictions dependent on stale data are gated with an explicit `"Prediction unavailable"` banner.

3. **Demographic & Geographical Limitations:**
   - Initial validation is focused on pilot regions (e.g., Bihar & Eastern India flood plains). Transferability to mountainous terrain (e.g., flash floods/landslides in Uttarakhand) requires re-calibration with localized steep-slope DEM and geotechnical data.

---

## 3. Data Privacy & DPDP Act 2023 Compliance (FR-39)

1. **Field-Level Masking:**
   - Citizen phone numbers, national IDs, and exact residential addresses are masked in public and triage queues.
   - Access to unmasked identifiable data requires role-based permission and generates an immutable, tamper-evident `AuditLog` entry.
2. **Consent & Purpose Limitation:**
   - Data collected during emergency reporting is strictly limited to rescue and relief delivery purposes and is never shared with third parties or ad brokers.
