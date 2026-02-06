import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'diagnostic_channels.dart';

/// Data Saver Mode status (Android 7+)
enum DataSaverStatus {
  /// Data Saver is enabled (background data blocked)
  enabled,

  /// Data Saver is disabled (background data allowed)
  disabled,

  /// App is whitelisted (background data allowed even with Data Saver on)
  whitelisted,

  /// Data Saver not available on this platform/version
  notAvailable,

  /// Status could not be determined
  unknown,
}

/// Extension methods for [DataSaverStatus]
extension DataSaverStatusX on DataSaverStatus {
  /// Convert string from native code to [DataSaverStatus]
  static DataSaverStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ENABLED':
        return DataSaverStatus.enabled;
      case 'DISABLED':
        return DataSaverStatus.disabled;
      case 'WHITELISTED':
        return DataSaverStatus.whitelisted;
      case 'NOT_AVAILABLE':
        return DataSaverStatus.notAvailable;
      default:
        return DataSaverStatus.unknown;
    }
  }

  /// Check if Data Saver will block background data
  bool get blocksBackgroundData => this == DataSaverStatus.enabled;

  /// Check if background data is allowed
  bool get allowsBackgroundData =>
      this == DataSaverStatus.disabled || this == DataSaverStatus.whitelisted;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case DataSaverStatus.enabled:
        return 'Enabled';
      case DataSaverStatus.disabled:
        return 'Disabled';
      case DataSaverStatus.whitelisted:
        return 'Whitelisted';
      case DataSaverStatus.notAvailable:
        return 'Not Available';
      case DataSaverStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Background data restriction status
enum BackgroundDataStatus {
  /// Background data is allowed for this app
  allowed,

  /// Background data is restricted for this app
  restricted,

  /// Status could not be determined
  unknown,
}

/// Extension methods for [BackgroundDataStatus]
extension BackgroundDataStatusX on BackgroundDataStatus {
  /// Convert string from native code to [BackgroundDataStatus]
  static BackgroundDataStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ALLOWED':
        return BackgroundDataStatus.allowed;
      case 'RESTRICTED':
        return BackgroundDataStatus.restricted;
      default:
        return BackgroundDataStatus.unknown;
    }
  }

  /// Check if background data is restricted
  bool get isRestricted => this == BackgroundDataStatus.restricted;

  /// Check if background data is allowed
  bool get isAllowed => this == BackgroundDataStatus.allowed;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case BackgroundDataStatus.allowed:
        return 'Allowed';
      case BackgroundDataStatus.restricted:
        return 'Restricted';
      case BackgroundDataStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Network connectivity type
enum ConnectivityType {
  /// Connected to WiFi network
  wifi,

  /// Connected to cellular network (mobile data)
  cellular,

  /// No network connection
  none,

  /// Connectivity type could not be determined
  unknown,
}

/// Extension methods for [ConnectivityType]
extension ConnectivityTypeX on ConnectivityType {
  /// Convert string from native code to [ConnectivityType]
  static ConnectivityType fromString(String type) {
    switch (type.toUpperCase()) {
      case 'WIFI':
        return ConnectivityType.wifi;
      case 'CELLULAR':
        return ConnectivityType.cellular;
      case 'NONE':
        return ConnectivityType.none;
      default:
        return ConnectivityType.unknown;
    }
  }

  /// Check if connected to network
  bool get isConnected =>
      this == ConnectivityType.wifi || this == ConnectivityType.cellular;

  /// Check if offline
  bool get isOffline => this == ConnectivityType.none;

  /// Get user-friendly description
  String get description {
    switch (this) {
      case ConnectivityType.wifi:
        return 'WiFi';
      case ConnectivityType.cellular:
        return 'Cellular';
      case ConnectivityType.none:
        return 'No Connection';
      case ConnectivityType.unknown:
        return 'Unknown';
    }
  }

  /// Get icon representation
  String get icon {
    switch (this) {
      case ConnectivityType.wifi:
        return '📶';
      case ConnectivityType.cellular:
        return '📱';
      case ConnectivityType.none:
        return '❌';
      case ConnectivityType.unknown:
        return '❓';
    }
  }
}

