import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'diagnostic_channels.dart';

/// Status of health platform availability
enum HealthPlatformStatus {
  /// Platform is available and ready to use (SDK_AVAILABLE)
  available,

  /// Platform needs to be installed (Health Connect on Android 9-13)
  notInstalled,

  /// Platform is not supported on this device/OS version
  notSupported,

  /// Built-in to the OS (Health Connect on Android 14+)
  builtIn,

  /// Stub/shell is present but needs update/download (SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED)
  /// This happens when Health Connect framework module exists but isn't fully initialized
  needsUpdate,

  /// Status could not be determined
  unknown,
}

/// Extension methods for [HealthPlatformStatus]
extension HealthPlatformStatusX on HealthPlatformStatus {
  /// Convert string from native code to [HealthPlatformStatus]
  static HealthPlatformStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'SDK_AVAILABLE':
      case 'AVAILABLE':
        return HealthPlatformStatus.available;
      case 'NOT_INSTALLED':
      case 'SDK_UNAVAILABLE':
        return HealthPlatformStatus.notInstalled;
      case 'NOT_SUPPORTED':
        return HealthPlatformStatus.notSupported;
      case 'BUILT_IN':
        return HealthPlatformStatus.builtIn;
      case 'SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED':
        return HealthPlatformStatus.needsUpdate;
      default:
        return HealthPlatformStatus.unknown;
    }
  }

  /// Check if platform is ready to use
  bool get isAvailable =>
      this == HealthPlatformStatus.available ||
      this == HealthPlatformStatus.builtIn;

  /// Check if platform needs installation or update
  bool get needsInstallation =>
      this == HealthPlatformStatus.notInstalled ||
      this == HealthPlatformStatus.needsUpdate;

  /// Check if platform is not supported
  bool get isNotSupported => this == HealthPlatformStatus.notSupported;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case HealthPlatformStatus.available:
        return 'Available';
      case HealthPlatformStatus.notInstalled:
        return 'Not Installed';
      case HealthPlatformStatus.notSupported:
        return 'Not Supported';
      case HealthPlatformStatus.builtIn:
        return 'Built-in';
      case HealthPlatformStatus.needsUpdate:
        return 'Needs Update';
      case HealthPlatformStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Authorization status for HealthKit (iOS)
enum HealthKitAuthStatus {
  /// User has authorized access
  authorized,

  /// User has denied access
  denied,

  /// User has not been asked yet
  notDetermined,

  /// Status could not be determined
  unknown,
}

/// Extension methods for [HealthKitAuthStatus]
extension HealthKitAuthStatusX on HealthKitAuthStatus {
  /// Convert string from native code to [HealthKitAuthStatus]
  static HealthKitAuthStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'AUTHORIZED':
        return HealthKitAuthStatus.authorized;
      case 'DENIED':
        return HealthKitAuthStatus.denied;
      case 'NOT_DETERMINED':
        return HealthKitAuthStatus.notDetermined;
      default:
        return HealthKitAuthStatus.unknown;
    }
  }

  /// Check if authorized
  bool get isAuthorized => this == HealthKitAuthStatus.authorized;

  /// Check if can request authorization
  bool get canRequest =>
      this == HealthKitAuthStatus.denied ||
      this == HealthKitAuthStatus.notDetermined;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case HealthKitAuthStatus.authorized:
        return 'Authorized';
      case HealthKitAuthStatus.denied:
        return 'Denied';
      case HealthKitAuthStatus.notDetermined:
        return 'Not Determined';
      case HealthKitAuthStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Result of Health Connect availability check
class HealthConnectAvailability {
  final HealthPlatformStatus status;
  final int? apiLevel;
  final String? packageName;
  final String? version;
  final bool isStubOnly;

  const HealthConnectAvailability({
    required this.status,
    this.apiLevel,
    this.packageName,
    this.version,
    this.isStubOnly = false,
  });

  factory HealthConnectAvailability.fromMap(Map<dynamic, dynamic> map) {
    return HealthConnectAvailability(
      status: HealthPlatformStatusX.fromString(map['status'] as String),
      apiLevel: map['apiLevel'] as int?,
      packageName: map['packageName'] as String?,
      version: map['version'] as String?,
      isStubOnly: map['isStubOnly'] as bool? ?? false,
    );
  }

