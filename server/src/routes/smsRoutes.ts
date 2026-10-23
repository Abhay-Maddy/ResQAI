import { Router, Request, Response } from 'express';
import { SMSAdapterService } from '../services/smsAdapterService';

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
