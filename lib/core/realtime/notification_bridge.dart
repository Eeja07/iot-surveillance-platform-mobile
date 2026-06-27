import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notification/providers/notification_provider.dart';
import '../notifications/notification_provider.dart';
import '../observability/app_lifecycle_provider.dart';
import '../observability/observability_service.dart';
import 'connection_monitor.dart';
import 'dashboard_sync.dart';
import 'realtime_dispatcher.dart';
import 'realtime_lifecycle.dart';
import 'reverb_provider.dart';

class NotificationBridge {
  final Ref _ref;

  NotificationBridge(this._ref);

  void init() {
    _ref.read(reverbServiceProvider);
    _ref.read(realtimeLifecycleProvider);
    _ref.read(connectionMonitorProvider);
    _ref.read(realtimeDispatcherProvider);
    _ref.read(dashboardSyncProvider);
  }

  void handleNotificationChanged(
    AsyncValue<NotificationState>? previous,
    AsyncValue<NotificationState> next,
  ) {
    final nextValue = next.valueOrNull;
    final prevValue = previous?.valueOrNull;

    if (nextValue == null || prevValue == null) return;

    final newItems = nextValue.items
        .where(
          (item) => !prevValue.items.any((prevItem) => prevItem.id == item.id),
        )
        .toList();

    if (newItems.isEmpty) return;

    // Only fire Android notifications when the app is NOT in the foreground.
    // When app is open, provider invalidation already refreshes the UI.
    final lifecycle = _ref.read(appLifecycleProvider);
    final isInForeground = lifecycle == AppLifecycleState.resumed;

    if (isInForeground) {
      ObservabilityService.instance.info(
        '[NOTIF] App in foreground — skipping Android notification '
        '(${newItems.length} new item(s))',
      );
      return;
    }

    final localNotificationService = _ref.read(localNotificationServiceProvider);

    for (final item in newItems) {
      debugPrint('[NOTIF] sending — ${item.cameraName}: ${item.message}');
      ObservabilityService.instance.info(
        '[NOTIF] sending Android notification id=${item.id} camera=${item.cameraName}',
      );
      localNotificationService.showNotification(
        id: int.tryParse(item.id) ?? item.hashCode,
        title: 'Deteksi Objek: ${item.cameraName}',
        body: item.message,
        payload: item.id,
      );
    }
  }
}

final notificationBridgeProvider = Provider<NotificationBridge>((ref) {
  final bridge = NotificationBridge(ref);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    bridge.init();
  });

  ref.listen<AsyncValue<NotificationState>>(notificationProvider, (
    previous,
    next,
  ) {
    bridge.handleNotificationChanged(previous, next);
  });

  return bridge;
});
