import '../router/app_router.dart';
import '../router/app_routes.dart';

class LocalNotificationRouter {
  static void navigateToDetections() {
    AppRouter.router.go(AppRoutes.detections);
  }
}
