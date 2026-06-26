// lib/core/di/repository_providers.dart
//
// Repository Adapter Layer — Phase 4 Task 8
//
// Thin adapter providers that sit between the raw Service singletons
// and the feature-level AsyncNotifier providers.
//
// Design contract:
// - Services (CameraService, NotificationService) are NOT modified.
// - SessionService is NOT modified.
// - AuthController / GoRouter are NOT touched.
// - UI layer (HomeScreen, CameraDetailScreen) is NOT touched.
//
// Dependency direction:
//   Service (singleton) → repository provider → feature provider → UI
//
// The "repository" here is intentionally thin — it wraps the existing
// service interface as a typed Riverpod provider so that:
//   1. Feature providers declare dependencies on repositories, not services.
//   2. The concrete service backing a repository can be swapped in one place.
//   3. The seam is testable (override repositoryProvider in tests).
//
// Consumer map:
//   dashboardRepositoryProvider    → dashboard_provider.dart (DashboardNotifier)
//   cameraRepositoryProvider       → camera_provider.dart    (CameraDetailNotifier)
//   notificationRepositoryProvider → notification_provider.dart (NotificationNotifier)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/camera_model.dart';
import '../../services/camera_service.dart';
import '../../features/notification/providers/notification_provider.dart';
import 'providers.dart';

// ---------------------------------------------------------------------------
// DashboardRepository — camera groups & thumbnail data
// ---------------------------------------------------------------------------

/// Thin repository adapter for dashboard / camera-group data.
///
/// Wraps [CameraService] so that [DashboardNotifier] depends on this
/// adapter rather than directly on [cameraServiceProvider].
///
/// Backed by [CameraService] which remains unmodified.
class DashboardRepository {
  final CameraService _service;

  const DashboardRepository(this._service);

  /// Fetches all camera groups with their cameras.
  Future<List<CameraGroup>> fetchCameraGroups(String token) =>
      _service.fetchCameraGroups(token);

  /// Returns the most recent image URL for [cameraId], or null.
  Future<String?> getLatestImage(String token, String cameraId) =>
      _service.getLatestImage(token, cameraId);
}

/// Provides a [DashboardRepository] backed by [CameraService].
///
/// Override in tests:
/// ```dart
/// container = ProviderContainer(overrides: [
///   dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
/// ]);
/// ```
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(cameraServiceProvider)),
  name: 'dashboardRepositoryProvider',
);

// ---------------------------------------------------------------------------
// CameraRepository — recording history & image detail
// ---------------------------------------------------------------------------

/// Thin repository adapter for camera detail / recording history data.
///
/// Wraps [CameraService] so that [CameraDetailNotifier] depends on this
/// adapter rather than directly on [cameraServiceProvider].
class CameraRepository {
  final CameraService _service;

  const CameraRepository(this._service);

  /// Returns history stats for [cameraId]; optionally filtered by [date]/[hour].
  Future<Map<String, dynamic>> getHistoryStats(
    String token,
    String cameraId, {
    String? date,
    String? hour,
  }) => _service.getHistoryStats(token, cameraId, date: date, hour: hour);

  /// Returns images for [cameraId] at the given [date]/[hour]/[minute].
  Future<List<Map<String, dynamic>>> getHistoryImages({
    required String token,
    required String cameraId,
    required String date,
    required String hour,
    required String minute,
  }) => _service.getHistoryImages(
    token: token,
    cameraId: cameraId,
    date: date,
    hour: hour,
    minute: minute,
  );

  /// Returns the most recent image URL for [cameraId], or null.
  Future<String?> getLatestImage(String token, String cameraId) =>
      _service.getLatestImage(token, cameraId);

  /// Deletes [cameraId] via the API.
  Future<Map<String, dynamic>> deleteCamera(String token, String cameraId) =>
      _service.deleteCamera(token, cameraId);
}

/// Provides a [CameraRepository] backed by [CameraService].
final cameraRepositoryProvider = Provider<CameraRepository>(
  (ref) => CameraRepository(ref.watch(cameraServiceProvider)),
  name: 'cameraRepositoryProvider',
);

// ---------------------------------------------------------------------------
// NotificationRepository — CCTV alert data
// ---------------------------------------------------------------------------

/// Thin repository adapter for CCTV notification data.
///
/// Wraps [NotificationService] so that [NotificationNotifier] depends on
/// this adapter rather than directly on [notificationServiceProvider].
class NotificationRepository {
  final NotificationService _service;

  const NotificationRepository(this._service);

  /// Fetches all notifications for the authenticated user.
  Future<List<CctvNotification>> fetchNotifications(String token) =>
      _service.fetchNotifications(token);

  /// Marks notification [id] as read.
  Future<bool> markAsRead(String token, String id) =>
      _service.markAsRead(token, id);
}

/// Provides a [NotificationRepository] backed by [NotificationService].
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(notificationServiceProvider)),
  name: 'notificationRepositoryProvider',
);
