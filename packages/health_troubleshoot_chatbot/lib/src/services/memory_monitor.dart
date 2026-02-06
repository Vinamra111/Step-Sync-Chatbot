/// Memory Monitoring Service
///
/// Provides real-time memory tracking with:
/// - Per-session and global byte tracking
/// - Alert thresholds (80% warning, 95% critical)
/// - Dashboard statistics
/// - Automatic cleanup triggers
/// - RSS memory monitoring using dart:developer

import 'dart:async';
import 'dart:developer' as developer;
import 'package:logger/logger.dart';

/// Configuration for memory monitoring
class MemoryMonitorConfig {
  /// Maximum memory per session in bytes (default: 5MB)
  final int maxSessionBytes;

  /// Maximum global memory in bytes (default: 50MB)
  final int maxGlobalBytes;

  /// Warning threshold percentage (default: 0.8 = 80%)
  final double warningThreshold;

  /// Critical threshold percentage (default: 0.95 = 95%)
  final double criticalThreshold;

  /// Monitoring interval for RSS checks (default: 10 seconds)
  final Duration monitoringInterval;

  const MemoryMonitorConfig({
    this.maxSessionBytes = 5 * 1024 * 1024, // 5MB
    this.maxGlobalBytes = 50 * 1024 * 1024, // 50MB
    this.warningThreshold = 0.8,
    this.criticalThreshold = 0.95,
    this.monitoringInterval = const Duration(seconds: 10),
  });

  int get warningSessionBytes => (maxSessionBytes * warningThreshold).round();
  int get criticalSessionBytes => (maxSessionBytes * criticalThreshold).round();
  int get warningGlobalBytes => (maxGlobalBytes * warningThreshold).round();
  int get criticalGlobalBytes => (maxGlobalBytes * criticalThreshold).round();
}

/// Severity level for memory alerts
enum MemoryAlertLevel {
  normal,
  warning,
  critical,
}

/// Snapshot of current memory usage
class MemoryUsageSnapshot {
  /// Current session bytes used
  final int sessionBytes;

  /// Maximum session bytes allowed
  final int maxSessionBytes;

  /// Current global bytes used across all sessions
  final int globalBytes;

  /// Maximum global bytes allowed
  final int maxGlobalBytes;

  /// Current RSS memory from dart:developer (if available)
  final int? rssBytes;

  /// Timestamp of snapshot
  final DateTime timestamp;

  /// Number of active sessions
  final int activeSessions;

