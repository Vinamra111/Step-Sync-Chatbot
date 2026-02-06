/// Sensor Availability Checker for Android
///
/// Detects if the device has a hardware step counter sensor, which is
/// critical for accurate and battery-efficient step tracking.
///
/// Platform Support:
/// - Android: Checks for TYPE_STEP_COUNTER and TYPE_STEP_DETECTOR sensors
/// - iOS: Returns notApplicable (uses CoreMotion/HealthKit instead)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Sensor availability result
enum SensorStatus {
  /// Step counter sensor is available
  available,

  /// Step counter sensor is NOT available
  notAvailable,

  /// Status unknown (error checking)
  unknown,

  /// Not applicable (iOS or error)
  notApplicable,
}

/// Sensor information
class SensorInfo {
  final bool stepCounterAvailable;
  final bool stepDetectorAvailable;
  final String? stepCounterVendor;
  final String? stepCounterName;
  final double? stepCounterPower; // mA
  final bool playServicesAvailable;
  final String? playServicesVersion;

  SensorInfo({
    required this.stepCounterAvailable,
    required this.stepDetectorAvailable,
    this.stepCounterVendor,
    this.stepCounterName,
    this.stepCounterPower,
    this.playServicesAvailable = false,
    this.playServicesVersion,
  });

  factory SensorInfo.fromMap(Map<String, dynamic> map) {
    return SensorInfo(
      stepCounterAvailable: map['stepCounterAvailable'] as bool? ?? false,
      stepDetectorAvailable: map['stepDetectorAvailable'] as bool? ?? false,
      stepCounterVendor: map['stepCounterVendor'] as String?,
      stepCounterName: map['stepCounterName'] as String?,
      stepCounterPower: (map['stepCounterPower'] as num?)?.toDouble(),
      playServicesAvailable: map['playServicesAvailable'] as bool? ?? false,
      playServicesVersion: map['playServicesVersion'] as String?,
    );
  }

  @override
  String toString() {
    return 'SensorInfo(stepCounter: $stepCounterAvailable, '
        'stepDetector: $stepDetectorAvailable, '
        'vendor: $stepCounterVendor, '
        'name: $stepCounterName, '
        'power: ${stepCounterPower}mA, '
        'playServices: $playServicesAvailable v$playServicesVersion)';
  }
}

/// Google Play Services status
enum PlayServicesStatus {
  /// Google Play Services available and up-to-date
  available,

  /// Not installed or outdated
  unavailable,

  /// Status unknown
  unknown,

  /// Not applicable (iOS)
  notApplicable,
}

/// Sensors Checker
class SensorsChecker {
  static const MethodChannel _channel = MethodChannel('com.stepsync.chatbot/sensors');
  final Logger _logger;

  SensorsChecker({Logger? logger}) : _logger = logger ?? Logger();

