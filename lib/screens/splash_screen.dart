import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection.dart';
import '../core/network/api_result.dart';
import '../core/network/network_exception.dart';
import '../core/router/app_routes.dart';
import '../features/auth/domain/model/user_model.dart';
import 'dart:async';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SplashScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final sessionService = AppLocator.instance.sessionService;
    final authRepository = AppLocator.instance.authRepository;

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final hasSession = await sessionService.isLoggedIn();

    if (!hasSession) {
      // No local token at all — must login.
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    // Token exists. Try to validate with server.
    bool shouldGoToDashboard = true;

    try {
      final result = await authRepository.me();

      if (result is ApiFailure<UserModel>) {
        final exception = result.exception;
        if (exception is UnauthorizedException) {
          // Server explicitly rejected token (401) — token is invalid.
          await sessionService.clearSession();
          shouldGoToDashboard = false;
        }
        // 403, 500, NetworkException, TimeoutException — server unreachable
        // or temporarily unavailable. Keep session and proceed to dashboard;
        // the user will get a proper error if they try to load data.
      }
    } on SocketException {
      // No network — keep session, go to dashboard.
    } catch (_) {
      // Unexpected error — keep session, go to dashboard.
    }

    if (!mounted) return;

    if (shouldGoToDashboard) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Image.asset('assets/logomivion.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            Text(
              "Mivion",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Smart IoT Surveillance",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
