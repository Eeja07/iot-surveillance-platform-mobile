import 'package:flutter/foundation.dart';
import 'logger.dart';

class AppLogger implements Logger {
  final bool _isDevelopment;

  AppLogger({bool isDevelopment = kDebugMode}) : _isDevelopment = isDevelopment;

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDevelopment) {
      _log('DEBUG', message, error, stackTrace);
    }
  }

  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDevelopment) {
      _log('INFO', message, error, stackTrace);
    }
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDevelopment) {
      _log('WARNING', message, error, stackTrace);
    }
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // Sentry / Firebase Crashlytics integration hook spot
    _log('ERROR', message, error, stackTrace);
  }

  void _log(
    String level,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] $message';

    debugPrint(logMessage);
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
