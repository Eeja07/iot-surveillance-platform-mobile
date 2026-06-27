import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reverb_provider.dart';

class ConnectionMonitor {
  final Ref _ref;
  DateTime _lastActivity = DateTime.now();
  Timer? _heartbeatTimer;

  ConnectionMonitor(this._ref);

  void start() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkHealth();
    });
    recordActivity();
  }

  void recordActivity() {
    _lastActivity = DateTime.now();
  }

  void _checkHealth() {
    final reverb = _ref.read(reverbServiceProvider);

    final diff = DateTime.now().difference(_lastActivity);
    if (diff > const Duration(seconds: 60)) {
      reverb.forceReconnect();
      recordActivity();
    }
  }

  void stop() {
    _heartbeatTimer?.cancel();
  }
}

final connectionMonitorProvider = Provider<ConnectionMonitor>((ref) {
  final monitor = ConnectionMonitor(ref);
  monitor.start();
  ref.onDispose(() {
    monitor.stop();
  });
  return monitor;
});