/// Detailed connectivity information
class ConnectivityInfo {
  final ConnectivityType type;
  final bool isConnected;
  final String? networkType; // e.g., "LTE", "5G", "WiFi 6"
  final bool isMetered; // true if cellular or metered WiFi

  const ConnectivityInfo({
    required this.type,
    required this.isConnected,
    this.networkType,
    this.isMetered = false,
  });

  factory ConnectivityInfo.fromMap(Map<dynamic, dynamic> map) {
    return ConnectivityInfo(
      type: ConnectivityTypeX.fromString(map['type'] as String? ?? 'UNKNOWN'),
      isConnected: map['isConnected'] as bool? ?? false,
      networkType: map['networkType'] as String?,
      isMetered: map['isMetered'] as bool? ?? false,
    );
  }

  /// Get detailed description
  String get detailedDescription {
    if (!isConnected) return 'No connection';
    if (networkType != null) {
      return '${type.description} ($networkType)';
    }
    return type.description;
  }
}

/// Checker for network-related features
/// Handles Data Saver Mode, Background Data Restriction, and Connectivity Status
class NetworkChecker {
  final Logger _logger;

  NetworkChecker({Logger? logger}) : _logger = logger ?? Logger();

  // ============================================================================
  // DATA SAVER MODE (Android 7+)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #4: Data Saver Mode (Android 7+)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// A system-wide Android feature that blocks apps from using background
  /// data to save your mobile data allowance. It's like a master switch
  /// that affects ALL apps at once.
  ///
  /// KEY POINTS:
  /// • System-wide setting affecting ALL apps (not per-app)
  /// • Apps can be whitelisted to bypass Data Saver
  /// • Only blocks BACKGROUND data - foreground (open apps) still work
  /// • Popular on phones with limited data plans
  ///
  /// TECHNICAL DETAILS:
  /// Android API: ConnectivityManager.restrictBackgroundStatus
  /// Available Since: Android 7 (API 24, Nougat, released August 2016)
  /// Confidence: 90% (Official API, varies slightly by OEM)
  ///
  /// IN SIMPLE TERMS:
  /// Data Saver is Android's built-in feature to help people save mobile
  /// data. When turned on, it stops apps from using data in the background
  /// (when you're not actively using them). Think of it as Android's way
  /// of saying "only let apps use data when I'm watching them."
  ///
  /// REAL-WORLD EXAMPLE:
  /// Imagine you're at a party with limited snacks (mobile data). Data
  /// Saver is like telling everyone "you can only eat when you're at
  /// the food table" (foreground). People can't grab snacks to take home
  /// (background data) unless they're on a VIP list (whitelisted apps).
  ///
  /// WHY IT MATTERS:
  /// When Data Saver is ON and your app is NOT whitelisted:
  /// • Steps only sync when app is OPEN
  /// • Cloud backup blocked when app is closed
  /// • Health Connect sync stops in background
  /// • Manual sync required after closing app
  /// • Real-time step updates stop working
  ///
  /// WHEN IT'S WHITELISTED:
  /// • App works normally even with Data Saver enabled
  /// • Background sync continues as expected
  /// • No impact on step tracking
  ///
  /// FOUND IN:
  /// Settings → Network & internet → Data Saver
  /// Settings → Connections → Data usage → Data saver (Samsung)
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check Data Saver Mode status (Android 7+)
  ///
  /// Returns [DataSaverStatus]:
  /// - ENABLED: Data Saver on, background data blocked for most apps
  /// - DISABLED: Data Saver off, background data allowed
  /// - WHITELISTED: Data Saver on, but this app is whitelisted
  /// - NOT_AVAILABLE: Android < 7 or non-Android platform
  Future<DataSaverStatus> checkDataSaverMode() async {
    if (!Platform.isAndroid) {
      _logger.d('Data Saver Mode not applicable on non-Android platforms');
      return DataSaverStatus.notAvailable;
    }

    try {
      _logger.d('Checking Data Saver Mode...');
      final result =
          await DiagnosticChannels.network.invokeMethod('checkDataSaverMode');

      final status = DataSaverStatusX.fromString(result as String);
      _logger.i('Data Saver Mode: ${status.description}');
      return status;
    } on PlatformException catch (e) {
      _logger.e('PlatformException checking Data Saver Mode: ${e.message}');
      if (e.code == 'NOT_AVAILABLE') {
        return DataSaverStatus.notAvailable;
      }
      return DataSaverStatus.unknown;
    } catch (e) {
      _logger.e('Error checking Data Saver Mode: $e');
      return DataSaverStatus.unknown;
    }
  }

