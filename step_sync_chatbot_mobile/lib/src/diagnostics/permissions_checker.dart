/// Permissions Checker for Android and iOS
///
/// Detects if critical permissions are granted for step tracking, including:
/// - Physical Activity permission (Android 10+)
/// - Motion & Fitness permission (iOS)
/// - Location permission (if required)
/// - Notification permission (Android 13+)
///
/// Platform Support:
/// - Android 10+: Physical Activity Recognition permission
/// - Android 13+: Notification permission
/// - iOS 13+: Motion & Fitness permission
/// - All platforms: Location permission (optional)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'diagnostic_channels.dart';

/// Permission check result
enum PermissionStatus {
  /// Permission is granted
  granted,

  /// Permission is denied but can be requested
  denied,

  /// Permission is permanently denied (Android)
  permanentlyDenied,

  /// Permission has not been requested yet
  notDetermined,

  /// Permission is restricted (iOS - parental controls)
  restricted,

  /// Status unknown (method channel failed or error)
  unknown,

  /// Not applicable (wrong platform or OS version)
  notApplicable,
}

extension PermissionStatusX on PermissionStatus {
  /// Create PermissionStatus from string returned by native code
  static PermissionStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'GRANTED':
        return PermissionStatus.granted;
      case 'DENIED':
        return PermissionStatus.denied;
      case 'PERMANENTLY_DENIED':
        return PermissionStatus.permanentlyDenied;
      case 'NOT_DETERMINED':
        return PermissionStatus.notDetermined;
      case 'RESTRICTED':
        return PermissionStatus.restricted;
      case 'NOT_APPLICABLE':
        return PermissionStatus.notApplicable;
      default:
        return PermissionStatus.unknown;
    }
  }

  /// Check if permission is granted
  bool get isGranted => this == PermissionStatus.granted;

  /// Check if permission can be requested
  bool get canRequest => this == PermissionStatus.denied || this == PermissionStatus.notDetermined;

  /// Check if permission requires opening settings
  bool get needsSettings => this == PermissionStatus.permanentlyDenied || this == PermissionStatus.restricted;
}

/// Permissions Checker
class PermissionsChecker {
  final Logger _logger;

  PermissionsChecker({Logger? logger}) : _logger = logger ?? Logger();

  // ========================================================================
  // PHYSICAL ACTIVITY PERMISSION (Android 10+)
  // ========================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #1: Physical Activity Recognition Permission (Android 10+)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// Android 10+ requires explicit permission for apps to access step count data.
  /// This is the most critical permission for step tracking.
  ///
  /// KEY POINTS:
  /// • WITHOUT THIS: Step counting is COMPLETELY BLOCKED - APIs return 0 steps
  /// • Required Since: Android 10 (API 29, released September 2019)
  /// • Permission Name: ACTIVITY_RECOGNITION
  /// • Impact: 100% blocking - app cannot count steps at all
  ///
  /// TECHNICAL DETAILS:
  /// Android API: Manifest.permission.ACTIVITY_RECOGNITION
  /// Required Since: Android 10 (API 29)
  /// Confidence: 95% (Official Android API, well-documented)
  ///
  /// IN SIMPLE TERMS:
  /// Starting from Android 10 (2019), Google made apps ask for explicit
  /// permission to count your steps. Before this, apps could access step
  /// data without asking. Now it's like asking for permission to enter
  /// a room - without it, the door stays locked.
  ///
  /// REAL-WORLD EXAMPLE:
  /// Think of it like a security guard at a building entrance. Without
  /// showing your ID badge (permission), the guard won't let you in to
  /// access the step counter. Even if the step counter hardware is working
  /// perfectly inside, you can't reach it without permission.
  ///
  /// WHY IT MATTERS:
  /// • Your steps won't be counted AT ALL without this
  /// • Health apps like Google Fit won't work
  /// • Daily step goals can't be tracked
  /// • No step history will be recorded
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check if Physical Activity Recognition permission is granted
  ///
  /// Returns:
  /// - [PermissionStatus.granted] if permission is granted
  /// - [PermissionStatus.denied] if permission is denied but can be requested
  /// - [PermissionStatus.permanentlyDenied] if user selected "Don't ask again"
  /// - [PermissionStatus.notApplicable] if Android < 10 or iOS
  /// - [PermissionStatus.unknown] if detection failed
  Future<PermissionStatus> checkPhysicalActivityPermission() async {
    // Only applicable on Android 10+
    if (!Platform.isAndroid) {
      _logger.d('Physical activity permission: Not applicable (not Android)');
      return PermissionStatus.notApplicable;
    }

    try {
      _logger.d('Checking physical activity permission...');

      final dynamic result = await DiagnosticChannels.permissions
          .invokeMethod('checkPhysicalActivityPermission');

      if (result == null) {
        _logger.w('Physical activity permission check returned null');
        return PermissionStatus.unknown;
      }

      final status = PermissionStatusX.fromString(result as String);
      _logger.i('Physical activity permission status: $status');
      return status;
    } on PlatformException catch (e) {
      _logger.e('Platform exception checking physical activity permission: ${e.code} - ${e.message}');

      // Handle specific error codes
      if (e.code == 'NOT_AVAILABLE') {
        // Android version < 10
        return PermissionStatus.notApplicable;
      }

      return PermissionStatus.unknown;
    } catch (e) {
      _logger.e('Error checking physical activity permission: $e');
      return PermissionStatus.unknown;
    }
  }

