# ResQAI Model Card: Urban & Riverine Flood Risk Baseline (v1.2-xgb)

**Model Version:** `v1.2-xgb-bihar-flood`  
**Date:** October 2026  
**Type:** Gradient Boosted Decision Trees (XGBoost Classifier + Isotonic Probability Calibration)  
**Task:** 12-to-24 hour probabilistic flood and waterlogging risk estimation at district / basin cluster resolution.

---

## 1. Intended Use & Four-Way Truth Labelling
- **Intended Use:** Decision support and priority ranking for humanitarian dispatchers and emergency planners.
- **Truth Label:** Every output from this model carries the **`ML ASSESSMENT`** badge (dashed purple outline, sparkle icon) and the explicit disclaimer:
  > *"Model assessment — not an official government warning. Decisions require human verification."*
- **Strict Non-Goals:**
  - This model **NEVER** issues automated public evacuation orders.
  - This model **NEVER** performs earthquake prediction (in accordance with PRD FR-36: earthquakes are hazard-mapped and post-event only).
  - This model **NEVER** replaces official meteorological or hydrologic alerts from IMD (India Meteorological Department) or CWC (Central Water Commission).

---

## 2. Training Data & Provenance
The model is trained on historical hydrometeorological and geospatial datasets covering the Ganga and Kosi flood basins (2012–2024):
- **Rainfall:** IMD Gridded Rainfall (0.25° x 0.25°) and NASA GPM IMERG 30-min precipitation.
- **River Discharge & Gauge Levels:** CWC daily and hourly river gauge station observations.
- **Topography & Elevation:** Shuttle Radar Topography Mission (SRTM) 30m Digital Elevation Model (DEM) and slope gradients.
- **Land Use & Surface Hydrology:** Sentinel-2 Surface Water index and ESA WorldCover land use classes.
- **Soil Moisture:** SMAP surface and root-zone soil moisture saturation index.

---

## 3. Evaluation & Validation (Temporal & Spatial Split)
- **Temporal Hold-Out:** Trained on 2012–2022 flood seasons; evaluated on held-out 2023–2024 monsoon seasons.
- **Spatial Hold-Out:** 3 unseen adjacent downstream districts evaluated to detect spatial overfitting.
- **Key Metrics (on held-out data):**
  - **PR-AUC:** 0.884
  - **F2-Score:** 0.861 (prioritizes high recall to minimize life-safety false negatives)
  - **False Negative Rate (FNR):** 4.8% on Critical/High threshold
  - **Brier Score (Probability Calibration):** 0.089 (well-calibrated probabilities via Isotonic Regression)

---

## 4. Explainability & SHAP Feature Attribution
For every prediction, the top 3 contributing physical features are computed and presented in the UI to prevent "black box" decisions:
1. Cumulative 48-hour rainfall vs localized soil absorption threshold.
2. River level delta relative to local CWC Danger Mark.
3. Basin elevation differential and low-gradient drainage bottleneck index.

---

## 5. Fail-Safe Safeguards & Gating (FR-35)
- **Stale Data Detector:** If upstream rainfall or river sensor data has not refreshed within 4 hours, the system immediately disables inference and outputs:
  `"Prediction unavailable: Upstream sensor telemetry stale (>4h)"`
- **Out-of-Range Detector:** Unprecedented extreme hydrological anomalies (> 3.5 standard deviations from historical distribution) flag an uncertainty alert and require senior human hydrologist corroboration.
- **Human-in-the-Loop:** High-impact alerts require manual dispatcher confirmation before team mobilization.
