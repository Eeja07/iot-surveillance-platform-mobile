import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../../features/detection/providers/detection_provider.dart';
import '../../features/notification/providers/notification_provider.dart';

class ReverbService {
  final Ref _ref;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _initialized = false;
  Timer? _watchdogTimer;

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

      await _pusher.connect();
      await _pusher.subscribe(channelName: 'detections');
      _initialized = true;

      _startWatchdog();
    } catch (e) {
      // Failed to initialize
    }
  }

  void _onConnectionStateChange(String currentState, String previousState) {
    if (currentState == 'DISCONNECTED') {
      _triggerReconnect();
    }
  }

  void _onError(String message, int? code, dynamic error) {
    // Connection or event error
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    // Successfully subscribed to channel
  }

  void _onSubscriptionError(String message, dynamic error) {
    // Subscription failed
  }

  void _onEvent(PusherEvent event) {
    if (event.eventName == 'person.detected') {
      _invalidateProviders();
    }
  }

  void _invalidateProviders() {
    _ref.invalidate(detectionNotifierProvider);
    _ref.invalidate(notificationProvider);
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final state = _pusher.connectionState;
        if (state == 'DISCONNECTED') {
          await _pusher.connect();
        }
      } catch (_) {}
    });
  }

  void _triggerReconnect() {
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        final state = _pusher.connectionState;
        if (state == 'DISCONNECTED') {
          await _pusher.connect();
        }
      } catch (_) {}
    });
  }

  void dispose() {
    _watchdogTimer?.cancel();
    try {
      _pusher.unsubscribe(channelName: 'detections');
      _pusher.disconnect();
    } catch (_) {}
  }
}