  /// Request Data Saver whitelist
  ///
  /// Opens settings where user can whitelist the app to allow
  /// background data even when Data Saver is enabled.
  ///
  /// Returns true if settings was opened successfully.
  Future<bool> requestDataSaverWhitelist() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot request Data Saver whitelist on non-Android');
      return false;
    }

    try {
      _logger.d('Requesting Data Saver whitelist...');
      final result = await DiagnosticChannels.network
          .invokeMethod('requestDataSaverWhitelist');
      final success = result as bool? ?? false;
      _logger.i('Data Saver whitelist settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException requesting Data Saver whitelist: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error requesting Data Saver whitelist: $e');
      return false;
    }
  }

  // ============================================================================
  // BACKGROUND DATA RESTRICTION (Android)
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #5: Background Data Restriction (Per-App, Android)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// A per-app setting that lets users block specific apps from using
  /// background data. Unlike Data Saver (system-wide), this targets
  /// individual apps the user wants to restrict.
  ///
  /// KEY POINTS:
  /// • PER-APP setting (not system-wide like Data Saver)
  /// • User manually restricts specific apps
  /// • Completely blocks background data for that app
  /// • Different from Data Saver Mode
  ///
  /// TECHNICAL DETAILS:
  /// Android API: ConnectivityManager.restrictBackgroundStatus (same as Data Saver)
  /// Available Since: Android 7 (API 24, Nougat)
  /// Confidence: 90% (Official API)
  ///
  /// IN SIMPLE TERMS:
  /// This is like putting a specific app in "timeout" for using data when
  /// it's not open. While Data Saver affects ALL apps at once, this setting
  /// lets you pick which apps you don't trust with background data. It's
  /// more targeted control.
  ///
  /// REAL-WORLD EXAMPLE:
  /// Imagine you have roommates (apps). Data Saver is like a house rule:
  /// "nobody can eat snacks at night." Background Data Restriction is like
  /// saying "Tom specifically can't eat snacks at night" while everyone
  /// else can. It's personal targeting, not a blanket rule.
  ///
  /// DIFFERENCE FROM DATA SAVER:
  /// • Data Saver: System-wide, affects ALL apps, can whitelist exceptions
  /// • Background Data: Per-app, manually set by user, no exceptions
  ///
  /// WHY IT MATTERS:
  /// When your app has background data RESTRICTED:
  /// • Steps cannot sync when app is closed
  /// • Health Connect updates blocked in background
  /// • Cloud backup fails when app is closed
  /// • Must manually open app to trigger sync
  /// • No automatic step tracking updates
  ///
  /// COMMON SCENARIO:
  /// User restricts background data to save battery or reduce data usage
  /// for apps they don't trust. If your step tracking app is restricted,
  /// it won't sync steps until the user opens the app again.
  ///
  /// FOUND IN:
  /// Settings → Apps → [App Name] → Mobile data & WiFi → Background data
  /// Settings → Apps → [App Name] → Data usage → Background data (some OEMs)
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check if background data is restricted for this app
  ///
  /// Returns [BackgroundDataStatus]:
  /// - ALLOWED: App can use background data
  /// - RESTRICTED: App cannot use background data
  Future<BackgroundDataStatus> checkBackgroundDataRestriction() async {
    if (!Platform.isAndroid) {
      _logger.d('Background data restriction not applicable on non-Android');
      return BackgroundDataStatus.unknown;
    }

    try {
      _logger.d('Checking background data restriction...');
      final result = await DiagnosticChannels.network
          .invokeMethod('checkBackgroundDataRestriction');

      final status = BackgroundDataStatusX.fromString(result as String);
      _logger.i('Background data: ${status.description}');
      return status;
    } on PlatformException catch (e) {
      _logger.e('PlatformException checking background data: ${e.message}');
      return BackgroundDataStatus.unknown;
    } catch (e) {
      _logger.e('Error checking background data restriction: $e');
      return BackgroundDataStatus.unknown;
    }
  }

  /// Open app data settings
  ///
  /// Opens the settings screen where user can enable background data
  /// for this app.
  ///
  /// Returns true if settings was opened successfully.
  Future<bool> openAppDataSettings() async {
    if (!Platform.isAndroid) {
      _logger.d('Cannot open app data settings on non-Android');
      return false;
    }

    try {
      _logger.d('Opening app data settings...');
      final result =
          await DiagnosticChannels.network.invokeMethod('openAppDataSettings');
      final success = result as bool? ?? false;
      _logger.i('App data settings opened: $success');
      return success;
    } on PlatformException catch (e) {
      _logger.e('PlatformException opening app data settings: ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Error opening app data settings: $e');
      return false;
    }
  }

  // ============================================================================
  // CONNECTIVITY STATUS
  // ============================================================================

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Feature #6: Network Connectivity Status (WiFi/Cellular Detection)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// WHAT IT IS:
  /// A real-time check of your device's internet connection type - whether
  /// you're connected to WiFi, using mobile data (cellular), or offline.
  /// This helps the app understand how and when it can sync your step data.
  ///
  /// KEY POINTS:
  /// • Detects WiFi, Cellular (mobile data), or No Connection
  /// • Identifies if network is "metered" (has data limits)
  /// • Shows detailed network type (e.g., "LTE", "5G", "WiFi 6")
  /// • Real-time status - changes as you switch networks
  /// • Available on both Android and iOS
  ///
  /// TECHNICAL DETAILS:
  /// Android API: ConnectivityManager, NetworkCapabilities
  /// iOS API: Network.framework (NWPathMonitor)
  /// Available Since: All Android/iOS versions
  /// Confidence: 95% (Standard APIs on both platforms)
  ///
  /// IN SIMPLE TERMS:
  /// Your phone can connect to the internet in different ways. This feature
  /// checks which way you're using right now. WiFi is usually unlimited and
  /// fast. Cellular (mobile data) often has limits and costs money. Knowing
  /// the difference helps the app decide when to sync your steps.
  ///
  /// REAL-WORLD EXAMPLE:
  /// Think of it like checking which door you're using to enter a building:
  /// • WiFi = Main entrance (wide, unlimited capacity)
  /// • Cellular = Side door (narrower, might have a cover charge)
  /// • Offline = All doors locked (can't get in at all)
  ///
  /// The app checks which "door" you're using to know how to send your data.
  ///
  /// WHY IT MATTERS:
  ///
  /// WHEN OFFLINE (No Connection):
  /// • Cannot sync steps to cloud
  /// • Health Connect/HealthKit sync paused
  /// • Manual sync required when back online
  /// • Local step counting still works (hardware sensor)
  /// • Data queued for later upload
  ///
  /// WHEN ON CELLULAR (Mobile Data):
  /// • Some apps limit sync to save your data allowance
  /// • May wait for WiFi to upload large amounts of data
  /// • User might have Data Saver enabled
  /// • Important for users with limited data plans
  ///
  /// WHEN ON WIFI:
  /// • Full sync capabilities (no data concerns)
  /// • Can upload/download freely
  /// • Best for large data transfers
  /// • No impact on mobile data allowance
  ///
  /// METERED NETWORKS:
  /// "Metered" means the network has a data limit (most cellular networks).
  /// Some WiFi networks can also be metered (e.g., mobile hotspots, public WiFi).
  /// The app can detect metered networks and adjust sync behavior to save data.
  ///
  /// WHAT THE APP GETS:
  /// • Connection Type: WiFi, Cellular, None, Unknown
  /// • Network Details: "5G", "LTE", "WiFi 6", "WiFi 5", etc.
  /// • Metered Status: true if data limits apply
  /// • Connection Status: true if connected to internet
  ///
  /// USE CASES FOR TROUBLESHOOTING:
  /// • User says "my steps aren't syncing" → Check if offline
  /// • Warning user about cellular data usage
  /// • Explaining why sync is paused (waiting for WiFi)
  /// • Detecting network issues affecting Health Connect
  ///
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Check current network connectivity
  ///
  /// Returns [ConnectivityInfo] with:
  /// - type: WiFi, Cellular, None, Unknown
  /// - isConnected: true if connected to network
  /// - networkType: Detailed type (e.g., "LTE", "5G", "WiFi 6")
  /// - isMetered: true if cellular or metered WiFi
  ///
  /// Useful for:
  /// - Detecting if device is offline
  /// - Checking if on WiFi vs cellular
  /// - Warning user about cellular data usage
  Future<ConnectivityInfo> checkConnectivity() async {
    try {
      print('DEBUG: NetworkChecker.checkConnectivity() called');
      _logger.d('Checking connectivity...');
      final result =
          await DiagnosticChannels.network.invokeMethod('checkConnectivity');
      print('DEBUG: Platform channel returned: $result');

      if (result == null) {
        print('DEBUG: Connectivity check returned NULL');
        _logger.w('Connectivity check returned null');
        return const ConnectivityInfo(
          type: ConnectivityType.unknown,
          isConnected: false,
        );
      }

      print('DEBUG: Parsing result: $result');
      final info = ConnectivityInfo.fromMap(result as Map<dynamic, dynamic>);
      print('DEBUG: Parsed info - type=${info.type.description}, connected=${info.isConnected}');
      _logger.i(
          'Connectivity: ${info.type.description}, connected=${info.isConnected}, metered=${info.isMetered}');
      return info;
    } on PlatformException catch (e) {
      print('DEBUG: PlatformException - ${e.code}: ${e.message}');
      _logger.e('PlatformException checking connectivity: ${e.message}');
      return const ConnectivityInfo(
        type: ConnectivityType.unknown,
        isConnected: false,
      );
    } catch (e, stackTrace) {
      print('DEBUG: Exception in checkConnectivity - $e');
      print('DEBUG: Stack trace: $stackTrace');
      _logger.e('Error checking connectivity: $e');
      return const ConnectivityInfo(
        type: ConnectivityType.unknown,
        isConnected: false,
      );
    }
  }

  /// Check if device is connected to WiFi
  Future<bool> isConnectedToWiFi() async {
    final info = await checkConnectivity();
    return info.type == ConnectivityType.wifi;
  }

  /// Check if device is connected to cellular
  Future<bool> isConnectedToCellular() async {
    final info = await checkConnectivity();
    return info.type == ConnectivityType.cellular;
  }

  /// Check if device is offline
  Future<bool> isOffline() async {
    final info = await checkConnectivity();
    return info.type == ConnectivityType.none;
  }

  // ============================================================================
  // COMBINED CHECKS
  // ============================================================================

  /// Check all network features
  ///
  /// Returns a map with all network-related statuses
  Future<Map<String, dynamic>> checkAllNetworkFeatures() async {
    _logger.d('Checking all network features...');

    final results = <String, dynamic>{};

    if (Platform.isAndroid) {
      final dataSaver = await checkDataSaverMode();
      final backgroundData = await checkBackgroundDataRestriction();

      results['dataSaver'] = {
        'status': dataSaver.description,
        'blocksBackgroundData': dataSaver.blocksBackgroundData,
        'allowsBackgroundData': dataSaver.allowsBackgroundData,
      };

      results['backgroundData'] = {
        'status': backgroundData.description,
        'isRestricted': backgroundData.isRestricted,
        'isAllowed': backgroundData.isAllowed,
      };
    }

    final connectivity = await checkConnectivity();
    results['connectivity'] = {
      'type': connectivity.type.description,
      'isConnected': connectivity.isConnected,
      'networkType': connectivity.networkType,
      'isMetered': connectivity.isMetered,
      'detailedDescription': connectivity.detailedDescription,
    };

    _logger.i('Network features check complete: ${results.length} features');
    return results;
  }
}
