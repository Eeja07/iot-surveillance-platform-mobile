import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocator.instance.initialize();
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  Timer? _tokenCheckTimer;
  final AuthService _authService = AuthService();
  bool _isCheckingToken = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _startPeriodicTokenCheck();
  }

  @override
  void dispose() {
    _tokenCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        prefs.setBool('isDarkMode', true);
      } else {
        _themeMode = ThemeMode.light;
        prefs.setBool('isDarkMode', false);
      }
    });
  }

  void _startPeriodicTokenCheck() {
    _tokenCheckTimer = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) async {
      await _performTokenCheck();
    });
  }

  Future<void> _performTokenCheck() async {
    if (_isCheckingToken) return;
    _isCheckingToken = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _isCheckingToken = false;
        return;
      }

      bool isValid = await _authService.checkTokenValidity(token);

      if (!isValid) {
        print("Token Expired/Invalid. Melakukan Logout Paksa...");

        await prefs.clear();

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              toggleTheme: _toggleTheme,
              isDarkMode: _themeMode == ThemeMode.dark,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print("Error checking token in background: $e");
    } finally {
      _isCheckingToken = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MiotVision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: SplashScreen(
        toggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
