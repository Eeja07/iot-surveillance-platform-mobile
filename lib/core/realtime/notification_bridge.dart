import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifications/notification_provider.dart';
import '../observability/app_lifecycle_provider.dart';
import '../observability/observability_service.dart';
import 'connection_monitor.dart';
import 'dashboard_sync.dart';
import 'detection_event.dart';
import 'realtime_dispatcher.dart';
import 'realtime_lifecycle.dart';
import 'reverb_provider.dart';

/// Single source of Android notification delivery.
///
/// Architecture (Phase 21.8):
///   Reverb → RealtimeDispatcher → [handleRealtimeDetection] → showNotification()
///                               ↘ DashboardSync.invalidate()  → UI refresh
///
/// Notifications are now **event-driven** — no dependency on provider refresh
/// timing, no previous/next diffing, no delayed delivery.
class NotificationBridge {
  final Ref _ref;

  NotificationBridge(this._ref);

  /// Initialise all realtime sub-services.
  void init() {
    _ref.read(reverbServiceProvider);
    _ref.read(realtimeLifecycleProvider);
    _ref.read(connectionMonitorProvider);
    _ref.read(realtimeDispatcherProvider);
    _ref.read(dashboardSyncProvider);
  }

  /// Called by [RealtimeDispatcher] immediately on `person.detected`.
  ///
  /// Fires an Android notification when the app is NOT in the foreground.
  /// When in foreground, provider invalidation (handled by DashboardSync)
  /// already refreshes the UI — no notification needed.
  void handleRealtimeDetection(DetectionEvent event) {
    debugPrint('[NOTIF] event=${event.id}');
    debugPrint('[NOTIF] camera=${event.cameraName}');

    final lifecycle = _ref.read(appLifecycleProvider);
    debugPrint('[NOTIF] lifecycle=$lifecycle');

    final isForeground = lifecycle == AppLifecycleState.resumed;

    if (isForeground) {
      debugPrint('[NOTIF] foreground skip');
      ObservabilityService.instance.info(
        '[NOTIF] foreground — skipping Android notification id=${event.id}',
      );
      return;
    }

    debugPrint('[NOTIF] showNotification id=${event.id}');
    ObservabilityService.instance.info(
      '[NOTIF] sending Android notification id=${event.id} camera=${event.cameraName}',
    );

    _ref
        .read(localNotificationServiceProvider)
        .showNotification(
          id: event.id,
          title: 'Deteksi Objek: ${event.cameraName}',
          body: event.message,
          payload: event.id.toString(),
        );
  }
}

final notificationBridgeProvider = Provider<NotificationBridge>((ref) {
  final bridge = NotificationBridge(ref);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    bridge.init();
  });

  // No ref.listen — notifications are now event-driven via
  // handleRealtimeDetection(), not state-diff-driven.

  return bridge;
});
