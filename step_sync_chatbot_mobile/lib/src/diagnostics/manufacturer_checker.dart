import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'diagnostic_channels.dart';

/// Device manufacturer types
enum Manufacturer {
  /// Xiaomi, Redmi, Poco devices (MIUI)
  xiaomi,

  /// Samsung devices (One UI)
  samsung,

  /// Oppo devices (ColorOS)
  oppo,

  /// Realme devices (Realme UI, based on ColorOS)
  realme,

  /// OnePlus devices (OxygenOS)
  onePlus,

  /// Vivo devices (Funtouch OS)
  vivo,

  /// Huawei devices (EMUI)
  huawei,

  /// Google Pixel devices (Stock Android)
  google,

  /// Other manufacturers
  other,

  /// Unknown manufacturer
  unknown,
}

/// Extension methods for [Manufacturer]
extension ManufacturerX on Manufacturer {
  /// Convert string from native code to [Manufacturer]
  static Manufacturer fromString(String manufacturer) {
    final lower = manufacturer.toLowerCase();

    if (lower.contains('xiaomi') || lower.contains('redmi') || lower.contains('poco')) {
      return Manufacturer.xiaomi;
    } else if (lower.contains('samsung')) {
      return Manufacturer.samsung;
    } else if (lower.contains('oppo')) {
      return Manufacturer.oppo;
    } else if (lower.contains('realme')) {
      return Manufacturer.realme;
    } else if (lower.contains('oneplus')) {
      return Manufacturer.onePlus;
    } else if (lower.contains('vivo')) {
      return Manufacturer.vivo;
    } else if (lower.contains('huawei') || lower.contains('honor')) {
      return Manufacturer.huawei;
    } else if (lower.contains('google')) {
      return Manufacturer.google;
    } else if (manufacturer.isEmpty) {
      return Manufacturer.unknown;
    } else {
      return Manufacturer.other;
    }
  }

  /// Get user-friendly manufacturer name
  String get displayName {
    switch (this) {
      case Manufacturer.xiaomi:
        return 'Xiaomi/Redmi/Poco';
      case Manufacturer.samsung:
        return 'Samsung';
      case Manufacturer.oppo:
        return 'Oppo';
      case Manufacturer.realme:
        return 'Realme';
      case Manufacturer.onePlus:
        return 'OnePlus';
      case Manufacturer.vivo:
        return 'Vivo';
      case Manufacturer.huawei:
        return 'Huawei';
      case Manufacturer.google:
        return 'Google Pixel';
      case Manufacturer.other:
        return 'Other';
      case Manufacturer.unknown:
        return 'Unknown';
    }
  }

  /// Check if manufacturer has aggressive battery optimization
  bool get hasAggressiveOptimization {
    switch (this) {
      case Manufacturer.xiaomi:
      case Manufacturer.samsung:
      case Manufacturer.oppo:
      case Manufacturer.realme:
      case Manufacturer.vivo:
      case Manufacturer.huawei:
        return true;
      case Manufacturer.onePlus:
      case Manufacturer.google:
      case Manufacturer.other:
      case Manufacturer.unknown:
        return false;
    }
  }

  /// Check if manufacturer requires autostart permission
  bool get requiresAutostartPermission {
    switch (this) {
      case Manufacturer.xiaomi:
      case Manufacturer.oppo:
      case Manufacturer.realme:
      case Manufacturer.vivo:
      case Manufacturer.huawei:
        return true;
      case Manufacturer.samsung:
      case Manufacturer.onePlus:
      case Manufacturer.google:
      case Manufacturer.other:
      case Manufacturer.unknown:
        return false;
    }
  }
}

/// Autostart permission status
enum AutostartStatus {
  /// Autostart is likely enabled (cannot detect programmatically)
  likelyEnabled,

  /// Autostart is likely disabled (cannot detect programmatically)
  likelyDisabled,

  /// Manufacturer requires autostart permission
  required,

  /// Manufacturer doesn't have autostart feature
  notApplicable,

  /// Cannot determine status
  unknown,
}

