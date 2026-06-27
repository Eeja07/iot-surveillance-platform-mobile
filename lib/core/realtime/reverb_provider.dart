import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reverb_service.dart';

final reverbServiceProvider = Provider<ReverbService>((ref) {
  final service = ReverbService(ref);
  service.init();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
