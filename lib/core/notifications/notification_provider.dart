import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  final service = LocalNotificationService();
  service.init();
  return service;
});
