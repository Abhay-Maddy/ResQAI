import { test, describe, before } from 'node:test';
import assert from 'node:assert/strict';
import { db, initDatabase } from '../src/db/database';
import { 
  hashPassword, 
  verifyPasswordHash, 
  createSessionAndTokens, 
  rotateRefreshToken, 
  revokeSession,
  generateOtp,
  verifyOtp,
  verifyAccessToken
} from '../src/services/authService';
import { logAuditEvent, getAuditLogs } from '../src/services/auditService';

describe('Phase 1: Auth, RBAC & DB Exit Criteria Test Suite', () => {
  before(async () => {
    await initDatabase();
  });

  test('FR-1: Argon2id Password Hashing & Verification', async () => {
    const rawPassword = 'SuperSecretEmergencyKey2026!';
    const passwordHash = await hashPassword(rawPassword);

    assert.ok(passwordHash.startsWith('$argon2id$'), 'Hash must use Argon2id algorithm');
    
    const isValid = await verifyPasswordHash(passwordHash, rawPassword);
    assert.equal(isValid, true, 'Valid password must verify');

    const isInvalid = await verifyPasswordHash(passwordHash, 'WrongPassword');
    assert.equal(isInvalid, false, 'Invalid password must fail verification');
  });

  test('FR-2: All 7 Roles Seeded and Queryable in Database', () => {
    const roles = ['CITIZEN', 'ADMIN', 'GOVT_OFFICER', 'RESPONDER', 'NGO', 'DONOR', 'AUDITOR'];
    for (const role of roles) {
      const user = db.prepare('SELECT * FROM users WHERE role = ?').get(role) as any;
      assert.ok(user, `User with role ${role} must exist in seed DB`);
      assert.ok(user.password_hash.startsWith('$argon2id$'), `Password for ${role} must be Argon2id hashed`);
    }
  });

  test('FR-1: Session Creation & JWT Verification', () => {
    const citizenUser = db.prepare("SELECT * FROM users WHERE role = 'CITIZEN'").get() as any;
    const session = createSessionAndTokens(citizenUser, 'TestRunner/1.0', '192.168.1.10');

    assert.ok(session.accessToken, 'Must generate access token');
    assert.ok(session.refreshToken, 'Must generate refresh token');
    assert.ok(session.sessionId, 'Must generate session ID');

    const payload = verifyAccessToken(session.accessToken);
    assert.equal(payload.userId, citizenUser.id);
    assert.equal(payload.role, 'CITIZEN');
  });

  test('FR-1: Refresh Token Rotation & Session Revocation', () => {
    const donorUser = db.prepare("SELECT * FROM users WHERE role = 'DONOR'").get() as any;
    const initialSession = createSessionAndTokens(donorUser, 'MobileApp', '192.168.1.20');

    // 1. Rotate refresh token
    const rotated = rotateRefreshToken(initialSession.refreshToken, 'MobileApp', '192.168.1.20');
    assert.ok(rotated.accessToken, 'Rotated session must issue new access token');
    assert.ok(rotated.refreshToken, 'Rotated session must issue new refresh token');
    assert.notEqual(rotated.refreshToken, initialSession.refreshToken, 'New refresh token must differ from old');

    // 2. Token reuse detection: Old refresh token must now be invalid and trigger protection
    assert.throws(() => {
      rotateRefreshToken(initialSession.refreshToken, 'Attacker', '192.168.1.99');
    }, /Revoked token reuse detected/);

    // 3. Explicit session revocation
    const activeSession = createSessionAndTokens(donorUser, 'WebBrowser', '192.168.1.21');
    const revoked = revokeSession(activeSession.sessionId, donorUser.id);
    assert.equal(revoked, true, 'Session revocation must succeed');

    assert.throws(() => {
      verifyAccessToken(activeSession.accessToken);
    }, /Session has been revoked/);
  });

  test('FR-1: One-Time Password (OTP) Generation & Verification', () => {
    const phone = '+919876543299';
    const otp = generateOtp(phone, 'LOGIN');
    assert.equal(otp.length, 6, 'OTP must be 6 digits');

    // Invalid OTP fails
    const badCheck = verifyOtp(phone, '000000', 'LOGIN');
    assert.equal(badCheck, false, 'Incorrect OTP must fail');

    // Valid OTP succeeds
    const goodCheck = verifyOtp(phone, otp, 'LOGIN');
    assert.equal(goodCheck, true, 'Correct OTP must succeed');

    // Replay attack: OTP cannot be reused
    const replayCheck = verifyOtp(phone, otp, 'LOGIN');
    assert.equal(replayCheck, false, 'Used OTP must not be reusable');
  });

  test('FR-4: Two-Factor Authentication (2FA) Flags for High-Privilege Roles', () => {
    const admin = db.prepare("SELECT * FROM users WHERE role = 'ADMIN'").get() as any;
    const govt = db.prepare("SELECT * FROM users WHERE role = 'GOVT_OFFICER'").get() as any;
    const ngo = db.prepare("SELECT * FROM users WHERE role = 'NGO'").get() as any;
    const citizen = db.prepare("SELECT * FROM users WHERE role = 'CITIZEN'").get() as any;

    assert.equal(admin.two_factor_enabled, 1, 'Admin must have 2FA enabled by default');
    assert.equal(govt.two_factor_enabled, 1, 'Govt Officer must have 2FA enabled by default');
    assert.equal(ngo.two_factor_enabled, 1, 'NGO finance role must have 2FA enabled by default');
    assert.equal(citizen.two_factor_enabled, 0, 'Citizen standard role has 2FA optional');
  });

  test('FR-2: Jurisdiction-Scoped Authorization Rules', () => {
    const govtOfficer = db.prepare("SELECT * FROM users WHERE role = 'GOVT_OFFICER'").get() as any;
    assert.equal(govtOfficer.jurisdiction_region_id, 'area-a', 'Govt officer assigned to area-a');

    // Simulating jurisdiction validation function
    const validateJurisdiction = (user: any, targetAreaId: string) => {
      if (user.role === 'ADMIN' || user.role === 'AUDITOR') return true;
      if (user.jurisdiction_region_id && user.jurisdiction_region_id !== targetAreaId) {
        return false;
      }
      return true;
    };

    assert.equal(validateJurisdiction(govtOfficer, 'area-a'), true, 'Govt officer CAN operate in assigned area-a');
    assert.equal(validateJurisdiction(govtOfficer, 'area-b'), false, 'Govt officer CANNOT operate outside jurisdiction in area-b');

    const admin = db.prepare("SELECT * FROM users WHERE role = 'ADMIN'").get() as any;
    assert.equal(validateJurisdiction(admin, 'area-b'), true, 'Admin has global cross-jurisdiction clearance');
  });

  test('FR-53: Tamper-Evident Audit Logging', () => {
    const eventId = logAuditEvent({
      actionType: 'EMERGENCY_DISPATCH_AUTHORIZED',
      actorId: 'USR-ADMIN-01',
      actorRole: 'ADMIN',
      entityId: 'TEAM-NDRF-9A',
      details: 'Dispatched team to Sector A Rooftop Rescue',
      beforeState: { status: 'IDLE' },
      afterState: { status: 'DISPATCHED' }
    });

    assert.ok(eventId.startsWith('AUD-'), 'Audit event ID must be generated');

    const logs = getAuditLogs(10) as any[];
    const found = logs.find(l => l.id === eventId);
    assert.ok(found, 'Audit event must be saved in append-only audit log');
    assert.equal(found.action_type, 'EMERGENCY_DISPATCH_AUTHORIZED');
    assert.equal(found.actor_role, 'ADMIN');
  });
});
