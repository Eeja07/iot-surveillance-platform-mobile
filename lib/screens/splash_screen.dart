import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../core/network/api_result.dart';
import '../features/auth/domain/model/user_model.dart';
import '../features/auth/presentation/login/login_screen.dart';
import 'dart:async';

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
    final authController = AppLocator.instance.authController;

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final hasSession = await sessionService.isLoggedIn();
    bool isValid = false;

    if (hasSession) {
      final result = await authRepository.me();
      if (result is ApiSuccess<UserModel>) {
        isValid = true;
      } else {
        await sessionService.clearSession();
      }
    }

    if (!mounted) return;

    if (isValid) {
      await authController.handleLoginSuccess(
        context,
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
            onSuccess: () {
              authController.handleLoginSuccess(
                context,
                toggleTheme: widget.toggleTheme,
                isDarkMode: widget.isDarkMode,
              );
            },
          ),
        ),
      );
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
              child: Image.asset('assets/logo_MV.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            Text(
              "MiotVision",
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