  /// Request Physical Activity Recognition permission
  ///
  /// Opens Android's permission dialog.
  ///
  /// Returns true if permission was granted, false otherwise.
  Future<bool> requestPhysicalActivityPermission() async {
    if (!Platform.isAndroid) {
      _logger.w('requestPhysicalActivityPermission: Not applicable (not Android)');
      return false;
    }

    try {
      _logger.i('Requesting physical activity permission...');

      final dynamic result = await DiagnosticChannels.permissions
          .invokeMethod('requestPhysicalActivityPermission');

      final bool success = (result as bool?) ?? false;
      _logger.i('Physical activity permission request: ${success ? 'granted' : 'denied'}');

      return success;
    } on PlatformException catch (e) {
      _logger.e('Platform exception requesting physical activity permission: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error requesting physical activity permission: $e');
      return false;
    }
  }

  // ========================================================================
  // MOTION & FITNESS PERMISSION (iOS)
  // ========================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #2: Motion & Fitness Permission (iOS)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// iOS's equivalent of Android's Physical Activity permission. Allows
  /// apps to access motion and fitness data from CoreMotion framework.
  ///
  /// KEY POINTS:
  /// • WITHOUT THIS: iPhone cannot track steps at all
  /// • Required On: All iOS versions with step tracking
  /// • Framework: CoreMotion (CMPedometer)
  /// • Impact: 100% blocking - no step counting without it
  ///
  /// TECHNICAL DETAILS:
  /// iOS API: CoreMotion framework, CMPedometer.authorizationStatus()
  /// Required Since: iOS 11+
  /// Confidence: 95% (Official iOS API)
  ///
  /// IN SIMPLE TERMS:
  /// iPhones have a special chip called the Motion Coprocessor (M-series chip)
  /// that counts your steps in the background. But apps need your permission
  /// to read data from this chip. It's Apple's way of protecting your
  /// fitness privacy.
  ///
  /// REAL-WORLD EXAMPLE:
  /// Imagine your iPhone has a fitness diary that the Motion chip writes in
  /// all day. Without this permission, apps can't open the diary to read
  /// how many steps you took. The diary is still being written (steps are
  /// counted), but the app can't see inside.
  ///
  /// WHY IT MATTERS:
  /// • No step counting without this permission
  /// • Health app integration won't work
  /// • Can't sync steps to Apple Health
  /// • Fitness apps can't track your daily activity
  ///
  /// IMPORTANT NOTE:
  /// Unlike Android, this permission is controlled in two places on iOS:
  /// 1. Settings → Privacy → Motion & Fitness (main toggle)
  /// 2. Settings → Privacy → Motion & Fitness → [Your App] (per-app toggle)
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check if Motion & Fitness permission is granted (iOS)
  ///
  /// Returns:
  /// - [PermissionStatus.granted] if authorized
  /// - [PermissionStatus.denied] if denied
  /// - [PermissionStatus.notDetermined] if not yet requested
  /// - [PermissionStatus.restricted] if restricted by parental controls
  /// - [PermissionStatus.notApplicable] if Android
  Future<PermissionStatus> checkMotionFitnessPermission() async {
    // Only applicable on iOS
    if (!Platform.isIOS) {
      _logger.d('Motion & fitness permission: Not applicable (not iOS)');
      return PermissionStatus.notApplicable;
    }

    try {
      _logger.d('Checking motion & fitness permission...');

      final dynamic result = await DiagnosticChannels.permissions
          .invokeMethod('checkMotionFitnessPermission');

      if (result == null) {
        _logger.w('Motion & fitness permission check returned null');
        return PermissionStatus.unknown;
      }

      final status = PermissionStatusX.fromString(result as String);
      _logger.i('Motion & fitness permission status: $status');
      return status;
    } on PlatformException catch (e) {
      _logger.e('Platform exception checking motion & fitness permission: ${e.code} - ${e.message}');
      return PermissionStatus.unknown;
    } catch (e) {
      _logger.e('Error checking motion & fitness permission: $e');
      return PermissionStatus.unknown;
    }
  }

