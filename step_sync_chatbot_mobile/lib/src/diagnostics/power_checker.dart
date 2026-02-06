import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'diagnostic_channels.dart';

/// Status of power-related features
enum PowerStatus {
  /// Feature is enabled (generally bad for background work)
  enabled,

  /// Feature is disabled (good for background work)
  disabled,

  /// Feature is not available on this platform/version
  notAvailable,

  /// Status could not be determined
  unknown,
}

/// Extension methods for [PowerStatus]
extension PowerStatusX on PowerStatus {
  /// Convert string from native code to [PowerStatus]
  static PowerStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ENABLED':
        return PowerStatus.enabled;
      case 'DISABLED':
        return PowerStatus.disabled;
      case 'NOT_AVAILABLE':
        return PowerStatus.notAvailable;
      default:
        return PowerStatus.unknown;
    }
  }

  /// Check if feature is enabled (bad for background work)
  bool get isEnabled => this == PowerStatus.enabled;

  /// Check if feature is disabled (good for background work)
  bool get isDisabled => this == PowerStatus.disabled;

  /// Check if feature is available on this platform
  bool get isAvailable => this != PowerStatus.notAvailable;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case PowerStatus.enabled:
        return 'Enabled';
      case PowerStatus.disabled:
        return 'Disabled';
      case PowerStatus.notAvailable:
        return 'Not Available';
      case PowerStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Background App Refresh status (iOS)
enum BackgroundAppRefreshStatus {
  /// Background refresh is available for this app
  available,

  /// Background refresh is denied by user
  denied,

  /// Background refresh is restricted (parental controls, etc.)
  restricted,

  /// Status could not be determined
  unknown,
}

/// Extension methods for [BackgroundAppRefreshStatus]
extension BackgroundAppRefreshStatusX on BackgroundAppRefreshStatus {
  /// Convert string from native code to [BackgroundAppRefreshStatus]
  static BackgroundAppRefreshStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return BackgroundAppRefreshStatus.available;
      case 'DENIED':
        return BackgroundAppRefreshStatus.denied;
      case 'RESTRICTED':
        return BackgroundAppRefreshStatus.restricted;
      default:
        return BackgroundAppRefreshStatus.unknown;
    }
  }

  /// Check if background refresh is available
  bool get isAvailable => this == BackgroundAppRefreshStatus.available;

  /// Check if background refresh is blocked
  bool get isBlocked =>
      this == BackgroundAppRefreshStatus.denied ||
      this == BackgroundAppRefreshStatus.restricted;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case BackgroundAppRefreshStatus.available:
        return 'Available';
      case BackgroundAppRefreshStatus.denied:
        return 'Denied';
      case BackgroundAppRefreshStatus.restricted:
        return 'Restricted';
      case BackgroundAppRefreshStatus.unknown:
        return 'Unknown';
    }
  }
}

/// App Standby Bucket (Android 9+)
enum AppStandbyBucket {
  /// App is actively being used
  active,

  /// App is in working set (used regularly)
  workingSet,

  /// App is used frequently
  frequent,

  /// App is rarely used
  rare,

  /// App is restricted by system
  restricted,

  /// Bucket could not be determined
  unknown,
}

/// Extension methods for [AppStandbyBucket]
extension AppStandbyBucketX on AppStandbyBucket {
  /// Convert string from native code to [AppStandbyBucket]
  static AppStandbyBucket fromString(String bucket) {
    switch (bucket.toUpperCase()) {
      case 'ACTIVE':
        return AppStandbyBucket.active;
      case 'WORKING_SET':
        return AppStandbyBucket.workingSet;
      case 'FREQUENT':
        return AppStandbyBucket.frequent;
      case 'RARE':
        return AppStandbyBucket.rare;
      case 'RESTRICTED':
        return AppStandbyBucket.restricted;
      default:
        return AppStandbyBucket.unknown;
    }
  }

  /// Check if bucket is good for background work
  bool get isGoodForBackground =>
      this == AppStandbyBucket.active || this == AppStandbyBucket.workingSet;

  /// Check if bucket is bad for background work
  bool get isBadForBackground =>
      this == AppStandbyBucket.rare || this == AppStandbyBucket.restricted;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case AppStandbyBucket.active:
        return 'Active';
      case AppStandbyBucket.workingSet:
        return 'Working Set';
      case AppStandbyBucket.frequent:
        return 'Frequent';
      case AppStandbyBucket.rare:
        return 'Rare';
      case AppStandbyBucket.restricted:
        return 'Restricted';
      case AppStandbyBucket.unknown:
        return 'Unknown';
    }
  }
}

