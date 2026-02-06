/// Battery Optimization Checker for Android
///
/// Detects if battery optimization is enabled for the app, which can
/// block background step tracking and syncing.
///
/// Platform Support:
/// - Android 6.0+ (API 23+): Full battery optimization detection
/// - Android 5.x and below: Returns notApplicable
/// - iOS: Returns notApplicable (uses Low Power Mode instead)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Battery check result (renamed to avoid conflict with diagnostic model)
enum BatteryCheckResult {
  /// Battery optimization is enabled (blocking background work)
  enabled,

  /// Battery optimization is disabled (background work allowed)
  disabled,

  /// Status unknown (method channel failed or error)
  unknown,

  /// Not applicable (iOS or Android < 6.0)
  notApplicable,
}

/// Battery Optimization Checker
class BatteryChecker {
  static const MethodChannel _channel = MethodChannel('com.stepsync.chatbot/battery');
  final Logger _logger;

  BatteryChecker({Logger? logger}) : _logger = logger ?? Logger();

  /// Check if battery optimization is enabled for this app
  ///
  /// Returns:
  /// - [BatteryCheckResult.enabled] if optimization is blocking background work
  /// - [BatteryCheckResult.disabled] if app is whitelisted
  /// - [BatteryCheckResult.unknown] if detection failed
  /// - [BatteryCheckResult.notApplicable] if not Android 6.0+
  Future<BatteryCheckResult> checkBatteryOptimization() async {
    // Only applicable on Android
    if (!Platform.isAndroid) {
      _logger.d('Battery optimization check: Not applicable (not Android)');
      return BatteryCheckResult.notApplicable;
    }

    try {
      _logger.d('Checking battery optimization status...');

      // Call Android method channel
      final dynamic result = await _channel.invokeMethod('isBatteryOptimizationEnabled');

      if (result == null) {
        _logger.w('Battery optimization check returned null');
        return BatteryCheckResult.unknown;
      }

      final bool isOptimized = result as bool;
      final status = isOptimized
          ? BatteryCheckResult.enabled
          : BatteryCheckResult.disabled;

      _logger.i('Battery optimization status: $status');
      return status;
    } on PlatformException catch (e) {
      _logger.e('Platform exception checking battery optimization: ${e.code} - ${e.message}');

      // Handle specific error codes
      if (e.code == 'NOT_AVAILABLE') {
        // Android version < 6.0
        return BatteryCheckResult.notApplicable;
      }

      return BatteryCheckResult.unknown;
    } catch (e) {
      _logger.e('Error checking battery optimization: $e');
      return BatteryCheckResult.unknown;
    }
  }

  /// Request battery optimization exemption
  ///
  /// Opens the system settings screen where the user can disable
  /// battery optimization for this app.
  ///
  /// Returns true if the intent was launched successfully.
  Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) {
      _logger.w('requestBatteryOptimizationExemption: Not applicable (not Android)');
      return false;
    }

    try {
      _logger.i('Requesting battery optimization exemption...');

      final dynamic result = await _channel.invokeMethod('requestBatteryOptimizationExemption');

      final bool success = (result as bool?) ?? false;
      _logger.i('Battery optimization exemption request: ${success ? 'success' : 'failed'}');

      return success;
    } on PlatformException catch (e) {
      _logger.e('Platform exception requesting battery optimization exemption: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  /// Check if the device supports battery optimization detection
  ///
  /// Returns true if running on Android 6.0+ (API 23+)
  Future<bool> isBatteryOptimizationSupported() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final dynamic result = await _channel.invokeMethod('isBatteryOptimizationSupported');
      return (result as bool?) ?? false;
    } catch (e) {
      _logger.w('Error checking battery optimization support: $e');
      return false;
    }
  }
}
