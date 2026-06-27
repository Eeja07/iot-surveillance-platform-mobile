import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notification/providers/notification_provider.dart';
import '../notifications/notification_provider.dart';
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

    if (nextValue != null && prevValue != null) {
      final newItems = nextValue.items
          .where(
            (item) =>
                !prevValue.items.any((prevItem) => prevItem.id == item.id),
          )
          .toList();

      if (newItems.isNotEmpty) {
        final localNotificationService = _ref.read(
          localNotificationServiceProvider,
        );
        for (final item in newItems) {
          localNotificationService.showNotification(
            id: int.tryParse(item.id) ?? item.hashCode,
            title: 'Deteksi Objek: ${item.cameraName}',
            body: item.message,
            payload: item.id,
          );
        }
      }
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