  // ============================================================================
  // STEP COUNTER SENSOR (Android)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #15: Step Counter Sensor Availability
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// The step counter sensor is a hardware component (usually part of the
  /// accelerometer chip) that counts steps efficiently without draining battery.
  ///
  /// KEY POINTS:
  /// • Hardware-based step counting (very battery efficient)
  /// • Available on most devices since 2014 (Android 4.4 KitKat)
  /// • Two sensor types: TYPE_STEP_COUNTER and TYPE_STEP_DETECTOR
  /// • If missing, apps use accelerometer (less accurate, drains battery)
  ///
  /// WHY IT MATTERS:
  ///
  /// WITH STEP COUNTER SENSOR:
  /// • Battery-efficient step tracking (< 1% battery per day)
  /// • Accurate step count even when screen is off
  /// • No need for continuous accelerometer polling
  /// • Works reliably in background
  ///
  /// WITHOUT STEP COUNTER SENSOR:
  /// • App must use accelerometer directly (drains battery)
  /// • Less accurate step detection
  /// • May require app to stay awake
  /// • Background tracking unreliable
  ///
  /// TECHNICAL DETAILS:
  /// Android API: SensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
  /// Available Since: Android 4.4 KitKat (API 19, October 2013)
  /// Sensor Types:
  ///   - TYPE_STEP_COUNTER (19): Total steps since last reboot
  ///   - TYPE_STEP_DETECTOR (18): Triggers event when step detected
  /// Typical Power: 0.1-0.5 mA (very low)
  ///
  /// DETECTION STATUS:
  ///
  /// AVAILABLE:
  /// • Device has hardware step counter
  /// • Optimal battery-efficient tracking
  /// • No action needed
  ///
  /// NOT_AVAILABLE:
  /// • Device lacks hardware sensor (rare on modern phones)
  /// • App may use accelerometer fallback
  /// • Warn user about battery impact
  /// • Recommend keeping app open more frequently
  ///
  /// UNKNOWN:
  /// • Error checking sensor availability
  /// • Assume available (safer assumption)
  ///
  /// IMPACT ON STEP TRACKING:
  ///
  /// WITH SENSOR:
  /// • Step counting works perfectly in background
  /// • Minimal battery drain
  /// • Accurate step count
  /// • Reliable syncing
  ///
  /// WITHOUT SENSOR:
  /// • May require app to stay in foreground
  /// • Higher battery usage
  /// • Less accurate step detection
  /// • Background tracking limited
  ///
  /// TROUBLESHOOTING GUIDANCE:
  ///
  /// If NOT_AVAILABLE:
  ///   → Inform: "Your device doesn't have a step counter sensor"
  ///   → Impact: "Step tracking will use more battery"
  ///   → Recommendation: "Keep the app open while walking"
  ///   → Alternative: "Use Fitbit device for better accuracy"
  ///
  /// If AVAILABLE:
  ///   → Inform: "Step counter sensor detected"
  ///   → Status: "Optimal battery-efficient tracking enabled"
  ///
  /// NOTES:
  /// • Very rare on devices from 2015+
  /// • If missing, device is likely very old (< 2014)
  /// • Most budget phones from 2016+ have this sensor
  /// • This is NOT a permission issue - it's hardware availability
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check if step counter sensor is available
  ///
  /// Returns:
  /// - [SensorStatus.available] if hardware sensor exists
  /// - [SensorStatus.notAvailable] if no sensor (rare)
  /// - [SensorStatus.unknown] if detection failed
  /// - [SensorStatus.notApplicable] if not Android
  Future<SensorStatus> checkStepCounterSensor() async {
    // Only applicable on Android
    if (!Platform.isAndroid) {
      _logger.d('Step counter sensor check: Not applicable (not Android)');
      return SensorStatus.notApplicable;
    }

    try {
      _logger.d('Checking step counter sensor availability...');

      final dynamic result = await _channel.invokeMethod('checkStepCounterSensor');

      if (result == null) {
        _logger.w('Step counter sensor check returned null');
        return SensorStatus.unknown;
      }

      final bool isAvailable = result as bool;
      final status = isAvailable
          ? SensorStatus.available
          : SensorStatus.notAvailable;

      _logger.i('Step counter sensor status: $status');
      return status;
    } on PlatformException catch (e) {
      _logger.e('Platform exception checking step counter sensor: ${e.code} - ${e.message}');
      return SensorStatus.unknown;
    } catch (e) {
      _logger.e('Error checking step counter sensor: $e');
      return SensorStatus.unknown;
    }
  }

  /// Get detailed sensor information
  ///
  /// Returns sensor details including vendor, name, power consumption
  Future<SensorInfo?> getSensorInfo() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      _logger.d('Getting sensor information...');

      final dynamic result = await _channel.invokeMethod('getSensorInfo');

      if (result == null) {
        _logger.w('Sensor info returned null');
        return null;
      }