  /// Request Motion & Fitness permission (iOS)
  ///
  /// On iOS, this triggers the permission by attempting to query pedometer data.
  ///
  /// Returns true if permission was granted, false otherwise.
  Future<bool> requestMotionFitnessPermission() async {
    if (!Platform.isIOS) {
      _logger.w('requestMotionFitnessPermission: Not applicable (not iOS)');
      return false;
    }

    try {
      _logger.i('Requesting motion & fitness permission...');

      final dynamic result = await DiagnosticChannels.permissions
          .invokeMethod('requestMotionFitnessPermission');

      final bool success = (result as bool?) ?? false;
      _logger.i('Motion & fitness permission request: ${success ? 'granted' : 'denied'}');

      return success;
    } on PlatformException catch (e) {
      _logger.e('Platform exception requesting motion & fitness permission: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error requesting motion & fitness permission: $e');
      return false;
    }
  }

  /// Open iOS Settings app for manual permission granting
  ///
  /// Use when permission is denied and user needs to manually enable it.
  Future<bool> openIOSSettings() async {
    if (!Platform.isIOS) return false;

    try {
      _logger.i('Opening iOS Settings app...');

      final dynamic result = await DiagnosticChannels.iosSettings
          .invokeMethod('openSettings');

      return (result as bool?) ?? false;
    } catch (e) {
      _logger.e('Error opening iOS settings: $e');
      return false;
    }
  }

