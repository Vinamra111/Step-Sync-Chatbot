/// Crash Logger Service
///
/// Captures all crashes and errors for debugging
/// Stores crash logs locally and can display them in-app

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class CrashLogger {
  static final _log = Logger();
  static const String _crashLogKey = 'crash_logs';
  static const int _maxCrashLogs = 10;

  /// Initialize crash logging
  static Future<void> initialize() async {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.presentError(details);
      await _logCrash(
        type: 'Flutter Error',
        error: details.exception.toString(),
        stackTrace: details.stack.toString(),
        context: details.context?.toString() ?? 'No context',
      );
    };

    // Catch async errors outside Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _logCrash(
        type: 'Unhandled Exception',
        error: error.toString(),
        stackTrace: stack.toString(),
        context: 'Async error outside Flutter',
      );
      return true; // Handled
    };

    _log.i('Crash logger initialized');
  }

  /// Log a crash with details
  static Future<void> _logCrash({
    required String type,
    required String error,
    required String stackTrace,
    required String context,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final crashReport = {
        'timestamp': timestamp,
        'type': type,
        'error': error,
        'stackTrace': stackTrace,
        'context': context,
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      };

      _log.e('CRASH LOGGED: $type - $error');

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final existingLogs = prefs.getStringList(_crashLogKey) ?? [];

      // Add new crash log
      existingLogs.insert(0, _formatCrashReport(crashReport));

      // Keep only last N crashes
      if (existingLogs.length > _maxCrashLogs) {
        existingLogs.removeRange(_maxCrashLogs, existingLogs.length);
      }

      await prefs.setStringList(_crashLogKey, existingLogs);
    } catch (e) {
      _log.e('Failed to log crash: $e');
    }
  }

  /// Format crash report as string
  static String _formatCrashReport(Map<String, dynamic> crash) {
    return '''
═══════════════════════════════════════════════════════════════
CRASH REPORT
═══════════════════════════════════════════════════════════════
Time: ${crash['timestamp']}
Type: ${crash['type']}
Platform: ${crash['platform']} ${crash['version']}

ERROR:
${crash['error']}

CONTEXT:
${crash['context']}

STACK TRACE:
${crash['stackTrace']}
═══════════════════════════════════════════════════════════════
''';
  }

  /// Get all crash logs
  static Future<List<String>> getCrashLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_crashLogKey) ?? [];
    } catch (e) {
      _log.e('Failed to get crash logs: $e');
      return [];
    }
  }

  /// Check if there are any crash logs
  static Future<bool> hasCrashLogs() async {
    final logs = await getCrashLogs();
    return logs.isNotEmpty;
  }

  /// Clear all crash logs
  static Future<void> clearCrashLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_crashLogKey);
      _log.i('Crash logs cleared');
    } catch (e) {
      _log.e('Failed to clear crash logs: $e');
    }
  }

  /// Get the most recent crash log
  static Future<String?> getLastCrash() async {
    final logs = await getCrashLogs();
    return logs.isNotEmpty ? logs.first : null;
  }

  /// Log a custom error (for manual error tracking)
  static Future<void> logError({
    required String error,
    String? stackTrace,
    String? context,
  }) async {
    await _logCrash(
      type: 'Manual Error',
      error: error,
      stackTrace: stackTrace ?? 'No stack trace',
      context: context ?? 'Manual error log',
    );
  }
}
