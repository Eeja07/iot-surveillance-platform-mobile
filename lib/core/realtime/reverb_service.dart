import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../../features/detection/providers/detection_provider.dart';
import '../../features/notification/providers/notification_provider.dart';
import '../observability/offline_indicator.dart';
import '../observability/observability_service.dart';
import 'connection_monitor.dart';
import 'connection_provider.dart';

class ReverbService {
  final Ref _ref;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _initialized = false;

  // Reconnect state
  int _reconnectDelayIndex = 0;
  final List<Duration> _backoffDelays = const [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];
  bool _isReconnecting = false;
  Timer? _reconnectTimer;

  // Active channel list to resubscribe on reconnect
  final Set<String> _cameraChannels = {};

  ReverbService(this._ref);

  Future<void> init() async {
    if (_initialized) return;

    try {
      await _pusher.init(
        apiKey: 'j42ddfft9pcvefpkb2jl',
        cluster: 'mt1',
        host: 'cctv.miot-its.org',
        wsPort: 443,
        wssPort: 443,
        useTLS: true,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onEvent: _onEvent,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onSubscriptionError: _onSubscriptionError,
      );

      _initialized = true;

      // Start connections
      await connect();

      // Listen to connectivity changes (offline/online)
      _ref.listen<bool>(connectivityProvider, (previous, isOnline) {
        ObservabilityService.instance.info(
          '[REVERB] Connectivity changed. Online: $isOnline',
        );
        if (isOnline) {
          connect();
        } else {
          _ref.read(connectionStatusProvider.notifier).state =
              ConnectionStatus.offline;
        }
      });
    } catch (e) {
      ObservabilityService.instance.reportError(
        e,
        StackTrace.current,
        hint: 'ReverbService init failed',
      );
    }
  }

  Future<void> connect() async {
    final isOnline = _ref.read(connectivityProvider);
    if (!isOnline) {
      _ref.read(connectionStatusProvider.notifier).state =
          ConnectionStatus.offline;
      return;
    }

    try {
      final state = _pusher.connectionState;
      if (state == 'DISCONNECTED' || state == 'disconnecting') {
        _ref.read(connectionStatusProvider.notifier).state =
            ConnectionStatus.connecting;
        ObservabilityService.instance.info('[REVERB] Connecting websocket...');
        await _pusher.connect();
      }
    } catch (e) {
      _triggerReconnect();
    }
  }

  Future<void> pause() async {
    ObservabilityService.instance.info(
      '[REVERB] App paused, disconnecting websocket...',
    );
    try {
      await _pusher.disconnect();
    } catch (_) {}
  }

  Future<void> forceReconnect() async {
    ObservabilityService.instance.info(
      '[REVERB] Stale connection detected. Forcing reconnect...',
    );
    try {
      await _pusher.disconnect();
    } catch (_) {}
    await connect();
  }

  Future<void> subscribeToCameraChannel(String channelId) async {
    _cameraChannels.add(channelId);
    if (_pusher.connectionState == 'CONNECTED') {
      try {
        await _pusher.subscribe(channelName: channelId);
      } catch (_) {}
    }
  }

  Future<void> unsubscribeFromCameraChannel(String channelId) async {
    _cameraChannels.remove(channelId);
    try {
      await _pusher.unsubscribe(channelName: channelId);
    } catch (_) {}
  }

  void _onConnectionStateChange(String currentState, String previousState) {
    ObservabilityService.instance.info(
      '[REVERB] Connection state: $previousState -> $currentState',
    );

    // Map status
    final status = _mapState(currentState);
    _ref.read(connectionStatusProvider.notifier).state = status;

    // Reset backoff on success
    if (currentState == 'CONNECTED') {
      _reconnectDelayIndex = 0;
      _subscribeChannels();
    }

    if (currentState == 'DISCONNECTED') {
      _triggerReconnect();
    }

    // Record activity for heartbeat
    _ref.read(connectionMonitorProvider).recordActivity();
  }

  ConnectionStatus _mapState(String state) {
    switch (state) {
      case 'CONNECTED':
        return ConnectionStatus.connected;
      case 'CONNECTING':
        return ConnectionStatus.connecting;
      case 'RECONNECTING':
        return ConnectionStatus.reconnecting;
      default:
        final isOnline = _ref.read(connectivityProvider);
        return isOnline
            ? ConnectionStatus.connecting
            : ConnectionStatus.offline;
    }
  }

  Future<void> _subscribeChannels() async {
    try {
      ObservabilityService.instance.info(
        '[REVERB] Subscribing to detections channel...',
      );
      await _pusher.subscribe(channelName: 'detections');
      for (final channelId in _cameraChannels) {
        await _pusher.subscribe(channelName: channelId);
      }
    } catch (_) {}
  }

  void _onError(String message, int? code, dynamic error) {
    ObservabilityService.instance.info(
      '[REVERB] Connection error: $message (code: $code)',
    );
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    ObservabilityService.instance.info(
      '[REVERB] Subscription succeeded: $channelName',
    );
  }

  void _onSubscriptionError(String message, dynamic error) {
    ObservabilityService.instance.info('[REVERB] Subscription error: $message');
  }

  void _onEvent(PusherEvent event) {
    _ref.read(connectionMonitorProvider).recordActivity();
    if (event.eventName == 'person.detected') {
      ObservabilityService.instance.info(
        '[REVERB] Person detected event received!',
      );
      _invalidateProviders();
    }
  }

  void _invalidateProviders() {
    _ref.invalidate(detectionNotifierProvider);
    _ref.invalidate(notificationProvider);
  }

  void _triggerReconnect() {
    final isOnline = _ref.read(connectivityProvider);
    if (!isOnline) {
      _ref.read(connectionStatusProvider.notifier).state =
          ConnectionStatus.offline;
      return;
    }

    if (_isReconnecting) return;
    _isReconnecting = true;

    final delay = _backoffDelays[_reconnectDelayIndex];
    ObservabilityService.instance.info(
      '[REVERB] Reconnect scheduled in ${delay.inSeconds}s (backoff index: $_reconnectDelayIndex)',
    );
    _ref.read(connectionStatusProvider.notifier).state =
        ConnectionStatus.reconnecting;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      try {
        final state = _pusher.connectionState;
        if (state == 'DISCONNECTED') {
          await _pusher.connect();
        }
      } catch (_) {
      } finally {
        _isReconnecting = false;
        if (_reconnectDelayIndex < _backoffDelays.length - 1) {
          _reconnectDelayIndex++;
        }
      }
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    try {
      _pusher.unsubscribe(channelName: 'detections');
      for (final channelId in _cameraChannels) {
        _pusher.unsubscribe(channelName: channelId);
      }
      _pusher.disconnect();
    } catch (_) {}
  }
}
