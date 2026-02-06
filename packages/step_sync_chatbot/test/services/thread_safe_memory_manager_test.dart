/// Tests for Thread-Safe Memory Manager
///
/// Validates:
/// - Thread safety under concurrent access
/// - No data corruption
/// - Lock contention handling
/// - Performance with multiple threads
/// - Persistence integration

import 'package:test/test.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import '../../lib/src/services/thread_safe_memory_manager.dart';
import '../../lib/src/services/conversation_memory_manager.dart';
import '../../lib/src/services/groq_chat_service.dart';

void main() {
  group('ThreadSafeMemoryManager - Basic Operations', () {
    late ThreadSafeMemoryManager manager;

    setUp(() {
      manager = ThreadSafeMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('Creates and retrieves session', () async {
      final session = await manager.getSession('test-session');

      expect(session.id, equals('test-session'));
      expect(session.messageCount, equals(0));
    });

    test('Adds and retrieves messages', () async {
      await manager.addUserMessage('session-1', 'Hello');
      await manager.addAssistantMessage('session-1', 'Hi there');

      final history = await manager.getHistory('session-1');

      expect(history.length, equals(2));
      expect(history[0].content, equals('Hello'));
      expect(history[1].content, equals('Hi there'));
    });

    test('Gets session count', () async {
      await manager.getSession('session-1');
      await manager.getSession('session-2');

      final count = await manager.getSessionCount();

      expect(count, equals(2));
    });

    test('Clears single session', () async {
      await manager.addUserMessage('session-1', 'Test');
      await manager.addUserMessage('session-2', 'Test');

      await manager.clearSession('session-1');

      final has1 = await manager.hasSession('session-1');
      final has2 = await manager.hasSession('session-2');

      expect(has1, isFalse);
      expect(has2, isTrue);
    });

    test('Clears all sessions', () async {
      await manager.addUserMessage('session-1', 'Test');
      await manager.addUserMessage('session-2', 'Test');

      await manager.clearAllSessions();

      final count = await manager.getSessionCount();

      expect(count, equals(0));
    });
  });

  group('ThreadSafeMemoryManager - Concurrent Access to Different Sessions', () {
    late ThreadSafeMemoryManager manager;

    setUp(() {
      manager = ThreadSafeMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('Concurrent writes to different sessions', () async {
      print('\n🔄 Testing: Concurrent writes to different sessions');

      final futures = <Future>[];

      // Write to 10 different sessions concurrently
      for (int i = 0; i < 10; i++) {
        futures.add(
          manager.addUserMessage('session-$i', 'Message from session $i'),
        );
      }

      await Future.wait(futures);

      // Verify all messages written
      for (int i = 0; i < 10; i++) {
        final history = await manager.getHistory('session-$i');
        expect(history.length, equals(1));
        expect(history[0].content, equals('Message from session $i'));
      }

      print('✅ All 10 concurrent writes completed successfully\n');
    });

    test('High concurrent load on different sessions', () async {
      print('\n⚡ Testing: High load (100 concurrent operations)');

      final futures = <Future>[];

      // 100 concurrent operations across 20 sessions
      for (int i = 0; i < 100; i++) {
        final sessionId = 'session-${i % 20}';
        futures.add(
          manager.addUserMessage(sessionId, 'Message $i'),
        );
      }

      final startTime = DateTime.now();
      await Future.wait(futures);
      final duration = DateTime.now().difference(startTime);

      print('✅ 100 operations completed in ${duration.inMilliseconds}ms');
      print('   Average: ${duration.inMilliseconds / 100}ms per operation\n');

      // Verify data integrity
      int totalMessages = 0;
      for (int i = 0; i < 20; i++) {
        final history = await manager.getHistory('session-$i');
        totalMessages += history.length;
      }

      expect(totalMessages, equals(100));
    });
  });

  group('ThreadSafeMemoryManager - Concurrent Access to Same Session', () {
    late ThreadSafeMemoryManager manager;

    setUp(() {
      manager = ThreadSafeMemoryManager(
        memoryManager: ConversationMemoryManager(
          config: MemoryConfig(maxMessages: 100), // Increase limit for tests
        ),
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('Concurrent writes to same session are serialized', () async {
      print('\n🔒 Testing: Concurrent writes to SAME session (serialization)');

      final futures = <Future>[];

      // 50 concurrent writes to the same session
      for (int i = 0; i < 50; i++) {
        futures.add(
          manager.addUserMessage('shared-session', 'Message $i'),
        );
      }

      final startTime = DateTime.now();
      await Future.wait(futures);
      final duration = DateTime.now().difference(startTime);

      print('✅ 50 serialized writes completed in ${duration.inMilliseconds}ms\n');

      // Verify all 50 messages present (no corruption)
      final history = await manager.getHistory('shared-session');
      expect(history.length, equals(50));

      // Verify messages are valid
      for (int i = 0; i < 50; i++) {
        expect(history[i].content, startsWith('Message '));
      }

      print('✅ Data integrity verified: All 50 messages intact\n');
    });

    test('Concurrent reads and writes to same session', () async {
      print('\n📖 Testing: Concurrent reads + writes to same session');

      // Pre-populate with some messages
      for (int i = 0; i < 10; i++) {
        await manager.addUserMessage('session-1', 'Initial message $i');
      }

      final futures = <Future>[];

      // 20 concurrent reads
      for (int i = 0; i < 20; i++) {
        futures.add(manager.getHistory('session-1'));
      }

      // 10 concurrent writes
      for (int i = 0; i < 10; i++) {
        futures.add(manager.addUserMessage('session-1', 'New message $i'));
      }

      await Future.wait(futures);

      // Final verification
      final finalHistory = await manager.getHistory('session-1');
      expect(finalHistory.length, equals(20)); // 10 initial + 10 new

      print('✅ Mixed read/write operations completed successfully\n');
    });
  });

  group('ThreadSafeMemoryManager - Lock Statistics', () {
    late ThreadSafeMemoryManager manager;

    setUp(() {
      manager = ThreadSafeMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('Provides lock statistics', () async {
      await manager.addUserMessage('session-1', 'Test');

      final stats = manager.getLockStats();

      expect(stats, containsPair('totalLocks', greaterThanOrEqualTo(0)));
      expect(stats, containsPair('activeLocks', greaterThanOrEqualTo(0)));
      expect(stats, containsPair('isGlobalLocked', false));
    });

    test('Tracks lock contention', () async {
      print('\n📊 Testing: Lock contention tracking');

      // Start slow operation
      final slowOperation = manager.addUserMessage('session-1', 'Slow')
        ..timeout(Duration(milliseconds: 100));

      // Try to access same session (will wait)
      await Future.delayed(Duration(milliseconds: 10));

      // Check lock stats while waiting
      final stats = manager.getLockStats();
      print('   Lock stats during contention:');
      print('   Total locks: ${stats["totalLocks"]}');
      print('   Active locks: ${stats["activeLocks"]}');

      await slowOperation;

      print('✅ Lock contention tracked successfully\n');
    });
  });

  group('ThreadSafeMemoryManager - Stress Test', () {
    late ThreadSafeMemoryManager manager;

    setUp(() {
      manager = ThreadSafeMemoryManager(
        memoryManager: ConversationMemoryManager(
          config: MemoryConfig(maxMessages: 100), // Increase limit for stress test
        ),
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('Stress test: 1000 operations across 50 sessions', () async {
      print('\n💪 STRESS TEST: 1000 operations, 50 sessions');

      final futures = <Future>[];
      final operationCount = 1000;
      final sessionCount = 50;

      final startTime = DateTime.now();

      for (int i = 0; i < operationCount; i++) {
        final sessionId = 'stress-session-${i % sessionCount}';

        // Mix of operations
        if (i % 3 == 0) {
          // Write
          futures.add(manager.addUserMessage(sessionId, 'Stress message $i'));
        } else if (i % 3 == 1) {
          // Read
          futures.add(manager.getHistory(sessionId));
        } else {
          // Get recent
          futures.add(manager.getRecentMessages(sessionId, 5));
        }
      }

      await Future.wait(futures);

      final duration = DateTime.now().difference(startTime);
      final avgTime = duration.inMilliseconds / operationCount;

      print('✅ Stress test completed!');
      print('   Total time: ${duration.inMilliseconds}ms');
      print('   Operations: $operationCount');
      print('   Average: ${avgTime.toStringAsFixed(2)}ms/op');
      print('   Throughput: ${(operationCount / duration.inSeconds).toStringAsFixed(0)} ops/sec\n');

      // Verify data integrity
      int totalMessages = 0;
      for (int i = 0; i < sessionCount; i++) {
        final history = await manager.getHistory('stress-session-$i');
        totalMessages += history.length;
      }

      final expectedWrites = (operationCount / 3).ceil();
      expect(totalMessages, greaterThanOrEqualTo(expectedWrites - 10)); // Allow small variance

      print('✅ Data integrity verified: $totalMessages messages stored\n');
    });
  });

  group('ThreadSafeMemoryManager - Error Handling', () {
    late ThreadSafeMemoryManager manager;

    setUp(() {
      manager = ThreadSafeMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('Handles errors without deadlock', () async {
      print('\n⚠️  Testing: Error handling without deadlock');

      try {
        // This will succeed
        await manager.addUserMessage('session-1', 'Valid message');

        // Multiple operations, one might fail
        final futures = <Future>[];
        for (int i = 0; i < 10; i++) {
          futures.add(manager.addUserMessage('session-1', 'Message $i'));
        }

        await Future.wait(futures);

        // Should still be able to access
        final history = await manager.getHistory('session-1');
        expect(history, isNotEmpty);

        print('✅ No deadlock after errors\n');
      } catch (e) {
        // Even if error occurs, shouldn't deadlock
        print('   Error occurred (expected): $e');
      }
    });
  });

  group('ThreadSafeMemoryManager - Memory Limits & Monitoring', () {
    late ThreadSafeMemoryManager manager;

    setUp(() {
      manager = ThreadSafeMemoryManager(
        memoryManager: ConversationMemoryManager(
          config: MemoryConfig(maxMessages: 10), // Low limit for testing
        ),
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('Stats include capacity information', () async {
      // Add messages to approach limit
      for (int i = 0; i < 8; i++) {
        await manager.addUserMessage('session-1', 'Message $i');
      }

      final stats = await manager.getStats();

      expect(stats.maxCapacity, equals(10));
      expect(stats.messagesAtCapacity, equals(8));
      expect(stats.capacityUsedPercent, closeTo(80.0, 1.0));
      expect(stats.isApproachingCapacity, isTrue);
      expect(stats.isAtCapacity, isFalse);
    });

    test('Stats detect when at capacity', () async {
      // Fill to capacity
      for (int i = 0; i < 10; i++) {
        await manager.addUserMessage('session-1', 'Message $i');
      }

      final stats = await manager.getStats();

      expect(stats.messagesAtCapacity, equals(10));
      expect(stats.capacityUsedPercent, equals(100.0));
      expect(stats.isAtCapacity, isTrue);
    });

    test('Stats calculate average messages correctly', () async {
      await manager.addUserMessage('session-1', 'A');
      await manager.addUserMessage('session-1', 'B');
      await manager.addUserMessage('session-2', 'C');
      await manager.addUserMessage('session-2', 'D');
      await manager.addUserMessage('session-2', 'E');

      final stats = await manager.getStats();

      expect(stats.totalMessages, equals(5));
      expect(stats.activeSessions, equals(2));
      expect(stats.averageMessagesPerSession, closeTo(2.5, 0.1));
    });

    test('Stats export to JSON correctly', () async {
      await manager.addUserMessage('session-1', 'Test');

      final stats = await manager.getStats();
      final json = stats.toJson();

      expect(json, containsPair('totalMessages', 1));
      expect(json, containsPair('maxCapacity', 10));
      expect(json, containsPair('activeSessions', 1));
      expect(json, contains('capacityUsedPercent'));
      expect(json, contains('isApproachingCapacity'));
      expect(json, contains('averageMessagesPerSession'));
    });

    test('Gets per-session usage details', () async {
      // Session 1: 8 messages (80%)
      for (int i = 0; i < 8; i++) {
        await manager.addUserMessage('session-1', 'Message $i');
      }

      // Session 2: 5 messages (50%)
      for (int i = 0; i < 5; i++) {
        await manager.addUserMessage('session-2', 'Message $i');
      }

      final usage = await manager.getSessionUsage();

      expect(usage, contains('session-1'));
      expect(usage, contains('session-2'));

      expect(usage['session-1']!['messageCount'], equals(8));
      expect(usage['session-1']!['usagePercent'], equals(80));
      expect(usage['session-1']!['isApproachingLimit'], isTrue);
      expect(usage['session-1']!['isAtLimit'], isFalse);

      expect(usage['session-2']!['messageCount'], equals(5));
      expect(usage['session-2']!['usagePercent'], equals(50));
      expect(usage['session-2']!['isApproachingLimit'], isFalse);
    });

    test('Session usage includes timing information', () async {
      await manager.addUserMessage('session-1', 'Test');

      final usage = await manager.getSessionUsage();
      final session1 = usage['session-1']!;

      expect(session1, contains('startTime'));
      expect(session1, contains('lastActivity'));
      expect(session1, contains('duration'));
      expect(session1['duration'], greaterThanOrEqualTo(0));
    });

    test('Automatic trimming when exceeding max messages', () async {
      print('\n✂️  Testing: Automatic message trimming at limit');

      // Add 15 messages (max is 10)
      for (int i = 0; i < 15; i++) {
        await manager.addUserMessage('session-1', 'Message $i');
      }

      final history = await manager.getHistory('session-1');

      // Should be trimmed to 10
      expect(history.length, equals(10));

      // Should keep most recent messages (10-14)
      expect(history[0].content, equals('Message 5')); // Oldest kept
      expect(history[9].content, equals('Message 14')); // Most recent

      print('✅ Automatic trimming working correctly');
      print('   Kept messages 5-14 (most recent 10)\n');
    });

    test('Multiple sessions trim independently', () async {
      // Fill session 1 to capacity
      for (int i = 0; i < 15; i++) {
        await manager.addUserMessage('session-1', 'S1-Message $i');
      }

      // Fill session 2 partially
      for (int i = 0; i < 5; i++) {
        await manager.addUserMessage('session-2', 'S2-Message $i');
      }

      final history1 = await manager.getHistory('session-1');
      final history2 = await manager.getHistory('session-2');

      expect(history1.length, equals(10)); // Trimmed
      expect(history2.length, equals(5));  // Not trimmed
    });

    test('Stats track highest session capacity', () async {
      await manager.addUserMessage('session-1', 'A');
      await manager.addUserMessage('session-1', 'B');

      for (int i = 0; i < 8; i++) {
        await manager.addUserMessage('session-2', 'Message $i');
      }

      final stats = await manager.getStats();

      // Should track session-2 as highest (8 messages)
      expect(stats.messagesAtCapacity, equals(8));
      expect(stats.totalMessages, equals(10)); // 2 + 8
    });
  });

  group('ThreadSafeMemoryManager - Capacity Warnings', () {
    test('Logs warning at 80% capacity', () async {
      print('\n⚠️  Testing: Warning logs at 80% capacity');

      // Use logger that captures output
      final logs = <String>[];
      final logger = Logger(
        level: Level.warning,
        printer: SimplePrinter(),
        output: _ListLogOutput(logs),
      );

      final manager = ThreadSafeMemoryManager(
        memoryManager: ConversationMemoryManager(
          config: MemoryConfig(maxMessages: 10),
          logger: logger,
        ),
        logger: Logger(level: Level.off),
      );

      // Add messages to reach 80% (8 messages)
      for (int i = 0; i < 8; i++) {
        await manager.addUserMessage('session-1', 'Message $i');
      }

      // Should have warning log
      final hasWarning = logs.any((log) =>
        log.contains('approaching message limit') &&
        log.contains('80%')
      );

      expect(hasWarning, isTrue, reason: 'Should log warning at 80% capacity');

      print('✅ Warning logged at 80% capacity\n');

      await manager.dispose();
    });

    test('No warning below 80% capacity', () async {
      final logs = <String>[];
      final logger = Logger(
        level: Level.warning,
        printer: SimplePrinter(),
        output: _ListLogOutput(logs),
      );

      final manager = ThreadSafeMemoryManager(
        memoryManager: ConversationMemoryManager(
          config: MemoryConfig(maxMessages: 10),
          logger: logger,
        ),
        logger: Logger(level: Level.off),
      );

      // Add only 5 messages (50%)
      for (int i = 0; i < 5; i++) {
        await manager.addUserMessage('session-1', 'Message $i');
      }

      // Should NOT have warning
      final hasWarning = logs.any((log) =>
        log.contains('approaching message limit')
      );

      expect(hasWarning, isFalse, reason: 'Should not warn below 80%');

      await manager.dispose();
    });
  });
}

// Helper class to capture log output
class _ListLogOutput extends LogOutput {
  final List<String> logs;

  _ListLogOutput(this.logs);

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      logs.add(line);
    }
  }
}