/// Extension methods for [AutostartStatus]
extension AutostartStatusX on AutostartStatus {
  /// Get user-friendly description
  String get description {
    switch (this) {
      case AutostartStatus.likelyEnabled:
        return 'Likely Enabled';
      case AutostartStatus.likelyDisabled:
        return 'Likely Disabled';
      case AutostartStatus.required:
        return 'Required';
      case AutostartStatus.notApplicable:
        return 'Not Applicable';
      case AutostartStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Device information
class DeviceInfo {
  final Manufacturer manufacturer;
  final String manufacturerName;
  final String model;
  final String androidVersion;
  final int sdkInt;

  const DeviceInfo({
    required this.manufacturer,
    required this.manufacturerName,
    required this.model,
    required this.androidVersion,
    required this.sdkInt,
  });

  factory DeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    final manufacturerName = map['manufacturer'] as String? ?? '';
    return DeviceInfo(
      manufacturer: ManufacturerX.fromString(manufacturerName),
      manufacturerName: manufacturerName,
      model: map['model'] as String? ?? '',
      androidVersion: map['androidVersion'] as String? ?? '',
      sdkInt: map['sdkInt'] as int? ?? 0,
    );
  }

  /// Get display string for device
  String get displayString => '$manufacturerName $model (Android $androidVersion)';
}

/// Checker for manufacturer-specific features
/// Handles autostart permissions, sleeping apps, and OEM-specific battery optimizations
class ManufacturerChecker {
  final Logger _logger;

  ManufacturerChecker({Logger? logger}) : _logger = logger ?? Logger();

  // ============================================================================
  // DEVICE DETECTION
  // ============================================================================

  /// Get device information (manufacturer, model, Android version)
  Future<DeviceInfo> getDeviceInfo() async {
    if (!Platform.isAndroid) {
      _logger.d('Device info not applicable on non-Android platforms');
      return const DeviceInfo(
        manufacturer: Manufacturer.unknown,
        manufacturerName: '',
        model: '',
        androidVersion: '',
        sdkInt: 0,
      );
    }

    try {
      _logger.d('Getting device info...');
      final result = await DiagnosticChannels.manufacturer
          .invokeMethod('getDeviceInfo');

      if (result == null) {
        _logger.w('Device info returned null');
        return const DeviceInfo(
          manufacturer: Manufacturer.unknown,
          manufacturerName: '',
          model: '',
          androidVersion: '',
          sdkInt: 0,
        );
      }

      final deviceInfo = DeviceInfo.fromMap(result as Map<dynamic, dynamic>);
      _logger.i('Device: ${deviceInfo.displayString}');
      return deviceInfo;
    } on PlatformException catch (e) {
      _logger.e('PlatformException getting device info: ${e.message}');
      return const DeviceInfo(
        manufacturer: Manufacturer.unknown,
        manufacturerName: '',
        model: '',
        androidVersion: '',
        sdkInt: 0,
      );
    } catch (e) {
      _logger.e('Error getting device info: $e');
      return const DeviceInfo(
        manufacturer: Manufacturer.unknown,
        manufacturerName: '',
        model: '',
        androidVersion: '',
        sdkInt: 0,
      );
    }
  }

  // ============================================================================
  // XIAOMI/MIUI AUTOSTART
  // ============================================================================

  /// Check if device is Xiaomi/MIUI and requires autostart permission
  Future<bool> isXiaomiDevice() async {
    final deviceInfo = await getDeviceInfo();
    return deviceInfo.manufacturer == Manufacturer.xiaomi;
  }

  /// Open Xiaomi autostart settings
  ///
  /// Opens MIUI's autostart management screen where user can enable
  /// autostart for this app. Falls back to app settings if intent fails.
  ///
  /// Returns true if settings was opened successfully.
  Future<bool> openXiaomiAutostartSettings() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot open Xiaomi settings on non-Android platform');
      return false;
    }

    try {
      _logger.d('Opening Xiaomi autostart settings...');
      final result = await DiagnosticChannels.manufacturer
          .invokeMethod('openXiaomiAutostartSettings');
      final success = result as bool? ?? false;
      _logger.i('Xiaomi autostart settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException opening Xiaomi settings: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error opening Xiaomi autostart settings: $e');
      return false;
    }
  }

  // ============================================================================
  // SAMSUNG SLEEPING APPS
  // ============================================================================

  /// Check if device is Samsung
  Future<bool> isSamsungDevice() async {
    final deviceInfo = await getDeviceInfo();
    return deviceInfo.manufacturer == Manufacturer.samsung;
  }

