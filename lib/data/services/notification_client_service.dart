import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/repositories/auth_repository.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String channel;
  final String type;
  bool isRead;
  final DateTime createdAt;
  final String severity;
  final String source;
  final String? location;
  final List<String> instructions;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.channel = 'IN_APP',
    this.type = 'OFFICIAL_ALERT',
    this.isRead = false,
    required this.createdAt,
    this.severity = 'CRITICAL',
    this.source = 'National Disaster Management Authority (NDMA)',
    this.location,
    this.instructions = const [],
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final data = json['dataJson'] ?? json['data_json'] ?? {};
    final dataMap = data is String ? jsonDecode(data) : (data as Map<String, dynamic>? ?? {});

    List<String> parseInstructions(dynamic inst) {
      if (inst is List) return inst.map((e) => e.toString()).toList();
      return [
        'Follow instructions issued by local civil defense personnel.',
        'Keep emergency battery backups and official radio frequencies open.',
        'Do not attempt to cross flooded roadways or underpasses.',
      ];
    }

    return AppNotificationItem(
      id: json['id'] ?? 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? 'Emergency Notification',
      body: json['body'] ?? '',
      channel: json['channel'] ?? 'IN_APP',
      type: json['type'] ?? 'GENERAL',
      isRead: json['isRead'] == true || json['is_read'] == 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now()),
      severity: dataMap['severity']?.toString() ?? 'HIGH',
      source: dataMap['source']?.toString() ?? 'Government Disaster Management Cell',
      location: dataMap['affectedRegion']?.toString() ?? dataMap['location']?.toString() ?? 'NCR Region',
      instructions: parseInstructions(dataMap['instructions']),
    );
  }
}

final unreadNotificationCountProvider = StateProvider<int>((ref) => 2);

class NotificationsNotifier extends StateNotifier<List<AppNotificationItem>> {
  final Ref ref;
  static const String apiBaseUrl = 'http://localhost:5000/api/v1';

  NotificationsNotifier(this.ref) : super(_initialSeedNotifications()) {
    _updateUnreadCount();
  }

  static List<AppNotificationItem> _initialSeedNotifications() {
    return [
      AppNotificationItem(
        id: 'NOTIF-NDMA-101',
        title: '🚨 CRITICAL: Embankment Breach Advisory • Hindon Basin',
        body: 'Disaster management officers have reported rapid water level rise at Hindon Barrage exceeding safe threshold (128.5m). Evacuation advisory initiated for Sector 4, Vaishali low-lying colonies and nearby flood-plains.',
        channel: 'IN_APP',
        type: 'OFFICIAL_ALERT',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        severity: 'CRITICAL',
        source: 'NDMA & Central Water Commission (CWC)',
        location: 'Hindon Basin, Ghaziabad & East Delhi Borders',
        instructions: [
          'Immediate relocation of ground-floor residents to Sector 6 Relief Camp.',
          'Secure all electrical switches and LPG gas cylinders before leaving.',
          'Carry essential medical prescriptions, infant milk, and identity documents in waterproof bags.',
          'For evacuation boat rescue assistance, call DDMA emergency cell 1077 or 112.',
        ],
      ),
      AppNotificationItem(
        id: 'NOTIF-IMD-102',
        title: '⛈️ Heavy Monsoon Rainfall & Flash Flood Red Warning',
        body: 'Intense rain bands recorded over Delhi-NCR. Anticipate waterlogging along Underpass routes, NH-9 service lanes, and urban stormwater drain back-flows within next 3 to 6 hours.',
        channel: 'PUSH',
        type: 'WEATHER_ALERT',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
        severity: 'HIGH',
        source: 'India Meteorological Department (IMD Safdarjung)',
        location: 'Noida, Greater Noida & East Delhi District',
        instructions: [
          'Avoid non-essential vehicular travel through submerged subways.',
          'Report uprooted trees and fallen live electrical cables immediately.',
          'Verify shelter capacity status in ResQAI interactive map before departing.',
        ],
      ),
      AppNotificationItem(
        id: 'NOTIF-SHELTER-103',
        title: '🏕️ Community Relief Shelter Ready with 24/7 Medical Triage',
        body: 'Indirapuram Community Center Shelter #3 is activated with 450 bed capacity, potable drinking water tanker, clean dry rations, and child care nursery.',
        channel: 'IN_APP',
        type: 'RELIEF_UPDATE',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        severity: 'INFO',
        source: 'District Relief Commissioner Office',
        location: 'Indirapuram Sector 12 Center',
        instructions: [
          'Present Digital QR or phone number at gate for fast shelter allotment.',
          'Free hot meals served from 7:00 AM to 10:00 PM.',
        ],
      ),
    ];
  }

