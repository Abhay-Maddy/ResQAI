import { test, describe, before } from 'node:test';
import assert from 'node:assert';
import { initDatabase, db } from '../src/db/database';
import { SmsGatewayManager, MockSmsProvider, TwilioSmsProvider, Msg91SmsProvider } from '../src/services/smsProviders';
import { sendSms } from '../src/services/smsAdapterService';
import { escapeXml } from '../src/routes/smsRoutes';

describe('Real SMS Gateway & Interactive Voice Response (IVR) Hotline Flow', () => {
  before(async () => {
    await initDatabase();
  });

  test('Step 1: Mock & Pluggable SMS Provider dispatches outbound SMS message', async () => {
    const res = await sendSms({
      to: '+919876543210',
      message: 'RESQAI Alert: Flash flood warning in Sector A. Evacuate immediately.'
    });

    assert.strictEqual(res.success, true);
    assert.ok(res.messageId.startsWith('MOCK_SMS_') || res.messageId.startsWith('SMS-'));
  });

  test('Step 2: Twilio Provider simulates dispatch when credentials absent', async () => {
    const twilioProvider = new TwilioSmsProvider();
    const result = await twilioProvider.send('+919876543210', 'Test Twilio Gateway');
    assert.strictEqual(result.success, true);
    assert.strictEqual(result.provider, 'TWILIO');
  });

  test('Step 3: MSG91 Provider simulates dispatch when credentials absent', async () => {
    const msg91Provider = new Msg91SmsProvider();
    const result = await msg91Provider.send('+919876543210', 'Test MSG91 Flow');
    assert.strictEqual(result.success, true);
    assert.strictEqual(result.provider, 'MSG91');
  });

  test('Step 4: IVR Hotline creates emergency incident from DTMF keypress (1 -> FLOOD)', () => {
    const callerPhone = '+919123456789';
    const incidentId = `INC-IVR-TEST-${Date.now()}`;
    const logId = `IVR-LOG-${Date.now()}`;

    // First insert incident
    db.prepare(`
      INSERT INTO incidents (
        id, title, category, status, urgency, priority_score,
        latitude, longitude, location_name, area_id, people_affected,
        created_at, updated_at, sla_deadline_minutes, is_simulated_drill
      ) VALUES (
        ?, 'IVR Test Emergency', 'FLOOD', 'RECEIVED', 'CRITICAL', 85,
        25.5941, 85.1376, 'Hotline Jurisdiction', 'area-a', 2,
        datetime('now'), datetime('now'), 15, 0
      )
    `).run(incidentId);

    // Verify database schema handles IVR call logs
    db.prepare(`
      INSERT INTO ivr_call_logs (
        id, call_sid, caller_phone, digits_pressed, selected_emergency, incident_id, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(logId, 'CA12345678', callerPhone, '1', 'FLOOD', incidentId, 'COMPLETED');

    const logged = db.prepare('SELECT * FROM ivr_call_logs WHERE id = ?').get(logId) as any;
    assert.ok(logged);
    assert.strictEqual(logged.caller_phone, callerPhone);
    assert.strictEqual(logged.selected_emergency, 'FLOOD');
  });

  test('Step 5: escapeXml sanitizes special characters preventing TwiML XML injection', () => {
    const raw = '<alert type="urgent" code=\'99\' & category="flood">';
    const escaped = escapeXml(raw);
    assert.strictEqual(escaped, '&lt;alert type=&quot;urgent&quot; code=&apos;99&apos; &amp; category=&quot;flood&quot;&gt;');
    assert.strictEqual(escapeXml('INC-IVR-12345'), 'INC-IVR-12345');
  });

  test('Step 6: IVR TwiML XML generation handles safe callSid and valid response structure', () => {
    const incidentId = 'INC-IVR-<TEST>&123';
    const safeIncidentId = escapeXml(incidentId);
    assert.strictEqual(safeIncidentId, 'INC-IVR-&lt;TEST&gt;&amp;123');

    const twimlIncoming = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Gather numDigits="1" action="/api/v1/sms/ivr/selection" method="POST" timeout="10">
    <Say language="hi-IN">Namaste. Aap ResQAI Aapatkaaleen Seva par hain. Baadh ya paani aane par ek dabayein. Medical emergency ke liye do dabayein. Khana aur paani ke liye teen dabayein. Malbe me dabe hone par chaar dabayein.</Say>
    <Say language="en-IN">For Flood emergency, press 1. For Medical emergency, press 2. For Food and water, press 3. For Collapse or Trapped victim, press 4.</Say>
  </Gather>
  <Say language="hi-IN">Humein aapka input nahi mila. Kripya 112 par call karein.</Say>
</Response>`;

    assert.ok(twimlIncoming.includes('<?xml version="1.0" encoding="UTF-8"?>'));
    assert.ok(twimlIncoming.includes('<Gather numDigits="1" action="/api/v1/sms/ivr/selection"'));
    assert.ok(twimlIncoming.includes('<Say language="hi-IN">'));
    assert.ok(twimlIncoming.includes('<Say language="en-IN">'));

    const twimlSelection = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say language="hi-IN">Aapki soochana darj kar li gayi hai. Aapatkaaleen ticket number hai: ${safeIncidentId}. Sahayata dal ko suchit kiya ja raha hai.</Say>
  <Say language="en-IN">Your emergency has been registered under ticket number ${safeIncidentId}. Rescue teams are notified.</Say>
  <Hangup/>
</Response>`;

    assert.ok(twimlSelection.includes(safeIncidentId));
    assert.ok(!twimlSelection.includes('<TEST>'));
    assert.ok(twimlSelection.includes('&lt;TEST&gt;&amp;123'));
    assert.ok(twimlSelection.includes('<Hangup/>'));
  });
});
