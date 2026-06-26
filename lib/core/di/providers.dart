// lib/core/di/providers.dart
//
// Provider Registry — Phase 4 Riverpod Foundation (Tasks 1, 3, 4, 5, 8)
//
// Bridge layer between legacy AppLocator / service singletons and Riverpod.
// Exposes existing services as Riverpod providers WITHOUT migrating them.
//
// Dependency direction (Task 8):
//   Service singleton
//     → service provider  (this file)
//     → repository provider (repository_providers.dart)
//     → feature notifier  (dashboard/camera/notification _provider.dart)
//
// Consumer map:
//   sessionServiceProvider        → session_state_provider.dart (SessionStateNotifier)
//   authControllerProvider        → auth_provider.dart          (AuthNotifier)
//   cameraServiceProvider         → repository_providers.dart   (DashboardRepository, CameraRepository)
//   notificationServiceProvider   → repository_providers.dart   (NotificationRepository)
//
// Rules:
// - Do NOT modify SessionService, AuthController, or any service here.
// - Do NOT add business logic here.
// - This file is the ONLY place that reads from AppLocator inside Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'injection.dart';
import '../storage/session_service.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../services/camera_service.dart';
import '../../features/notification/providers/notification_provider.dart';

/// Provides the [SessionService] singleton from [AppLocator].
///
/// Scoped to the lifetime of [ProviderScope] (i.e., entire app).
/// Consumed by [SessionStateNotifier] in session_state_provider.dart.
/// SessionService itself is unchanged — this is purely a lookup bridge.
final sessionServiceProvider = Provider<SessionService>(
  (ref) => AppLocator.instance.sessionService,
  name: 'sessionServiceProvider',
);

/// Provides the [AuthController] singleton from [AppLocator].
///
/// AuthController extends ChangeNotifier and is managed by AppLocator.
/// Consumed by [AuthNotifier] in auth_provider.dart — subscribed via
/// addListener so that state changes are reflected in [authProvider].
///
/// Widget usage directly is discouraged; prefer [authProvider] instead.
final authControllerProvider = Provider<AuthController>(
  (ref) => AppLocator.instance.authController,
  name: 'authControllerProvider',
);

/// Provides a [CameraService] instance for dashboard data loading.
///
/// [CameraService] is the existing data source for camera groups and images.
/// It is NOT a repository in the DDD sense, but is the current data boundary.
/// Consumed by [DashboardNotifier] in dashboard_provider.dart.
///
/// CameraService itself is unchanged — this is purely a lookup bridge.
final cameraServiceProvider = Provider<CameraService>(
  (ref) => CameraService(),
  name: 'cameraServiceProvider',
);

/// Provides a [NotificationService] instance.
///
/// Consumed by [NotificationNotifier] in notification_provider.dart.
/// NotificationService itself is untouched — this is purely a lookup bridge.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => const NotificationService(),
  name: 'notificationServiceProvider',
);
