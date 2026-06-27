import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reverb_service.dart';
import '../observability/observability_service.dart';
import 'detection_event.dart';
import 'notification_bridge.dart';
import 'dashboard_sync.dart';

/// Routes incoming Reverb events to the correct handlers.
///
/// For `person.detected` (Phase 21.8):
///   1. NotificationBridge.handleRealtimeDetection() — fire Android notification
///      immediately from the event payload (before any HTTP round-trip).
///   2. DashboardSync.handleEvent()                  — invalidate providers
///      so the UI (dashboard, detections, notifications) refreshes.
///
/// Notification fires BEFORE invalidation so there is zero dependency on
/// HTTP response timing.
class RealtimeDispatcher {
  final Ref _ref;

  RealtimeDispatcher(this._ref);

  void dispatch(PusherEvent event) {
    ObservabilityService.instance.info(
      '[DISPATCHER] Event received: ${event.eventName}',
    );

    if (event.eventName == 'person.detected') {
      _handlePersonDetected(event);
    }

    // Always hand the event to DashboardSync for provider invalidation.
    _ref.read(dashboardSyncProvider).handleEvent(event);
  }

  void _handlePersonDetected(PusherEvent event) {
    // Parse the raw Reverb payload into a typed DetectionEvent.
    final detectionEvent = DetectionEvent.tryParse(event.data);

    if (detectionEvent == null) {
      ObservabilityService.instance.info(
        '[DISPATCHER] person.detected — could not parse payload, skipping notification',
      );
      return;
    }

    ObservabilityService.instance.info(
      '[DISPATCHER] person.detected — id=${detectionEvent.id} camera=${detectionEvent.cameraName}',
    );

    // Fire notification immediately from the Reverb event payload.
    // This happens BEFORE the HTTP refresh so there is no timing dependency.
    _ref
        .read(notificationBridgeProvider)
        .handleRealtimeDetection(detectionEvent);
  }
}

final realtimeDispatcherProvider = Provider<RealtimeDispatcher>((ref) {
  return RealtimeDispatcher(ref);
});