  // ========================================================================
  // NOTIFICATION PERMISSION (Android 13+)
  // ========================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #3: Notification Permission (Android 13+)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// Android 13+ requires explicit permission for apps to show notifications.
  /// Before Android 13, apps could show notifications without asking.
  ///
  /// KEY POINTS:
  /// • Won't receive notifications from Health Connect without this
  /// • Step sync status, health data updates, background activity alerts
  /// • NOT CRITICAL for step counting itself - steps still count without it
  /// • Only affects notifications, not core functionality
  ///
  /// TECHNICAL DETAILS:
  /// Android API: Manifest.permission.POST_NOTIFICATIONS
  /// Required Since: Android 13 (API 33, released August 2022)
  /// Confidence: 95% (Official Android API)
  ///
  /// IN SIMPLE TERMS:
  /// Starting from Android 13 (2022), apps must ask for your explicit
  /// permission to show you notifications - even simple alerts. It's Google's
  /// way of reducing notification spam and giving users more control.
  ///
  /// REAL-WORLD EXAMPLE:
  /// It's like someone needing your permission to knock on your door and
  /// tell you something. If you don't give permission, they can still do
  /// their work inside (count your steps), but they can't update you about
  /// it. The work gets done, you just don't get notified about progress.
  ///
  /// WHY IT MATTERS:
  /// Without this permission, you WON'T get notified about:
  /// • "Your steps have synced successfully"
  /// • "Background sync completed"
  /// • "Step tracking is active"
  /// • Daily step goal reminders
  /// • Health data sync status updates
  ///
  /// IMPORTANT:
  /// This permission is NOT critical for step counting itself - your steps
  /// will still count without it. You just won't get notified about updates.
  /// It's about user convenience, not core functionality.
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check if Notification permission is granted (Android 13+)
  ///
  /// Returns:
  /// - [PermissionStatus.granted] if permission is granted
  /// - [PermissionStatus.denied] if permission is denied but can be requested
  /// - [PermissionStatus.notApplicable] if Android < 13 or iOS
  Future<PermissionStatus> checkNotificationPermission() async {
    if (!Platform.isAndroid) {
      _logger.d('Notification permission: Not applicable (not Android)');
      return PermissionStatus.notApplicable;
    }

    try {
      _logger.d('Checking notification permission...');

      final dynamic result = await DiagnosticChannels.permissions
          .invokeMethod('checkNotificationPermission');

      if (result == null) {
        _logger.w('Notification permission check returned null');
        return PermissionStatus.unknown;
      }

      final status = PermissionStatusX.fromString(result as String);
      _logger.i('Notification permission status: $status');
      return status;
    } on PlatformException catch (e) {
      _logger.e('Platform exception checking notification permission: ${e.code} - ${e.message}');

      if (e.code == 'NOT_AVAILABLE') {
        return PermissionStatus.notApplicable;
      }

      return PermissionStatus.unknown;
    } catch (e) {
      _logger.e('Error checking notification permission: $e');
      return PermissionStatus.unknown;
    }
  }

  /// Request Notification permission (Android 13+)
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      _logger.i('Requesting notification permission...');

      final dynamic result = await DiagnosticChannels.permissions
          .invokeMethod('requestNotificationPermission');

      final bool success = (result as bool?) ?? false;
      _logger.i('Notification permission request: ${success ? 'granted' : 'denied'}');

      return success;
    } on PlatformException catch (e) {
      _logger.e('Platform exception requesting notification permission: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error requesting notification permission: $e');
      return false;
    }
  }

  // ========================================================================
  // LOCATION PERMISSION (Optional)
  // ========================================================================

  /// Check if Location permission is granted
  ///
  /// Some fitness apps use location for outdoor activity tracking.
  /// Not required for basic step counting.
  ///
  /// Returns map with:
  /// - 'fine': bool - Fine location (GPS) granted
  /// - 'coarse': bool - Coarse location (network) granted
  /// - 'background': bool - Background location granted (Android 10+)
  Future<Map<String, bool>> checkLocationPermission() async {
    try {
      _logger.d('Checking location permission...');

      final dynamic result = await DiagnosticChannels.permissions
          .invokeMethod('checkLocationPermission');

      if (result == null) {
        _logger.w('Location permission check returned null');
        return {'fine': false, 'coarse': false, 'background': false};
      }

      final map = Map<String, bool>.from(result as Map);
      _logger.i('Location permission status: $map');
      return map;
    } catch (e) {
      _logger.e('Error checking location permission: $e');
      return {'fine': false, 'coarse': false, 'background': false};
    }
  }

  // ========================================================================
  // COMPREHENSIVE CHECK
  // ========================================================================

  /// Run all permission checks relevant to current platform
  ///
  /// Returns map of permission name to status
  Future<Map<String, PermissionStatus>> checkAllPermissions() async {
    final results = <String, PermissionStatus>{};

    if (Platform.isAndroid) {
      results['physicalActivity'] = await checkPhysicalActivityPermission();
      results['notification'] = await checkNotificationPermission();
    } else if (Platform.isIOS) {
      results['motionFitness'] = await checkMotionFitnessPermission();
    }

    return results;
  }
}
