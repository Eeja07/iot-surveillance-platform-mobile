import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/detection/providers/detection_provider.dart';
import '../../features/notification/providers/notification_provider.dart';
import '../../features/ota/providers/ota_provider.dart';

class RealtimeProviderRegistry {
  static final List<ProviderBase> globalRealtimeProviders = [
    dashboardProvider,
    detectionNotifierProvider,
    notificationProvider,
    otaNotifierProvider,
  ];
}
