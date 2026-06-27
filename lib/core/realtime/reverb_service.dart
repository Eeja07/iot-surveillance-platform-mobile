import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/injection.dart';
import '../di/auth_provider.dart';
import '../observability/offline_indicator.dart';
import '../observability/observability_service.dart';
import 'connection_monitor.dart';
import 'connection_provider.dart';
import 'realtime_dispatcher.dart';

class PusherEvent {
  final String? channelName;
  final String eventName;
  final dynamic data;

  const PusherEvent({
    this.channelName,
    required this.eventName,
    required this.data,
  });

  @override
  String toString() => 'PusherEvent(channel: $channelName, event: $eventName, data: $data)';
}

class ReverbService {
  final Ref _ref;
  WebSocket? _socket;
  bool _initialized = false;
  bool _connecting = false;

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
  Timer? _pingTimer;

  // Active channel list to resubscribe on reconnect
  final Set<String> _cameraChannels = {};

  ReverbService(this._ref);

  void _updateConnectionStatus(ConnectionStatus status) {
    Future.microtask(() {
      _ref.read(connectionStatusProvider.notifier).state = status;
    });
  }

  Future<void> init() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      ObservabilityService.instance.info("[REVERB] init blocked");
      return;
    }
    ObservabilityService.instance.info("[REVERB] init allowed");
    ObservabilityService.instance.info("[REVERB] init");
    
    if (_initialized) return;
    _initialized = true;
    await connect();
  }

  Future<void> disconnect() async {
    ObservabilityService.instance.info("[REVERB] disconnect");
    _initialized = false;
    _connecting = false;
    _closeSocket();
    _updateConnectionStatus(ConnectionStatus.offline);
  }

  void handleConnectivityChanged(bool isOnline) {
    ObservabilityService.instance.info(
      '[REVERB] Connectivity changed. Online: $isOnline',
    );
    if (isOnline) {
      connect();
    } else {
      _closeSocket();
      _updateConnectionStatus(ConnectionStatus.offline);
    }
  }

  Future<void> connect() async {
    final isAuthenticated = _ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      return;
    }

    ObservabilityService.instance.info("[REVERB] connect");
    final isOnline = _ref.read(connectivityProvider);
    if (!isOnline) {
      _updateConnectionStatus(ConnectionStatus.offline);
      return;
    }

    if (_socket != null && _socket!.readyState == WebSocket.open) {
      return;
    }

    if (_connecting) return;
    _connecting = true;

    _updateConnectionStatus(ConnectionStatus.connecting);

    final config = AppLocator.instance.config;
    final host = config.reverbHost;
    final port = config.reverbPort;
    final scheme = config.reverbScheme == 'https' ? 'wss' : 'ws';
    final appKey = config.reverbAppKey;

    final portPart = (port == 80 || port == 443) ? "" : ":$port";
    final url = '$scheme://$host$portPart/app/$appKey?protocol=7&client=js&version=7.0.6&flash=false';

    ObservabilityService.instance.info('[REVERB] Connecting websocket to: $url');

    try {
      _socket = await WebSocket.connect(url).timeout(const Duration(seconds: 5));
      _connecting = false;
      _isReconnecting = false;
      _reconnectDelayIndex = 0;

      _startPingTimer();

      _socket!.listen(
        (message) {
          _onMessageReceived(message as String);
        },
        onError: (err) {
          ObservabilityService.instance.info('[REVERB] Socket error: $err');
          _handleDisconnect();
        },
        onDone: () {
          ObservabilityService.instance.info('[REVERB] Socket done (closed)');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e, stack) {
      _connecting = false;
      ObservabilityService.instance.reportError(
        e,
        stack,
        hint: 'Reverb connection failed',
      );
      _handleDisconnect();
    }
  }

  void _onMessageReceived(String message) {
    _ref.read(connectionMonitorProvider).recordActivity();

    try {
      final decoded = json.decode(message) as Map<String, dynamic>;
      final eventName = decoded['event'] as String?;
      final channel = decoded['channel'] as String?;
      final rawData = decoded['data'];

      if (eventName == null) return;

      if (eventName == 'pusher:connection_established') {
        _updateConnectionStatus(ConnectionStatus.connected);
        print("[REVERB] connected");
        ObservabilityService.instance.info("[REVERB] connected");
        ObservabilityService.instance.info('[REVERB] Connection state: CONNECTED');

        // Resubscribe to channels
        _subscribe('detections');
        for (final cameraChannel in _cameraChannels) {
          _subscribe(cameraChannel);
        }
      } else if (eventName == 'pusher_internal:subscription_succeeded') {
        if (channel == 'detections') {
          print("[REVERB] subscribed detections");
          ObservabilityService.instance.info("[REVERB] subscribed detections");
        }
        ObservabilityService.instance.info('[REVERB] Subscription succeeded: $channel');
      } else if (eventName == 'pusher:ping') {
        _send({'event': 'pusher:pong', 'data': {}});
      } else if (eventName == 'pusher:error') {
        ObservabilityService.instance.info('[REVERB] Reverb error event: $rawData');
      } else {
        // App events
        final event = PusherEvent(
          channelName: channel,
          eventName: eventName,
          data: rawData,
        );

        if (eventName == 'person.detected') {
          print(event.eventName);
          print(event.data);
          ObservabilityService.instance.info("[REVERB] person.detected received");
        }

        _ref.read(realtimeDispatcherProvider).dispatch(event);
      }
    } catch (e, stack) {
      ObservabilityService.instance.reportError(e, stack, hint: 'Failed parsing websocket frame');
    }
  }

  void _send(Map<String, dynamic> payload) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(json.encode(payload));
    }
  }

  void _subscribe(String channelName) {
    _send({
      'event': 'pusher:subscribe',
      'data': {
        'channel': channelName,
      }
    });
  }

  void _unsubscribe(String channelName) {
    _send({
      'event': 'pusher:unsubscribe',
      'data': {
        'channel': channelName,
      }
    });
  }

  void _handleDisconnect() {
    _closeSocket();
    
    final isOnline = _ref.read(connectivityProvider);
    if (!isOnline) {
      _updateConnectionStatus(ConnectionStatus.offline);
      return;
    }

    _triggerReconnect();
  }

  void _closeSocket() {
    _pingTimer?.cancel();
    _pingTimer = null;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _send({'event': 'pusher:ping', 'data': {}});
    });
  }

  void _triggerReconnect() {
    final isOnline = _ref.read(connectivityProvider);
    if (!isOnline) {
      _updateConnectionStatus(ConnectionStatus.offline);
      return;
    }

    if (_isReconnecting) return;
    _isReconnecting = true;

    final delay = _backoffDelays[_reconnectDelayIndex];
    ObservabilityService.instance.info(
      '[REVERB] Reconnect scheduled in ${delay.inSeconds}s (backoff index: $_reconnectDelayIndex)',
    );
    _updateConnectionStatus(ConnectionStatus.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      try {
        _isReconnecting = false;
        await connect();
      } catch (_) {
        _isReconnecting = false;
      } finally {
        if (_reconnectDelayIndex < _backoffDelays.length - 1) {
          _reconnectDelayIndex++;
        }
      }
    });
  }

  Future<void> pause() async {
    ObservabilityService.instance.info(
      '[REVERB] App paused, disconnecting websocket...',
    );
    _closeSocket();
    _updateConnectionStatus(ConnectionStatus.offline);
  }

  Future<void> forceReconnect() async {
    ObservabilityService.instance.info(
      '[REVERB] Stale connection detected. Forcing reconnect...',
    );
    _closeSocket();
    await connect();
  }

  Future<void> subscribeToCameraChannel(String channelId) async {
    _cameraChannels.add(channelId);
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      try {
        _subscribe(channelId);
      } catch (_) {}
    }
  }

  Future<void> unsubscribeFromCameraChannel(String channelId) async {
    _cameraChannels.remove(channelId);
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      try {
        _unsubscribe(channelId);
      } catch (_) {}
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _closeSocket();
  }
}
