import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/notification_client_service.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final AppNotificationItem notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  ConsumerState<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends ConsumerState<NotificationDetailScreen> {
  late AppNotificationItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.notification;
    // Automatically mark as read when user opens full detail page if it was unread
    if (!_item.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationsProvider.notifier).markAsRead(_item.id);
        setState(() {
          _item.isRead = true;
        });
      });
    }
  }

  void _toggleReadStatus(bool shouldBeRead) {
    if (shouldBeRead) {
      ref.read(notificationsProvider.notifier).markAsRead(_item.id);
      setState(() => _item.isRead = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as Read.'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      ref.read(notificationsProvider.notifier).markAsUnread(_item.id);
      setState(() => _item.isRead = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as Unread.'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  void _deleteNotification() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notification?'),
        content: const Text('This emergency bulletin will be removed from your notification history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notificationsProvider.notifier).deleteNotification(_item.id);
              Navigator.pop(context); // Close detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.emergencyRed;
      case 'HIGH':
      case 'WARN':
        return AppColors.warningOrange;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sevColor = _getSeverityColor(_item.severity);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Official Emergency Bulletin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          // Unread Button 1 (Top Bar Quick Action)
          IconButton(
            icon: Icon(
              _item.isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
              color: _item.isRead ? AppColors.primaryBlue : AppColors.successGreen,
            ),
            tooltip: _item.isRead ? 'Mark as Unread' : 'Mark as Read',
            onPressed: () => _toggleReadStatus(!_item.isRead),
          ),
          // Delete Icon Button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.emergencyRed),
            tooltip: 'Delete Notification',
            onPressed: _deleteNotification,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              // Unread Button 2 (Bottom Bar explicit Unread button)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: _item.isRead ? AppColors.primaryBlue : Colors.grey,
                    side: BorderSide(
                      color: _item.isRead ? AppColors.primaryBlue : Colors.grey.shade400,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.mark_as_unread, size: 16),
                  label: const Text('Mark Unread', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => _toggleReadStatus(false),
                ),
              ),
              const SizedBox(width: 8),

              // Read Button (Bottom Bar explicit Read button)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Mark Read', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => _toggleReadStatus(true),
                ),
              ),
              const SizedBox(width: 8),

              // Delete button mark
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed.withOpacity(0.12),
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.delete_forever, color: AppColors.emergencyRed, size: 20),
                tooltip: 'Delete',
                onPressed: _deleteNotification,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sevColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sevColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sevColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.warning_amber_rounded, color: sevColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sevColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _item.severity.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                  child: Text(
                                    _item.channel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : AppColors.deepNavy,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Icon(
                                      _item.isRead ? Icons.done_all : Icons.circle,
                                      size: 12,
                                      color: _item.isRead ? AppColors.successGreen : AppColors.primaryBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _item.isRead ? 'Read' : 'Unread',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _item.isRead ? AppColors.successGreen : AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Dispatched by ${_item.source}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : AppColors.deepNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Full Notification Title
                Text(
                  _item.title,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.deepNavy,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),

                // Meta Row: Timestamp & Location
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${_item.createdAt.hour.toString().padLeft(2, '0')}:${_item.createdAt.minute.toString().padLeft(2, '0')} • ${_item.createdAt.day}/${_item.createdAt.month}/${_item.createdAt.year}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (_item.location != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _item.location!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Full Body text (Read all of it)
                Text(
                  'Full Bulletin Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: isDark ? Colors.white70 : AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    _item.body,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.white : AppColors.deepNavy,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Instructions
                if (_item.instructions.isNotEmpty) ...[
                  Text(
                    'Civil Defense Safety Instructions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: isDark ? Colors.white70 : AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._item.instructions.map(
                    (inst) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4, right: 10),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              inst,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: isDark ? Colors.white70 : AppColors.deepNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 112 Helpline Emergency Assistance Call
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.emergencyRed.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_in_talk, color: AppColors.emergencyRed, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'National Emergency Helpline: 112',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.emergencyRed),
                            ),
                            Text(
                              '24/7 Police, Fire, Ambulance & NDRF Disaster Command Control Room',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : AppColors.mutedText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

