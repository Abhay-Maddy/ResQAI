import '../../core/constants/app_constants.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/repositories/auth_repository.dart';
import 'storage_service.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String channel;
  final String
      type; // SOS, DISASTER_ALERT, NGO_REPORT, REQUIREMENT, DONATION, SYSTEM
  bool isRead;
  final DateTime createdAt;
  final String severity; // CRITICAL, HIGH, WARN, INFO
  final String source;
  final String? location;
  final List<String> instructions;
  final String senderId;
  final String senderRole;
  final List<String> targetRoles;
  final String direction; // RECEIVED or SENT
  final String status; // DELIVERED, BROADCAST ACTIVE, RESOLVED, PENDING

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.channel = 'IN_APP',
    this.type = 'DISASTER_ALERT',
    this.isRead = false,
    required this.createdAt,
    this.severity = 'CRITICAL',
    this.source = 'National Disaster Management Authority (NDMA)',
    this.location,
    this.instructions = const [],
    this.senderId = 'SYSTEM',
    this.senderRole = 'GOVT_OFFICIAL',
    this.targetRoles = const ['ALL'],
    this.direction = 'RECEIVED',
    this.status = 'DELIVERED',
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final data = json['dataJson'] ?? json['data_json'] ?? {};
    final dataMap = data is String
        ? jsonDecode(data)
        : (data as Map<String, dynamic>? ?? {});

    List<String> parseInstructions(dynamic inst) {
      if (inst is List) return inst.map((e) => e.toString()).toList();
      return [
        'Follow instructions issued by local civil defense personnel.',
        'Keep emergency battery backups and official radio frequencies open.',
        'Do not attempt to cross flooded roadways or underpasses.',
      ];
    }

    List<String> parseTargets(dynamic t) {
      if (t is List) return t.map((e) => e.toString()).toList();
      return ['ALL'];
    }

    return AppNotificationItem(
      id: json['id'] ?? 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? 'Emergency Notification',
      body: json['body'] ?? '',
      channel: json['channel'] ?? 'IN_APP',
      type: json['type'] ?? 'DISASTER_ALERT',
      isRead: json['isRead'] == true || json['is_read'] == 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
              : DateTime.now()),
      severity: dataMap['severity']?.toString() ??
          json['severity']?.toString() ??
          'HIGH',
      source: dataMap['source']?.toString() ??
          json['source']?.toString() ??
          'Government Disaster Cell',
      location: dataMap['affectedRegion']?.toString() ??
          dataMap['location']?.toString() ??
          json['location']?.toString() ??
          'NCR Region',
      instructions:
          parseInstructions(dataMap['instructions'] ?? json['instructions']),
      senderId: json['senderId']?.toString() ??
          dataMap['senderId']?.toString() ??
          'SYSTEM',
      senderRole: json['senderRole']?.toString() ??
          dataMap['senderRole']?.toString() ??
          'GOVT_OFFICIAL',
      targetRoles: parseTargets(json['targetRoles'] ?? dataMap['targetRoles']),
      direction: json['direction']?.toString() ?? 'RECEIVED',
      status: json['status']?.toString() ?? 'DELIVERED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'channel': channel,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'severity': severity,
      'source': source,
      'location': location,
      'instructions': instructions,
      'senderId': senderId,
      'senderRole': senderRole,
      'targetRoles': targetRoles,
      'direction': direction,
      'status': status,
    };
  }
}

final unreadNotificationCountProvider = StateProvider<int>((ref) => 2);

class NotificationsNotifier extends StateNotifier<List<AppNotificationItem>> {
  final Ref ref;
  static String get apiBaseUrl => AppConstants.apiBaseUrl;

  NotificationsNotifier(this.ref) : super(_loadInitialNotifications()) {
    _updateUnreadCount();
  }