  /// Open Samsung battery settings
  ///
  /// Opens Samsung's battery optimization settings where user can:
  /// - Add app to "Never sleeping apps"
  /// - Remove app from "Sleeping apps" or "Deep sleeping apps"
  ///
  /// Returns true if settings was opened successfully.
  Future<bool> openSamsungBatterySettings() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot open Samsung settings on non-Android platform');
      return false;
    }

    try {
      _logger.d('Opening Samsung battery settings...');
      final result = await DiagnosticChannels.manufacturer
          .invokeMethod('openSamsungBatterySettings');
      final success = result as bool? ?? false;
      _logger.i('Samsung battery settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException opening Samsung settings: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error opening Samsung battery settings: $e');
      return false;
    }
  }

  // ============================================================================
  // OPPO/REALME AUTOSTART
  // ============================================================================

  /// Check if device is Oppo or Realme
  Future<bool> isOppoOrRealmeDevice() async {
    final deviceInfo = await getDeviceInfo();
    return deviceInfo.manufacturer == Manufacturer.oppo ||
        deviceInfo.manufacturer == Manufacturer.realme;
  }

  /// Open Oppo/Realme startup manager
  ///
  /// Opens ColorOS/Realme UI's startup manager where user can enable
  /// autostart for this app.
  ///
  /// Returns true if settings was opened successfully.
  Future<bool> openOppoAutostartSettings() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot open Oppo settings on non-Android platform');
      return false;
    }

    try {
      _logger.d('Opening Oppo/Realme autostart settings...');
      final result = await DiagnosticChannels.manufacturer
          .invokeMethod('openOppoAutostartSettings');
      final success = result as bool? ?? false;
      _logger.i('Oppo/Realme autostart settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException opening Oppo settings: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error opening Oppo autostart settings: $e');
      return false;
    }
  }

  // ============================================================================
  // VIVO AUTOSTART
  // ============================================================================

  /// Check if device is Vivo
  Future<bool> isVivoDevice() async {
    final deviceInfo = await getDeviceInfo();
    return deviceInfo.manufacturer == Manufacturer.vivo;
  }

  /// Open Vivo autostart settings
  ///
  /// Opens Funtouch OS's autostart management screen.
  ///
  /// Returns true if settings was opened successfully.
  Future<bool> openVivoAutostartSettings() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot open Vivo settings on non-Android platform');
      return false;
    }

    try {
      _logger.d('Opening Vivo autostart settings...');
      final result = await DiagnosticChannels.manufacturer
          .invokeMethod('openVivoAutostartSettings');
      final success = result as bool? ?? false;
      _logger.i('Vivo autostart settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException opening Vivo settings: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error opening Vivo autostart settings: $e');
      return false;
    }
  }

  // ============================================================================
  // HUAWEI AUTOSTART
  // ============================================================================

  /// Check if device is Huawei
  Future<bool> isHuaweiDevice() async {
    final deviceInfo = await getDeviceInfo();
    return deviceInfo.manufacturer == Manufacturer.huawei;
  }

  /// Open Huawei autostart settings
  ///
  /// Opens EMUI's startup manager.
  ///
  /// Returns true if settings was opened successfully.
  Future<bool> openHuaweiAutostartSettings() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot open Huawei settings on non-Android platform');
      return false;
    }

    try {
      _logger.d('Opening Huawei autostart settings...');
      final result = await DiagnosticChannels.manufacturer
          .invokeMethod('openHuaweiAutostartSettings');
      final success = result as bool? ?? false;
      _logger.i('Huawei autostart settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException opening Huawei settings: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error opening Huawei autostart settings: $e');
      return false;
    }
  }

  // ============================================================================
  // GENERIC APP SETTINGS FALLBACK
  // ============================================================================

  /// Open app settings page (fallback for unsupported manufacturers)
  Future<bool> openAppSettings() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot open app settings on non-Android platform');
      return false;
    }

    try {
      _logger.d('Opening app settings...');
      final result = await DiagnosticChannels.manufacturer
          .invokeMethod('openAppSettings');
      final success = result as bool? ?? false;
      _logger.i('App settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException opening app settings: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error opening app settings: $e');
      return false;
    }
  }

  // ============================================================================
  // COMBINED CHECKS
  // ============================================================================

  /// Check all manufacturer-specific features
  ///
  /// Returns a map with manufacturer info and applicable features
  Future<Map<String, dynamic>> checkAllManufacturerFeatures() async {
    _logger.d('Checking all manufacturer features...');

    final deviceInfo = await getDeviceInfo();

    final results = <String, dynamic>{
      'manufacturer': deviceInfo.manufacturer.displayName,
      'model': deviceInfo.model,
      'androidVersion': deviceInfo.androidVersion,
      'sdkInt': deviceInfo.sdkInt,
      'hasAggressiveOptimization': deviceInfo.manufacturer.hasAggressiveOptimization,
      'requiresAutostartPermission': deviceInfo.manufacturer.requiresAutostartPermission,
    };

    // Add manufacturer-specific flags
    results['isXiaomi'] = deviceInfo.manufacturer == Manufacturer.xiaomi;
    results['isSamsung'] = deviceInfo.manufacturer == Manufacturer.samsung;
    results['isOppo'] = deviceInfo.manufacturer == Manufacturer.oppo;
    results['isRealme'] = deviceInfo.manufacturer == Manufacturer.realme;
    results['isVivo'] = deviceInfo.manufacturer == Manufacturer.vivo;
    results['isHuawei'] = deviceInfo.manufacturer == Manufacturer.huawei;

    _logger.i('Manufacturer features check complete');
    return results;
  }

  /// Get troubleshooting guidance for current manufacturer
  Future<String> getManufacturerGuidance() async {
    final deviceInfo = await getDeviceInfo();

    switch (deviceInfo.manufacturer) {
      case Manufacturer.xiaomi:
        return '''
**Xiaomi/MIUI Detected**

Xiaomi restricts apps from starting automatically by default.

**Required Steps:**
1. Tap "Open Autostart Settings" below
2. Find "Step Sync Assistant" in the list
3. Enable the toggle
4. Also check "Battery saver" settings

Without this, step tracking stops when you close the app.
''';

      case Manufacturer.samsung:
        return '''
**Samsung Device Detected**

Samsung may put your app to sleep to save battery.

**Check These Settings:**

**Battery Settings:**
1. Settings → Battery and device care
2. Battery → Background usage limits
3. Add this app to "Never sleeping apps"

**App Settings:**
Settings → Apps → Step Sync → Battery → Unrestricted
''';

      case Manufacturer.oppo:
      case Manufacturer.realme:
        return '''
**${deviceInfo.manufacturer.displayName} Detected**

ColorOS restricts background app activity by default.

**Required Steps:**
1. Tap "Open Startup Manager" below
2. Find "Step Sync Assistant"
3. Enable the toggle
4. Also disable "Battery optimization"

Without this, step sync stops in background.
''';

      case Manufacturer.vivo:
        return '''
**Vivo Device Detected**

Funtouch OS restricts background apps aggressively.

**Required Steps:**
1. Settings → Battery → Background energy consumption management
2. Find and enable "Step Sync Assistant"
3. Settings → More settings → Applications → Autostart
4. Enable "Step Sync Assistant"
''';

      case Manufacturer.huawei:
        return '''
**Huawei Device Detected**

EMUI requires manual autostart permission.

**Required Steps:**
1. Settings → Apps → Apps
2. Find "Step Sync Assistant"
3. Battery → App launch → Manage manually
4. Enable all toggles (Auto-launch, Secondary launch, Run in background)
''';

      case Manufacturer.google:
        return '''
**Google Pixel Detected**

Stock Android has standard battery optimization.
No manufacturer-specific restrictions detected.

Just ensure Battery Optimization is disabled for this app.
''';

      case Manufacturer.onePlus:
        return '''
**OnePlus Device Detected**

OxygenOS has moderate battery optimization.

**Check:**
Settings → Battery → Battery optimization → Step Sync → Don't optimize
''';

      case Manufacturer.other:
      case Manufacturer.unknown:
        return '''
**${deviceInfo.manufacturerName} ${deviceInfo.model}**

Your device may have manufacturer-specific battery restrictions.

**General Guidance:**
1. Disable Battery Optimization for this app
2. Check for "App startup" or "Autostart" settings
3. Look for "Background app management" settings
4. Add app to battery whitelist if available
''';
    }
  }
}
