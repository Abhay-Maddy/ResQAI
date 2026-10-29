import { test, describe, before } from 'node:test';
import assert from 'node:assert';
import { initDatabase, db } from '../src/db/database';
import { FcmPushService } from '../src/services/fcmPushService';
import { sendNotification, registerDeviceToken } from '../src/services/notificationService';

describe('Production Push Notifications (FCM / APNs Architecture)', () => {
  const testUserId = 'USER-PUSH-TEST-001';
  const testDeviceToken = 'fcm_token_device_abc123456789';

  before(async () => {
    await initDatabase();
    // Ensure test user exists
    db.prepare(`
      INSERT OR IGNORE INTO users (id, phone, name, role, is_verified)
      VALUES (?, '+919876543299', 'Push Test Citizen', 'CITIZEN', 1)
    `).run(testUserId);
  });

  test('Step 1: Register device FCM token linked to user', () => {
    registerDeviceToken(testUserId, testDeviceToken, 'FCM_ANDROID');
    const device = db.prepare('SELECT * FROM devices WHERE user_id = ? AND device_token = ?').get(testUserId, testDeviceToken) as any;
    assert.ok(device);
    assert.strictEqual(device.device_token, testDeviceToken);
    assert.strictEqual(device.device_type, 'FCM_ANDROID');
  });

  test('Step 2: Dispatch PUSH notification triggers FcmPushService delivering to registered device', async () => {
    const notif = await sendNotification({
      userId: testUserId,
      title: '🚨 Extreme Weather Flash Alert',
      body: 'River water level exceeded safety limit by 1.2m in Sector 4.',
      channel: 'PUSH',
      type: 'DISASTER_ALERT'
    });

    assert.ok(notif.id);
    assert.strictEqual(notif.channel, 'PUSH');

    // Verify delivery receipt recorded
    const delivery = db.prepare('SELECT * FROM notification_deliveries WHERE notification_id = ?').get(notif.id) as any;
    assert.ok(delivery);
    assert.strictEqual(delivery.status, 'SENT');
    assert.ok(delivery.provider_receipt.includes('projects/'));
  });

  test('Step 3: FcmPushService delivers broadcast to emergency topic', async () => {
    const topicResult = await FcmPushService.sendToTopic('disaster-patna-flood', {
      title: 'Patna District Emergency Evacuation',
      body: 'All residents in low-lying areas move to designated shelters immediately.',
      priority: 'high',
      channelId: 'resqai_emergency_channel'
    });

    assert.strictEqual(topicResult.success, true);
    assert.strictEqual(topicResult.topic, 'disaster-patna-flood');
    assert.ok(topicResult.messageId.startsWith('topic/'));
  });

  test('Step 4: Prune stale device token on uninstallation or invalid token error', () => {
    FcmPushService.pruneStaleToken(testDeviceToken);
    const device = db.prepare('SELECT * FROM devices WHERE device_token = ?').get(testDeviceToken);
    assert.strictEqual(device, undefined);
  });
});
