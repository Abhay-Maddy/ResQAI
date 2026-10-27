# ResQAI Model Card: Disaster Intelligence & Risk Baseline (PRD v2.0)

**Model Version:** `v2.0-resqai-hydrologic-triage`  
**Date:** October 2026  
**Type:** Calibrated Hydrological Gradient Boosted Trees + Deterministic Factor Decomposition + Telemetry Anomaly Gating  
**Task:** 12-to-24 hour probabilistic flood and inundation risk estimation, priority triage scoring, and communication blackout detection.

---

## 1. Intended Use & Four-Way Truth Labelling
- **Intended Use:** Decision support and priority ranking for humanitarian dispatchers, government emergency officers, and field responders.
- **Truth Labels:** Every output from the AI models carries an immutable truth label:
  - `[ML ASSESSMENT]` (Dashed purple outline, sparkle icon) — Model assessment, not an official warning; requires human confirmation.
  - `[COMMUNITY_VERIFIED]` (Blue shield icon) — Independent ground check completed by a verified local volunteer without conflict of interest.
  - `[OFFICIALLY_VERIFIED]` (Green emblem icon) — Officially inspected and certified by a gazetted government revenue officer.
  - `[OFFICIAL WARNING]` (Solid red badge) — Four-eyes approved government directive.
- **Strict Scientific Non-Goals:**
  - This model **NEVER** issues automated public evacuation orders.
  - This model **NEVER** predicts short-term earthquake timing or exact epicenters (PRD FR-36: seismic hazards are strictly mapped to historical BIS seismic zones and post-event ShakeMaps).
  - This model **NEVER** auto-denies citizen aid or auto-rejects damage claims.

---

## 2. Training Data & Provenance
The hydrological risk model is trained on historical hydrometeorological and geospatial datasets covering the Ganga and Kosi flood basins (2012–2024):
- **Rainfall:** IMD Gridded Rainfall (0.25° x 0.25°) and NASA GPM IMERG 30-min precipitation.
- **River Discharge & Gauge Levels:** Central Water Commission (CWC) daily and hourly river gauge station observations.
- **Topography & Elevation:** Shuttle Radar Topography Mission (SRTM) 30m Digital Elevation Model (DEM) and slope gradients.
- **Land Use & Surface Hydrology:** Sentinel-2 Surface Water index and ESA WorldCover land use classes.
- **Soil Moisture:** SMAP surface and root-zone soil moisture saturation index.

---

## 3. Evaluation Metrics & Calibration
- **Temporal Hold-Out:** Trained on 2012–2022 monsoon seasons; validated on held-out 2023–2024 flood seasons.
- **Spatial Hold-Out:** 3 unseen adjacent downstream districts evaluated to detect spatial overfitting.
- **Key Metrics:**
  - **PR-AUC:** 0.884
  - **F2-Score:** 0.861 (prioritizes high recall to minimize life-safety false negatives)
  - **False Negative Rate (FNR):** 4.8% on Critical/High threshold
  - **Brier Score (Probability Calibration):** 0.089 (well-calibrated probabilities via Platt scaling & Isotonic Regression)

---

## 4. Deterministic Explainable Priority Scoring (F-14)
To ensure transparency and eliminate AI hallucinations in triage scoring, emergency priority is calculated using a deterministic, stored mathematical formula:

$$\text{Priority Score} = \text{Urgency}(10\text{–}40) + \min(30, \text{People} \times 5) + \text{WaterRising}(15) + \text{Vulnerable}(15) + \text{EvidenceBonus}(0\text{–}10)$$

Dispatchers can test hypotheses via the **Interactive What-If Simulator** (`POST /api/v1/research/priority/what-if`), which computes the exact factor delta before mobilizing teams.

---

## 5. Fail-Safe Safeguards & Gating (FR-35, F-17, F-22)
- **Stale Telemetry Detector:** If upstream rainfall or river sensor data is older than 4 hours, the system immediately switches to safe mode and displays:
  `"Prediction unavailable: Upstream sensor telemetry stale (>4h)"`
- **Out-of-Range Anomaly Detector:** Telemetry values exceeding 3.5 standard deviations ($\sigma$) from historical baselines are quarantined for physical sensor inspection before alert issuance.
- **Silent-Zone Blackout Detector (F-17):** When an area experiencing an active flood or storm suffers a $> 75\%$ drop in incident reports, the system flags the sector as `COMMUNICATIONS_BLACKOUT_SUSPECTED`. It is **NEVER** marked as safe or recovered.
- **Hazard-Aware Route Caution (F-22):** Any movement corridor passing through closed roads or flooded bridges is stamped with `CAUTION: NOT VERIFIED SAFE`.

---

## 6. Field Ground-Truth Feedback Loop (F-25)
Field responders and disaster management personnel submit real-time physical observations (`POST /api/v1/research/prediction-feedback`) including:
- Measured water depth (in meters)
- Embankment breach confirmation
- Model accuracy rating (1 for accurate, 0 for inaccurate)

This continuous feedback loop provides auditability and detects localized model drift during dynamic flood events.