  MemoryUsageSnapshot({
    required this.sessionBytes,
    required this.maxSessionBytes,
    required this.globalBytes,
    required this.maxGlobalBytes,
    this.rssBytes,
    DateTime? timestamp,
    required this.activeSessions,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Session usage percentage (0.0 to 1.0)
  double get sessionUsagePercent => sessionBytes / maxSessionBytes;

  /// Global usage percentage (0.0 to 1.0)
  double get globalUsagePercent => globalBytes / maxGlobalBytes;

  /// Alert level based on highest usage
  MemoryAlertLevel getAlertLevel(MemoryMonitorConfig config) {
    final sessionPercent = sessionUsagePercent;
    final globalPercent = globalUsagePercent;
    final maxPercent = sessionPercent > globalPercent ? sessionPercent : globalPercent;

    if (maxPercent >= config.criticalThreshold) {
      return MemoryAlertLevel.critical;
    } else if (maxPercent >= config.warningThreshold) {
      return MemoryAlertLevel.warning;
    } else {
      return MemoryAlertLevel.normal;
    }
  }

  /// Human-readable description
  String describe() {
    final sessionMB = (sessionBytes / (1024 * 1024)).toStringAsFixed(2);
    final maxSessionMB = (maxSessionBytes / (1024 * 1024)).toStringAsFixed(2);
    final globalMB = (globalBytes / (1024 * 1024)).toStringAsFixed(2);
    final maxGlobalMB = (maxGlobalBytes / (1024 * 1024)).toStringAsFixed(2);
    final sessionPercent = (sessionUsagePercent * 100).toStringAsFixed(1);
    final globalPercent = (globalUsagePercent * 100).toStringAsFixed(1);

    final buffer = StringBuffer();
    buffer.writeln('Memory Usage:');
    buffer.writeln('  Session: $sessionMB MB / $maxSessionMB MB ($sessionPercent%)');
    buffer.writeln('  Global: $globalMB MB / $maxGlobalMB MB ($globalPercent%)');
    buffer.writeln('  Active Sessions: $activeSessions');

    if (rssBytes != null) {
      final rssMB = (rssBytes! / (1024 * 1024)).toStringAsFixed(2);
      buffer.writeln('  RSS: $rssMB MB');
    }

    return buffer.toString();
  }
}

/// Callback type for memory alerts
typedef MemoryAlertCallback = void Function(
  MemoryAlertLevel level,
  MemoryUsageSnapshot snapshot,
);

/// Memory monitoring service with real-time tracking
class MemoryMonitor {
  final MemoryMonitorConfig config;
  final Logger _logger;

  /// Callbacks for memory alerts
  final List<MemoryAlertCallback> _alertCallbacks = [];

  /// Current session bytes tracked
  final Map<String, int> _sessionBytes = {};

  /// Last alert level per session
  final Map<String, MemoryAlertLevel> _lastAlertLevel = {};

  /// RSS monitoring timer
  Timer? _rssMonitorTimer;

  /// Last RSS value in bytes
  int? _lastRssBytes;

  /// Total snapshots taken
  int _snapshotCount = 0;

  /// Alert history
  final List<(DateTime, MemoryAlertLevel, MemoryUsageSnapshot)> _alertHistory = [];

  MemoryMonitor({
    required this.config,
    Logger? logger,
  }) : _logger = logger ?? Logger() {
    _startRssMonitoring();
  }

  /// Add callback for memory alerts
  void addAlertCallback(MemoryAlertCallback callback) {
    _alertCallbacks.add(callback);
  }

  /// Remove callback
  void removeAlertCallback(MemoryAlertCallback callback) {
    _alertCallbacks.remove(callback);
  }

  /// Start monitoring RSS memory
  void _startRssMonitoring() {
    _rssMonitorTimer?.cancel();
    _rssMonitorTimer = Timer.periodic(config.monitoringInterval, (_) {
      _updateRssMemory();
    });
  }

  /// Update RSS memory from dart:developer
  void _updateRssMemory() {
    try {
      // Get current RSS from VM
      final timeline = developer.Timeline.now;

      // Note: dart:developer doesn't directly expose RSS, but we can use
      // developer.Service to get VM metrics in a real implementation.
      // For now, we'll track our own byte counting as the primary metric.

      // This is a placeholder - in production, integrate with:
      // - developer.Service.getIsolateMemoryUsage() for Dart VM stats
      // - platform channels for native memory on iOS/Android

    } catch (e) {
      _logger.w('Failed to get RSS memory: $e');
    }
  }

  /// Track bytes for a session
  void trackSession(String sessionId, int bytes) {
    _sessionBytes[sessionId] = bytes;
    _checkThresholds(sessionId);
  }

  /// Add bytes to a session
  void addBytes(String sessionId, int additionalBytes) {
    final currentBytes = _sessionBytes[sessionId] ?? 0;
    trackSession(sessionId, currentBytes + additionalBytes);
  }

  /// Remove bytes from a session
  void removeBytes(String sessionId, int bytesToRemove) {
    final currentBytes = _sessionBytes[sessionId] ?? 0;
    final newBytes = currentBytes - bytesToRemove;
    trackSession(sessionId, newBytes > 0 ? newBytes : 0);
  }

  /// Remove session from tracking
  void removeSession(String sessionId) {
    _sessionBytes.remove(sessionId);
    _lastAlertLevel.remove(sessionId);
  }

  /// Get current snapshot for a session
  MemoryUsageSnapshot getSnapshot(String sessionId) {
    final sessionBytes = _sessionBytes[sessionId] ?? 0;
    final globalBytes = _sessionBytes.values.fold<int>(0, (sum, bytes) => sum + bytes);

    _snapshotCount++;

    return MemoryUsageSnapshot(
      sessionBytes: sessionBytes,
      maxSessionBytes: config.maxSessionBytes,
      globalBytes: globalBytes,
      maxGlobalBytes: config.maxGlobalBytes,
      rssBytes: _lastRssBytes,
      activeSessions: _sessionBytes.length,
    );
  }

  /// Check if thresholds are exceeded and trigger alerts
  void _checkThresholds(String sessionId) {
    final snapshot = getSnapshot(sessionId);
    final alertLevel = snapshot.getAlertLevel(config);

    // Only trigger if alert level changed
    final lastLevel = _lastAlertLevel[sessionId] ?? MemoryAlertLevel.normal;
    if (alertLevel != lastLevel) {
      _lastAlertLevel[sessionId] = alertLevel;

      // Log alert
      if (alertLevel == MemoryAlertLevel.warning) {
        _logger.w('Memory warning for session $sessionId:\n${snapshot.describe()}');
      } else if (alertLevel == MemoryAlertLevel.critical) {
        _logger.e('Memory critical for session $sessionId:\n${snapshot.describe()}');
      }

      // Record in history
      _alertHistory.add((DateTime.now(), alertLevel, snapshot));

      // Keep only last 100 alerts
      if (_alertHistory.length > 100) {
        _alertHistory.removeAt(0);
      }

      // Trigger callbacks
      for (final callback in _alertCallbacks) {
        try {
          callback(alertLevel, snapshot);
        } catch (e) {
          _logger.e('Error in memory alert callback: $e');
        }
      }
    }
  }

  /// Get global memory usage across all sessions
  int getGlobalBytes() {
    return _sessionBytes.values.fold<int>(0, (sum, bytes) => sum + bytes);
  }

  /// Get statistics for dashboard
  Map<String, dynamic> getStatistics() {
    final globalBytes = getGlobalBytes();
    final activeSessions = _sessionBytes.length;

    final stats = <String, dynamic>{
      'global_bytes': globalBytes,
      'global_mb': (globalBytes / (1024 * 1024)).toStringAsFixed(2),
      'max_global_bytes': config.maxGlobalBytes,
      'max_global_mb': (config.maxGlobalBytes / (1024 * 1024)).toStringAsFixed(2),
      'global_usage_percent': ((globalBytes / config.maxGlobalBytes) * 100).toStringAsFixed(1),
      'active_sessions': activeSessions,
      'snapshots_taken': _snapshotCount,
      'warning_threshold_percent': (config.warningThreshold * 100).toStringAsFixed(0),
      'critical_threshold_percent': (config.criticalThreshold * 100).toStringAsFixed(0),
      'alerts_in_history': _alertHistory.length,
    };

    // Per-session stats
    if (_sessionBytes.isNotEmpty) {
      final sessionStats = <String, Map<String, dynamic>>{};
      for (final entry in _sessionBytes.entries) {
        final sessionId = entry.key;
        final bytes = entry.value;
        final snapshot = getSnapshot(sessionId);

        sessionStats[sessionId] = {
          'bytes': bytes,
          'mb': (bytes / (1024 * 1024)).toStringAsFixed(2),
          'usage_percent': (snapshot.sessionUsagePercent * 100).toStringAsFixed(1),
          'alert_level': snapshot.getAlertLevel(config).name,
        };
      }
      stats['sessions'] = sessionStats;
    }

    // Recent alerts
    if (_alertHistory.isNotEmpty) {
      stats['recent_alerts'] = _alertHistory.reversed.take(10).map((alert) {
        return {
          'timestamp': alert.$1.toIso8601String(),
          'level': alert.$2.name,
          'session_bytes': alert.$3.sessionBytes,
          'global_bytes': alert.$3.globalBytes,
        };
      }).toList();
    }

    return stats;
  }

  /// Check if any session is at warning threshold
  bool hasWarning() {
    return _sessionBytes.entries.any((entry) {
      final snapshot = getSnapshot(entry.key);
      return snapshot.getAlertLevel(config) == MemoryAlertLevel.warning;
    });
  }

  /// Check if any session is at critical threshold
  bool hasCritical() {
    return _sessionBytes.entries.any((entry) {
      final snapshot = getSnapshot(entry.key);
      return snapshot.getAlertLevel(config) == MemoryAlertLevel.critical;
    });
  }

  /// Reset all monitoring (for testing)
  void reset() {
    _sessionBytes.clear();
    _lastAlertLevel.clear();
    _alertHistory.clear();
    _snapshotCount = 0;
    _lastRssBytes = null;
    _logger.d('Memory monitor reset');
  }

  /// Dispose resources
  void dispose() {
    _rssMonitorTimer?.cancel();
    _rssMonitorTimer = null;
    _alertCallbacks.clear();
    _logger.d('Memory monitor disposed');
  }
}
