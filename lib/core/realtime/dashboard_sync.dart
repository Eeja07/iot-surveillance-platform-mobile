import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/detection/providers/detection_provider.dart';
import '../../features/notification/providers/notification_provider.dart';
import '../../features/camera/providers/camera_config_provider.dart';
import '../../features/ota/providers/ota_provider.dart';
import '../observability/app_lifecycle_provider.dart';
import '../observability/observability_service.dart';
import '../notifications/notification_provider.dart';
import 'reverb_service.dart';

class DashboardSync {
  final Ref _ref;
  Timer? _debounceTimer;
  final Set<ProviderOrFamily> _pendingInvalidations = {};
  final Set<int> _pendingCameraConfigInvalidations = {};

  DashboardSync(this._ref);

  void handleEvent(PusherEvent event) {
    ObservabilityService.instance.info(
      '[SYNC] Handling event: ${event.eventName}',
    );

    switch (event.eventName) {
      case 'person.detected':
        // Always refresh data providers — works in foreground and background.
        _ref.invalidate(detectionProvider);
        _ref.invalidate(notificationProvider);
        _ref.invalidate(overviewProvider);
        _ref.invalidate(cameraProvider);

        // Fire a native Android notification ONLY when the app is not in the
        // foreground (minimised, screen locked, or force-stopped).
        // When the app is open the refreshed providers already update the UI.
        try {
          final Map<String, dynamic> payload = event.data is String
              ? json.decode(event.data as String) as Map<String, dynamic>
              : Map<String, dynamic>.from(event.data as Map);

          final lifecycle = _ref.read(appLifecycleProvider);
          final isInForeground = lifecycle == AppLifecycleState.resumed;

          if (!isInForeground) {
            ObservabilityService.instance.info(
              '[SYNC] App in background — sending native notification',
            );
            _showNativeNotification(payload);
          } else {
            ObservabilityService.instance.info(
              '[SYNC] App in foreground — skipping native notification',
            );
          }
        } catch (e, stack) {
          ObservabilityService.instance.reportError(
            e,
            stack,
            hint: 'Failed parsing person.detected event data',
          );
        }
        break;

      case 'image.received':
      case 'telemetry.updated':
      case 'camera.online':
      case 'camera.offline':
        _queueInvalidation(dashboardProvider);
        break;

      case 'config.updated':
        final cameraId = _parseCameraId(event.data);
        if (cameraId != null) {
          _queueCameraConfigInvalidation(cameraId);
        } else {
          _queueInvalidation(dashboardProvider);
        }
        break;

      case 'ota.updated':
        _queueInvalidation(otaNotifierProvider);
        _queueInvalidation(dashboardProvider);
        break;
    }
  }

  /// Fires a native system push notification.
  ///
  /// Background-safe: does NOT touch any widget tree or Overlay.
  /// Only called when [appLifecycleProvider] is NOT [AppLifecycleState.resumed].
  void _showNativeNotification(Map<String, dynamic> data) {
    try {
      final id = int.tryParse(data['id']?.toString() ?? '') ?? data.hashCode;
      final cameraName = data['camera_name']?.toString() ?? 'Kamera';
      final confidence = data['confidence']?.toString() ?? '';

      const title = 'Human Detected';
      final body =
          'Person detected on $cameraName${confidence.isNotEmpty ? ' ($confidence)' : ''}';

      _ref.read(localNotificationServiceProvider).showNotification(
        id: id,
        title: title,
        body: body,
        payload: data['id']?.toString(),
      );
    } catch (e, stack) {
      ObservabilityService.instance.reportError(
        e,
        stack,
        hint: 'Native notification failed',
      );
    }
  }

  void _queueInvalidation(ProviderOrFamily provider) {
    _pendingInvalidations.add(provider);
    _startDebounceTimer();
  }

  void _queueCameraConfigInvalidation(int cameraId) {
    _pendingCameraConfigInvalidations.add(cameraId);
    _startDebounceTimer();
  }

  int? _parseCameraId(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map) {
        return int.tryParse(data['camera_id']?.toString() ?? '');
      }
      final decoded = Map<String, dynamic>.from(data as Map);
      return int.tryParse(decoded['camera_id']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  void _startDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _flush);
  }

  void _flush() {
    ObservabilityService.instance.info(
      '[SYNC] Flushing debounced invalidations. Providers: ${_pendingInvalidations.length}, Configs: ${_pendingCameraConfigInvalidations.length}',
    );

    for (final provider in _pendingInvalidations) {
      _ref.invalidate(provider);
    }
    _pendingInvalidations.clear();

    for (final cameraId in _pendingCameraConfigInvalidations) {
      _ref.invalidate(cameraConfigProvider(cameraId));
    }
    _pendingCameraConfigInvalidations.clear();
  }
}

final dashboardSyncProvider = Provider<DashboardSync>((ref) {
  return DashboardSync(ref);
});