/// Result of Doze Mode check (Android)
class DozeModeStatus {
  final bool isDeviceInDozeMode;
  final AppStandbyBucket appStandbyBucket;
  final bool isAppWhitelisted;

  const DozeModeStatus({
    required this.isDeviceInDozeMode,
    required this.appStandbyBucket,
    this.isAppWhitelisted = false,
  });

  factory DozeModeStatus.fromMap(Map<dynamic, dynamic> map) {
    return DozeModeStatus(
      isDeviceInDozeMode: map['isDeviceInDozeMode'] as bool? ?? false,
      appStandbyBucket: AppStandbyBucketX.fromString(
          map['appStandbyBucket'] as String? ?? 'UNKNOWN'),
      isAppWhitelisted: map['isAppWhitelisted'] as bool? ?? false,
    );
  }

  /// Check if Doze Mode will significantly impact background work
  bool get hasSignificantImpact =>
      isDeviceInDozeMode && !isAppWhitelisted && appStandbyBucket.isBadForBackground;

  /// Check if Doze Mode has moderate impact
  bool get hasModerateImpact =>
      isDeviceInDozeMode && !isAppWhitelisted && !appStandbyBucket.isGoodForBackground;
}

/// Checker for power management features
/// Handles Low Power Mode (iOS), Background App Refresh (iOS),
/// Power Saving Mode (Android), and Doze Mode (Android)
class PowerChecker {
  final Logger _logger;

  PowerChecker({Logger? logger}) : _logger = logger ?? Logger();

  // ============================================================================
  // LOW POWER MODE (iOS)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #7: Low Power Mode (iOS)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// Apple's battery-saving mode that temporarily reduces power consumption
  /// on iPhone and iPad by disabling or reducing background activities.
  /// Automatically turns off when the device is charged above 80%.
  ///
  /// KEY POINTS:
  /// • TEMPORARY power-saving feature (auto-disables when charged)
  /// • User can toggle on/off manually in Settings or Control Center
  /// • iOS offers to enable it automatically at 20% battery
  /// • Disables Background App Refresh while active
  /// • Available on all iOS devices (iPhone, iPad)
  ///
  /// TECHNICAL DETAILS:
  /// iOS API: ProcessInfo.processInfo.isLowPowerModeEnabled
  /// Available Since: iOS 9.0 (released September 2015)
  /// Event Notification: NSProcessInfoPowerStateDidChange
  /// Confidence: 95% (Official Apple API)
  ///
  /// IN SIMPLE TERMS:
  /// Low Power Mode is like putting your iPhone on a "diet" to make the
  /// battery last longer. It reduces or stops background activities that
  /// drain battery. Your phone still works, but apps can't do things in
  /// the background until you turn it off or charge your device.
  ///
  /// REAL-WORLD EXAMPLE:
  /// Think of it like a hotel during off-peak hours. Normally, the hotel
  /// keeps all lights on, runs the AC in every room, and has staff cleaning
  /// 24/7 (normal mode). During Low Power Mode, it's like saying "we're
  /// short on electricity - only keep lights on in occupied rooms, turn off
  /// AC in empty rooms, and pause non-urgent maintenance." The hotel still
  /// functions, but consumes less power.
  ///
  /// WHY IT MATTERS:
  ///
  /// WHEN LOW POWER MODE IS ENABLED:
  /// • Background App Refresh is DISABLED (apps can't refresh in background)
  /// • Step sync stops working when app is closed
  /// • Health data updates paused until app is opened
  /// • Mail fetch is reduced (manual only)
  /// • Automatic downloads are paused
  /// • Visual effects are reduced (animations slower)
  /// • 5G is disabled (uses 4G/LTE instead)
  /// • Auto-lock happens faster (30 seconds)
  ///
  /// IMPACT ON STEP TRACKING:
  /// • Local step counting CONTINUES (hardware sensor still works)
  /// • Cloud sync PAUSED (no background upload)
  /// • Health Connect/HealthKit sync DELAYED (waits for app to open)
  /// • Manual sync required by opening the app
  ///
  /// WHEN IT AUTO-DISABLES:
  /// • Device is charged above 80%
  /// • User manually turns it off in Settings/Control Center
  ///
  /// USER EXPERIENCE:
  /// This is TEMPORARY by design. Users enable it to get through the day
  /// when battery is low. As soon as they charge their device, syncing
  /// resumes automatically. Our troubleshooter should inform users that
  /// this is expected behavior and will resolve when they charge.
  ///
  /// HOW TO CHECK:
  /// Settings → Battery → Low Power Mode
  /// Control Center → Battery icon (tap to toggle)
  ///
  /// NOTIFICATION SUPPORT:
  /// This feature supports REAL-TIME notifications via event channel.
  /// The app can detect when Low Power Mode is toggled and inform users
  /// immediately.
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check if Low Power Mode is enabled on iOS
  ///
  /// Returns [PowerStatus.enabled] if Low Power Mode is on
  /// Returns [PowerStatus.disabled] if Low Power Mode is off
  /// Returns [PowerStatus.notAvailable] on non-iOS platforms
  ///
  /// Low Power Mode reduces background activity and affects:
  /// - Background App Refresh (disabled)
  /// - Automatic downloads
  /// - Visual effects
  /// - Auto-lock timing
  Future<PowerStatus> checkLowPowerMode() async {
    if (!Platform.isIOS) {
      _logger.d('Low Power Mode not applicable on non-iOS platforms');
      return PowerStatus.notAvailable;
    }

    try {
      _logger.d('Checking Low Power Mode...');
      final result =
          await DiagnosticChannels.power.invokeMethod('checkLowPowerMode');

      final isEnabled = result as bool? ?? false;
      final status =
          isEnabled ? PowerStatus.enabled : PowerStatus.disabled;

      _logger.i('Low Power Mode: ${status.description}');
      return status;
    } on PlatformException catch (e) {
      _logger.e('PlatformException checking Low Power Mode: ${e.message}');
      return PowerStatus.unknown;
    } catch (e) {
      _logger.e('Error checking Low Power Mode: $e');
      return PowerStatus.unknown;
    }
  }

