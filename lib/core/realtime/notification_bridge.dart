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

    // Never bail out because previous is null.
    // Treat null previous (startup / reconnect / provider refresh) as empty
    // list so the very first batch is always processed.
    if (nextValue == null) return;

    final previousItems = previous?.valueOrNull?.items ?? [];

    final newItems = nextValue.items
        .where(
          (item) => !previousItems.any((p) => p.id == item.id),
        )
        .toList();

    // Diagnostics — visible in `flutter run` logcat.
    debugPrint('[NOTIF] previous=${previousItems.length}');
    debugPrint('[NOTIF] next=${nextValue.items.length}');
    debugPrint('[NOTIF] new=${newItems.length}');

    if (newItems.isEmpty) return;

    // TODO(phase-21.7-verify): foreground guard temporarily disabled so
    // notification delivery can be confirmed end-to-end.
    // Re-enable after verifying [NOTIF] sending appears in logs.
    debugPrint('[NOTIF] lifecycle=${_ref.read(appLifecycleProvider)}');

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
