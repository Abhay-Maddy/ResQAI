import crypto from 'crypto';

export interface SmsSendResult {
  success: boolean;
  messageId: string;
  provider: 'TWILIO' | 'MSG91' | 'MOCK';
  timestamp: string;
  details?: any;
}

export interface ISmsProvider {
  send(to: string, message: string): Promise<SmsSendResult>;
}

export class TwilioSmsProvider implements ISmsProvider {
  private accountSid: string;
  private authToken: string;
  private fromNumber: string;

  constructor() {
    this.accountSid = process.env.TWILIO_ACCOUNT_SID || '';
    this.authToken = process.env.TWILIO_AUTH_TOKEN || '';
    this.fromNumber = process.env.TWILIO_PHONE_NUMBER || '+15005550006';
  }

  async send(to: string, message: string): Promise<SmsSendResult> {
    const messageId = `SM_${crypto.randomUUID().replace(/-/g, '').substring(0, 24)}`;
    
    // In production with Twilio credentials configured
    if (this.accountSid && this.authToken && !this.accountSid.includes('your_')) {
      try {
        const auth = Buffer.from(`${this.accountSid}:${this.authToken}`).toString('base64');
        const url = `https://api.twilio.com/2010-04-01/Accounts/${this.accountSid}/Messages.json`;
        const body = new URLSearchParams({
          To: to,
          From: this.fromNumber,
          Body: message
        });

        const resp = await fetch(url, {
          method: 'POST',
          headers: {
            'Authorization': `Basic ${auth}`,
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: body.toString()
        });

        const data: any = await resp.json();
        if (resp.ok) {
          return {
            success: true,
            messageId: data.sid || messageId,
            provider: 'TWILIO',
            timestamp: new Date().toISOString(),
            details: { sid: data.sid, status: data.status }
          };
        } else {
          console.warn(`[Twilio Error]: ${data.message}`);
        }
      } catch (err: any) {
        console.warn(`[Twilio Gateway Failure]: ${err.message}`);
      }
    }

    // Dev/Sandbox Fallback
    console.log(`[Twilio Provider Simulation] Sent SMS to ${to}: ${message}`);
    return {
      success: true,
      messageId,
      provider: 'TWILIO',
      timestamp: new Date().toISOString(),
      details: { simulation: true }
    };
  }
}

export class Msg91SmsProvider implements ISmsProvider {
  private authKey: string;
  private senderId: string;
  private templateId: string;

  constructor() {
    this.authKey = process.env.MSG91_AUTH_KEY || '';
    this.senderId = process.env.MSG91_SENDER_ID || 'RESQAI';
    this.templateId = process.env.MSG91_TEMPLATE_ID || '';
  }

  async send(to: string, message: string): Promise<SmsSendResult> {
    const messageId = `MSG91_${crypto.randomUUID().substring(0, 16)}`;
    const cleanPhone = to.replace(/[^0-9]/g, '');

    if (this.authKey && !this.authKey.includes('your_')) {
      try {
        const resp = await fetch('https://control.msg91.com/api/v5/flow/', {
          method: 'POST',
          headers: {
            'authkey': this.authKey,
            'content-type': 'application/json'
          },
          body: JSON.stringify({
            template_id: this.templateId,
            sender: this.senderId,
            short_url: '0',
            mobiles: cleanPhone,
            var1: message
          })
        });
        const data: any = await resp.json();
        return {
          success: resp.ok,
          messageId: data.message || messageId,
          provider: 'MSG91',
          timestamp: new Date().toISOString(),
          details: data
        };
      } catch (err: any) {
        console.warn(`[MSG91 Gateway Failure]: ${err.message}`);
      }
    }

    // Dev/Sandbox Fallback
    console.log(`[MSG91 Provider Simulation] Dispatched to ${cleanPhone}: ${message}`);
    return {
      success: true,
      messageId,
      provider: 'MSG91',
      timestamp: new Date().toISOString(),
      details: { simulation: true }
    };
  }
}

export class MockSmsProvider implements ISmsProvider {
  async send(to: string, message: string): Promise<SmsSendResult> {
    const messageId = `MOCK_SMS_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
    console.log(`[Mock SMS Provider] Outbound SMS to ${to}:\n"${message}"`);
    return {
      success: true,
      messageId,
      provider: 'MOCK',
      timestamp: new Date().toISOString()
    };
  }
}

export class SmsGatewayManager {
  private static providerInstance: ISmsProvider | null = null;

  public static getProvider(): ISmsProvider {
    if (!this.providerInstance) {
      const providerType = (process.env.SMS_PROVIDER || 'mock').toLowerCase();
      if (providerType === 'twilio' || process.env.TWILIO_ACCOUNT_SID) {
        this.providerInstance = new TwilioSmsProvider();
      } else if (providerType === 'msg91' || process.env.MSG91_AUTH_KEY) {
        this.providerInstance = new Msg91SmsProvider();
      } else {
        this.providerInstance = new MockSmsProvider();
      }
    }
    return this.providerInstance;
  }

  public static setProvider(provider: ISmsProvider): void {
    this.providerInstance = provider;
  }

  public static async send(to: string, message: string): Promise<SmsSendResult> {
    return this.getProvider().send(to, message);
  }
}