  /// Listen to Low Power Mode changes (iOS)
  ///
  /// Returns a stream that emits true when Low Power Mode is enabled,
  /// false when disabled.
  ///
  /// This allows real-time updates when user toggles Low Power Mode
  /// in Settings or Control Center.
  Stream<bool>? listenToLowPowerModeChanges() {
    if (!Platform.isIOS) {
      _logger.d('Low Power Mode events not applicable on non-iOS');
      return null;
    }

    try {
      _logger.d('Setting up Low Power Mode event stream...');
      return DiagnosticChannels.lowPowerModeEvents
          .receiveBroadcastStream()
          .map((event) => event as bool);
    } catch (e) {
      _logger.e('Error setting up Low Power Mode event stream: $e');
      return null;
    }
  }

  // ============================================================================
  // BACKGROUND APP REFRESH (iOS)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #8: Background App Refresh (iOS)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// An iOS system feature that allows apps to update their content in
  /// the background, so new data is ready when you open them. Users can
  /// control this per-app or system-wide to save battery and data.
  ///
  /// KEY POINTS:
  /// • Controls whether apps can run tasks when NOT actively open
  /// • Can be disabled system-wide or per individual app
  /// • User has full control via Settings
  /// • Automatically disabled when Low Power Mode is on
  /// • Different from foreground activity (always works when app is open)
  ///
  /// TECHNICAL DETAILS:
  /// iOS API: UIApplication.shared.backgroundRefreshStatus
  /// Available Since: iOS 7.0 (released September 2013)
  /// Confidence: 90% (Official Apple API)
  ///
  /// IN SIMPLE TERMS:
  /// Imagine you have a newspaper delivered to your door every morning.
  /// Background App Refresh is like having the newspaper delivery service
  /// bring it while you're asleep, so it's ready when you wake up. If you
  /// disable it, you have to go pick up the newspaper yourself when you're
  /// ready (open the app manually to sync).
  ///
  /// REAL-WORLD EXAMPLE:
  /// You're using a step tracking app. With Background App Refresh ENABLED,
  /// the app quietly syncs your steps to the cloud every few hours, even
  /// when closed. When you open the app, your data is already up-to-date.
  ///
  /// With Background App Refresh DISABLED, the app can only sync when you
  /// actively open it. Your steps are still counted (hardware sensor), but
  /// they're not uploaded until you launch the app.
  ///
  /// WHY IT MATTERS:
  ///
  /// WHEN BACKGROUND APP REFRESH IS AVAILABLE (Enabled):
  /// • App can sync steps periodically when closed
  /// • Health data uploads to cloud automatically
  /// • HealthKit updates happen in background
  /// • Users see up-to-date data across devices
  /// • No manual intervention required
  ///
  /// WHEN BACKGROUND APP REFRESH IS DENIED (Disabled by user):
  /// • App CANNOT sync when closed
  /// • Steps only sync when app is actively opened
  /// • Cloud backup is delayed until next app launch
  /// • Users must manually open app to trigger sync
  /// • Step count may be "stale" across devices
  ///
  /// WHEN BACKGROUND APP REFRESH IS RESTRICTED (System-level):
  /// • Disabled by parental controls (Screen Time)
  /// • Disabled by enterprise/MDM policy (work devices)
  /// • Cannot be changed by user (requires parent/admin password)
  /// • Affects ALL apps system-wide
  ///
  /// HOW USERS CONTROL IT:
  ///
  /// System-Wide Setting:
  /// Settings → General → Background App Refresh → Toggle On/Off
  ///
  /// Per-App Setting:
  /// Settings → General → Background App Refresh → [App Name] → Toggle On/Off
  ///
  /// AUTOMATIC DISABLING:
  /// Background App Refresh is automatically disabled when:
  /// • Low Power Mode is enabled (temporary)
  /// • Device storage is critically low
  /// • Battery is critically low (< 10%)
  ///
  /// IMPORTANT NOTES:
  /// • iOS intelligently schedules background refresh based on usage patterns
  /// • Apps used frequently get more background time
  /// • Apps rarely used get less background time (App Standby)
  /// • Background refresh only happens when device is on WiFi (by default)
  /// • Cellular background refresh can be disabled separately
  ///
  /// TROUBLESHOOTING GUIDANCE:
  /// If DENIED:
  ///   → Guide user to Settings to enable it for this app
  ///   → Explain that steps will only sync when app is open
  ///
  /// If RESTRICTED:
  ///   → Inform user it's disabled by parental controls or work policy
  ///   → User needs parent/admin password to change
  ///   → Suggest manual app opening for sync
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check Background App Refresh status on iOS
  ///
  /// Returns [BackgroundAppRefreshStatus] indicating if the app can
  /// refresh content in the background.
  ///
  /// Background App Refresh can be:
  /// - AVAILABLE: App can refresh in background
  /// - DENIED: User disabled it in Settings
  /// - RESTRICTED: Disabled by parental controls or enterprise policy
  Future<BackgroundAppRefreshStatus> checkBackgroundAppRefresh() async {
    if (!Platform.isIOS) {
      _logger.d('Background App Refresh not applicable on non-iOS');
      return BackgroundAppRefreshStatus.unknown;
    }

    try {
      _logger.d('Checking Background App Refresh...');
      final result = await DiagnosticChannels.power
          .invokeMethod('checkBackgroundAppRefresh');

      final status = BackgroundAppRefreshStatusX.fromString(result as String);
      _logger.i('Background App Refresh: ${status.description}');
      return status;
    } on PlatformException catch (e) {
      _logger
          .e('PlatformException checking Background App Refresh: ${e.message}');
      return BackgroundAppRefreshStatus.unknown;
    } catch (e) {
      _logger.e('Error checking Background App Refresh: $e');
      return BackgroundAppRefreshStatus.unknown;
    }
  }

