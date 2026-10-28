import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/notification_client_service.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  static void showNotificationCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationsSheetModal(),
    );
  }

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'ALL'; // 'ALL', 'UNREAD', 'CRITICAL'

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = notifications.where((n) {
      if (_filter == 'UNREAD') return !n.isRead;
      if (_filter == 'CRITICAL') return n.severity == 'CRITICAL';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications & Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: unreadCount > 0 ? AppColors.emergencyRed : Colors.grey.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Mark all read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Notifications',
            onPressed: () => ref.read(notificationsProvider.notifier).refreshFromServer(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildFilterChip('All (${notifications.length})', 'ALL', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Unread ($unreadCount)', 'UNREAD', isDark, isHighlight: unreadCount > 0),
                const SizedBox(width: 8),
                _buildFilterChip('Critical', 'CRITICAL', isDark, isEmergency: true),
              ],
            ),
          ),

          // Notification List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'UNREAD' ? 'No unread notifications' : 'No notifications in this filter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildNotificationCard(context, item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark, {bool isHighlight = false, bool isEmergency = false}) {
    final isSelected = _filter == value;
    Color activeBg = AppColors.primaryBlue;
    if (isEmergency) activeBg = AppColors.emergencyRed;

    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeBg
              : (isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeBg
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.deepNavy),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotificationItem item, bool isDark) {
    Color sevColor = AppColors.primaryBlue;
    if (item.severity.toUpperCase() == 'CRITICAL') sevColor = AppColors.emergencyRed;
    if (item.severity.toUpperCase() == 'HIGH' || item.severity.toUpperCase() == 'WARN') sevColor = AppColors.warningOrange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Open full notification detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => NotificationDetailScreen(notification: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: !item.isRead
                  ? sevColor.withOpacity(0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: !item.isRead ? 1.5 : 1,
            ),
            boxShadow: [
              if (!item.isRead)
                BoxShadow(
                  color: sevColor.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Severity Badge, Unread Dot, Actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: sevColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.severity.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.source,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : AppColors.mutedText,
                    ),
                  ),
                  const Spacer(),
                  if (!item.isRead)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sevColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  // Read / Unread toggle icon
                  IconButton(
                    icon: Icon(
                      item.isRead ? Icons.mark_email_unread_outlined : Icons.check_circle_outline,
                      size: 18,
                      color: item.isRead ? AppColors.primaryBlue : AppColors.successGreen,
                    ),
                    tooltip: item.isRead ? 'Mark as Unread' : 'Mark as Read',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (item.isRead) {
                        ref.read(notificationsProvider.notifier).markAsUnread(item.id);
                      } else {
                        ref.read(notificationsProvider.notifier).markAsRead(item.id);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // Delete icon
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.emergencyRed),
                    tooltip: 'Delete Notification',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.read(notificationsProvider.notifier).deleteNotification(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification removed.'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 4),

              // Body Preview (Click to read all)
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? Colors.white70 : AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 8),

              // Bottom Info: Time & Tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')} • ${item.createdAt.day}/${item.createdAt.month}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Row(
                    children: [
                      Text(
                        'Read full bulletin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primaryBlue),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsSheetModal extends ConsumerWidget {
  const NotificationsSheetModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Emergency Bulletins',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: unreadCount > 0 ? AppColors.emergencyRed : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        ref.read(notificationsProvider.notifier).markAllAsRead();
                      },
                      child: const Text('Mark all read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('No active notifications'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final item = notifications[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => NotificationDetailScreen(notification: item),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !item.isRead
                                  ? AppColors.emergencyRed.withOpacity(0.4)
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: !item.isRead ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.severity == 'CRITICAL' ? AppColors.emergencyRed : AppColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.severity,
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.source,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      item.isRead ? Icons.mark_email_unread_outlined : Icons.check_circle_outline,
                                      size: 16,
                                      color: item.isRead ? AppColors.primaryBlue : AppColors.successGreen,
                                    ),
                                    tooltip: item.isRead ? 'Mark as Unread' : 'Mark as Read',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      if (item.isRead) {
                                        ref.read(notificationsProvider.notifier).markAsUnread(item.id);
                                      } else {
                                        ref.read(notificationsProvider.notifier).markAsRead(item.id);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.emergencyRed),
                                    tooltip: 'Delete Notification',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      ref.read(notificationsProvider.notifier).deleteNotification(item.id);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Read full bulletin →',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