  bool get isAvailable => status.isAvailable;
  bool get needsInstallation => status.needsInstallation;
  bool get isBuiltIn => status == HealthPlatformStatus.builtIn;
}

/// Result of HealthKit availability check
class HealthKitAvailability {
  final bool available;
  final HealthKitAuthStatus authStatus;
  final String? error;

  const HealthKitAvailability({
    required this.available,
    required this.authStatus,
    this.error,
  });

  factory HealthKitAvailability.fromMap(Map<dynamic, dynamic> map) {
    return HealthKitAvailability(
      available: map['available'] as bool? ?? false,
      authStatus:
          HealthKitAuthStatusX.fromString(map['status'] as String? ?? 'UNKNOWN'),
      error: map['error'] as String?,
    );
  }

  bool get isAuthorized => authStatus.isAuthorized;
  bool get canRequest => authStatus.canRequest;
}

/// Checker for health platform availability and permissions
/// Handles Health Connect (Android) and HealthKit (iOS)
class HealthPlatformChecker {
  final Logger _logger;

  HealthPlatformChecker({Logger? logger})
      : _logger = logger ?? Logger();

  // ============================================================================
  // HEALTH CONNECT (ANDROID)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #11: Health Connect (Android)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// Google's unified health and fitness data platform for Android that
  /// allows apps to securely store, share, and access health data in one
  /// central place. Think of it as the Android equivalent of Apple's HealthKit.
  ///
  /// KEY POINTS:
  /// • Central hub for ALL health and fitness data on Android
  /// • Replaces Google Fit as the primary health platform
  /// • Encrypted, user-controlled health data storage
  /// • One-time permission system (user grants per data type)
  /// • Apps can read/write step count, heart rate, sleep, nutrition, etc.
  /// • Android 14+: Built into OS (no installation needed)
  /// • Android 9-13: Requires separate app from Play Store (free)
  /// • Android 8 and below: Not supported
  ///
  /// TECHNICAL DETAILS:
  /// Android API: androidx.health.connect.client.HealthConnectClient
  /// Built-in Since: Android 14 (API 34, October 2023)
  /// Separate App: Android 9-13 (API 28-33)
  /// Not Supported: Android 8 and below (API 27 and below)
  /// Confidence: 90% (Official API, but relatively new)
  ///
  /// IN SIMPLE TERMS:
  /// Health Connect is like a secure vault where all your health apps store
  /// their data. Instead of each app (step tracker, sleep monitor, nutrition
  /// app) having its own isolated data, they all put it in one shared place.
  /// You control which apps can read or write to this vault.
  ///
  /// REAL-WORLD EXAMPLE:
  /// Before Health Connect:
  /// • Step tracking app has its own step database
  /// • Fitness app has its own step database
  /// • Health app has its own step database
  /// • Problem: Data doesn't sync between apps, inconsistent counts
  ///
  /// With Health Connect:
  /// • ALL apps store steps in Health Connect
  /// • Step tracking app writes steps to Health Connect
  /// • Fitness app reads steps from Health Connect
  /// • Health app reads steps from Health Connect
  /// • Result: Everyone sees the same step count, always synchronized
  ///
  /// WHY IT MATTERS:
  ///
  /// WHEN HEALTH CONNECT IS AVAILABLE (Installed):
  /// • App can store steps in centralized, encrypted storage
  /// • Other health apps can read your steps
  /// • User has unified health dashboard in Health Connect app
  /// • Data survives app uninstalls (stored in Health Connect)
  /// • Backup and sync across Android devices
  /// • Privacy controls (user can delete data, revoke permissions)
  ///
  /// WHEN HEALTH CONNECT IS NOT INSTALLED (Android 9-13):
  /// • App CANNOT use Health Connect APIs
  /// • Step data stays isolated in your app
  /// • Other apps can't access step count
  /// • No unified health dashboard
  /// • Must install Health Connect app from Play Store (free)
  ///
  /// WHEN HEALTH CONNECT IS NOT SUPPORTED (Android 8 and below):
  /// • Device is too old for Health Connect
  /// • App must use alternative storage (local database)
  /// • No health data integration with other apps
  /// • Recommend upgrading device (if possible)
  ///
  /// ANDROID VERSION BREAKDOWN:
  ///
  /// ANDROID 14+ (October 2023 onwards):
  /// • Status: BUILT_IN
  /// • Health Connect is part of the operating system
  /// • Pre-installed on all Android 14+ devices
  /// • No user action required
  /// • Updated via system updates (not Play Store)
  ///
  /// ANDROID 9-13 (2018-2023):
  /// • Status: AVAILABLE (if installed) or NOT_INSTALLED
  /// • Health Connect is a separate app from Google Play Store
  /// • FREE to download
  /// • Package name: com.google.android.apps.healthdata
  /// • Requires manual installation by user
  /// • Updated via Play Store
  ///
  /// ANDROID 8 AND BELOW (2017 and earlier):
  /// • Status: NOT_SUPPORTED
  /// • Health Connect requires Android 9 minimum
  /// • App must use alternative storage solutions
  /// • These devices are 7+ years old (2018 or older)
  ///
  /// PERMISSION SYSTEM:
  /// Health Connect uses granular permissions:
  /// • STEPS: Read/write step count data
  /// • DISTANCE: Read/write distance traveled
  /// • CALORIES: Read/write calories burned
  /// • HEART_RATE: Read/write heart rate data
  /// • SLEEP: Read/write sleep sessions
  /// • And 40+ other health data types
  ///
  /// User grants permissions PER DATA TYPE (e.g., allow steps but deny heart rate).
  ///
  /// TROUBLESHOOTING GUIDANCE:
  ///
  /// If NOT_INSTALLED (Android 9-13):
  ///   → Explain Health Connect is required for step tracking on Android 9-13
  ///   → Emphasize it's FREE from Google Play Store
  ///   → Offer action button: "Install Health Connect"
  ///   → Opens Play Store directly to Health Connect app page
  ///   → Guide user: "Tap Install → Open → Grant Permissions"
  ///
  /// If BUILT_IN (Android 14+):
  ///   → Inform user Health Connect is already installed (part of OS)
  ///   → No installation needed
  ///   → Check if permissions are granted
  ///   → If not granted: "Grant Permissions" button
  ///
  /// If NOT_SUPPORTED (Android 8 and below):
  ///   → Inform user device is too old for Health Connect
  ///   → Explain app will use local storage instead
  ///   → Suggest: Upgrade to Android 9+ for full features
  ///   → Reassure: Step tracking still works, just no integration
  ///
  /// INTEGRATION WITH STEP TRACKING:
  /// • Step tracking app WRITES steps to Health Connect
  /// • Health Connect stores steps securely
  /// • User can view all health data in Health Connect app
  /// • Other fitness apps can READ steps from Health Connect
  /// • Google Fit can sync with Health Connect
  /// • Backup to Google account (if enabled by user)
  ///
  /// COMPARISON WITH GOOGLE FIT:
  /// Health Connect REPLACES Google Fit as the primary API:
  /// • Google Fit: Older platform (deprecated)
  /// • Health Connect: New platform (current standard)
  /// • Google Fit still works but is being phased out
  /// • Developers should use Health Connect going forward
  ///
  /// IMPORTANT NOTES:
  /// • Health Connect data is encrypted and stored locally on device
  /// • User has full control: can delete data, revoke permissions anytime
  /// • Apps cannot access data without explicit user permission
  /// • Health Connect is privacy-focused by design
  /// • Data can be backed up to Google account (user choice)
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check Health Connect availability on Android
  ///
  /// Returns [HealthConnectAvailability] with:
  /// - Android 14+: BUILT_IN (Health Connect is part of OS)
  /// - Android 9-13: AVAILABLE (if app installed) or NOT_INSTALLED
  /// - Android 8 and below: NOT_SUPPORTED
  ///
  /// Throws [PlatformException] if native code fails
  Future<HealthConnectAvailability> checkHealthConnectAvailability() async {
    if (!Platform.isAndroid) {
      _logger.d('Health Connect not applicable on non-Android platforms');
      return const HealthConnectAvailability(
        status: HealthPlatformStatus.notSupported,
      );
    }

    try {
      _logger.d('Checking Health Connect availability...');
      final result = await DiagnosticChannels.healthConnect
          .invokeMethod('checkHealthConnectAvailability');

      if (result == null) {
        _logger.w('Health Connect availability check returned null');
        return const HealthConnectAvailability(
          status: HealthPlatformStatus.unknown,
        );
      }

      // DEBUG: Log raw result from native side
      _logger.i('=== DART: Raw result from native ===');
      _logger.i('Result map: $result');
      _logger.i('Status string: ${result['status']}');
      _logger.i('SDK Status code: ${result['sdkStatus']}');
      _logger.i('API Level: ${result['apiLevel']}');

      final availability = HealthConnectAvailability.fromMap(
          result as Map<dynamic, dynamic>);
      _logger.i('Converted to status: ${availability.status.description}');
      _logger.i('Is available: ${availability.isAvailable}');
      _logger.i('Needs installation: ${availability.needsInstallation}');
      return availability;
    } on PlatformException catch (e) {
      _logger.e('PlatformException checking Health Connect: ${e.message}');
      if (e.code == 'NOT_SUPPORTED') {
        return const HealthConnectAvailability(
          status: HealthPlatformStatus.notSupported,
        );
      }
      return const HealthConnectAvailability(
        status: HealthPlatformStatus.unknown,
      );
    } catch (e) {
      _logger.e('Error checking Health Connect availability: $e');
      return const HealthConnectAvailability(
        status: HealthPlatformStatus.unknown,
      );
    }
  }

