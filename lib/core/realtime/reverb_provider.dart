import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../observability/offline_indicator.dart';
import 'reverb_service.dart';

final reverbServiceProvider = Provider<ReverbService>((ref) {
  final service = ReverbService(ref);

  ref.listen<bool>(connectivityProvider, (previous, next) {
    service.handleConnectivityChanged(next);
  });

  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
