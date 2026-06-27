import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/detection/providers/detection_provider.dart';
import '../../features/notification/providers/notification_provider.dart';
import '../../features/camera/providers/camera_config_provider.dart';
import '../../features/ota/providers/ota_provider.dart';
import '../observability/observability_service.dart';
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
        // Invalidate data providers so UI refreshes in real-time.
        // Android notification is handled exclusively by NotificationBridge.
        debugPrint('[SYNC] person.detected — invalidating providers');
        ObservabilityService.instance.info(
          '[SYNC] person.detected — invalidating providers',
        );
        _ref.invalidate(detectionProvider);
        _ref.invalidate(notificationProvider);
        _ref.invalidate(overviewProvider);
        _ref.invalidate(cameraProvider);
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

  // NOTE: Android notification delivery is handled exclusively by
  // NotificationBridge via the notificationProvider stream.
  // DashboardSync is UI-sync only — it must never call showNotification().

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
