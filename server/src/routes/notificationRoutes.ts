import { Router, Request, Response } from 'express';
import { authenticate } from '../middleware/rbacMiddleware';
import {
  registerDeviceToken,
  removeDeviceToken,
  sendTestNotification,
  getUserNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount,
} from '../services/notificationService';

export const notificationRouter = Router();

// NTF-3: Register device push token
notificationRouter.post('/register-device', authenticate, (req: Request, res: Response) => {
  const { deviceToken, deviceType = 'WEB_PUSH', endpoint, p256dh, authSecret } = req.body;
  if (!deviceToken) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'deviceToken is required' });
  }

  registerDeviceToken(req.user!.userId, deviceToken, deviceType, endpoint, p256dh, authSecret);
  return res.json({ success: true, message: 'Device registered for notifications (NTF-3)' });
});

// NTF-3 & SEC-4: Remove device token on logout
notificationRouter.post('/remove-device', authenticate, (req: Request, res: Response) => {
  const { deviceToken } = req.body;
  if (!deviceToken) {
    return res.status(400).json({ error: 'BAD_REQUEST', message: 'deviceToken is required' });
  }

  removeDeviceToken(req.user!.userId, deviceToken);
  return res.json({ success: true, message: 'Device token removed' });
});

// NTF-8: Send test notification to prove all 3 channels work (In-App, Push, SMS)
notificationRouter.post('/test', authenticate, async (req: Request, res: Response) => {
  try {
    const { phone } = req.body;
    const result = await sendTestNotification(req.user!.userId, phone);
    return res.json({
      success: true,
      message: 'Test notifications dispatched to all 3 channels (NTF-8)',
      channels: result,
    });
  } catch (err: any) {
    return res.status(500).json({ error: 'TEST_NOTIFICATION_FAILED', message: err.message });
  }
});

// NTF-1: Get unread count for bell icon
notificationRouter.get('/unread-count', authenticate, (req: Request, res: Response) => {
  const count = getUnreadCount(req.user!.userId);
  return res.json({ unreadCount: count });
});

// NTF-9: List user notifications with filtering
notificationRouter.get('/', authenticate, (req: Request, res: Response) => {
  const filter = req.query.filter as string | undefined;
  const notifications = getUserNotifications(req.user!.userId, filter);
  return res.json({ notifications, total: notifications.length });
});

// Mark single notification as read
notificationRouter.patch('/:id/read', authenticate, (req: Request, res: Response) => {
  markAsRead(String(req.params.id), req.user!.userId);
  return res.json({ success: true });
});

// Mark all notifications as read
notificationRouter.post('/mark-all-read', authenticate, (req: Request, res: Response) => {
  markAllAsRead(req.user!.userId);
  return res.json({ success: true });
});

// Delete notification
notificationRouter.delete('/:id', authenticate, (req: Request, res: Response) => {
  deleteNotification(String(req.params.id), req.user!.userId);
  return res.json({ success: true });
});