  /// Open iOS Settings to configure Background App Refresh
  ///
  /// Opens Settings app where user can enable/disable Background App Refresh
  /// Returns true if Settings was opened successfully
  Future<bool> openBackgroundAppRefreshSettings() async {
    if (!Platform.isIOS) {
      _logger.d('Cannot open iOS settings on non-iOS platform');
      return false;
    }

    try {
      _logger.d('Opening Background App Refresh settings...');
      final result = await DiagnosticChannels.power
          .invokeMethod('openBackgroundAppRefreshSettings');
      final success = result as bool? ?? false;
      _logger.i('Settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException opening settings: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error opening settings: $e');
      return false;
    }
  }

  // ============================================================================
  // POWER SAVING MODE (Android)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #9: Power Saving Mode (Android)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// Android's system-wide battery conservation mode that reduces power
  /// consumption by limiting device performance, background activity, and
  /// visual effects. Similar to iOS Low Power Mode but with more OEM
  /// customizations.
  ///
  /// KEY POINTS:
  /// • System-wide feature affecting all apps and services
  /// • Can be enabled manually or automatically at low battery (typically 15%)
  /// • Different manufacturers have different implementations (Samsung, Xiaomi, etc.)
  /// • Some OEMs have multiple levels (Normal, Medium, Maximum power saving)
  /// • Automatically disables when device is charged (usually above 80-90%)
  ///
  /// TECHNICAL DETAILS:
  /// Android API: PowerManager.isPowerSaveMode
  /// Available Since: Android 5.0 Lollipop (API 21, released November 2014)
  /// Event Notification: ACTION_POWER_SAVE_MODE_CHANGED broadcast
  /// Confidence: 85% (Official API, but OEM variations exist)
  ///
  /// IN SIMPLE TERMS:
  /// Power Saving Mode is Android's way of making your battery last longer
  /// when it's running low. It's like dimming lights and turning off
  /// unnecessary appliances in your house to reduce electricity usage.
  /// Your phone still works, but it does less in the background.
  ///
  /// REAL-WORLD EXAMPLE:
  /// Think of it like a restaurant during a power outage. Normally, they
  /// keep all lights bright, AC running, ovens on, music playing, and
  /// multiple stations cooking (normal mode). During power saving, they
  /// switch to emergency generators - only essential lights on, AC off,
  /// limited cooking, no music, slower service. The restaurant still
  /// operates, but conserves power for essentials.
  ///
  /// WHY IT MATTERS:
  ///
  /// WHEN POWER SAVING MODE IS ENABLED:
  /// • Background sync is RESTRICTED or DISABLED
  /// • Location services use less power (lower accuracy)
  /// • Visual effects reduced (animations disabled/slower)
  /// • CPU performance limited (throttled)
  /// • Screen brightness may be reduced
  /// • Vibration may be disabled
  /// • Network connectivity reduced (WiFi scanning paused)
  /// • Background data may be restricted
  ///
  /// IMPACT ON STEP TRACKING:
  /// • Local step counting CONTINUES (hardware sensor still works)
  /// • Cloud sync DELAYED or PAUSED (background restrictions)
  /// • Health Connect sync may be delayed
  /// • Manual sync required by opening the app
  /// • Real-time syncing stops until mode is disabled
  ///
  /// OEM-SPECIFIC VARIATIONS:
  ///
  /// Samsung (One UI):
  /// • Power Saving Mode (moderate restrictions)
  /// • Maximum Power Saving Mode (aggressive restrictions, limited apps)
  /// • Settings → Battery and device care → Battery → Power saving
  ///
  /// Xiaomi (MIUI):
  /// • Battery Saver (moderate restrictions)
  /// • Ultra Battery Saver (extreme restrictions, only essential apps)
  /// • Settings → Battery & performance → Battery saver
  ///
  /// Oppo/Realme (ColorOS):
  /// • Power Saving Mode (moderate)
  /// • Super Power Saving Mode (extreme)
  /// • Settings → Battery → Power Saving Mode
  ///
  /// Google Pixel (Stock Android):
  /// • Battery Saver (standard restrictions)
  /// • Extreme Battery Saver (Android 12+, only essential apps)
  /// • Settings → Battery → Battery Saver
  ///
  /// AUTOMATIC ENABLEMENT:
  /// Most Android devices offer to enable Power Saving Mode automatically when:
  /// • Battery reaches 15% (common threshold)
  /// • Battery reaches 20% (some devices)
  /// • Battery reaches 5% (forced on some devices)
  /// • User-configurable threshold in settings
  ///
  /// AUTOMATIC DISABLEMENT:
  /// Power Saving Mode typically disables automatically when:
  /// • Device is charged above 80-90% (varies by manufacturer)
  /// • User manually disables it
  /// • Device is fully charged (100%)
  ///
  /// DETECTION CHALLENGES:
  /// • Standard API returns true/false
  /// • Cannot detect "level" of power saving (moderate vs extreme)
  /// • OEM-specific modes may not be detected by standard API
  /// • Some manufacturers use custom implementations
  ///
  /// TROUBLESHOOTING GUIDANCE:
  /// If ENABLED:
  ///   → Inform user this is TEMPORARY (auto-disables when charged)
  ///   → Explain background sync is paused to save battery
  ///   → Suggest charging device to resume normal operation
  ///   → Offer manual sync option by opening app
  ///   → Show battery percentage if available
  ///   → Reassure that local step counting still works
  ///
  /// USER EXPERIENCE:
  /// This is typically a TEMPORARY state users enable to get through
  /// the day on low battery. It's not a permanent restriction. Our
  /// troubleshooter should be empathetic and explain this is expected
  /// behavior that will resolve once the device is charged.
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check if Power Saving Mode is enabled on Android
  ///
  /// Returns [PowerStatus.enabled] if Power Saving Mode is on
  /// Returns [PowerStatus.disabled] if Power Saving Mode is off
  /// Returns [PowerStatus.notAvailable] on non-Android platforms
  ///
  /// Power Saving Mode reduces background activity and affects:
  /// - Background sync
  /// - Location services
  /// - Visual effects
  /// - Performance
  Future<PowerStatus> checkPowerSavingMode() async {
    if (!Platform.isAndroid) {
      _logger.d('Power Saving Mode not applicable on non-Android platforms');
      return PowerStatus.notAvailable;
    }

    try {
      _logger.d('Checking Power Saving Mode...');
      final result =
          await DiagnosticChannels.power.invokeMethod('checkPowerSavingMode');

      final isEnabled = result as bool? ?? false;
      final status =
          isEnabled ? PowerStatus.enabled : PowerStatus.disabled;

      _logger.i('Power Saving Mode: ${status.description}');
      return status;
    } on PlatformException catch (e) {
      _logger.e('PlatformException checking Power Saving Mode: ${e.message}');
      return PowerStatus.unknown;
    } catch (e) {
      _logger.e('Error checking Power Saving Mode: $e');
      return PowerStatus.unknown;
    }
  }

