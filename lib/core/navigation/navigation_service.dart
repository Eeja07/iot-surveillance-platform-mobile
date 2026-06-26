import 'package:flutter/material.dart';
import '../storage/session_service.dart';
import '../../screens/admin_home_screen.dart';
import '../../screens/main_screen.dart';

class NavigationService {
  final SessionService _sessionService;

  NavigationService(this._sessionService);

  Future<void> navigateToLandingPage(
    BuildContext context, {
    required VoidCallback toggleTheme,
    required bool isDarkMode,
  }) async {
    final user = await _sessionService.getCurrentUser();
    final role = user?.role ?? 'user';

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => role == 'admin'
            ? AdminHomeScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode)
            : MainScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode),
      ),
    );
  }
}
