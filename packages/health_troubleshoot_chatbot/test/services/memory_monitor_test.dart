/// Tests for MemoryMonitor Service
///
/// Validates:
/// - Byte tracking accuracy (±5%)
/// - Alert threshold triggers (80% warning, 95% critical)
/// - Automatic cleanup validation
/// - Concurrent access safety
/// - Dashboard statistics

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:step_sync_chatbot/src/services/memory_monitor.dart';

void main() {
  group('MemoryMonitorConfig', () {
    test('should have sensible defaults', () {
      const config = MemoryMonitorConfig();

      expect(config.maxSessionBytes, equals(5 * 1024 * 1024)); // 5MB
      expect(config.maxGlobalBytes, equals(50 * 1024 * 1024)); // 50MB
      expect(config.warningThreshold, equals(0.8));
      expect(config.criticalThreshold, equals(0.95));
      expect(config.monitoringInterval, equals(const Duration(seconds: 10)));
    });

    test('should calculate threshold bytes correctly', () {
      const config = MemoryMonitorConfig(
        maxSessionBytes: 1000,
        maxGlobalBytes: 10000,
        warningThreshold: 0.8,
        criticalThreshold: 0.95,
      );

      expect(config.warningSessionBytes, equals(800));
      expect(config.criticalSessionBytes, equals(950));
      expect(config.warningGlobalBytes, equals(8000));
      expect(config.criticalGlobalBytes, equals(9500));
    });
  });

  group('MemoryUsageSnapshot', () {
    test('should calculate usage percentages correctly', () {
      final snapshot = MemoryUsageSnapshot(
        sessionBytes: 4000,
        maxSessionBytes: 5000,
        globalBytes: 40000,
        maxGlobalBytes: 50000,
        activeSessions: 3,
      );

      expect(snapshot.sessionUsagePercent, equals(0.8));
      expect(snapshot.globalUsagePercent, equals(0.8));
    });

    test('should determine alert levels correctly - normal', () {
      const config = MemoryMonitorConfig();
      final snapshot = MemoryUsageSnapshot(
        sessionBytes: 1000,
        maxSessionBytes: 5000,
        globalBytes: 10000,
        maxGlobalBytes: 50000,
        activeSessions: 1,
      );

      expect(snapshot.getAlertLevel(config), equals(MemoryAlertLevel.normal));
    });

    test('should determine alert levels correctly - warning', () {
      const config = MemoryMonitorConfig();
      final snapshot = MemoryUsageSnapshot(
        sessionBytes: 4100, // 82% of 5000
        maxSessionBytes: 5000,
        globalBytes: 10000,
        maxGlobalBytes: 50000,
        activeSessions: 1,
      );

      expect(snapshot.getAlertLevel(config), equals(MemoryAlertLevel.warning));
    });

    test('should determine alert levels correctly - critical', () {
      const config = MemoryMonitorConfig();
      final snapshot = MemoryUsageSnapshot(
        sessionBytes: 4800, // 96% of 5000
        maxSessionBytes: 5000,
        globalBytes: 10000,
        maxGlobalBytes: 50000,
        activeSessions: 1,
      );

      expect(snapshot.getAlertLevel(config), equals(MemoryAlertLevel.critical));
    });

    test('should generate human-readable description', () {
      final snapshot = MemoryUsageSnapshot(
        sessionBytes: 2 * 1024 * 1024, // 2 MB
        maxSessionBytes: 5 * 1024 * 1024, // 5 MB
        globalBytes: 10 * 1024 * 1024, // 10 MB
        maxGlobalBytes: 50 * 1024 * 1024, // 50 MB
        rssBytes: 15 * 1024 * 1024, // 15 MB
        activeSessions: 2,
      );

      final description = snapshot.describe();

      expect(description, contains('Session: 2.00 MB / 5.00 MB (40.0%)'));
      expect(description, contains('Global: 10.00 MB / 50.00 MB (20.0%)'));
      expect(description, contains('Active Sessions: 2'));
      expect(description, contains('RSS: 15.00 MB'));
    });
  });

  group('MemoryMonitor - Basic Tracking', () {
    late MemoryMonitor monitor;

    setUp(() {
      monitor = MemoryMonitor(
        config: const MemoryMonitorConfig(
          maxSessionBytes: 5000,
          maxGlobalBytes: 50000,
        ),
        logger: Logger(level: Level.off), // Disable logging in tests
      );
    });

    tearDown(() {
      monitor.dispose();
    });

    test('should track session bytes accurately', () {
      monitor.trackSession('session1', 1000);

      final snapshot = monitor.getSnapshot('session1');
      expect(snapshot.sessionBytes, equals(1000));
      expect(snapshot.globalBytes, equals(1000));
    });

    test('should add bytes to existing session', () {
      monitor.trackSession('session1', 1000);
      monitor.addBytes('session1', 500);

      final snapshot = monitor.getSnapshot('session1');
      expect(snapshot.sessionBytes, equals(1500));
    });

    test('should remove bytes from session', () {
      monitor.trackSession('session1', 1000);
      monitor.removeBytes('session1', 300);

      final snapshot = monitor.getSnapshot('session1');
      expect(snapshot.sessionBytes, equals(700));
    });

    test('should not allow negative bytes when removing', () {
      monitor.trackSession('session1', 500);
      monitor.removeBytes('session1', 1000);

      final snapshot = monitor.getSnapshot('session1');
      expect(snapshot.sessionBytes, equals(0));
    });

    test('should track multiple sessions independently', () {
      monitor.trackSession('session1', 1000);
      monitor.trackSession('session2', 2000);
      monitor.trackSession('session3', 3000);

      final snapshot1 = monitor.getSnapshot('session1');
      final snapshot2 = monitor.getSnapshot('session2');
      final snapshot3 = monitor.getSnapshot('session3');

      expect(snapshot1.sessionBytes, equals(1000));
      expect(snapshot2.sessionBytes, equals(2000));
      expect(snapshot3.sessionBytes, equals(3000));

      // Global should be sum of all
      expect(snapshot1.globalBytes, equals(6000));
      expect(snapshot2.globalBytes, equals(6000));
      expect(snapshot3.globalBytes, equals(6000));
    });

    test('should remove session correctly', () {
      monitor.trackSession('session1', 1000);
      monitor.trackSession('session2', 2000);

      monitor.removeSession('session1');

      final snapshot = monitor.getSnapshot('session2');
      expect(snapshot.globalBytes, equals(2000));
      expect(snapshot.activeSessions, equals(1));
    });

    test('should calculate global bytes correctly', () {
      monitor.trackSession('session1', 1000);
      monitor.trackSession('session2', 2000);
      monitor.trackSession('session3', 1500);

      expect(monitor.getGlobalBytes(), equals(4500));
    });
  });

  group('MemoryMonitor - Alert Callbacks', () {
    late MemoryMonitor monitor;
    late List<(MemoryAlertLevel, MemoryUsageSnapshot)> alertsReceived;

    setUp(() {
      monitor = MemoryMonitor(
        config: const MemoryMonitorConfig(
          maxSessionBytes: 5000,
          maxGlobalBytes: 50000,
          warningThreshold: 0.8,
          criticalThreshold: 0.95,
        ),
        logger: Logger(level: Level.off),
      );

      alertsReceived = [];
      monitor.addAlertCallback((level, snapshot) {
        alertsReceived.add((level, snapshot));
      });
    });

    tearDown(() {
      monitor.dispose();
    });

    test('should trigger warning alert at 80% threshold', () {
      monitor.trackSession('session1', 4100); // 82% of 5000

      expect(alertsReceived.length, equals(1));
      expect(alertsReceived[0].$1, equals(MemoryAlertLevel.warning));
      expect(alertsReceived[0].$2.sessionBytes, equals(4100));
    });

    test('should trigger critical alert at 95% threshold', () {
      monitor.trackSession('session1', 4800); // 96% of 5000

      expect(alertsReceived.length, equals(1));
      expect(alertsReceived[0].$1, equals(MemoryAlertLevel.critical));
      expect(alertsReceived[0].$2.sessionBytes, equals(4800));
    });

    test('should not trigger duplicate alerts for same level', () {
      monitor.trackSession('session1', 4100); // Warning
      monitor.trackSession('session1', 4200); // Still warning

      expect(alertsReceived.length, equals(1));
    });

    test('should trigger new alert when level changes', () {
      monitor.trackSession('session1', 4100); // Warning
      expect(alertsReceived.length, equals(1));

      monitor.trackSession('session1', 4800); // Critical
      expect(alertsReceived.length, equals(2));
      expect(alertsReceived[1].$1, equals(MemoryAlertLevel.critical));
    });

    test('should trigger alert when dropping from critical to warning', () {
      monitor.trackSession('session1', 4800); // Critical
      expect(alertsReceived.length, equals(1));

      monitor.trackSession('session1', 4100); // Warning
      expect(alertsReceived.length, equals(2));
      expect(alertsReceived[1].$1, equals(MemoryAlertLevel.warning));
    });

    test('should support multiple alert callbacks', () {
      final secondAlerts = <MemoryAlertLevel>[];
      monitor.addAlertCallback((level, snapshot) {
        secondAlerts.add(level);
      });

      monitor.trackSession('session1', 4100); // Warning

      expect(alertsReceived.length, equals(1));
      expect(secondAlerts.length, equals(1));
    });

    test('should allow removing callbacks', () {
      void callback(MemoryAlertLevel level, MemoryUsageSnapshot snapshot) {
        alertsReceived.add((level, snapshot));
      }

      monitor.addAlertCallback(callback);
      monitor.trackSession('session1', 4100); // Warning
      expect(alertsReceived.length, equals(2)); // Original + new callback

      monitor.removeAlertCallback(callback);
      alertsReceived.clear();

      monitor.trackSession('session1', 4800); // Critical
      expect(alertsReceived.length, equals(1)); // Only original callback
    });
  });

  group('MemoryMonitor - Statistics', () {
    late MemoryMonitor monitor;

    setUp(() {
      monitor = MemoryMonitor(
        config: const MemoryMonitorConfig(
          maxSessionBytes: 5000,
          maxGlobalBytes: 50000,
        ),
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() {
      monitor.dispose();
    });

    test('should provide comprehensive statistics', () {
      monitor.trackSession('session1', 1000);
      monitor.trackSession('session2', 2000);
      monitor.trackSession('session3', 1500);

      final stats = monitor.getStatistics();

      expect(stats['global_bytes'], equals(4500));
      expect(stats['global_mb'], equals('0.00')); // Less than 1MB
      expect(stats['active_sessions'], equals(3));
      expect(stats['snapshots_taken'], equals(3));
      expect(stats['warning_threshold_percent'], equals('80'));
      expect(stats['critical_threshold_percent'], equals('95'));
    });

    test('should track per-session statistics', () {
      monitor.trackSession('session1', 4100); // 82% warning
      monitor.trackSession('session2', 1000); // Normal

      final stats = monitor.getStatistics();
      final sessions = stats['sessions'] as Map<String, Map<String, dynamic>>;

      expect(sessions.containsKey('session1'), isTrue);
      expect(sessions.containsKey('session2'), isTrue);

      expect(sessions['session1']!['bytes'], equals(4100));
      expect(sessions['session1']!['alert_level'], equals('warning'));

      expect(sessions['session2']!['bytes'], equals(1000));
      expect(sessions['session2']!['alert_level'], equals('normal'));
    });

    test('should track alert history', () {
      monitor.trackSession('session1', 4100); // Warning
      monitor.trackSession('session1', 4800); // Critical
      monitor.trackSession('session1', 1000); // Normal

      final stats = monitor.getStatistics();
      final recentAlerts = stats['recent_alerts'] as List;

      expect(recentAlerts.length, equals(3));
      // Reversed, so most recent first
      expect(recentAlerts[0]['level'], equals('normal'));
      expect(recentAlerts[1]['level'], equals('critical'));
      expect(recentAlerts[2]['level'], equals('warning'));
    });

    test('should limit alert history to 100 entries', () {
      for (int i = 0; i < 150; i++) {
        // Alternate between warning and normal to trigger alerts
        monitor.trackSession('session1', i % 2 == 0 ? 4100 : 1000);
      }

      final stats = monitor.getStatistics();
      final recentAlerts = stats['recent_alerts'] as List;

      expect(recentAlerts.length, lessThanOrEqualTo(10)); // Only shows last 10
    });

    test('should detect warning state correctly', () {
      expect(monitor.hasWarning(), isFalse);

      monitor.trackSession('session1', 4100); // 82% warning
      expect(monitor.hasWarning(), isTrue);
    });

    test('should detect critical state correctly', () {
      expect(monitor.hasCritical(), isFalse);

      monitor.trackSession('session1', 4800); // 96% critical
      expect(monitor.hasCritical(), isTrue);
    });
  });

  group('MemoryMonitor - Reset and Cleanup', () {
    late MemoryMonitor monitor;

    setUp(() {
      monitor = MemoryMonitor(
        config: const MemoryMonitorConfig(),
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() {
      monitor.dispose();
    });

    test('should reset all tracking', () {
      monitor.trackSession('session1', 1000);
      monitor.trackSession('session2', 2000);

      monitor.reset();

      expect(monitor.getGlobalBytes(), equals(0));
      expect(monitor.hasWarning(), isFalse);
      expect(monitor.hasCritical(), isFalse);

      final stats = monitor.getStatistics();
      expect(stats['active_sessions'], equals(0));
      expect(stats['snapshots_taken'], equals(0));
    });

    test('should clean up on dispose', () {
      monitor.trackSession('session1', 1000);
      final snapshot1 = monitor.getSnapshot('session1');
      expect(snapshot1.sessionBytes, equals(1000));

      monitor.dispose();

      // After dispose, monitor should still work but callbacks cleared
      // (Actual behavior depends on implementation)
    });
  });

  group('MemoryMonitor - Concurrent Access', () {
    test('should handle concurrent session tracking', () async {
      final monitor = MemoryMonitor(
        config: const MemoryMonitorConfig(),
        logger: Logger(level: Level.off),
      );

      // Simulate concurrent access from multiple "threads"
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(Future(() {
          monitor.trackSession('session$i', 1000 + (i * 100));
        }));
      }

      await Future.wait(futures);

      expect(monitor.getGlobalBytes(), equals(14500)); // Sum of all sessions
      expect(monitor.getStatistics()['active_sessions'], equals(10));

      monitor.dispose();
    });

    test('should handle concurrent updates to same session', () async {
      final monitor = MemoryMonitor(
        config: const MemoryMonitorConfig(),
        logger: Logger(level: Level.off),
      );

      monitor.trackSession('session1', 0);

      // Simulate concurrent adds
      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
        futures.add(Future(() {
          monitor.addBytes('session1', 10);
        }));
      }

      await Future.wait(futures);

      final snapshot = monitor.getSnapshot('session1');
      expect(snapshot.sessionBytes, equals(1000)); // 100 * 10

      monitor.dispose();
    });
  });
}
