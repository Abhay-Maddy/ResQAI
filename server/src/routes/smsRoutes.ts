import { Router, Request, Response } from 'express';
import { SMSAdapterService } from '../services/smsAdapterService';
import { VoiceTranscriptionService } from '../services/voiceTranscriptionService';
import { db } from '../db/database';

const router = Router();

// POST /api/v1/sms/inbound — Inbound SMS Gateway Webhook (FR-48, FR-50)
router.post('/inbound', (req: Request, res: Response) => {
  try {
    const { sender_phone, message, text } = req.body;
    const rawText = message || text;

    if (!sender_phone || !rawText) {
      return res.status(400).json({
        success: false,
        error: 'Missing required SMS payload: sender_phone, and message/text'
      });
    }

    const result = SMSAdapterService.parseInboundSMS(sender_phone, rawText);
    res.json({
      success: true,
      message: 'Inbound emergency SMS parsed and processed into incident pipeline (FR-50)',
      data: result
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/sms/whatsapp/inbound — Inbound WhatsApp Webhook (FR-50)
router.post('/whatsapp/inbound', (req: Request, res: Response) => {
  try {
    const { from, body, message } = req.body;
    const senderPhone = from || req.body.sender_phone;
    const rawText = body || message || req.body.text;

    if (!senderPhone || !rawText) {
      return res.status(400).json({
        success: false,
        error: 'Missing required WhatsApp payload: from/sender_phone and body/message'
      });
    }

    const result = SMSAdapterService.parseInboundSMS(senderPhone, rawText);
    res.json({
      success: true,
      channel: 'WHATSAPP',
      message: 'Inbound WhatsApp distress message processed into incident triage queue',
      data: result
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/sms/voice-note — Inbound Voice Note with STT Transcription & Audio Link
router.post('/voice-note', async (req: Request, res: Response) => {
  try {
    const { caller_phone, audio_url, duration_seconds, language, transcript_override } = req.body;

    if (!caller_phone) {
      return res.status(400).json({
        success: false,
        error: 'Missing required field: caller_phone'
      });
    }

    const result = await VoiceTranscriptionService.processVoiceNote({
      caller_phone,
      audio_url: audio_url || `/uploads/audio/VN-${Date.now()}.m4a`,
      duration_seconds: duration_seconds || 15,
      language: language || 'hi-IN',
      transcript_override
    });

    res.json({
      success: true,
      message: 'Voice note transcribed and incident filed with original audio preservation',
      data: result
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/sms/voice-notes/:id — Fetch voice note details
router.get('/voice-notes/:id', (req: Request, res: Response) => {
  try {
    const note = db.prepare('SELECT * FROM voice_notes WHERE id = ?').get(req.params.id);
    if (!note) {
      return res.status(404).json({ success: false, error: 'Voice note not found' });
    }
    res.json({ success: true, data: note });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/sms/simulate-offline-fallback — Generates formatted SMS under 160 chars
router.post('/simulate-offline-fallback', (req: Request, res: Response) => {
  try {
    const { category = 'FLOOD', people_count = 2, location = 'Sector A', needs = ['food', 'boat'] } = req.body;
    const formattedPayload = VoiceTranscriptionService.formatOfflineSMSPayload({
      category,
      peopleCount: people_count,
      location,
      needs
    });

    res.json({
      success: true,
      lengthChars: formattedPayload.length,
      isUnder160Chars: formattedPayload.length <= 160,
      smsPayload: formattedPayload,
      targetShortCode: '112 / 51969'
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/v1/sms/status-callback — Delivery receipts callback
router.post('/status-callback', (req: Request, res: Response) => {
  try {
    const { message_id, status = 'DELIVERED', error_code } = req.body;
    if (message_id) {
      db.prepare(`
        UPDATE inbound_sms_messages
        SET delivery_status = ?, provider_error = ?
        WHERE id = ?
      `).run(status === 'DELIVERED' ? 'PROCESSED' : 'PARSE_FAILED', error_code || null, message_id);
    }

    res.json({ success: true, received: true, status });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/v1/sms/messages — List inbound messages
router.get('/messages', (_req: Request, res: Response) => {
  try {
    const messages = SMSAdapterService.getAllInboundMessages();
    res.json({ success: true, count: messages.length, data: messages });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

export default router;
