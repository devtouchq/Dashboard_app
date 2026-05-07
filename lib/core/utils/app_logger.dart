import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Simple logger wrapper around `dart:developer` so log entries are
/// grouped by screen/tag in the Flutter DevTools console.
class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    developer.log(message, name: 'INFO/$tag');
  }

  static void warn(String tag, String message) {
    developer.log(message, name: 'WARN/$tag');
  }

  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'ERROR/$tag',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    if (kDebugMode) {
      // Also print to the run console so you spot it without DevTools.
      // ignore: avoid_print
      print('[ERROR/$tag] $message');
      if (error != null) print('  └─ $error');
      if (stackTrace != null) print(stackTrace);
    }
  }
}
