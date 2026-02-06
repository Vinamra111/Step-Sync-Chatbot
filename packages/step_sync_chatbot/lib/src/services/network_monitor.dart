/// Network Connectivity Monitor
///
/// Monitors network connectivity status and provides real-time updates.
/// Features:
/// - Real-time connectivity detection
/// - Connection type detection (WiFi, Mobile, Ethernet, None)
/// - Stream-based notifications
/// - Auto-reconnection detection
/// - Bandwidth quality estimation

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

/// Network connectivity status
enum ConnectivityStatus {
  /// Connected to the internet
  online,

  /// No internet connection
  offline,

  /// Connection status unknown
  unknown,
}

/// Connection type
enum ConnectionType {
  /// WiFi connection
  wifi,

  /// Mobile data connection
  mobile,

  /// Ethernet connection
  ethernet,

  /// No connection
  none,

  /// Unknown connection type
  unknown,
}

/// Connection quality estimate
enum ConnectionQuality {
  /// Excellent connection (fast)
  excellent,

  /// Good connection (moderate)
  good,

  /// Poor connection (slow)
  poor,

  /// Unknown quality
  unknown,
}

/// Network connectivity information
class ConnectivityInfo {
  final ConnectivityStatus status;
  final ConnectionType type;
  final ConnectionQuality quality;
  final DateTime timestamp;

  const ConnectivityInfo({
    required this.status,
    required this.type,
    required this.quality,
    required this.timestamp,
  });

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;

  @override
  String toString() =>
      'ConnectivityInfo(status: $status, type: $type, quality: $quality)';
}

/// Network Monitor Service
class NetworkMonitor {
  final Connectivity _connectivity;
  final Logger _logger;
  final http.Client _httpClient;

  /// Current connectivity status
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  ConnectivityStatus get status => _status;

  /// Current connection type
  ConnectionType _connectionType = ConnectionType.unknown;
  ConnectionType get connectionType => _connectionType;

  /// Current connection quality
  ConnectionQuality _quality = ConnectionQuality.unknown;
  ConnectionQuality get quality => _quality;

  /// Whether currently online
  bool get isOnline => _status == ConnectivityStatus.online;

  /// Whether currently offline
  bool get isOffline => _status == ConnectivityStatus.offline;

  /// Stream of connectivity changes
  final StreamController<ConnectivityInfo> _connectivityController =
      StreamController<ConnectivityInfo>.broadcast();
  Stream<ConnectivityInfo> get connectivityStream =>
      _connectivityController.stream;

  /// Stream subscription for connectivity changes
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Timer for periodic connectivity checks
  Timer? _periodicCheckTimer;

  /// URL to check for internet connectivity
  final String _connectivityCheckUrl;

  /// Timeout for connectivity checks
  final Duration _checkTimeout;

  /// Interval for periodic checks
  final Duration _checkInterval;

  NetworkMonitor({
    Connectivity? connectivity,
    Logger? logger,
    http.Client? httpClient,
    String connectivityCheckUrl = 'https://www.google.com',
    Duration checkTimeout = const Duration(seconds: 5),
    Duration checkInterval = const Duration(seconds: 30),
  })  : _connectivity = connectivity ?? Connectivity(),
        _logger = logger ?? Logger(),
        _httpClient = httpClient ?? http.Client(),
        _connectivityCheckUrl = connectivityCheckUrl,
        _checkTimeout = checkTimeout,
        _checkInterval = checkInterval;

