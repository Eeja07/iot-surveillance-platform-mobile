import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // AppLocator must initialize before ProviderScope reads from it.
  await AppLocator.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
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
    AppRouter.init(
      toggleTheme: _toggleTheme,
      isDarkMode: () => _themeMode == ThemeMode.dark,
      navigatorKey: navigatorKey,
    );
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
        await prefs.clear();
        AppRouter.router.go('/login');
      }
    } catch (e) {
      // ignore background token check errors
    } finally {
      _isCheckingToken = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      title: 'MiotVision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
    );
  }
}
