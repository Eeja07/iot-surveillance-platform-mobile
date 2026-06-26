import 'package:flutter/material.dart';

class AppRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('AppRouter: [PUSH] Route: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('AppRouter: [POP] Route: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint(
      'AppRouter: [REPLACE] New: ${newRoute?.settings.name}, Old: ${oldRoute?.settings.name}',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    debugPrint('AppRouter: [REMOVE] Route: ${route.settings.name}');
  }
}
