import 'dart:collection';
import 'package:flutter/foundation.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? details;

  LogEntry({required this.level, required this.message, this.details})
    : timestamp = DateTime.now();

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] [${level.name.toUpperCase()}] $message${details != null ? '\nDetails: $details' : ''}';
  }
}

class ObservabilityService {
  static final ObservabilityService instance = ObservabilityService._();
  ObservabilityService._();

  final ListQueue<LogEntry> _logs = ListQueue<LogEntry>(100);

  List<LogEntry> get logs => _logs.toList();

  void info(String message, {String? details}) =>
      _log(LogLevel.info, message, details);

  void warning(String message, {String? details}) =>
      _log(LogLevel.warning, message, details);

  void error(String message, {String? details}) =>
      _log(LogLevel.error, message, details);

  void _log(LogLevel level, String message, String? details) {
    final entry = LogEntry(level: level, message: message, details: details);
    if (_logs.length >= 100) {
      _logs.removeFirst();
    }
    _logs.addLast(entry);
    debugPrint(entry.toString());
  }

  void reportError(Object error, StackTrace? stackTrace, {String? hint}) {
    this.error(
      'Caught Error: ${error.toString()}',
      details:
          '${hint != null ? "Hint: $hint\n" : ""}${stackTrace?.toString()}',
    );
    debugPrint('*** SENDING CRASH REPORT TO OBSERVE SYSTEMS: $error ***');
  }

  void setupGlobalErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      reportError(
        details.exception,
        details.stack,
        hint: 'FlutterError.onError: ${details.library}',
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      reportError(error, stack, hint: 'PlatformDispatcher.instance.onError');
      return true;
    };
  }
}