  static List<AppNotificationItem> _loadInitialNotifications() {
    try {
      final saved = StorageService.getString('resqai_persisted_notifications');
      if (saved != null && saved.isNotEmpty) {
        final list = jsonDecode(saved) as List;
        if (list.isNotEmpty) {
          return list
              .map((e) =>
                  AppNotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return _initialSeedNotifications();
  }

  void _persistNotifications() {
    try {
      final jsonList = state.map((n) => n.toJson()).toList();
      StorageService.setString(
          'resqai_persisted_notifications', jsonEncode(jsonList));
    } catch (_) {}
  }

  static List<AppNotificationItem> _initialSeedNotifications() {
    return [
      AppNotificationItem(
        id: 'NOTIF-NDMA-101',
        title: '🚨 CRITICAL: Embankment Breach Advisory • Hindon Basin',
        body:
            'Disaster management officers have reported rapid water level rise at Hindon Barrage exceeding safe threshold (128.5m). Evacuation advisory initiated for Sector 4, Vaishali low-lying colonies and nearby flood-plains.',
        channel: 'IN_APP',
        type: 'DISASTER_ALERT',
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
        senderRole: 'GOVT_OFFICIAL',
        targetRoles: ['CITIZEN', 'NGO_LEAD', 'VOLUNTEER'],
        direction: 'RECEIVED',
        status: 'DELIVERED',
      ),
      AppNotificationItem(
        id: 'NOTIF-IMD-102',
        title: '⛈️ Heavy Monsoon Rainfall & Flash Flood Red Warning',
        body:
            'Intense rain bands recorded over Delhi-NCR. Anticipate waterlogging along Underpass routes, NH-9 service lanes, and urban stormwater drain back-flows within next 3 to 6 hours.',
        channel: 'PUSH',
        type: 'DISASTER_ALERT',
        isRead: false,
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
        severity: 'HIGH',
        source: 'India Meteorological Department (IMD Safdarjung)',
        location: 'Noida, Greater Noida & East Delhi District',
        instructions: [
          'Avoid non-essential vehicular travel through submerged subways.',
          'Report uprooted trees and fallen live electrical cables immediately.',
          'Verify shelter capacity status in ResQAI interactive map before departing.',
        ],
        senderRole: 'GOVT_OFFICIAL',
        targetRoles: ['ALL'],
        direction: 'RECEIVED',
        status: 'DELIVERED',
      ),
      AppNotificationItem(
        id: 'NOTIF-SHELTER-103',
        title: '🏕️ Community Relief Shelter Ready with 24/7 Medical Triage',
        body:
            'Indirapuram Community Center Shelter #3 is activated with 450 bed capacity, potable drinking water tanker, clean dry rations, and child care nursery.',
        channel: 'IN_APP',
        type: 'NGO_REPORT',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        severity: 'INFO',
        source: 'District Relief Commissioner Office',
        location: 'Indirapuram Sector 12 Center',
        instructions: [
          'Present Digital QR or phone number at gate for fast shelter allotment.',
          'Free hot meals served from 7:00 AM to 10:00 PM.',
        ],
        senderRole: 'NGO_LEAD',
        targetRoles: ['CITIZEN', 'VOLUNTEER'],
        direction: 'RECEIVED',
        status: 'DELIVERED',
      ),
      // Seed Sent Broadcasts / Transmissions (for Sent Tab)
      AppNotificationItem(
        id: 'NOTIF-SENT-201',
        title: '📢 Public Evacuation Route Advisory • Vaishali Sector 4',
        body:
            'Directed high-clearance SDRF trucks to Vaishali Metro station for low-lying civilian evacuation. Safe corridor along Link Road opened.',
        channel: 'BROADCAST',
        type: 'DISASTER_ALERT',
        isRead: true,
        createdAt:
            DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
        severity: 'HIGH',
        source: 'My Incident Command Station',
        location: 'Vaishali Sector 4 to 6',
        instructions: [
          'Move strictly in organized groups towards higher elevation points.',
        ],
        senderRole: 'GOVT_OFFICIAL',
        targetRoles: ['CITIZEN', 'VOLUNTEER'],
        direction: 'SENT',
        status: 'BROADCAST ACTIVE',
      ),
      AppNotificationItem(
        id: 'NOTIF-SENT-202',
        title: '🆘 Emergency Medical & Potable Water Requirement Dispatched',
        body:
            'Dispatched emergency requirement notice for 150 water purification kits and child rehydration salts for Hindon transit shelter.',
        channel: 'IN_APP',
        type: 'REQUIREMENT',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        severity: 'CRITICAL',
        source: 'Field Command Dispatcher',
        location: 'Hindon Transit Shelter Camp',
        instructions: [
          'Deliver to Camp In-charge officer directly.',
        ],
        senderRole: 'NGO_LEAD',
        targetRoles: ['GOVT_OFFICIAL', 'VOLUNTEER'],
        direction: 'SENT',
        status: 'DELIVERED',
      ),
    ];
  }

  void _updateUnreadCount() {
    final count =
        state.where((n) => n.direction == 'RECEIVED' && !n.isRead).length;
    ref.read(unreadNotificationCountProvider.notifier).state = count;
  }

  void markAsRead(String id) {
    _persistNotifications();
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
            senderId: n.senderId,
            senderRole: n.senderRole,
            targetRoles: n.targetRoles,
            direction: n.direction,
            status: n.status,
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
            senderId: n.senderId,
            senderRole: n.senderRole,
            targetRoles: n.targetRoles,
            direction: n.direction,
            status: n.status,
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
          senderId: n.senderId,
          senderRole: n.senderRole,
          targetRoles: n.targetRoles,
          direction: n.direction,
          status: n.status,
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
    String type = 'DISASTER_ALERT',
    String direction = 'RECEIVED',
    String status = 'DELIVERED',
  }) {
    final newItem = AppNotificationItem(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      channel: 'IN_APP',
      type: type,
      isRead: direction == 'SENT',
      createdAt: DateTime.now(),
      severity: severity,
      source: source,
      location: location ?? 'NCR Region',
      instructions: instructions ??
          const [
            'Heed official evacuation guidance immediately.',
            'Keep emergency supplies in a portable go-bag.',
          ],
      direction: direction,
      status: status,
    );
    state = [newItem, ...state];
    _updateUnreadCount();
    _persistNotifications();
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
          final serverItems =
              list.map((item) => AppNotificationItem.fromJson(item)).toList();
          state = serverItems;
          _updateUnreadCount();
        }
      }
    } catch (_) {
      // Graceful local fallback with preserved offline state
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

  Future<bool> registerDeviceToken(String deviceToken,
      {String deviceType = 'FCM_MOBILE'}) async {
    try {
      final user = ref.read(authProvider);
      final resp = await http
          .post(
            Uri.parse('$apiBaseUrl/notifications/register-device'),
            headers: {
              'Content-Type': 'application/json',
              if (user != null) 'x-user-id': user.id,
            },
            body: jsonEncode({
              'deviceToken': deviceToken,
              'deviceType': deviceType,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> subscribeToTopic(String topic) async {
    try {
      final user = ref.read(authProvider);
      final resp = await http
          .post(
            Uri.parse('$apiBaseUrl/notifications/subscribe-topic'),
            headers: {
              'Content-Type': 'application/json',
              if (user != null) 'x-user-id': user.id,
            },
            body: jsonEncode({'topic': topic}),
          )
          .timeout(const Duration(seconds: 4));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
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

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotificationItem>>(
        (ref) {
  return NotificationsNotifier(ref);
});
