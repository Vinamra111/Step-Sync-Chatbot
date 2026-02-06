import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utility class for platform-specific operations and detection.
class PlatformUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Check if running on Android.
  static bool get isAndroid => Platform.isAndroid;

  /// Check if running on iOS.
  static bool get isIOS => Platform.isIOS;

  /// Get Android API level (version).
  ///
  /// Returns null if not on Android.
  static Future<int?> getAndroidApiLevel() async {
    if (!isAndroid) return null;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      return null;
    }
  }

  /// Check if device requires separate Health Connect app.
  ///
  /// - Android 14+ (API 34+): Built-in
  /// - Android 9-13 (API 28-33): Requires separate app
  /// - Android 8 and below: Not supported
  static Future<HealthConnectRequirement> getHealthConnectRequirement() async {
    final apiLevel = await getAndroidApiLevel();

    if (apiLevel == null) {
      return HealthConnectRequirement.notApplicable;
    }

    if (apiLevel >= 34) {
      return HealthConnectRequirement.builtIn;
    } else if (apiLevel >= 28) {
      return HealthConnectRequirement.separateApp;
    } else {
      return HealthConnectRequirement.notSupported;
    }
  }

  /// Get device manufacturer and model.
  static Future<String> getDeviceInfo() async {
    try {
      if (isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Get Android version string (e.g., "13", "14").
  static Future<String?> getAndroidVersionString() async {
    if (!isAndroid) return null;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.release;
    } catch (e) {
      return null;
    }
  }

  /// Open Google Play Store to Health Connect app.
  static Future<bool> openHealthConnectPlayStore() async {
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';

    try {
      final uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Open battery optimization settings for the app.
  ///
  /// This is Android-specific. On other platforms, returns false.
  static Future<bool> openBatteryOptimizationSettings() async {
    if (!isAndroid) return false;

    try {
      // Try to open battery optimization settings
      // Note: This requires platform-specific implementation via method channel
      // For now, we open general battery settings
      const settingsUrl = 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS';
      final uri = Uri.parse('intent://$settingsUrl#Intent;end');

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings.
  static Future<bool> openAppSettings() async {
    try {
      if (isAndroid) {
        const settingsUrl = 'android.settings.APPLICATION_DETAILS_SETTINGS';
        final uri = Uri.parse('intent://$settingsUrl#Intent;end');

        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (isIOS) {
        final uri = Uri.parse('app-settings:');

        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri);
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Health Connect requirement based on Android version.
enum HealthConnectRequirement {
  /// Health Connect is built into the OS (Android 14+).
  builtIn,

  /// Requires separate Health Connect app from Play Store (Android 9-13).
  separateApp,

  /// Health Connect is not supported (Android 8 and below).
  notSupported,

  /// Not applicable (not on Android).
  notApplicable,
}

extension HealthConnectRequirementExtension on HealthConnectRequirement {
  String get description {
    switch (this) {
      case HealthConnectRequirement.builtIn:
        return 'Health Connect is built into your Android version';
      case HealthConnectRequirement.separateApp:
        return 'Health Connect requires a separate app from Google Play Store';
      case HealthConnectRequirement.notSupported:
        return 'Your Android version does not support Health Connect';
      case HealthConnectRequirement.notApplicable:
        return 'Health Connect is only available on Android';
    }
  }

  bool get requiresInstallation {
    return this == HealthConnectRequirement.separateApp;
  }

  bool get isSupported {
    return this == HealthConnectRequirement.builtIn ||
        this == HealthConnectRequirement.separateApp;
  }
}
