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

  // ============================================================================
  // BATTERY OPTIMIZATION (Android 6+)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #5: Battery Optimization (Android 6+)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// Android's per-app battery management system that restricts background
  /// activity for apps the system determines are not critical. When enabled
  /// for your app, it blocks background processes to extend battery life.
  ///
  /// KEY POINTS:
  /// • PER-APP setting (user can exempt specific apps)
  /// • Enabled by DEFAULT for all non-system apps
  /// • Blocks background sync, network access, wake locks when app is closed
  /// • User must MANUALLY disable it for your app (requires exemption request)
  /// • Different from Power Saving Mode (device-wide) and Doze Mode (automatic)
  /// • Available since Android 6.0 Marshmallow (API 23, October 2015)
  ///
  /// TECHNICAL DETAILS:
  /// Android API: PowerManager.isIgnoringBatteryOptimizations(packageName)
  /// Available Since: Android 6.0 Marshmallow (API 23, October 2015)
  /// Settings Action: ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
  /// Confidence: 100% (Official API, already working in v6)
  ///
  /// IN SIMPLE TERMS:
  /// Battery Optimization is like Android's "naughty list" for apps it thinks
  /// use too much battery. Apps on this list can't do work in the background
  /// (when closed) to save power. To get off the list, you need to ask Android
  /// for an exemption, and the user must approve it in Settings.
  ///
  /// REAL-WORLD EXAMPLE:
  /// Think of it like a nightclub with a strict bouncer:
  /// • Normal apps: Wait outside, can't get in when doors are closed (optimized)
  /// • Exempted apps: Have VIP passes, can enter anytime (not optimized)
  /// • The bouncer (Android) lets most apps wait outside to save energy
  /// • User decides which apps get VIP passes
  ///
  /// WHY IT MATTERS:
  ///
  /// WHEN BATTERY OPTIMIZATION IS ENABLED (Default):
  /// • Background step sync BLOCKED when app is closed
  /// • Health Connect updates DELAYED until app is opened
  /// • Cloud backup PAUSED (no network access in background)
  /// • Push notifications may be delayed
  /// • Alarms may be deferred
  /// • JobScheduler tasks postponed
  /// • Location updates stopped (background)
  /// • Sensors (step counter) may be throttled
  ///
  /// WHEN BATTERY OPTIMIZATION IS DISABLED (Exempted):
  /// • Full background sync capability
  /// • Health Connect updates work normally
  /// • Cloud backup continues in background
  /// • Real-time step tracking possible
  /// • Alarms fire on time
  /// • Network access allowed in background
  /// • Wake locks work properly
  ///
  /// HOW IT WORKS:
  ///
  /// DEFAULT BEHAVIOR:
  /// • When you install ANY app, Battery Optimization is ENABLED by default
  /// • Android assumes the app is not critical
  /// • App must explicitly request exemption
  ///
  /// REQUESTING EXEMPTION:
  /// 1. App calls requestBatteryOptimizationExemption()
  /// 2. Android opens Settings screen
  /// 3. User sees: "Allow [App Name] to run in background?"
  /// 4. User taps: "Allow" or "Deny"
  /// 5. If allowed: Battery Optimization DISABLED for app
  ///
  /// USER CONTROL:
  /// Users can manually change this in Settings:
  /// • Settings → Battery → Battery optimization
  /// • Select app from "All apps" dropdown
  /// • Choose: "Optimize" or "Don't optimize"
  ///
  /// WHEN TO REQUEST EXEMPTION:
  ///
  /// GOOD REASONS (Google-approved):
  /// • Real-time messaging apps (WhatsApp, Telegram)
  /// • Alarm clock apps (timely alarms critical)
  /// • Health/fitness tracking (continuous monitoring)
  /// • Navigation apps (real-time location)
  /// • VoIP calling apps (receive calls)
  ///
  /// BAD REASONS (Google may reject):
  /// • General productivity apps
  /// • Games (no real-time requirement)
  /// • News/social media apps
  /// • Shopping apps
  /// • Any app that doesn't need real-time background work
  ///
  /// GOOGLE PLAY POLICY:
  /// Google has STRICT rules about requesting battery optimization exemption:
  /// • App must have legitimate use case for background work
  /// • Must NOT request exemption unnecessarily
  /// • Apps violating policy may be removed from Play Store
  /// • Document your use case in policy declaration
  ///
  /// OEM VARIATIONS:
  ///
  /// Samsung (One UI):
  /// • Settings → Apps → [App] → Battery → Optimize battery usage
  /// • Additional "Sleeping apps" feature (separate check)
  ///
  /// Xiaomi (MIUI):
  /// • Settings → Apps → Manage apps → [App] → Battery saver
  /// • Also requires Autostart permission (separate check)
  ///
  /// Oppo/Realme (ColorOS):
  /// • Settings → Battery → Battery optimization
  /// • Also requires Startup Manager exemption (separate check)
  ///
  /// OnePlus (OxygenOS):
  /// • Settings → Battery → Battery optimization
  /// • "Advanced Optimization" may override (check separately)
  ///
  /// DETECTION STATUS:
  ///
  /// ENABLED:
  /// • Battery Optimization is active for your app
  /// • Background work is restricted
  /// • User should disable it for full functionality
  ///
  /// DISABLED:
  /// • App is exempted from Battery Optimization
  /// • Background work allowed
  /// • No action needed
  ///
  /// UNKNOWN:
  /// • Detection failed (error in method channel)
  /// • Cannot determine status
  /// • Assume ENABLED (safer assumption)
  ///
  /// NOT_APPLICABLE:
  /// • Android version < 6.0 (no Battery Optimization feature)
  /// • iOS (uses Low Power Mode instead)
  ///
  /// TROUBLESHOOTING GUIDANCE:
  ///
  /// If ENABLED:
  ///   → Explain: "Battery Optimization is blocking background step sync"
  ///   → Impact: "Steps only sync when you open the app"
  ///   → Solution: "Disable Battery Optimization for this app"
  ///   → Action: Show "Disable Optimization" button
  ///   → Opens Settings → User taps "Don't optimize"
  ///   → Verify: Re-check status after user returns
  ///
  /// If DISABLED:
  ///   → Inform: "Battery Optimization is already disabled"
  ///   → Status: "Background step sync is working properly"
  ///   → No action needed
  ///
  /// If UNKNOWN:
  ///   → Inform: "Cannot detect Battery Optimization status"
  ///   → Suggest: Opening Settings manually
  ///   → Provide: Manual instructions for popular OEMs
  ///
  /// IMPACT ON STEP TRACKING:
  ///
  /// WITH OPTIMIZATION ENABLED:
  /// • Local step counting WORKS (hardware sensor not affected)
  /// • Cloud sync BLOCKED (no network in background)
  /// • Health Connect sync DELAYED (waits for app open)
  /// • Real-time updates STOPPED (background refresh blocked)
  /// • User must open app to trigger sync
  ///
  /// WITH OPTIMIZATION DISABLED:
  /// • Local step counting WORKS
  /// • Cloud sync WORKS (background network allowed)
  /// • Health Connect sync WORKS (continuous updates)
  /// • Real-time updates WORK (background refresh enabled)
  /// • No manual intervention needed
  ///
  /// TESTING STRATEGY:
  /// Test on multiple devices to verify:
  /// • Stock Android (Google Pixel)
  /// • Samsung (One UI)
  /// • Xiaomi (MIUI)
  /// • Oppo/Realme (ColorOS)
  /// • OnePlus (OxygenOS)
  ///
  /// Each OEM may have slightly different Settings paths.
  ///
  /// IMPORTANT NOTES:
  /// • Battery Optimization is GOOD for most users (saves battery)
  /// • Only request exemption if NECESSARY for app functionality
  /// • Clearly explain WHY exemption is needed
  /// • Respect user's decision if they deny exemption
  /// • Offer degraded functionality (manual sync) as fallback
  /// • This is the MOST COMMON cause of step sync issues
  ///
  /// CURRENTLY IMPLEMENTED:
  /// ✅ Detection via PowerManager.isIgnoringBatteryOptimizations()
  /// ✅ Exemption request via ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
  /// ✅ Device info retrieval (manufacturer, model, Android version)
  /// ✅ Works on Android 6.0+ (API 23+)
  /// ✅ Manufacturer-specific guidance (Samsung, Xiaomi, Oppo)
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

  /// Get device information (manufacturer, model, Android version)
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final dynamic result = await _channel.invokeMethod('getDeviceInfo');
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      _logger.e('Error getting device info: $e');
      return null;
    }
  }
}