  /// Initialize the network monitor
  Future<void> initialize() async {
    _logger.d('Initializing network monitor');

    // Check initial connectivity
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Start periodic checks (fallback for missed events)
    _startPeriodicChecks();

    _logger.i('Network monitor initialized. Status: $_status, Type: $_connectionType');
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    _logger.d('Connectivity changed: $result');
    _checkConnectivity();
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      // Get connection type from platform
      final result = await _connectivity.checkConnectivity();
      final connectionType = _mapConnectivityResult(result);

      // If no connection, mark as offline
      if (connectionType == ConnectionType.none) {
        _updateStatus(
          ConnectivityStatus.offline,
          connectionType,
          ConnectionQuality.unknown,
        );
        return;
      }

      // Verify actual internet connectivity with HTTP request
      final hasInternet = await _verifyInternetConnection();

      if (hasInternet) {
        // Estimate connection quality
        final quality = await _estimateConnectionQuality();
        _updateStatus(ConnectivityStatus.online, connectionType, quality);
      } else {
        _updateStatus(
          ConnectivityStatus.offline,
          connectionType,
          ConnectionQuality.unknown,
        );
      }
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      _updateStatus(
        ConnectivityStatus.unknown,
        ConnectionType.unknown,
        ConnectionQuality.unknown,
      );
    }
  }

  /// Verify actual internet connection with HTTP request
  Future<bool> _verifyInternetConnection() async {
    try {
      final response = await _httpClient
          .get(Uri.parse(_connectivityCheckUrl))
          .timeout(_checkTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      _logger.d('Internet verification failed: $e');
      return false;
    }
  }

  /// Estimate connection quality based on response time
  Future<ConnectionQuality> _estimateConnectionQuality() async {
    try {
      final stopwatch = Stopwatch()..start();
      await _httpClient
          .head(Uri.parse(_connectivityCheckUrl))
          .timeout(const Duration(seconds: 3));
      stopwatch.stop();

      final latency = stopwatch.elapsedMilliseconds;

      if (latency < 200) {
        return ConnectionQuality.excellent;
      } else if (latency < 1000) {
        return ConnectionQuality.good;
      } else {
        return ConnectionQuality.poor;
      }
    } catch (e) {
      _logger.d('Quality estimation failed: $e');
      return ConnectionQuality.unknown;
    }
  }

  /// Map ConnectivityResult to ConnectionType
  ConnectionType _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.none:
        return ConnectionType.none;
      default:
        return ConnectionType.unknown;
    }
  }

  /// Update connectivity status and notify listeners
  void _updateStatus(
    ConnectivityStatus newStatus,
    ConnectionType newType,
    ConnectionQuality newQuality,
  ) {
    final changed = _status != newStatus ||
        _connectionType != newType ||
        _quality != newQuality;

    if (changed) {
      final previousStatus = _status;
      _status = newStatus;
      _connectionType = newType;
      _quality = newQuality;

      final info = ConnectivityInfo(
        status: newStatus,
        type: newType,
        quality: newQuality,
        timestamp: DateTime.now(),
      );

      _connectivityController.add(info);
      _logger.i('Connectivity changed: ${previousStatus.name} → ${newStatus.name} ($newType, $newQuality)');
    }
  }

  /// Start periodic connectivity checks
  void _startPeriodicChecks() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(_checkInterval, (_) {
      _checkConnectivity();
    });
  }

  /// Force an immediate connectivity check
  Future<void> forceCheck() async {
    _logger.d('Forcing connectivity check');
    await _checkConnectivity();
  }

  /// Wait for online status with timeout
  Future<bool> waitForOnline({Duration timeout = const Duration(seconds: 30)}) async {
    if (isOnline) return true;

    try {
      await connectivityStream
          .firstWhere((info) => info.isOnline)
          .timeout(timeout);
      return true;
    } catch (e) {
      _logger.w('Timeout waiting for online status');
      return false;
    }
  }

  /// Get current connectivity information
  ConnectivityInfo getConnectivityInfo() {
    return ConnectivityInfo(
      status: _status,
      type: _connectionType,
      quality: _quality,
      timestamp: DateTime.now(),
    );
  }

  /// Dispose resources
  void dispose() {
    _logger.d('Disposing network monitor');
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
    _connectivityController.close();
    _httpClient.close();
  }
}
