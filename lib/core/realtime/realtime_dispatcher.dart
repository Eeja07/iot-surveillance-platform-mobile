import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../observability/observability_service.dart';
import 'dashboard_sync.dart';

class RealtimeDispatcher {
  final Ref _ref;

  RealtimeDispatcher(this._ref);

  void dispatch(PusherEvent event) {
    ObservabilityService.instance.info(
      '[DISPATCHER] Event received: ${event.eventName}',
    );
    _ref.read(dashboardSyncProvider).handleEvent(event);
  }
}

final realtimeDispatcherProvider = Provider<RealtimeDispatcher>((ref) {
  return RealtimeDispatcher(ref);
});
