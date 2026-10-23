import { test, describe, before } from 'node:test';
import assert from 'node:assert/strict';
import { db, initDatabase } from '../src/db/database';
import { ReliefService } from '../src/services/reliefService';

describe('Phase 4: Needs Matrix, Double-Allocation Prevention & Smart Donor Matching', () => {
  before(async () => {
    await initDatabase();

    // Reset area_needs to exact PRD baseline for deterministic testing
    const updateNeed = db.prepare(`
      UPDATE area_needs 
      SET available_units = @available, reserved_units = @reserved, dispatched_units = @dispatched, delivered_units = @delivered, pending_units = @pending, last_verified = datetime('now')
      WHERE area_id = @areaId AND resource_type = @resType
    `);
    // Area A
    updateNeed.run({ areaId: 'area-a', resType: 'FOOD', available: 500, reserved: 50, dispatched: 350, delivered: 100, pending: 0 });
    updateNeed.run({ areaId: 'area-a', resType: 'WATER', available: 800, reserved: 100, dispatched: 500, delivered: 200, pending: 200 });
    updateNeed.run({ areaId: 'area-a', resType: 'MEDICINE', available: 60, reserved: 10, dispatched: 30, delivered: 20, pending: 240 });

    // Area B
    updateNeed.run({ areaId: 'area-b', resType: 'FOOD', available: 160, reserved: 20, dispatched: 100, delivered: 40, pending: 240 });
    updateNeed.run({ areaId: 'area-b', resType: 'WATER', available: 0, reserved: 0, dispatched: 0, delivered: 0, pending: 800 });
    updateNeed.run({ areaId: 'area-b', resType: 'MEDICINE', available: 120, reserved: 15, dispatched: 80, delivered: 25, pending: 80 });

    // Area C
    updateNeed.run({ areaId: 'area-c', resType: 'FOOD', available: 190, reserved: 20, dispatched: 140, delivered: 30, pending: 10 });
    updateNeed.run({ areaId: 'area-c', resType: 'WATER', available: 450, reserved: 50, dispatched: 350, delivered: 50, pending: 50 });
    updateNeed.run({ areaId: 'area-c', resType: 'MEDICINE', available: 90, reserved: 10, dispatched: 70, delivered: 10, pending: 10 });
  });

  test('Step 1: PRD E6 Worked Example Baseline & System Output Verification', () => {
    const matrix = ReliefService.getNeedsMatrix();
    assert.equal(matrix.length, 3, 'Should contain all 3 worked example sectors (A, B, C)');

    // Sector A Check
    const sectorA = matrix.find(m => m.areaId === 'area-a');
    assert.ok(sectorA, 'Sector A must exist');
    assert.equal(sectorA.needs['FOOD'].coveragePercent, 100, 'Sector A Food must be 100% covered');
    assert.equal(sectorA.needs['WATER'].coveragePercent, 80, 'Sector A Water must be 80% covered');
    assert.equal(sectorA.needs['MEDICINE'].coveragePercent, 20, 'Sector A Medicine must be 20% covered (urgent deficit)');
    assert.equal(sectorA.systemOutput.statusBadge, 'REDIRECT');
    assert.ok(sectorA.systemOutput.title.includes('Medicines Needed'));

    // Sector B Check
    const sectorB = matrix.find(m => m.areaId === 'area-b');
    assert.ok(sectorB, 'Sector B must exist');
    assert.equal(sectorB.needs['WATER'].coveragePercent, 0, 'Sector B Water must be 0% covered (life-critical shortage)');
    assert.equal(sectorB.needs['FOOD'].coveragePercent, 40, 'Sector B Food must be 40% covered');
    assert.equal(sectorB.systemOutput.statusBadge, 'CRITICAL');
    assert.ok(sectorB.systemOutput.title.includes('Water Tankers Prioritized'));

    // Sector C Check
    const sectorC = matrix.find(m => m.areaId === 'area-c');
    assert.ok(sectorC, 'Sector C must exist');
    assert.ok(sectorC.needs['FOOD'].coveragePercent >= 90, 'Sector C Food must be >= 90%');
    assert.ok(sectorC.needs['WATER'].coveragePercent >= 90, 'Sector C Water must be >= 90%');
    assert.equal(sectorC.systemOutput.statusBadge, 'MONITOR');
    assert.ok(sectorC.systemOutput.title.includes('Monitor Only'));
  });

  test('Step 2: FR-26 Configurable Transparent Priority Score Calculation', () => {
    // Water with 0% coverage (Sector B: req 800, avail 0)
    const waterScore = ReliefService.calculatePriorityScore('WATER', 800, 0, 450);
    assert.ok(waterScore.score >= 85, '0% Water shortage should have critical priority score >= 85');
    assert.equal(waterScore.factors.threatToLife, 95);
    assert.equal(waterScore.factors.shortageRatio, 100);
    assert.ok(waterScore.factors.explanation.includes('Threat to life'));

    // Food with 100% coverage (Sector A: req 500, avail 500)
    const foodScore = ReliefService.calculatePriorityScore('FOOD', 500, 500, 100);
    assert.ok(foodScore.score < waterScore.score, 'Fully met food need should have lower priority score than 0% water');
    assert.equal(foodScore.factors.shortageRatio, 0);
  });

  test('Step 3: FR-27 Smart Donation Matching — Food Over-Supply Redirection', () => {
    // Donor attempts to pledge 200 Food kits to Sector A (already 100% covered)
    const donorResult = ReliefService.processDonorMatching({
      donorName: 'Ramesh Gupta',
      donorContact: '+919876500001',
      resourceType: 'FOOD',
      offeredUnits: 200,
      targetAreaId: 'area-a'
    });

    assert.equal(donorResult.redirected, true, 'Offer to 100% covered area must be redirected');
    assert.ok(donorResult.suggestedAlternatives.length > 0, 'Must provide verified active alternatives');
    
    // Check that alternatives include Sector A Medicine (only 20% covered) or Sector B Food/Water
    const hasMedAlt = donorResult.suggestedAlternatives.some(
      (alt: any) => alt.areaId === 'area-a' && alt.resourceType === 'MEDICINE'
    );
    const hasWaterAlt = donorResult.suggestedAlternatives.some(
      (alt: any) => alt.areaId === 'area-b' && alt.resourceType === 'WATER'
    );
    assert.ok(hasMedAlt || hasWaterAlt, 'Must suggest Sector A Medicine or Sector B Water/Food');
  });

  test('Step 4: FR-27 Donor Accepts Redirected Alternative to Sector B Water', () => {
    // Donor accepts redirection and pledges 300 Water units to Sector B
    const acceptResult = ReliefService.processDonorMatching({
      donorName: 'Ramesh Gupta',
      donorContact: '+919876500001',
      resourceType: 'WATER',
      offeredUnits: 300,
      targetAreaId: 'area-b',
      forceAcceptRedirect: true,
      redirectedFromAreaId: 'area-a'
    });

    assert.equal(acceptResult.redirected, false);
    assert.equal(acceptResult.status, 'ALLOCATED');
    assert.ok(acceptResult.pledgeId);

    // Verify Sector B Water was updated
    const updatedWater = db.prepare(
      "SELECT * FROM area_needs WHERE area_id = 'area-b' AND resource_type = 'WATER'"
    ).get() as any;
    assert.equal(updatedWater.available_units, 300, 'Available units should now reflect the 300 pledged units');
  });

  test('Step 5: FR-28 Double-Allocation Prevention & Mandatory Override Reason', () => {
    // Sector B Water now has available: 300, reserved: 0 -> freeStock = 300
    // Attempt to reserve 500 units without override reason should FAIL
    assert.throws(() => {
      ReliefService.allocateResource({
        areaId: 'area-b',
        resourceType: 'WATER',
        allocatedUnits: 500,
        sourceType: 'CENTRAL_DEPOT',
        sourceName: 'Patna Regional Warehouse',
        allocatedByUserId: 'USR-ADMIN-01'
      });
    }, /Double-allocation risk/);

    // Attempt with valid human override reason should SUCCEED
    const successResult = ReliefService.allocateResource({
      areaId: 'area-b',
      resourceType: 'WATER',
      allocatedUnits: 500,
      sourceType: 'CENTRAL_DEPOT',
      sourceName: 'Patna Regional Warehouse',
      allocatedByUserId: 'USR-ADMIN-01',
      overrideReason: 'DDO special emergency authorization for Lowland Colony child care camp'
    });

    assert.ok(successResult.allocationId);
    assert.equal(successResult.status, 'RESERVED');
  });

  test('Step 6: FR-29 Delivery Confirmation with Proof Gate (Photo / OTP / Signature)', () => {
    // Create an allocation to confirm
    const alloc = ReliefService.allocateResource({
      areaId: 'area-c',
      resourceType: 'FOOD',
      allocatedUnits: 25,
      sourceType: 'NGO_STOCK',
      sourceName: 'Rotary Club Camp C',
      allocatedByUserId: 'USR-NGO-01'
    });

    // Confirmation without reference must FAIL
    assert.throws(() => {
      ReliefService.confirmDelivery({
        allocationId: alloc.allocationId,
        confirmationType: 'OTP',
        confirmationRef: '',
        confirmedByUserId: 'USR-RESPONDER-01'
      });
    }, /FR-29 Violation/);

    // Confirmation with valid OTP succeeds
    const confirmed = ReliefService.confirmDelivery({
      allocationId: alloc.allocationId,
      confirmationType: 'OTP',
      confirmationRef: 'OTP-982143',
      confirmedByUserId: 'USR-RESPONDER-01'
    });

    assert.equal(confirmed.status, 'DELIVERED');
    assert.equal(confirmed.confirmationType, 'OTP');

    // Allocation in DB must be updated
    const savedAlloc = db.prepare('SELECT * FROM resource_allocations WHERE id = ?').get(alloc.allocationId) as any;
    assert.equal(savedAlloc.status, 'DELIVERED');
    assert.equal(savedAlloc.delivery_confirmation_ref, 'OTP-982143');
  });

  test('Step 7: FR-30 & FR-53 Shortage Alerts & Tamper-Evident Audit Trail', () => {
    const alerts = ReliefService.getResourceAlerts() as any[];
    assert.ok(alerts.length >= 2, 'Should contain active shortage and over-supply alerts');
    
    // Check audit logs contains ALLOCATION and DONATION_PAYOUT
    const auditLogs = db.prepare(
      "SELECT * FROM audit_logs WHERE action_type IN ('ALLOCATION', 'DONATION_PAYOUT')"
    ).all() as any[];
    assert.ok(auditLogs.length >= 3, 'All allocation and donation matching actions must be logged in audit trail');
  });
});
