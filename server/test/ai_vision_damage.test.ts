import { test, describe, before } from 'node:test';
import assert from 'node:assert';
import { initDatabase } from '../src/db/database';
import { AiVisionDamageService } from '../src/services/aiVisionDamageService';

describe('AI Vision Damage Assessment Engine', () => {
  before(async () => {
    await initDatabase();
  });

  test('Step 1: Structural collapse photo assessment detects severe damage (Grade 4)', async () => {
    const result = await AiVisionDamageService.inspectDamagePhoto({
      claimId: 'CLAIM-TEST-001',
      damageDescription: 'House completely collapsed due to flash flood landslide, roof gone',
      photoUrl: 'https://resqai.org/uploads/claims/collapse_photo_01.jpg'
    });

    assert.ok(result.inspectionId.startsWith('INSP-'));
    assert.strictEqual(result.overallDamageGrade, 'GRADE_4_TOTAL_DESTRUCTION');
    assert.strictEqual(result.wallCrackSeverity, 'TOTAL_COLLAPSE');
    assert.ok(result.roofDamagePercent >= 80);
    assert.strictEqual(result.recommendedSdrfGrantInr, 120000);
    assert.strictEqual(result.fraudCheckPassed, true);
  });

  test('Step 2: Flood inundation water mark assessment detects silt water line at 3.6 ft (Grade 3)', async () => {
    const result = await AiVisionDamageService.inspectDamagePhoto({
      claimId: 'CLAIM-TEST-002',
      damageDescription: 'Ground floor submerged by flood water, waterlogged rooms',
      photoUrl: 'https://resqai.org/uploads/claims/flood_waterline_02.jpg'
    });

    assert.strictEqual(result.overallDamageGrade, 'GRADE_3_SEVERE');
    assert.strictEqual(result.wallCrackSeverity, 'STRUCTURAL_COMPROMISE');
    assert.strictEqual(result.waterLineHeightFeet, 3.6);
    assert.strictEqual(result.recommendedSdrfGrantInr, 75000);
    assert.ok(result.visualObservations.some(v => v.includes('watermark line visible at 3.6 feet')));
  });

  test('Step 3: Minor boundary wall crack assessment assigns moderate tier (Grade 2)', async () => {
    const result = await AiVisionDamageService.inspectDamagePhoto({
      claimId: 'CLAIM-TEST-003',
      damageDescription: 'Hairline cracks on outer boundary wall from minor water flow',
      photoUrl: 'https://resqai.org/uploads/claims/wall_crack_03.jpg'
    });

    assert.strictEqual(result.overallDamageGrade, 'GRADE_2_MODERATE');
    assert.strictEqual(result.wallCrackSeverity, 'MODERATE_CRACK');
    assert.strictEqual(result.recommendedSdrfGrantInr, 45000);
    assert.ok(result.confidenceScore >= 0.90);
  });
});
