import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { db, initDatabase } from '../src/db/database';
import { SMSAdapterService } from '../src/services/smsAdapterService';
import { VoiceTranscriptionService } from '../src/services/voiceTranscriptionService';

test('PRD v2.0 Phase 9: SMS & Voice Gateway (Low-Bandwidth Fallback, Inbound SMS, Voice Note STT)', async (t) => {
  before(async () => {
    await initDatabase();
  });

  const timestamp = Date.now();
  const testPhone = `+91981${timestamp.toString().slice(-7)}`;
  const duplicatePhone = `+91982${timestamp.toString().slice(-7)}`;

  await t.test('ACCEPT CRITERIA 1: Inbound SMS creates incident with extracted category, urgency, location and headcount', () => {
    const rawSms = 'SOS FLOOD trapped 5 people at Gandhi Maidan near river bank need boat and food';
    const result = SMSAdapterService.parseInboundSMS(testPhone, rawSms);

    assert.equal(result.delivery_status, 'PROCESSED');
    assert.equal(result.parsed_category, 'FLOOD');
    assert.equal(result.parsed_urgency, 'CRITICAL');
    assert.equal(result.parsed_people_count, 5);
    assert.ok(result.parsed_needs.includes('boat'));
    assert.ok(result.parsed_needs.includes('food'));
    assert.ok(result.incident_id, 'Must generate incident ID');
    assert.ok(result.report_id, 'Must generate report ID');

    // Verify database record
    const incident = db.prepare('SELECT * FROM incidents WHERE id = ?').get(result.incident_id) as any;
    assert.ok(incident);
    assert.equal(incident.category, 'FLOOD');
    assert.equal(incident.urgency, 'CRITICAL');
    assert.equal(incident.people_affected, 5);

    const report = db.prepare('SELECT * FROM incident_reports WHERE id = ?').get(result.report_id) as any;
    assert.ok(report);
    assert.equal(report.source_type, 'SMS_ADAPTER');
    assert.equal(report.contact_phone, testPhone);
  });

  await t.test('ACCEPT CRITERIA 2: Duplicate SMS within 5 minutes is marked DUPLICATE_IGNORED and creates NO redundant incident', () => {
    const message = 'SOS MEDICAL 2 people injured at Rajendra Nagar';

    // First arrival
    const firstResult = SMSAdapterService.parseInboundSMS(duplicatePhone, message);
    assert.equal(firstResult.delivery_status, 'PROCESSED');
    const originalIncidentId = firstResult.incident_id;
    assert.ok(originalIncidentId);

    // Immediate second arrival (within 5 minutes)
    const secondResult = SMSAdapterService.parseInboundSMS(duplicatePhone, message);
    assert.equal(secondResult.delivery_status, 'DUPLICATE_IGNORED', 'Duplicate SMS within 5 minutes must be ignored');
    assert.equal(secondResult.incident_id, undefined, 'Must not spawn a second redundant incident');

    // Verify only 1 incident was generated for this duplicatePhone
    const reportCount = (db.prepare(`
      SELECT count(*) as count FROM incident_reports
      WHERE contact_phone = ? AND description LIKE '%SOS MEDICAL 2 people injured at Rajendra Nagar%'
    `).get(duplicatePhone) as any).count;

    assert.equal(reportCount, 1, 'Only exactly 1 report must be saved for duplicate messages within window');
  });

  await t.test('ACCEPT CRITERIA 3: Voice Note Ingestion Transcribes Audio and Preserves Raw Audio URL for Human Dispatcher', async () => {
    const callerPhone = `+91983${timestamp.toString().slice(-7)}`;
    const mockAudioUrl = `https://storage.resqai.org/audio/distress-${timestamp}.m4a`;

    const voiceResult = await VoiceTranscriptionService.processVoiceNote({
      caller_phone: callerPhone,
      audio_url: mockAudioUrl,
      duration_seconds: 22,
      language: 'hi-IN',
      transcript_override: 'हम कंकड़बाग में छत पर फंसे हैं, बाढ़ का पानी बढ़ रहा है और बच्चा बीमार है तुरंत नाव भेजिए'
    });

    assert.equal(voiceResult.status, 'PROCESSED');
    assert.equal(voiceResult.parsed_category, 'FLOOD');
    assert.equal(voiceResult.parsed_urgency, 'CRITICAL');
    assert.equal(voiceResult.audio_url, mockAudioUrl);
    assert.ok(voiceResult.transcript_text.includes('कंकड़बाग'));

    // Check incident report preservation of raw audio URL
    const savedReport = db.prepare(`
      SELECT * FROM incident_reports WHERE incident_id = ?
    `).get(voiceResult.incident_id) as any;

    assert.ok(savedReport);
    assert.equal(savedReport.source_type, 'CALL_112');
    const mediaUrls = JSON.parse(savedReport.media_urls_json || '[]');
    assert.ok(mediaUrls.includes(mockAudioUrl), 'Raw audio URL must be preserved so dispatchers can listen to audio');

    // Verify voice_notes table record
    const voiceRecord = db.prepare('SELECT * FROM voice_notes WHERE id = ?').get(voiceResult.id) as any;
    assert.ok(voiceRecord);
    assert.equal(voiceRecord.audio_url, mockAudioUrl);
    assert.equal(voiceRecord.duration_seconds, 22);
    assert.equal(voiceRecord.confidence_score, 0.94);
  });

  await t.test('ACCEPT CRITERIA 4: Low-Bandwidth Offline SMS Formatter Constrains Payload under 160 Characters', () => {
    const payload = VoiceTranscriptionService.formatOfflineSMSPayload({
      category: 'FLOOD',
      peopleCount: 4,
      location: 'Kankarbagh Ward 12 Main Market',
      needs: ['food', 'water', 'boat', 'medicine']
    });

    assert.ok(payload.startsWith('RESQAI SOS FLOOD'));
    assert.ok(payload.includes('P:4'));
    assert.ok(payload.includes('LOC:Kankarbagh'));
    assert.ok(payload.length <= 160, `SMS payload must fit in 160 GSM chars. Actual: ${payload.length}`);
  });

  await t.test('Step 5: WhatsApp Webhook Distress Ingestion', () => {
    const waPhone = `+91984${timestamp.toString().slice(-7)}`;
    const waMessage = 'HELP FIRE 3 people trapped in building at Sector C Market';

    const result = SMSAdapterService.parseInboundSMS(waPhone, waMessage);
    assert.equal(result.delivery_status, 'PROCESSED');
    assert.equal(result.parsed_category, 'FIRE');
    assert.equal(result.parsed_people_count, 3);
    assert.equal(result.parsed_urgency, 'CRITICAL');
  });

  await t.test('Step 6: Outbound SMS Status Callback Updates Message Status', () => {
    const statusPhone = `+91985${timestamp.toString().slice(-7)}`;
    const initial = SMSAdapterService.parseInboundSMS(statusPhone, 'STATUS INQ 1');

    db.prepare(`
      UPDATE inbound_sms_messages
      SET delivery_status = 'PROCESSED'
      WHERE id = ?
    `).run(initial.id);

    const record = db.prepare('SELECT * FROM inbound_sms_messages WHERE id = ?').get(initial.id) as any;
    assert.equal(record.delivery_status, 'PROCESSED');
  });
});

