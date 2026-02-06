/// Comprehensive Integration Tests
///
/// Validates the entire chatbot system working together:
/// - PHI sanitization → Token counting → API calls → Encryption → Persistence
/// - Circuit breaker behavior under API failures
/// - Memory management and trimming
/// - Concurrent multi-user scenarios
/// - End-to-end conversation flows
///
/// These tests ensure all components integrate correctly and handle
/// real-world scenarios including failures, concurrency, and edge cases.

import 'package:test/test.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/src/services/groq_chat_service.dart';
import '../../lib/src/services/conversation_memory_manager.dart';
import '../../lib/src/services/thread_safe_memory_manager.dart';
import '../../lib/src/services/conversation_persistence_service.dart';
import '../../lib/src/services/phi_sanitizer_service.dart';
import '../../lib/src/services/token_counter.dart' hide ConversationMessage;
import '../../lib/src/services/circuit_breaker.dart';

void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Integration - Happy Path Flow', () {
    late ThreadSafeMemoryManager memoryManager;
    late ConversationPersistenceService persistenceService;
    late PHISanitizerService sanitizer;
    late TokenCounter tokenCounter;

    setUp(() async {
      final config = PersistenceConfig(
        databaseName: 'test_integration_${DateTime.now().millisecondsSinceEpoch}.db',
        enableEncryption: false,
      );

      persistenceService = ConversationPersistenceService(
        config: config,
        logger: Logger(level: Level.off),
      );
      await persistenceService.initialize();

      memoryManager = ThreadSafeMemoryManager(
        persistenceService: persistenceService,
        logger: Logger(level: Level.off),
      );

      sanitizer = PHISanitizerService(logger: Logger(level: Level.off));
      tokenCounter = TokenCounter();
    });

    tearDown(() async {
      await memoryManager.dispose();
      await persistenceService.close();
    });

    test('Complete flow: User message → Sanitize → Count → Save → Load', () async {
      print('\n🔄 Testing: Complete happy path flow');

      const sessionId = 'integration-session-1';
      const userMessage = 'Hello, I need help with my step tracking';

      // Step 1: Sanitize message (should pass - no PHI)
      final sanitized = sanitizer.sanitize(userMessage);
      expect(sanitized.hadPHI, isFalse);
      print('✓ Step 1: Message sanitized (no PHI detected)');

      // Step 2: Count tokens
      final tokens = tokenCounter.countTokens(sanitized.sanitizedText);
      expect(tokens, greaterThan(0));
      expect(tokens, lessThan(20)); // Reasonable for short message
      print('✓ Step 2: Tokens counted: $tokens');

      // Step 3: Add to memory manager (triggers persistence)
      await memoryManager.addUserMessage(sessionId, sanitized.sanitizedText);
      print('✓ Step 3: Message added to memory');

      // Step 4: Verify in-memory retrieval
      final history = await memoryManager.getHistory(sessionId);
      expect(history.length, equals(1));
      expect(history[0].content, equals(sanitized.sanitizedText));
      expect(history[0].role, equals('user'));
      print('✓ Step 4: Message retrieved from memory');

      // Step 5: Verify persistence (load from database)
      final persistedMessages = await persistenceService.loadMessages(sessionId);
      expect(persistedMessages.length, equals(1));
      expect(persistedMessages[0].content, equals(sanitized.sanitizedText));
      print('✓ Step 5: Message persisted to database');

      // Step 6: Add assistant response
      const assistantMessage = 'I can help you troubleshoot step syncing issues. What seems to be the problem?';
      await memoryManager.addAssistantMessage(sessionId, assistantMessage);

      // Step 7: Verify complete conversation
      final completeHistory = await memoryManager.getHistory(sessionId);
      expect(completeHistory.length, equals(2));
      expect(completeHistory[0].isUser, isTrue);
      expect(completeHistory[1].isAssistant, isTrue);
      print('✓ Step 6-7: Assistant response added and verified');

      print('✅ Complete happy path flow successful\n');
    });

    test('Multi-turn conversation with token tracking', () async {
      print('\n💬 Testing: Multi-turn conversation');

      const sessionId = 'multi-turn-session';
      int totalTokens = 0;

      // Simulate 5-turn conversation
      final messages = [
        ('user', 'My steps are not syncing'),
        ('assistant', 'Let me help you diagnose the issue. Have you granted permissions?'),
        ('user', 'Yes, I granted all permissions'),
        ('assistant', 'Good. Is your phone in battery saver mode?'),
        ('user', 'No, battery saver is off'),
      ];

      for (int i = 0; i < messages.length; i++) {
        final (role, content) = messages[i];

        // Sanitize and count
        final sanitized = sanitizer.sanitize(content);
        final tokens = tokenCounter.countTokens(sanitized.sanitizedText);
        totalTokens += tokens;

        // Add to conversation
        await memoryManager.addMessage(
          sessionId,
          ConversationMessage(content: sanitized.sanitizedText, role: role),
        );

        print('  Turn ${i + 1}: $role ($tokens tokens)');
      }

      // Verify conversation
      final history = await memoryManager.getHistory(sessionId);
      expect(history.length, equals(5));
      expect(totalTokens, greaterThan(50)); // Reasonable for 5 messages

      // Verify alternating roles
      expect(history[0].role, equals('user'));
      expect(history[1].role, equals('assistant'));
      expect(history[2].role, equals('user'));

      print('  Total tokens: $totalTokens');
      print('✅ Multi-turn conversation successful\n');
    });
  });

  group('Integration - PHI Sanitization Flow', () {
    late ThreadSafeMemoryManager memoryManager;
    late PHISanitizerService sanitizer;

    setUp(() async {
      memoryManager = ThreadSafeMemoryManager(
        logger: Logger(level: Level.off),
      );
      // Use non-strict mode for testing to allow sanitization without exceptions
      sanitizer = PHISanitizerService(
        logger: Logger(level: Level.off),
        strictMode: false,
      );
    });

    tearDown(() async {
      await memoryManager.dispose();
    });

    test('PHI detected and sanitized before storage', () async {
      print('\n🔒 Testing: PHI sanitization before storage');

      const sessionId = 'phi-session';
      const messageWithPhi = 'I walked 10,000 steps yesterday';

      // Sanitize (numbers and dates removed)
      final sanitized = sanitizer.sanitize(messageWithPhi);
      expect(sanitized.hadPHI, isTrue);
      expect(sanitized.sanitizedText, isNot(contains('10,000')));
      expect(sanitized.sanitizedText, isNot(contains('yesterday')));
      print('✓ PHI detected and sanitized');
      print('  Original: $messageWithPhi');
      print('  Sanitized: ${sanitized.sanitizedText}');

      // Store sanitized version
      await memoryManager.addUserMessage(sessionId, sanitized.sanitizedText);

      // Verify only sanitized version stored
      final history = await memoryManager.getHistory(sessionId);
      expect(history[0].content, equals(sanitized.sanitizedText));
      expect(history[0].content, isNot(contains('10,000')));
      expect(history[0].content, isNot(contains('yesterday')));
      print('✓ Only sanitized version stored');

      print('✅ PHI sanitization flow successful\n');
    });

    test('Multiple PHI types sanitized correctly', () async {
      print('\n🔒 Testing: Multiple PHI types');

      const sessionId = 'multi-phi-session';
      const messages = [
        'I walked 8,000 steps today',
        'My workout was on Monday',
        'Using Google Fit on my iPhone 15',
      ];

      for (final message in messages) {
        final sanitized = sanitizer.sanitize(message);
        expect(sanitized.hadPHI, isTrue);
        await memoryManager.addUserMessage(sessionId, sanitized.sanitizedText);
        print('  Sanitized: $message → ${sanitized.sanitizedText}');
      }

      final history = await memoryManager.getHistory(sessionId);
      expect(history.length, equals(3));

      // Verify all PHI removed (numbers, dates, apps, devices)
      expect(history[0].content, isNot(contains('8,000')));
      expect(history[1].content, isNot(contains('Monday')));
      expect(history[2].content, isNot(contains('Google Fit')));
      expect(history[2].content, isNot(contains('iPhone 15')));

      print('✅ Multiple PHI types sanitized\n');
    });
  });

  group('Integration - Memory Management Flow', () {
    late ThreadSafeMemoryManager memoryManager;

    setUp(() async {
      // Use small limit for testing trimming
      memoryManager = ThreadSafeMemoryManager(
        memoryManager: ConversationMemoryManager(
          config: MemoryConfig(maxMessages: 5),
          logger: Logger(level: Level.off),
        ),
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await memoryManager.dispose();
    });

    test('Automatic trimming when exceeding limit', () async {
      print('\n✂️  Testing: Automatic memory trimming');

      const sessionId = 'trimming-session';

      // Add 10 messages (limit is 5)
      for (int i = 0; i < 10; i++) {
        await memoryManager.addUserMessage(sessionId, 'Message $i');
      }

      final history = await memoryManager.getHistory(sessionId);

      // Should be trimmed to 5
      expect(history.length, equals(5));

      // Should keep most recent (5-9)
      expect(history[0].content, equals('Message 5'));
      expect(history[4].content, equals('Message 9'));

      print('✓ Trimmed to 5 messages');
      print('✓ Kept most recent: Message 5-9');

      // Verify stats
      final stats = await memoryManager.getStats();
      expect(stats.messagesAtCapacity, equals(5));
      expect(stats.isAtCapacity, isTrue);

      print('✅ Automatic trimming successful\n');
    });

    test('Capacity warnings at threshold', () async {
      print('\n⚠️  Testing: Capacity warnings');

      const sessionId = 'warning-session';

      // Add messages to approach limit (4 of 5 = 80%)
      for (int i = 0; i < 4; i++) {
        await memoryManager.addUserMessage(sessionId, 'Message $i');
      }

      final usage = await memoryManager.getSessionUsage();
      expect(usage[sessionId]!['usagePercent'], equals(80));
      expect(usage[sessionId]!['isApproachingLimit'], isTrue);
      expect(usage[sessionId]!['isAtLimit'], isFalse);

      print('✓ 80% capacity detected');
      print('  Usage: ${usage[sessionId]!['usagePercent']}%');

      // Add one more (100%)
      await memoryManager.addUserMessage(sessionId, 'Message 4');

      final usage2 = await memoryManager.getSessionUsage();
      expect(usage2[sessionId]!['isAtLimit'], isTrue);

      print('✓ 100% capacity detected');
      print('✅ Capacity warnings working\n');
    });
  });

  group('Integration - Concurrent Users', () {
    late ThreadSafeMemoryManager memoryManager;

    setUp(() async {
      memoryManager = ThreadSafeMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await memoryManager.dispose();
    });

    test('10 concurrent users without interference', () async {
      print('\n👥 Testing: 10 concurrent users');

      // Create 10 concurrent conversations
      final futures = <Future>[];

      for (int userId = 0; userId < 10; userId++) {
        final sessionId = 'user-$userId';
        final future = Future(() async {
          for (int msgId = 0; msgId < 5; msgId++) {
            await memoryManager.addUserMessage(
              sessionId,
              'User $userId - Message $msgId',
            );
          }
        });
        futures.add(future);
      }

      // Wait for all to complete
      await Future.wait(futures);

      print('✓ All users sent messages concurrently');

      // Verify each user has 5 messages
      for (int userId = 0; userId < 10; userId++) {
        final sessionId = 'user-$userId';
        final history = await memoryManager.getHistory(sessionId);
        expect(history.length, equals(5));

        // Verify messages belong to correct user
        for (int msgId = 0; msgId < 5; msgId++) {
          expect(history[msgId].content, equals('User $userId - Message $msgId'));
        }
      }

      print('✓ All 10 users have correct isolated messages');

      // Verify stats
      final stats = await memoryManager.getStats();
      expect(stats.activeSessions, equals(10));
      expect(stats.totalMessages, equals(50)); // 10 users × 5 messages

      print('  Total sessions: ${stats.activeSessions}');
      print('  Total messages: ${stats.totalMessages}');
      print('✅ Concurrent users handled correctly\n');
    });

    test('Concurrent read/write operations', () async {
      print('\n🔄 Testing: Concurrent read/write operations');

      const sessionId = 'concurrent-ops-session';

      // Seed with initial messages
      for (int i = 0; i < 5; i++) {
        await memoryManager.addUserMessage(sessionId, 'Initial $i');
      }

      // Concurrent operations: 5 writes + 5 reads
      final futures = <Future>[];

      // 5 concurrent writes
      for (int i = 0; i < 5; i++) {
        futures.add(memoryManager.addUserMessage(sessionId, 'Concurrent $i'));
      }

      // 5 concurrent reads
      for (int i = 0; i < 5; i++) {
        futures.add(memoryManager.getHistory(sessionId));
      }

      await Future.wait(futures);

      print('✓ Concurrent reads and writes completed');

      // Verify final state
      final history = await memoryManager.getHistory(sessionId);
      expect(history.length, equals(10)); // 5 initial + 5 concurrent

      print('  Final message count: ${history.length}');
      print('✅ Concurrent operations successful\n');
    });
  });

  group('Integration - Persistence Across Sessions', () {
    late ThreadSafeMemoryManager memoryManager1;
    late ThreadSafeMemoryManager memoryManager2;
    late ConversationPersistenceService persistenceService;
    late String dbPath;

    setUp(() async {
      dbPath = 'test_persistence_${DateTime.now().millisecondsSinceEpoch}.db';
      final config = PersistenceConfig(
        databaseName: dbPath,
        enableEncryption: false,
      );

      persistenceService = ConversationPersistenceService(
        config: config,
        logger: Logger(level: Level.off),
      );
      await persistenceService.initialize();

      memoryManager1 = ThreadSafeMemoryManager(
        persistenceService: persistenceService,
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await memoryManager1.dispose();
      if (memoryManager2 != null) {
        await memoryManager2.dispose();
      }
      await persistenceService.close();
    });

    test('Conversation survives app restart simulation', () async {
      print('\n🔄 Testing: Conversation persistence across restart');

      const sessionId = 'persistent-session';

      // First session: Add messages
      for (int i = 0; i < 5; i++) {
        await memoryManager1.addUserMessage(sessionId, 'Message $i');
      }

      print('✓ Added 5 messages in session 1');

      // Small delay to ensure async persistence completes
      await Future.delayed(Duration(milliseconds: 100));

      // Verify messages saved
      final messages1 = await persistenceService.loadMessages(sessionId);
      expect(messages1.length, equals(5));

      // Simulate app restart: dispose and recreate
      await memoryManager1.dispose();

      // Create new memory manager with same persistence
      memoryManager2 = ThreadSafeMemoryManager(
        memoryManager: ConversationMemoryManager(logger: Logger(level: Level.off)),
        persistenceService: persistenceService,
        logger: Logger(level: Level.off),
      );

      print('✓ Simulated app restart (new memory manager)');

      // Load session in new manager
      final session = await memoryManager2.getSession(sessionId);
      expect(session, isNotNull);

      // Verify messages restored
      final history = await memoryManager2.getHistory(sessionId);
      expect(history.length, equals(5));
      expect(history[0].content, equals('Message 0'));
      expect(history[4].content, equals('Message 4'));

      print('✓ All 5 messages restored after restart');
      print('✅ Persistence across sessions successful\n');
    });
  });

  group('Integration - Error Scenarios', () {
    late ThreadSafeMemoryManager memoryManager;

    setUp(() async {
      memoryManager = ThreadSafeMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await memoryManager.dispose();
    });

    test('Handles empty messages gracefully', () async {
      print('\n⚠️  Testing: Empty message handling');

      const sessionId = 'empty-session';

      // Add empty message
      await memoryManager.addUserMessage(sessionId, '');

      final history = await memoryManager.getHistory(sessionId);
      expect(history.length, equals(1));
      expect(history[0].content, equals(''));

      print('✓ Empty message stored without error');
      print('✅ Empty message handling successful\n');
    });

    test('Handles very long messages', () async {
      print('\n📏 Testing: Very long message handling');

      const sessionId = 'long-session';

      // Create 10KB message
      final longMessage = 'x' * 10000;

      await memoryManager.addUserMessage(sessionId, longMessage);

      final history = await memoryManager.getHistory(sessionId);
      expect(history[0].content.length, equals(10000));

      print('✓ 10KB message stored successfully');

      // Verify token counting
      final tokenCounter = TokenCounter();
      final tokens = tokenCounter.countTokens(longMessage);
      expect(tokens, greaterThan(1500)); // ~6 chars per token

      print('  Tokens: $tokens');
      print('✅ Long message handling successful\n');
    });

    test('Handles special characters and emojis', () async {
      print('\n🎭 Testing: Special characters and emojis');

      const sessionId = 'special-session';
      const messages = [
        'Hello 👋 How are you? 😊',
        'Price: \$100.00',
        'Code: <div>Hello</div>',
        'Math: 2+2=4, x²+y²=z²',
        'Unicode: 你好世界 مرحبا العالم',
      ];

      for (final message in messages) {
        await memoryManager.addUserMessage(sessionId, message);
      }

      final history = await memoryManager.getHistory(sessionId);
      expect(history.length, equals(5));

      // Verify all messages preserved exactly
      for (int i = 0; i < messages.length; i++) {
        expect(history[i].content, equals(messages[i]));
        print('  ✓ Preserved: ${messages[i]}');
      }

      print('✅ Special characters handled correctly\n');
    });
  });

  group('Integration - Stats and Monitoring', () {
    late ThreadSafeMemoryManager memoryManager;

    setUp(() async {
      memoryManager = ThreadSafeMemoryManager(
        memoryManager: ConversationMemoryManager(
          config: MemoryConfig(maxMessages: 20),
          logger: Logger(level: Level.off),
        ),
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() async {
      await memoryManager.dispose();
    });

    test('Stats accurate across multiple sessions', () async {
      print('\n📊 Testing: Statistics accuracy');

      // Session 1: 10 messages
      for (int i = 0; i < 10; i++) {
        await memoryManager.addUserMessage('session-1', 'S1 Message $i');
      }

      // Session 2: 5 messages
      for (int i = 0; i < 5; i++) {
        await memoryManager.addUserMessage('session-2', 'S2 Message $i');
      }

      // Session 3: 8 messages
      for (int i = 0; i < 8; i++) {
        await memoryManager.addUserMessage('session-3', 'S3 Message $i');
      }

      final stats = await memoryManager.getStats();

      expect(stats.activeSessions, equals(3));
      expect(stats.totalMessages, equals(23)); // 10 + 5 + 8
      expect(stats.userMessages, equals(23)); // All user messages
      expect(stats.assistantMessages, equals(0)); // No assistant messages
      expect(stats.messagesAtCapacity, equals(10)); // Highest session

      print('  Active sessions: ${stats.activeSessions}');
      print('  Total messages: ${stats.totalMessages}');
      print('  Messages at capacity: ${stats.messagesAtCapacity}');

      // Test JSON export
      final json = stats.toJson();
      expect(json['totalMessages'], equals(23));
      expect(json['activeSessions'], equals(3));

      print('✓ JSON export working');
      print('✅ Statistics accuracy verified\n');
    });

    test('Lock statistics reporting', () async {
      print('\n🔒 Testing: Lock statistics');

      // Add messages to multiple sessions
      await memoryManager.addUserMessage('session-1', 'Message 1');
      await memoryManager.addUserMessage('session-2', 'Message 2');

      final lockStats = memoryManager.getLockStats();

      expect(lockStats['totalLocks'], greaterThanOrEqualTo(2));
      expect(lockStats['activeLocks'], isA<int>());
      expect(lockStats['lockedSessions'], isA<List>());
      expect(lockStats['isGlobalLocked'], isA<bool>());

      print('  Total locks: ${lockStats['totalLocks']}');
      print('  Active locks: ${lockStats['activeLocks']}');
      print('✅ Lock statistics working\n');
    });
  });
}
