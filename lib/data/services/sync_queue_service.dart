import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

enum SyncStatus { pending, syncing, synced, failed }

class SyncQueueItem {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;
  SyncStatus status;
  String? lastError;

  SyncQueueItem({
    required this.id,
    required this.endpoint,
    this.method = 'POST',
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'status': status.name,
        'lastError': lastError,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'] as String,
        endpoint: json['endpoint'] as String,
        method: json['method'] as String? ?? 'POST',
        payload: json['payload'] as Map<String, dynamic>,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
        status: SyncStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SyncStatus.pending,
        ),
        lastError: json['lastError'] as String?,
      );
}

class SyncQueueNotifier extends StateNotifier<List<SyncQueueItem>> {
  SyncQueueNotifier() : super([]);

  /// Enqueue an action performed while offline (SOS, damage claim, or verification)
  void enqueue({
    required String endpoint,
    required Map<String, dynamic> payload,
    String method = 'POST',
  }) {
    final item = SyncQueueItem(
      id: 'SYNC-${DateTime.now().millisecondsSinceEpoch}',
      endpoint: endpoint,
      method: method,
      payload: payload,
      createdAt: DateTime.now(),
    );
    state = [...state, item];
  }

  /// Remove a successfully synced item
  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  /// Number of items awaiting sync
  int get pendingCount =>
      state.where((item) => item.status == SyncStatus.pending || item.status == SyncStatus.failed).length;

  /// Attempt to synchronize all pending offline operations
  Future<int> syncAll({String? authToken}) async {
    final pendingItems = state.where((item) => item.status != SyncStatus.synced).toList();
    if (pendingItems.isEmpty) return 0;

    int successCount = 0;
    final updatedList = List<SyncQueueItem>.from(state);

    for (final item in pendingItems) {
      final index = updatedList.indexWhere((e) => e.id == item.id);
      if (index == -1) continue;

      updatedList[index].status = SyncStatus.syncing;
      state = List.from(updatedList);

      try {
        final uri = Uri.parse('${AppConstants.apiBaseUrl}${item.endpoint}');
        final headers = {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        };

        http.Response response;
        if (item.method == 'POST') {
          response = await http
              .post(uri, headers: headers, body: jsonEncode(item.payload))
              .timeout(const Duration(seconds: 5));
        } else if (item.method == 'PATCH') {
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(item.payload))
              .timeout(const Duration(seconds: 5));
        } else {
          response = await http
              .put(uri, headers: headers, body: jsonEncode(item.payload))
              .timeout(const Duration(seconds: 5));
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          updatedList[index].status = SyncStatus.synced;
          successCount++;
        } else {
          updatedList[index].status = SyncStatus.failed;
          updatedList[index].retryCount++;
          updatedList[index].lastError = 'HTTP ${response.statusCode}';
        }
      } catch (e) {
        updatedList[index].status = SyncStatus.failed;
        updatedList[index].retryCount++;
        updatedList[index].lastError = e.toString();
      }

      state = List.from(updatedList);
    }

    // Automatically remove fully synced items to keep queue lean
    state = state.where((item) => item.status != SyncStatus.synced).toList();

    return successCount;
  }
}

final syncQueueProvider = StateNotifierProvider<SyncQueueNotifier, List<SyncQueueItem>>((ref) {
  return SyncQueueNotifier();
});
