import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'config/app_colors.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

    _tokenCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
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
              isDarkMode: _themeMode == ThemeMode.dark
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

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFFF5F5F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0.5,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.white,
        elevation: 1.0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF161C24),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF25293C),
        foregroundColor: AppColors.light,
        elevation: 0,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Color(0xFF25293C),
        elevation: 1.0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF25293C),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: AppColors.light),
        bodyMedium: TextStyle(color: Colors.grey[400]),
        titleLarge: const TextStyle(color: AppColors.light, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: AppColors.light),
    );

    return MaterialApp(

      navigatorKey: navigatorKey,

      title: 'MiotVision',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: SplashScreen(
        toggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}