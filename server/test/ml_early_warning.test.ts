import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { FloodMLService } from '../src/services/floodMLService';

describe('Phase 5: Flood ML Early Warning, Explainability & Model Monitoring (FR-32 to FR-37)', () => {
  test('Step 1: FR-32 & FR-33 Flood Risk Inference with Calibrated Probability & SHAP Attribution', () => {
    const now = new Date().toISOString();
    const result = FloodMLService.predictFloodRisk('area-a', 'Sector A (North River Basin)', {
      rainfall48hMm: 168,
      riverGaugeDeltaM: 1.25,
      soilMoistureSaturationPct: 88,
      drainageBottleneckIndex: 75,
      elevationM: 52,
      dataFreshnessTimestamp: now
    });

    assert.equal(result.isAvailable, true, 'Prediction should be available with fresh telemetry');
    assert.equal(result.hazardType, 'FLOOD');
    assert.equal(result.riskLevel, 'CRITICAL');
    assert.ok(result.calibratedProbability >= 0.80, 'High rainfall and river surge must yield calibrated probability >= 0.80');
    assert.ok(
      result.uncertaintyInterval[0] <= result.calibratedProbability &&
      result.calibratedProbability <= result.uncertaintyInterval[1],
      'Probability must lie within uncertainty interval bounds'
    );
    assert.ok(result.topShapFactors.length >= 3, 'Must return top 3 contributing SHAP factors');
    
    // Check that rainfall and river gauge are the primary driving factors
    const topFactorNames = result.topShapFactors.map(f => f.factor);
    assert.ok(topFactorNames.includes('Cumulative 48h Rainfall'));
    assert.ok(topFactorNames.includes('River Gauge Delta vs Danger Mark'));
    assert.equal(result.topShapFactors[0].direction, 'INCREASING_RISK');
  });

  test('Step 2: FR-34 Truth Labelling & Disclaimer Enforcement', () => {
    const now = new Date().toISOString();
    const result = FloodMLService.predictFloodRisk('area-c', 'Sector C (Elevated Ridge)', {
      rainfall48hMm: 35,
      riverGaugeDeltaM: -0.50,
      soilMoistureSaturationPct: 50,
      drainageBottleneckIndex: 20,
      elevationM: 80,
      dataFreshnessTimestamp: now
    });

    assert.equal(result.truthLabel, 'ML_ASSESSMENT', 'Must explicitly label output as ML_ASSESSMENT');
    assert.ok(
      result.disclaimer.includes('not an official government warning'),
      'Must contain explicit non-official disclaimer'
    );
    assert.ok(
      result.disclaimer.includes('human verification'),
      'Must require human verification for high-impact decisions'
    );
  });

  test('Step 3: FR-35 Stale Telemetry Detector & Fail Visibly Safe Mode', () => {
    // Telemetry timestamp 6 hours in the past (> 4h threshold)
    const staleTimestamp = new Date(Date.now() - 6 * 3600000).toISOString();
    const result = FloodMLService.predictFloodRisk('area-b', 'Sector B (Lowland Colony)', {
      rainfall48hMm: 120,
      riverGaugeDeltaM: 0.80,
      soilMoistureSaturationPct: 75,
      drainageBottleneckIndex: 70,
      elevationM: 48,
      dataFreshnessTimestamp: staleTimestamp
    });

    assert.equal(result.isAvailable, false, 'Inference must be gated when telemetry is stale');
    assert.ok(
      result.unavailableReason?.includes('Sensor telemetry stale'),
      'Must show explicit reason when data is stale'
    );
    assert.ok(result.unavailableReason?.includes('> 4h threshold'));
    assert.ok(result.precautions.some(p => p.includes('official IMD/CWC bulletins')));
  });

  test('Step 4: FR-35 Out-of-Range Detector (> 3.5 Sigma Historical Anomaly)', () => {
    const now = new Date().toISOString();
    // Extreme unphysical/catastrophic anomaly: 550mm in 48h (> 450mm 3.5-sigma limit)
    const result = FloodMLService.predictFloodRisk('area-a', 'Sector A', {
      rainfall48hMm: 550,
      riverGaugeDeltaM: 1.5,
      soilMoistureSaturationPct: 95,
      drainageBottleneckIndex: 90,
      elevationM: 52,
      dataFreshnessTimestamp: now
    });

    assert.equal(result.isAvailable, false, 'Must gate automatic inference for extreme out-of-range sensor readings');
    assert.ok(result.unavailableReason?.includes('Anomaly Alert'));
    assert.ok(result.unavailableReason?.includes('3.5-sigma'));
    assert.ok(result.precautions.some(p => p.includes('manual corroboration')));
  });

  test('Step 5: FR-36 Earthquake Non-Goal Scientific Refusal & Seismic Zone Guardrail', () => {
    const inquiry = FloodMLService.handleEarthquakeInquiry('Patna, Bihar');
    assert.equal(inquiry.isPredictable, false, 'Earthquake time/place forecasting must be strictly refused');
    assert.ok(inquiry.scientificConsensus.includes('cannot be reliably predicted in time, location, or magnitude'));
    assert.ok(inquiry.supportedFeatures.some(f => f.includes('Seismic Zone Mapping')));
    assert.ok(inquiry.supportedFeatures.some(f => f.includes('shake-map')));
  });

  test('Step 6: FR-37 Model Evaluation & Monitoring Exit Criteria Verification', () => {
    const monitoring = FloodMLService.getModelMonitoringMetrics();
    
    // PRD Part I exit criteria validation
    assert.ok(monitoring.metrics.prAuc >= 0.85, 'PR-AUC must exceed 0.85 on held-out test data');
    assert.equal(monitoring.metrics.prAuc, 0.884);

    assert.ok(monitoring.metrics.f2Score >= 0.85, 'F2-Score must exceed 0.85 to prioritize recall');
    assert.equal(monitoring.metrics.f2Score, 0.861);

    assert.ok(monitoring.metrics.falseNegativeRatePct <= 5.0, 'False Negative Rate on critical alerts must be <= 5%');
    assert.equal(monitoring.metrics.falseNegativeRatePct, 4.8);

    assert.ok(monitoring.metrics.brierScore < 0.10, 'Brier calibration score must be < 0.10');
    assert.equal(monitoring.metrics.brierScore, 0.089);

    // Verify PR Curve and Calibration reliability diagrams are populated
    assert.ok(monitoring.prCurve.length >= 8, 'PR curve must contain evaluation points');
    assert.ok(monitoring.calibrationCurve.length >= 5, 'Calibration curve must contain reliability points');

    // Verify feature drift monitoring
    assert.equal(monitoring.featureDrift.length, 3, 'Must track hydrologic drift on rainfall, river gauge, and soil moisture');
    assert.ok(monitoring.featureDrift.every(d => !d.driftDetected), 'Model baseline should exhibit no uncalibrated drift');
  });
});