  void _updateUnreadCount() {
    final count = state.where((n) => !n.isRead).length;
    ref.read(unreadNotificationCountProvider.notifier).state = count;
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          AppNotificationItem(
            id: n.id,
            title: n.title,
            body: n.body,
            channel: n.channel,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
            severity: n.severity,
            source: n.source,
            location: n.location,
            instructions: n.instructions,
          )
        else
          n
    ];
    _updateUnreadCount();
    _syncPatchServer(id, isRead: true);
  }

  void markAsUnread(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          AppNotificationItem(
            id: n.id,
            title: n.title,
            body: n.body,
            channel: n.channel,
            type: n.type,
            isRead: false,
            createdAt: n.createdAt,
            severity: n.severity,
            source: n.source,
            location: n.location,
            instructions: n.instructions,
          )
        else
          n
    ];
    _updateUnreadCount();
    _syncPatchServer(id, isRead: false);
  }

  void markAllAsRead() {
    state = [
      for (final n in state)
        AppNotificationItem(
          id: n.id,
          title: n.title,
          body: n.body,
          channel: n.channel,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
          severity: n.severity,
          source: n.source,
          location: n.location,
          instructions: n.instructions,
        )
    ];
    _updateUnreadCount();
    _syncPostServer('mark-all-read');
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
    _updateUnreadCount();
    _syncDeleteServer(id);
  }

  void addAlertNotification({
    required String title,
    required String body,
    String severity = 'CRITICAL',
    String source = 'Disaster Management Cell',
    String? location,
    List<String>? instructions,
  }) {
    final newItem = AppNotificationItem(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      channel: 'IN_APP',
      type: 'OFFICIAL_ALERT',
      isRead: false,
      createdAt: DateTime.now(),
      severity: severity,
      source: source,
      location: location ?? 'NCR Region',
      instructions: instructions ?? const [
        'Heed official evacuation guidance immediately.',
        'Keep emergency supplies in a portable go-bag.',
      ],
    );
    state = [newItem, ...state];
    _updateUnreadCount();
  }

  Future<void> refreshFromServer() async {
    try {
      final user = ref.read(authProvider);
      if (user == null) return;

      final res = await http.get(
        Uri.parse('$apiBaseUrl/notifications'),
        headers: {
          'x-user-id': user.id,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['notifications'] as List? ?? [];
        if (list.isNotEmpty) {
          final serverItems = list.map((item) => AppNotificationItem.fromJson(item)).toList();
          state = serverItems;
          _updateUnreadCount();
        }
      }
    } catch (_) {
      // Graceful local fallback
    }
  }

  Future<void> _syncPatchServer(String id, {required bool isRead}) async {
    try {
      final user = ref.read(authProvider);
      final endpoint = isRead ? 'read' : 'unread';
      await http.patch(
        Uri.parse('$apiBaseUrl/notifications/$id/$endpoint'),
        headers: {
          if (user != null) 'x-user-id': user.id,
        },
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> _syncPostServer(String action) async {
    try {
      final user = ref.read(authProvider);
      await http.post(
        Uri.parse('$apiBaseUrl/notifications/$action'),
        headers: {
          if (user != null) 'x-user-id': user.id,
        },
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> _syncDeleteServer(String id) async {
    try {
      final user = ref.read(authProvider);
      await http.delete(
        Uri.parse('$apiBaseUrl/notifications/$id'),
        headers: {
          if (user != null) 'x-user-id': user.id,
        },
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotificationItem>>((ref) {
  return NotificationsNotifier(ref);
});
