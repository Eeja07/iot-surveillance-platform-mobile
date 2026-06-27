import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reverb_provider.dart';

class NotificationBridge {
  final Ref _ref;

  NotificationBridge(this._ref);

  void init() {
    _ref.read(reverbServiceProvider);
  }
}

final notificationBridgeProvider = Provider<NotificationBridge>((ref) {
  final bridge = NotificationBridge(ref);
  bridge.init();
  return bridge;
});
