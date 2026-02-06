/// Tests for Production Conversation Memory Manager
///
/// Validates:
/// - Session creation and management
/// - Message storage and retrieval
/// - History management
/// - Session expiration
/// - Memory limits and trimming
/// - Statistics tracking
/// - Export/import functionality

import 'package:test/test.dart';
import 'package:logger/logger.dart';
import '../../lib/src/services/conversation_memory_manager.dart';
import '../../lib/src/services/groq_chat_service.dart';

void main() {
  group('ConversationMemoryManager - Configuration', () {
    test('Creates with default config', () {
      final manager = ConversationMemoryManager();

      expect(manager.config.maxMessages, equals(20));
      expect(manager.config.maxTokens, equals(4000));
      expect(manager.config.enableSummarization, isFalse);
      expect(manager.config.sessionTimeout, equals(Duration(hours: 24)));

      manager.dispose();
    });

    test('Creates with custom config', () {
      final config = MemoryConfig(
        maxMessages: 10,
        maxTokens: 2000,
        enableSummarization: true,
        sessionTimeout: Duration(hours: 1),
      );
      final manager = ConversationMemoryManager(
        config: config,
        logger: Logger(level: Level.off),
      );

      expect(manager.config.maxMessages, equals(10));
      expect(manager.config.maxTokens, equals(2000));
      expect(manager.config.enableSummarization, isTrue);
      expect(manager.config.sessionTimeout, equals(Duration(hours: 1)));

      manager.dispose();
    });
  });

  group('ConversationMemoryManager - Session Management', () {
    late ConversationMemoryManager manager;

    setUp(() {
      manager = ConversationMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('Creates new session', () {
      final session = manager.getSession('test-session-1');

      expect(session.id, equals('test-session-1'));
      expect(session.messageCount, equals(0));
      expect(manager.sessionCount, equals(1));
      expect(manager.hasSession('test-session-1'), isTrue);
    });

    test('Returns existing session', () {
      final session1 = manager.getSession('test-session-1');
      final session2 = manager.getSession('test-session-1');

      expect(identical(session1, session2), isTrue);
      expect(manager.sessionCount, equals(1));
    });

    test('Creates multiple sessions', () {
      manager.getSession('session-1');
      manager.getSession('session-2');
      manager.getSession('session-3');

      expect(manager.sessionCount, equals(3));
      expect(manager.hasSession('session-1'), isTrue);
      expect(manager.hasSession('session-2'), isTrue);
      expect(manager.hasSession('session-3'), isTrue);
    });

    test('Gets active session IDs', () {
      manager.getSession('session-1');
      manager.getSession('session-2');

      final ids = manager.getActiveSessionIds();

      expect(ids.length, equals(2));
      expect(ids, contains('session-1'));
      expect(ids, contains('session-2'));
    });

    test('Clears single session', () {
      manager.getSession('session-1');
      manager.getSession('session-2');

      expect(manager.sessionCount, equals(2));

      manager.clearSession('session-1');

      expect(manager.sessionCount, equals(1));
      expect(manager.hasSession('session-1'), isFalse);
      expect(manager.hasSession('session-2'), isTrue);
    });

    test('Clears all sessions', () {
      manager.getSession('session-1');
      manager.getSession('session-2');
      manager.getSession('session-3');

      expect(manager.sessionCount, equals(3));

      manager.clearAllSessions();

      expect(manager.sessionCount, equals(0));
    });
  });

  group('ConversationMemoryManager - Message Management', () {
    late ConversationMemoryManager manager;

    setUp(() {
      manager = ConversationMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('Adds user message', () {
      manager.addUserMessage('session-1', 'Hello');

      final history = manager.getHistory('session-1');

      expect(history.length, equals(1));
      expect(history[0].content, equals('Hello'));
      expect(history[0].role, equals('user'));
      expect(history[0].isUser, isTrue);
      expect(history[0].isAssistant, isFalse);
    });

    test('Adds assistant message', () {
      manager.addAssistantMessage('session-1', 'Hi there');

      final history = manager.getHistory('session-1');

      expect(history.length, equals(1));
      expect(history[0].content, equals('Hi there'));
      expect(history[0].role, equals('assistant'));
      expect(history[0].isUser, isFalse);
      expect(history[0].isAssistant, isTrue);
    });

    test('Adds multiple messages in order', () {
      manager.addUserMessage('session-1', 'Message 1');
      manager.addAssistantMessage('session-1', 'Response 1');
      manager.addUserMessage('session-1', 'Message 2');
      manager.addAssistantMessage('session-1', 'Response 2');

      final history = manager.getHistory('session-1');

      expect(history.length, equals(4));
      expect(history[0].content, equals('Message 1'));
      expect(history[1].content, equals('Response 1'));
      expect(history[2].content, equals('Message 2'));
      expect(history[3].content, equals('Response 2'));
    });

    test('Returns immutable history', () {
      manager.addUserMessage('session-1', 'Test');

      final history = manager.getHistory('session-1');

      expect(
        () => history.add(ConversationMessage(content: 'Hack', role: 'user')),
        throwsUnsupportedError,
      );
    });

    test('Gets recent messages', () {
      for (int i = 1; i <= 10; i++) {
        manager.addUserMessage('session-1', 'Message $i');
      }

      final recent = manager.getRecentMessages('session-1', 3);

      expect(recent.length, equals(3));
      expect(recent[0].content, equals('Message 8'));
      expect(recent[1].content, equals('Message 9'));
      expect(recent[2].content, equals('Message 10'));
    });

    test('Gets all messages when requesting more than exist', () {
      manager.addUserMessage('session-1', 'Message 1');
      manager.addUserMessage('session-1', 'Message 2');

      final recent = manager.getRecentMessages('session-1', 10);

      expect(recent.length, equals(2));
    });
  });

  group('ConversationMemoryManager - Message Limits', () {
    test('Trims messages when exceeding max', () {
      final config = MemoryConfig(maxMessages: 5);
      final manager = ConversationMemoryManager(
        config: config,
        logger: Logger(level: Level.off),
      );

      // Add 8 messages (exceeds max of 5)
      for (int i = 1; i <= 8; i++) {
        manager.addUserMessage('session-1', 'Message $i');
      }

      final history = manager.getHistory('session-1');

      // Should only keep last 5 messages
      expect(history.length, equals(5));
      expect(history[0].content, equals('Message 4'));
      expect(history[4].content, equals('Message 8'));

      manager.dispose();
    });

    test('Does not trim when under limit', () {
      final config = MemoryConfig(maxMessages: 10);
      final manager = ConversationMemoryManager(
        config: config,
        logger: Logger(level: Level.off),
      );

      for (int i = 1; i <= 5; i++) {
        manager.addUserMessage('session-1', 'Message $i');
      }

      final history = manager.getHistory('session-1');

      expect(history.length, equals(5));

      manager.dispose();
    });
  });

  group('ConversationMemoryManager - Session Expiration', () {
    test('Session is not expired initially', () {
      final session = ConversationSession(id: 'test');

      expect(session.isExpired(Duration(hours: 1)), isFalse);
    });

    test('Session expires after timeout', () {
      final session = ConversationSession(
        id: 'test',
        lastActivityTime: DateTime.now().subtract(Duration(hours: 2)),
      );

      expect(session.isExpired(Duration(hours: 1)), isTrue);
    });

    test('Touch updates last activity time', () {
      final session = ConversationSession(
        id: 'test',
        lastActivityTime: DateTime.now().subtract(Duration(minutes: 30)),
      );

      final beforeTouch = session.lastActivityTime;
      session.touch();
      final afterTouch = session.lastActivityTime;

      expect(afterTouch.isAfter(beforeTouch), isTrue);
    });

    test('Cleans up expired sessions automatically', () async {
      final config = MemoryConfig(
        sessionTimeout: Duration(milliseconds: 100),
      );
      final manager = ConversationMemoryManager(
        config: config,
        logger: Logger(level: Level.off),
      );

      manager.getSession('session-1');

      expect(manager.sessionCount, equals(1));

      // Wait for session to expire
      await Future.delayed(Duration(milliseconds: 150));

      // Trigger cleanup by getting active sessions
      final activeIds = manager.getActiveSessionIds();

      expect(activeIds.length, equals(0));
      expect(manager.sessionCount, equals(0));

      manager.dispose();
    });
  });

  group('ConversationMemoryManager - Statistics', () {
    late ConversationMemoryManager manager;

    setUp(() {
      manager = ConversationMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('Provides accurate statistics', () {
      manager.addUserMessage('session-1', 'User message 1');
      manager.addAssistantMessage('session-1', 'Assistant response 1');
      manager.addUserMessage('session-2', 'User message 2');

      final stats = manager.getStats();

      expect(stats.totalMessages, equals(3));
      expect(stats.userMessages, equals(2));
      expect(stats.assistantMessages, equals(1));
      expect(stats.activeSessions, equals(2));
      expect(stats.estimatedTokens, greaterThan(0));
    });

    test('Tracks session metrics', () {
      final session = manager.getSession('session-1');

      manager.addUserMessage('session-1', 'Message 1');
      manager.addUserMessage('session-1', 'Message 2');
      manager.addAssistantMessage('session-1', 'Response');

      expect(session.messageCount, equals(3));
      expect(session.userMessageCount, equals(2));
      expect(session.assistantMessageCount, equals(1));
      // Duration might be 0ms on fast machines - just check it's non-negative
      expect(session.duration.inMilliseconds, greaterThanOrEqualTo(0));
    });
  });

  group('ConversationMemoryManager - Export/Import', () {
    late ConversationMemoryManager manager;

    setUp(() {
      manager = ConversationMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('Exports session to JSON', () {
      manager.addUserMessage('session-1', 'Hello');
      manager.addAssistantMessage('session-1', 'Hi there');

      final exported = manager.exportSession('session-1');

      expect(exported['id'], equals('session-1'));
      expect(exported['messages'], hasLength(2));
      expect(exported['messages'][0]['content'], equals('Hello'));
      expect(exported['messages'][0]['role'], equals('user'));
      expect(exported['messages'][1]['content'], equals('Hi there'));
      expect(exported['messages'][1]['role'], equals('assistant'));
    });

    test('Imports session from JSON', () {
      final data = {
        'id': 'imported-session',
        'startTime': DateTime.now().toIso8601String(),
        'lastActivityTime': DateTime.now().toIso8601String(),
        'messages': [
          {
            'content': 'Imported message',
            'role': 'user',
            'timestamp': DateTime.now().toIso8601String(),
            'metadata': null,
          },
        ],
        'metadata': {},
      };

      manager.importSession(data);

      expect(manager.hasSession('imported-session'), isTrue);

      final history = manager.getHistory('imported-session');
      expect(history.length, equals(1));
      expect(history[0].content, equals('Imported message'));
    });

    test('Round-trip export and import', () {
      manager.addUserMessage('session-1', 'Original message 1');
      manager.addAssistantMessage('session-1', 'Original response');
      manager.addUserMessage('session-1', 'Original message 2');

      final exported = manager.exportSession('session-1');

      // Create new manager and import
      final newManager = ConversationMemoryManager(
        logger: Logger(level: Level.off),
      );
      newManager.importSession(exported);

      final history = newManager.getHistory('session-1');

      expect(history.length, equals(3));
      expect(history[0].content, equals('Original message 1'));
      expect(history[1].content, equals('Original response'));
      expect(history[2].content, equals('Original message 2'));

      newManager.dispose();
    });
  });

  group('ConversationMemoryManager - LangChain Integration', () {
    late ConversationMemoryManager manager;

    setUp(() {
      manager = ConversationMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('Creates LangChain memory for session', () {
      final memory = manager.getLangChainMemory('session-1');

      expect(memory, isNotNull);
    });
  });

  group('ConversationMemoryManager - Multi-Session', () {
    late ConversationMemoryManager manager;

    setUp(() {
      manager = ConversationMemoryManager(
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('Manages multiple independent sessions', () {
      manager.addUserMessage('session-1', 'Message in session 1');
      manager.addUserMessage('session-2', 'Message in session 2');
      manager.addUserMessage('session-3', 'Message in session 3');

      final history1 = manager.getHistory('session-1');
      final history2 = manager.getHistory('session-2');
      final history3 = manager.getHistory('session-3');

      expect(history1.length, equals(1));
      expect(history2.length, equals(1));
      expect(history3.length, equals(1));

      expect(history1[0].content, equals('Message in session 1'));
      expect(history2[0].content, equals('Message in session 2'));
      expect(history3[0].content, equals('Message in session 3'));
    });

    test('Sessions do not interfere with each other', () {
      for (int i = 1; i <= 5; i++) {
        manager.addUserMessage('session-1', 'Session 1 message $i');
      }

      for (int i = 1; i <= 3; i++) {
        manager.addUserMessage('session-2', 'Session 2 message $i');
      }

      final history1 = manager.getHistory('session-1');
      final history2 = manager.getHistory('session-2');

      expect(history1.length, equals(5));
      expect(history2.length, equals(3));
    });
  });
}