  /// Open Play Store to install Health Connect app (Android 9-13)
  ///
  /// Returns true if Play Store was opened successfully
  Future<bool> openHealthConnectPlayStore() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot open Play Store on non-Android platforms');
      return false;
    }

    try {
      _logger.d('Opening Play Store for Health Connect...');
      final result = await DiagnosticChannels.healthConnect
          .invokeMethod('openHealthConnectPlayStore');
      final success = result as bool? ?? false;
      _logger.i('Play Store opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException opening Play Store: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error opening Play Store: $e');
      return false;
    }
  }

  /// Check if Health Connect permissions are granted (Android)
  ///
  /// Returns true if READ_STEPS permission is granted
  /// Returns false if permissions not granted
  /// Throws exception if Health Connect is not available
  Future<bool> checkHealthConnectPermissions() async {
    if (!Platform.isAndroid) {
      _logger.d('Health Connect permissions not applicable on non-Android');
      throw UnsupportedError('Health Connect only available on Android');
    }

    try {
      _logger.d('Checking Health Connect permissions...');
      final result = await DiagnosticChannels.healthConnect
          .invokeMethod('checkHealthConnectPermissions');
      final granted = result as bool? ?? false;
      _logger.i('Health Connect permissions granted: $granted');
      return granted;
    } on PlatformException catch (e) {
      _logger.e('PlatformException checking permissions: ${e.message}');
      // Re-throw platform exceptions to signal HC is not available
      rethrow;
    } catch (e) {
      _logger.e('Error checking Health Connect permissions: $e');
      // Re-throw errors to signal HC is not available
      rethrow;
    }
  }

  /// Request Health Connect permissions (Android)
  ///
  /// Opens Health Connect permission screen where user can grant access
  /// Returns true if permission screen was opened successfully
  Future<bool> requestHealthConnectPermissions() async {
    if (!Platform.isAndroid) {
      _logger.d('Health Connect permissions not applicable on non-Android');
      return false;
    }

    try {
      _logger.d('Requesting Health Connect permissions...');
      final result = await DiagnosticChannels.healthConnect
          .invokeMethod('requestHealthConnectPermissions');
      final success = result as bool? ?? false;
      _logger.i('Health Connect permission screen opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException requesting permissions: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error requesting Health Connect permissions: $e');
      return false;
    }
  }

  /// Read today's step count from Health Connect (Android)
  ///
  /// Returns a map with:
  /// - status: "success", "unavailable", "permission_denied", or "error"
  /// - totalSteps: Total step count for today (when status is "success")
  /// - sources: Map of package names to step counts
  /// - recordCount: Number of step records
  /// - lastSync: Timestamp of last sync
  /// - error: Error message (when status is not "success")
  Future<Map<String, dynamic>> readTodaySteps() async {
    if (!Platform.isAndroid) {
      _logger.d('Step reading not applicable on non-Android');
      return {
        'status': 'unavailable',
        'error': 'Not available on this platform'
      };
    }

    try {
      _logger.d('Reading today\'s steps from Health Connect...');
      final result = await DiagnosticChannels.steps.invokeMethod('readSteps');
      final stepsData = Map<String, dynamic>.from(result as Map);
      _logger.i('Steps read result: ${stepsData['status']}, total: ${stepsData['totalSteps']}');
      return stepsData;
    } on PlatformException catch (e) {
      _logger.e('PlatformException reading steps: ${e.message}');
      return {
        'status': 'error',
        'error': e.message ?? 'Failed to read steps'
      };
    } catch (e) {
      _logger.e('Error reading steps: $e');
      return {
        'status': 'error',
        'error': e.toString()
      };
    }
  }

  // ============================================================================
  // HEALTHKIT (iOS)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #12: HealthKit (iOS)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// Apple's comprehensive health and fitness data platform built into iOS
  /// that provides a unified, encrypted repository for all health data.
  /// The iOS equivalent of Android's Health Connect, but more mature.
  ///
  /// KEY POINTS:
  /// • Built into iOS since iOS 8 (2014) - no installation needed
  /// • Central storage for ALL health and fitness data on iPhone
  /// • Encrypted with device passcode/Face ID/Touch ID
  /// • Powers the Apple Health app (pre-installed on all iPhones)
  /// • Apps request permission per data type (steps, heart rate, etc.)
  /// • Syncs across Apple devices via iCloud (if enabled)
  /// • Available on: iPhone (all models)
  /// • NOT available on: iPad (most models), iPod touch (all models)
  ///
  /// TECHNICAL DETAILS:
  /// iOS API: HealthKit framework (HKHealthStore)
  /// Available Since: iOS 8.0 (September 2014)
  /// Permission API: HKHealthStore.authorizationStatus(for:)
  /// Confidence: 95% (Mature, well-documented Apple API)
  ///
  /// IN SIMPLE TERMS:
  /// HealthKit is like a secure medical filing cabinet built into every
  /// iPhone. All health apps (step counters, sleep trackers, nutrition
  /// apps, etc.) store their data in this cabinet instead of keeping it
  /// separately. You control which apps can read or write to which folders
  /// in the cabinet.
  ///
  /// REAL-WORLD EXAMPLE:
  /// You go for a morning jog with your iPhone:
  /// • iPhone's built-in motion sensor counts your steps
  /// • Steps are automatically stored in HealthKit
  /// • Apple Health app shows your steps (reads from HealthKit)
  /// • Your fitness app reads steps from HealthKit (if you granted permission)
  /// • Your wellness app reads steps from HealthKit (if you granted permission)
  /// • Result: Everyone sees the same accurate step count from one source
  ///
  /// WHY IT MATTERS:
  ///
  /// WHEN HEALTHKIT IS AVAILABLE (iPhone):
  /// • Unified health dashboard in Apple Health app
  /// • Step data synced across all apps automatically
  /// • Data persists even if you uninstall fitness apps
  /// • Encrypted storage tied to device security
  /// • iCloud backup and sync (if enabled by user)
  /// • Medical ID for emergency responders
  /// • Health Records integration (medical data from doctors)
  /// • Sharing with family, doctors via Health app
  ///
  /// WHEN HEALTHKIT IS NOT AVAILABLE (iPad, iPod):
  /// • Device doesn't have HealthKit hardware support
  /// • No centralized health data storage
  /// • Apps must use local storage for step data
  /// • No integration with Apple Health ecosystem
  /// • Rare scenario (most iOS devices are iPhones)
  ///
  /// AUTHORIZATION STATUSES:
  ///
  /// 1. AUTHORIZED:
  ///    • User has granted permission to read/write step data
  ///    • App can access HealthKit for steps
  ///    • No further action needed
  ///
  /// 2. DENIED:
  ///    • User explicitly denied permission in the past
  ///    • App CANNOT access HealthKit
  ///    • User must go to Settings → Health → Data Access & Devices → [App]
  ///    • Can re-enable permission there
  ///
  /// 3. NOT_DETERMINED:
  ///    • App has never requested permission yet
  ///    • User hasn't been asked
  ///    • App should request authorization
  ///    • Shows native iOS permission sheet
  ///
  /// PERMISSION SYSTEM:
  /// HealthKit uses granular, per-data-type permissions:
  /// • STEPS: Read/write step count
  /// • DISTANCE: Read/write distance walked/run
  /// • FLIGHTS_CLIMBED: Read/write stairs climbed
  /// • ACTIVE_ENERGY: Read/write calories burned
  /// • HEART_RATE: Read/write heart rate
  /// • SLEEP_ANALYSIS: Read/write sleep data
  /// • And 100+ other health data types
  ///
  /// User grants permissions individually (e.g., allow steps but deny heart rate).
  ///
  /// PRIVACY FEATURES:
  /// • Apps can only READ data user explicitly approves
  /// • Apps can WRITE data without user knowing (prevents gaming the system)
  /// • User can revoke permissions anytime in Health app
  /// • User can delete specific data points or entire categories
  /// • Apps cannot tell if permission was denied or granted (privacy by design)
  ///
  /// DEVICE AVAILABILITY:
  ///
  /// iPhone (All Models):
  /// • HealthKit: ✅ AVAILABLE
  /// • Apple Health app: Pre-installed
  /// • Motion coprocessor: Counts steps automatically
  /// • Full HealthKit functionality
  ///
  /// iPad (Most Models):
  /// • HealthKit: ❌ NOT AVAILABLE (hardware limitation)
  /// • Apple Health app: Not available
  /// • No motion coprocessor (doesn't count steps)
  /// • Exception: Some iPad Pro models have limited HealthKit support
  ///
  /// iPod touch (All Models):
  /// • HealthKit: ❌ NOT AVAILABLE
  /// • Apple Health app: Not available
  /// • No motion coprocessor
  ///
  /// Apple Watch:
  /// • HealthKit: ✅ AVAILABLE (syncs with paired iPhone)
  /// • Primary fitness tracker for Apple ecosystem
  /// • All health data syncs to iPhone's HealthKit
  ///
  /// INTEGRATION WITH STEP TRACKING:
  /// • iPhone's M-series coprocessor automatically counts steps
  /// • Steps are stored in HealthKit continuously
  /// • Third-party apps READ steps from HealthKit
  /// • Third-party apps can WRITE steps to HealthKit
  /// • Apple Health app displays comprehensive health dashboard
  /// • Data syncs to Apple Watch, iPad Pro (if available)
  ///
  /// iCLOUD SYNC:
  /// If user enables Health syncing in iCloud:
  /// • All HealthKit data syncs across user's Apple devices
  /// • End-to-end encrypted
  /// • Automatic backup
  /// • Seamless device switching
  ///
  /// TROUBLESHOOTING GUIDANCE:
  ///
  /// If AUTHORIZED:
  ///   → Everything is working correctly
  ///   → No action needed
  ///   → App can read/write step data to HealthKit
  ///
  /// If DENIED:
  ///   → User previously denied permission
  ///   → Explain that app needs HealthKit access for step tracking
  ///   → Guide to: Settings → Health → Data Access & Devices → [App Name]
  ///   → User must toggle permissions on manually
  ///   → Cannot show permission dialog again (iOS restriction)
  ///
  /// If NOT_DETERMINED:
  ///   → App hasn't requested permission yet
  ///   → Show "Grant HealthKit Permission" button
  ///   → Triggers native iOS permission sheet
  ///   → User taps "Allow" or "Don't Allow"
  ///
  /// If NOT AVAILABLE (iPad/iPod):
  ///   → Device doesn't support HealthKit (hardware limitation)
  ///   → Explain: HealthKit is only available on iPhone
  ///   → Offer alternative: Manual step entry or external tracker
  ///   → Inform: Automatic step tracking requires iPhone
  ///
  /// COMPARISON WITH HEALTH CONNECT:
  /// HealthKit (iOS) vs Health Connect (Android):
  /// • HealthKit: More mature (2014 vs 2023)
  /// • HealthKit: Built into iOS (always available)
  /// • Health Connect: Requires separate app on Android 9-13
  /// • HealthKit: 100+ data types
  /// • Health Connect: 40+ data types (growing)
  /// • Both: Encrypted, user-controlled, privacy-focused
  ///
  /// IMPORTANT NOTES:
  /// • HealthKit data is encrypted with device passcode/biometrics
  /// • Data stays on device (unless iCloud sync enabled)
  /// • Apps cannot bypass HealthKit permissions
  /// • User has complete control over all data
  /// • Apple cannot read HealthKit data (end-to-end encrypted)
  /// • Medical ID can be accessed even when device is locked (emergency)
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check HealthKit availability on iOS
  ///
  /// Returns [HealthKitAvailability] with:
  /// - available: true if HealthKit is available on this device
  /// - authStatus: current authorization status for step count
  ///
  /// HealthKit is not available on iPad (most models) and iPod touch
  Future<HealthKitAvailability> checkHealthKitAvailability() async {
    if (!Platform.isIOS) {
      _logger.d('HealthKit not applicable on non-iOS platforms');
      return const HealthKitAvailability(
        available: false,
        authStatus: HealthKitAuthStatus.unknown,
      );
    }

    try {
      _logger.d('Checking HealthKit availability...');
      final result = await DiagnosticChannels.healthKit
          .invokeMethod('checkHealthKitAvailability');

      if (result == null) {
        _logger.w('HealthKit availability check returned null');
        return const HealthKitAvailability(
          available: false,
          authStatus: HealthKitAuthStatus.unknown,
        );
      }

      final availability =
          HealthKitAvailability.fromMap(result as Map<dynamic, dynamic>);
      _logger.i(
          'HealthKit available: ${availability.available}, auth: ${availability.authStatus.description}');
      return availability;
    } on PlatformException catch (e) {
      _logger.e('PlatformException checking HealthKit: ${e.message}');
      return HealthKitAvailability(
        available: false,
        authStatus: HealthKitAuthStatus.unknown,
        error: e.message,
      );
    } catch (e) {
      _logger.e('Error checking HealthKit availability: $e');
      return HealthKitAvailability(
        available: false,
        authStatus: HealthKitAuthStatus.unknown,
        error: e.toString(),
      );
    }
  }

  /// Request HealthKit authorization (iOS)
  ///
  /// Shows HealthKit permission sheet where user can grant access to step count
  /// Returns true if authorization request was successful
  Future<bool> requestHealthKitAuthorization() async {
    if (!Platform.isIOS) {
      _logger.d('HealthKit authorization not applicable on non-iOS');
      return false;
    }

    try {
      _logger.d('Requesting HealthKit authorization...');
      final result = await DiagnosticChannels.healthKit
          .invokeMethod('requestHealthKitAuthorization');
      final success = result as bool? ?? false;
      _logger.i('HealthKit authorization requested: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException requesting HealthKit auth: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error requesting HealthKit authorization: $e');
      return false;
    }
  }

  // ============================================================================
  // COMBINED CHECKS
  // ============================================================================

  /// Check all health platform features
  ///
  /// Returns a map with all health platform statuses
  Future<Map<String, dynamic>> checkAllHealthPlatforms() async {
    _logger.d('Checking all health platforms...');

    final results = <String, dynamic>{};

    if (Platform.isAndroid) {
      final healthConnect = await checkHealthConnectAvailability();
      results['healthConnect'] = {
        'status': healthConnect.status.description,
        'isAvailable': healthConnect.isAvailable,
        'needsInstallation': healthConnect.needsInstallation,
        'isBuiltIn': healthConnect.isBuiltIn,
        'apiLevel': healthConnect.apiLevel,
      };
    }

    if (Platform.isIOS) {
      final healthKit = await checkHealthKitAvailability();
      results['healthKit'] = {
        'available': healthKit.available,
        'authStatus': healthKit.authStatus.description,
        'isAuthorized': healthKit.isAuthorized,
        'canRequest': healthKit.canRequest,
      };
    }

    _logger.i('Health platform check complete: ${results.length} platforms');
    return results;
  }
}
