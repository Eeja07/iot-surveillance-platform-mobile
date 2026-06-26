import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/session_service.dart';
import 'app_routes.dart';

class RouterRedirect {
  final SessionService _sessionService;

  RouterRedirect(this._sessionService);

  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final isLoggedIn = await _sessionService.isLoggedIn();
    final location = state.uri.path;

    // 1. Not Logged In
    if (!isLoggedIn) {
      // Protect dashboard and admin routes, redirecting unauthenticated users to login
      if (location == AppRoutes.dashboard || location == AppRoutes.admin) {
        return AppRoutes.login;
      }
      return null;
    }

    // 2. Logged In
    if (isLoggedIn) {
      final user = await _sessionService.getCurrentUser();
      final role = user?.role ?? 'user';

      // Redirect logged in users away from the login screen to their respective dashboard
      if (location == AppRoutes.login) {
        return role == 'admin' ? AppRoutes.admin : AppRoutes.dashboard;
      }

      // Redirect admin from user dashboard to admin home
      if (location == AppRoutes.dashboard && role == 'admin') {
        return AppRoutes.admin;
      }

      // Redirect regular user from admin home to user dashboard
      if (location == AppRoutes.admin && role != 'admin') {
        return AppRoutes.dashboard;
      }
    }

    return null;
  }
}
