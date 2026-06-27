// lib/features/notification/providers/notification_provider.dart
//
// NotificationProvider — Phase 4 Task 6 / Task 8
//
// Provides reactive state for CCTV alerts/notifications.
//
// Design contract:
// - NotificationService handles API communication (unchanged).
// - NotificationProvider manages loading, refreshing, and read status updates.
// - SessionService is NOT modified — token retrieved via sessionServiceProvider.
// - NotificationScreen / UI is NOT migrated in this task.
//
// Dependency: notificationRepositoryProvider (repository_providers.dart)
//

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/di/providers.dart';
import '../../../core/di/repository_providers.dart';

// ---------------------------------------------------------------------------
// CctvNotification — immutable value object
// ---------------------------------------------------------------------------

class CctvNotification {
  final String id;
  final int cameraId;
  final String cameraName;
  final String? imageUrl;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const CctvNotification({
    required this.id,
    required this.cameraId,
    required this.cameraName,
    this.imageUrl,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  CctvNotification copyWith({
    String? id,
    int? cameraId,
    String? cameraName,
    String? imageUrl,
    String? message,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return CctvNotification(
      id: id ?? this.id,
      cameraId: cameraId ?? this.cameraId,
      cameraName: cameraName ?? this.cameraName,
      imageUrl: imageUrl ?? this.imageUrl,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory CctvNotification.fromJson(Map<String, dynamic> json) {
    return CctvNotification(
      id: json['id']?.toString() ?? '',
      cameraId: json['camera_id'] as int? ?? 0,
      cameraName: json['camera_name'] as String? ?? 'Kamera',
      imageUrl: json['image_url'] as String?,
      message: json['message'] as String? ?? 'Terjadi deteksi gerakan',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// NotificationService — network boundary
// ---------------------------------------------------------------------------

class NotificationService {
  static const String _baseUrl = 'https://cctv.miot-its.org/api';

  const NotificationService();

  Future<List<CctvNotification>> fetchNotifications(String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/notifications');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> items = body['items'] ?? body['data'] ?? [];
        return items.map((item) => CctvNotification.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> markAsRead(String token, String notificationId) async {
    try {
      final uri = Uri.parse('$_baseUrl/notifications/$notificationId/read');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// NotificationState — immutable UI state
// ---------------------------------------------------------------------------

class NotificationState {
  final List<CctvNotification> items;
  final int unreadCount;

  const NotificationState({this.items = const [], this.unreadCount = 0});

  NotificationState copyWith({
    List<CctvNotification>? items,
    int? unreadCount,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// ---------------------------------------------------------------------------
// NotificationNotifier — AsyncNotifier
// ---------------------------------------------------------------------------

class NotificationNotifier extends AsyncNotifier<NotificationState> {
  @override
  Future<NotificationState> build() async {
    return _loadNotifications();
  }

  Future<NotificationState> _loadNotifications() async {
    final repository = ref.read(notificationRepositoryProvider);
    final list = await repository.fetchNotifications();
    final unread = list.where((item) => !item.isRead).length;

    return NotificationState(items: list, unreadCount: unread);
  }

  Future<void> refresh({bool isSilent = false}) async {
    if (!isSilent) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(_loadNotifications);
  }

  Future<bool> markAsRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) return false;

    // Keep backup for rollback
    final previousState = current;

    // Apply optimistic update immediately
    final updatedItems = current.items.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    final unread = updatedItems.where((item) => !item.isRead).length;

    state = AsyncData(
      current.copyWith(items: updatedItems, unreadCount: unread),
    );

    final repository = ref.read(notificationRepositoryProvider);
    final success = await repository.markAsRead(id);

    if (!success) {
      // Rollback on failure
      state = AsyncData(previousState);
    }
    return success;
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
      name: 'notificationProvider',
    );