  /// Listen to Power Saving Mode changes (Android)
  ///
  /// Returns a stream that emits true when Power Saving Mode is enabled,
  /// false when disabled.
  ///
  /// This allows real-time updates when user toggles Power Saving Mode.
  Stream<bool>? listenToPowerSavingModeChanges() {
    if (!Platform.isAndroid) {
      _logger.d('Power Saving Mode events not applicable on non-Android');
      return null;
    }

    try {
      _logger.d('Setting up Power Saving Mode event stream...');
      return DiagnosticChannels.powerSaveModeEvents
          .receiveBroadcastStream()
          .map((event) => event as bool);
    } catch (e) {
      _logger.e('Error setting up Power Saving Mode event stream: $e');
      return null;
    }
  }

  // ============================================================================
  // DOZE MODE & APP STANDBY (Android 6+)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #10: Doze Mode & App Standby Buckets (Android 6+)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// Android's aggressive battery optimization system that puts devices
  /// into "deep sleep" when idle and restricts apps based on usage patterns.
  /// Two components: Doze Mode (device-level) and App Standby (app-level).
  ///
  /// KEY POINTS:
  /// • DOZE MODE: Device-level deep sleep (affects ALL apps)
  /// • APP STANDBY: Per-app restrictions based on usage frequency
  /// • Activates automatically when device is idle
  /// • Most aggressive battery optimization in Android
  /// • Can be whitelisted for critical apps (messaging, alarms)
  /// • Introduced in Android 6 (2015), enhanced in Android 9 (App Standby Buckets)
  ///
  /// TECHNICAL DETAILS:
  /// Android API: PowerManager.isDeviceIdleMode, UsageStatsManager.appStandbyBucket
  /// Available Since: Android 6.0 Marshmallow (API 23, October 2015)
  /// Enhanced: Android 9.0 Pie (API 28, August 2018) - App Standby Buckets
  /// Confidence: 75% (Complex API, OEM variations, requires special permission)
  ///
  /// IN SIMPLE TERMS:
  /// Doze Mode is like your phone "falling asleep" deeply when you're not
  /// using it. Imagine a bear hibernating for winter - it's not just resting,
  /// it's in a very deep sleep where almost all non-essential functions shut
  /// down to conserve energy. Apps can't wake it up unless they're on a VIP
  /// list (whitelisted) or the device is moved/charged.
  ///
  /// REAL-WORLD EXAMPLE:
  /// You leave your phone on a desk overnight:
  /// • After ~30 min: Phone enters "light doze" (some restrictions)
  /// • After ~1-2 hours: Phone enters "deep doze" (aggressive restrictions)
  /// • During deep doze: Apps can't access network, can't sync, can't run tasks
  /// • Periodically: Phone briefly wakes up (maintenance window) for critical tasks
  /// • When moved/screen on: Doze ends, all restrictions lifted
  ///
  /// DOZE MODE - TWO LEVELS:
  ///
  /// 1. LIGHT DOZE (Doze on the Go - Android 7+):
  ///    • Activates: Screen off + device moving (in pocket/bag)
  ///    • Restrictions: Moderate (network access limited, not blocked)
  ///    • Wake-up: Frequent maintenance windows
  ///
  /// 2. DEEP DOZE (Original Doze):
  ///    • Activates: Screen off + device stationary + unplugged + idle (30+ min)
  ///    • Restrictions: Aggressive (network access blocked, most tasks deferred)
  ///    • Wake-up: Infrequent maintenance windows (every 1-2 hours)
  ///
  /// WHEN DOZE MODE ACTIVATES:
  /// Required conditions (ALL must be true):
  /// • Screen is OFF
  /// • Device is NOT charging
  /// • Device is stationary (or moving for Light Doze)
  /// • Device has been idle for threshold time
  ///
  /// RESTRICTIONS DURING DOZE MODE:
  /// • Network access is SUSPENDED (no WiFi/cellular data)
  /// • Wake locks are IGNORED (apps can't keep CPU awake)
  /// • Alarms are DEFERRED (except setExactAndAllowWhileIdle)
  /// • WiFi scans are DISABLED
  /// • Sync adapters don't run
  /// • JobScheduler jobs are DEFERRED
  /// • GPS/location updates stop (except foreground apps)
  ///
  /// MAINTENANCE WINDOWS:
  /// Doze Mode briefly wakes up periodically to allow pending work:
  /// • First window: After ~1 hour of Doze
  /// • Subsequent windows: Every 2 hours (progressively longer intervals)
  /// • Duration: Short burst (a few minutes)
  /// • Purpose: Allow apps to sync, run deferred tasks
  ///
  /// APP STANDBY BUCKETS (Android 9+):
  /// Android classifies apps into "buckets" based on usage patterns:
  ///
  /// 1. ACTIVE (Best):
  ///    • App is currently open OR recently used (within minutes)
  ///    • NO restrictions
  ///    • Full background access
  ///
  /// 2. WORKING_SET (Good):
  ///    • App is used regularly (daily)
  ///    • Minimal restrictions
  ///    • Jobs can run once per 2 hours
  ///
  /// 3. FREQUENT (Medium):
  ///    • App is used frequently (every few days)
  ///    • Moderate restrictions
  ///    • Jobs can run once per 8 hours
  ///
  /// 4. RARE (Bad):
  ///    • App is rarely used (once a week or less)
  ///    • Heavy restrictions
  ///    • Jobs can run once per 24 hours
  ///    • May not run at all if device is low on battery
  ///
  /// 5. RESTRICTED (Worst):
  ///    • App is never used OR user manually restricted it
  ///    • Maximum restrictions
  ///    • Jobs almost never run
  ///    • Network access severely limited
  ///
  /// WHY IT MATTERS:
  ///
  /// IMPACT ON STEP TRACKING:
  ///
  /// WHEN DEVICE IN DOZE MODE:
  /// • Local step counting CONTINUES (hardware sensor, no restrictions)
  /// • Cloud sync BLOCKED (no network access)
  /// • Health Connect sync DEFERRED (waits for maintenance window or wake-up)
  /// • Background tasks paused until device wakes up
  /// • Sync resumes when: screen turns on, device moves, or charging starts
  ///
  /// WHEN APP IN RARE/RESTRICTED BUCKET:
  /// • Background sync happens INFREQUENTLY (once per 8-24 hours)
  /// • Cloud upload delayed significantly
  /// • Health data may be "stale" until user opens app
  /// • Manual app opening triggers immediate sync
  ///
  /// WHITELIST (Battery Optimization Exemption):
  /// Apps can request to be whitelisted (exempt from Doze restrictions):
  /// • Allows network access during Doze Mode
  /// • Allows wake locks to work
  /// • Should ONLY be used for critical apps (messaging, alarms)
  /// • Requires user approval via Settings
  /// • Google discourages unnecessary whitelisting
  ///
  /// DETECTION CHALLENGES:
  /// • isDeviceIdleMode returns current state (may be false when checked)
  /// • App Standby Bucket requires PACKAGE_USAGE_STATS permission
  /// • Permission must be granted in Settings (not runtime dialog)
  /// • Cannot programmatically detect if app is whitelisted on all Android versions
  /// • OEM implementations may vary
  ///
  /// TROUBLESHOOTING GUIDANCE:
  ///
  /// If Device in Doze Mode:
  ///   → Explain this is TEMPORARY (happens when device idle)
  ///   → Reassure that sync will resume when device wakes
  ///   → Suggest: moving device, turning on screen, or charging
  ///   → Note that local step counting is unaffected
  ///
  /// If App in RARE/RESTRICTED bucket:
  ///   → Explain app is rarely used (Android's perspective)
  ///   → Suggest opening app more frequently to improve bucket
  ///   → Offer: disable battery optimization (whitelist) for real-time sync
  ///   → Explain trade-off: better sync vs slightly higher battery usage
  ///
  /// If App NOT Whitelisted:
  ///   → Only suggest whitelisting if user needs real-time sync
  ///   → Explain that most users don't need this
  ///   → Guide to Settings → Battery → Battery optimization → [App] → Don't optimize
  ///
  /// IMPORTANT NOTES:
  /// • Doze Mode is GOOD for battery life (most users want it)
  /// • Don't encourage disabling it unless absolutely necessary
  /// • For step tracking apps, daily sync is usually sufficient
  /// • Whitelisting should be last resort, not default recommendation
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check Doze Mode and App Standby status (Android 6+)
  ///
  /// Returns [DozeModeStatus] with:
  /// - isDeviceInDozeMode: true if device is in deep sleep
  /// - appStandbyBucket: how frequently the app is used
  /// - isAppWhitelisted: true if app is exempt from Doze restrictions
  ///
  /// Doze Mode activates when:
  /// - Device is stationary
  /// - Screen is off
  /// - Device is not charging
  /// - Device has been idle for a while
  ///
  /// During Doze Mode:
  /// - Network access is suspended
  /// - Wake locks are ignored
  /// - Alarms are deferred
  /// - WiFi scans are disabled
  /// - Sync adapters don't run
  /// - JobScheduler jobs are deferred
  Future<DozeModeStatus> checkDozeModeStatus() async {
    if (!Platform.isAndroid) {
      _logger.d('Doze Mode not applicable on non-Android platforms');
      return DozeModeStatus(
        isDeviceInDozeMode: false,
        appStandbyBucket: AppStandbyBucket.unknown,
      );
    }

    try {
      _logger.d('Checking Doze Mode status...');
      final result =
          await DiagnosticChannels.power.invokeMethod('checkDozeModeStatus');

      if (result == null) {
        _logger.w('Doze Mode check returned null');
        return DozeModeStatus(
          isDeviceInDozeMode: false,
          appStandbyBucket: AppStandbyBucket.unknown,
        );
      }

      final status = DozeModeStatus.fromMap(result as Map<dynamic, dynamic>);
      _logger.i(
          'Doze Mode: device=${status.isDeviceInDozeMode}, bucket=${status.appStandbyBucket.description}, whitelisted=${status.isAppWhitelisted}');
      return status;
    } on PlatformException catch (e) {
      _logger.e('PlatformException checking Doze Mode: ${e.message}');
      if (e.code == 'NOT_AVAILABLE') {
        return DozeModeStatus(
          isDeviceInDozeMode: false,
          appStandbyBucket: AppStandbyBucket.unknown,
        );
      }
      return DozeModeStatus(
        isDeviceInDozeMode: false,
        appStandbyBucket: AppStandbyBucket.unknown,
      );
    } catch (e) {
      _logger.e('Error checking Doze Mode: $e');
      return DozeModeStatus(
        isDeviceInDozeMode: false,
        appStandbyBucket: AppStandbyBucket.unknown,
      );
    }
  }