      final info = SensorInfo.fromMap(Map<String, dynamic>.from(result as Map));
      _logger.i('Sensor info: $info');
      return info;
    } catch (e) {
      _logger.e('Error getting sensor info: $e');
      return null;
    }
  }

  // ============================================================================
  // GOOGLE PLAY SERVICES (Android)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #16: Google Play Services Status
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// Google Play Services is a background service that provides APIs for
  /// Google services, including Health Connect (on Android 9-13).
  ///
  /// KEY POINTS:
  /// • Required for Health Connect on Android 9-13
  /// • Pre-installed on most Android devices
  /// • Needs to be up-to-date for Health Connect
  /// • Missing on some Chinese market phones
  ///
  /// WHY IT MATTERS:
  ///
  /// WITH PLAY SERVICES (UP-TO-DATE):
  /// • Health Connect works properly
  /// • Step syncing enabled
  /// • Full health platform access
  ///
  /// WITHOUT PLAY SERVICES:
  /// • Health Connect won't work (Android 9-13)
  /// • No health data sync
  /// • App functionality severely limited
  ///
  /// TECHNICAL DETAILS:
  /// Android API: GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable()
  /// Required For: Health Connect on Android 9-13
  /// Not Required For: Health Connect on Android 14+ (built into OS)
  ///
  /// DETECTION STATUS:
  ///
  /// AVAILABLE:
  /// • Play Services installed and up-to-date
  /// • Health Connect can work
  /// • No action needed
  ///
  /// UNAVAILABLE:
  /// • Not installed or outdated
  /// • Update required from Play Store
  /// • Health Connect won't work
  ///
  /// NOT_APPLICABLE:
  /// • Android 14+ (Health Connect built-in, doesn't need Play Services)
  /// • iOS
  ///
  /// TROUBLESHOOTING GUIDANCE:
  ///
  /// If UNAVAILABLE (Android 9-13):
  ///   → Critical: "Google Play Services required for Health Connect"
  ///   → Action: "Update Google Play Services from Play Store"
  ///   → Impact: "Step syncing blocked until updated"
  ///
  /// If AVAILABLE:
  ///   → Status: "Google Play Services up-to-date"
  ///   → No action needed
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check Google Play Services availability
  ///
  /// Returns:
  /// - [PlayServicesStatus.available] if installed and up-to-date
  /// - [PlayServicesStatus.unavailable] if missing or outdated
  /// - [PlayServicesStatus.unknown] if check failed
  /// - [PlayServicesStatus.notApplicable] if not Android or Android 14+
  Future<PlayServicesStatus> checkPlayServices() async {
    if (!Platform.isAndroid) {
      _logger.d('Play Services check: Not applicable (not Android)');
      return PlayServicesStatus.notApplicable;
    }

    try {
      _logger.d('Checking Google Play Services...');

      final dynamic result = await _channel.invokeMethod('checkPlayServices');

      if (result == null) {
        _logger.w('Play Services check returned null');
        return PlayServicesStatus.unknown;
      }

      final String status = result as String;

      switch (status) {
        case 'AVAILABLE':
          _logger.i('Google Play Services: Available');
          return PlayServicesStatus.available;
        case 'UNAVAILABLE':
          _logger.w('Google Play Services: Unavailable');
          return PlayServicesStatus.unavailable;
        case 'NOT_APPLICABLE':
          _logger.d('Google Play Services: Not applicable (Android 14+)');
          return PlayServicesStatus.notApplicable;
        default:
          _logger.w('Unknown Play Services status: $status');
          return PlayServicesStatus.unknown;
      }
    } on PlatformException catch (e) {
      _logger.e('Platform exception checking Play Services: ${e.code} - ${e.message}');
      return PlayServicesStatus.unknown;
    } catch (e) {
      _logger.e('Error checking Play Services: $e');
      return PlayServicesStatus.unknown;
    }
  }

  /// Open Google Play Services in Play Store for update
  Future<bool> openPlayServicesInStore() async {
    if (!Platform.isAndroid) {
      _logger.w('openPlayServicesInStore: Not applicable (not Android)');
      return false;
    }

    try {
      _logger.i('Opening Google Play Services in Play Store...');

      final dynamic result = await _channel.invokeMethod('openPlayServicesInStore');

      final bool success = (result as bool?) ?? false;
      _logger.i('Open Play Store: ${success ? 'success' : 'failed'}');

      return success;
    } catch (e) {
      _logger.e('Error opening Play Services in store: $e');
      return false;
    }
  }
}
