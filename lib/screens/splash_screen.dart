import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'admin_home_screen.dart';
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
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    bool isValid = false;

    if (token != null && token.isNotEmpty) {
      isValid = await _authService.checkTokenValidity(token);
    }

    if (isValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => role == 'admin'
              ? AdminHomeScreen(
                  toggleTheme: widget.toggleTheme,
                  isDarkMode: widget.isDarkMode,
                )
              : MainScreen(
                  toggleTheme: widget.toggleTheme,
                  isDarkMode: widget.isDarkMode,
                ),
        ),
      );
    } else {
      if (token != null) {
        await prefs.clear();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
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