  /// Request Doze Mode whitelist (Android 6+)
  ///
  /// Opens settings where user can whitelist the app from Doze restrictions.
  /// This allows the app to maintain network access during Doze Mode.
  ///
  /// Returns true if settings was opened successfully.
  ///
  /// Note: Use this sparingly! Whitelisting should only be requested for
  /// apps that need real-time functionality (messaging, alarms, etc.)
  Future<bool> requestDozeModeWhitelist() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot request Doze whitelist on non-Android platform');
      return false;
    }

    try {
      _logger.d('Requesting Doze Mode whitelist...');
      final result = await DiagnosticChannels.power
          .invokeMethod('requestDozeModeWhitelist');
      final success = result as bool? ?? false;
      _logger.i('Doze whitelist settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException requesting Doze whitelist: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error requesting Doze whitelist: $e');
      return false;
    }
  }

  // ============================================================================
  // COMBINED CHECKS
  // ============================================================================

  /// Check all power management features
  ///
  /// Returns a map with all power-related statuses
  Future<Map<String, dynamic>> checkAllPowerFeatures() async {
    _logger.d('Checking all power management features...');

    final results = <String, dynamic>{};

    if (Platform.isIOS) {
      final lowPowerMode = await checkLowPowerMode();
      final backgroundRefresh = await checkBackgroundAppRefresh();

      results['lowPowerMode'] = {
        'status': lowPowerMode.description,
        'isEnabled': lowPowerMode.isEnabled,
        'isDisabled': lowPowerMode.isDisabled,
      };

      results['backgroundAppRefresh'] = {
        'status': backgroundRefresh.description,
        'isAvailable': backgroundRefresh.isAvailable,
        'isBlocked': backgroundRefresh.isBlocked,
      };
    }

    if (Platform.isAndroid) {
      final powerSaving = await checkPowerSavingMode();
      final dozeMode = await checkDozeModeStatus();

      results['powerSavingMode'] = {
        'status': powerSaving.description,
        'isEnabled': powerSaving.isEnabled,
        'isDisabled': powerSaving.isDisabled,
      };

      results['dozeMode'] = {
        'isDeviceInDozeMode': dozeMode.isDeviceInDozeMode,
        'appStandbyBucket': dozeMode.appStandbyBucket.description,
        'isAppWhitelisted': dozeMode.isAppWhitelisted,
        'hasSignificantImpact': dozeMode.hasSignificantImpact,
        'hasModerateImpact': dozeMode.hasModerateImpact,
      };
    }

    _logger.i('Power features check complete: ${results.length} features');
    return results;
  }
}
