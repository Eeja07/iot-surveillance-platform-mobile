import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reverb_provider.dart';

class RealtimeLifecycleObserver extends WidgetsBindingObserver {
  final Ref _ref;

  RealtimeLifecycleObserver(this._ref);

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final reverb = _ref.read(reverbServiceProvider);

    if (state == AppLifecycleState.resumed) {
      reverb.connect();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      reverb.pause();
    }
  }
}

final realtimeLifecycleProvider = Provider<RealtimeLifecycleObserver>((ref) {
  final observer = RealtimeLifecycleObserver(ref);
  observer.start();
  ref.onDispose(() {
    observer.stop();
  });
  return observer;
});
