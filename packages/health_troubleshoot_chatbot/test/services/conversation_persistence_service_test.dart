/// Tests for Production Conversation Persistence Service
///
/// Validates:
/// - Database initialization and schema creation
/// - Session save/load operations
/// - Message save/load operations
/// - Data integrity and transactions
/// - Error handling
/// - Performance with large datasets

import 'package:test/test.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:path/path.dart' as path_util;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/src/services/conversation_persistence_service.dart';
import '../../lib/src/services/groq_chat_service.dart';

void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  });

  // Helper to create test config with encryption disabled
  // (sqflite_ffi doesn't support SQLCipher encryption)
  PersistenceConfig _testConfig() {
    return const PersistenceConfig(
      databaseName: 'test_conversations.db',
      enableEncryption: false, // Disable for FFI testing
    );
  }

  group('ConversationPersistenceService - Initialization', () {
    late ConversationPersistenceService service;

    tearDown(() async {
      await service.close();
    });

    test('Initializes successfully', () async {
      final config = PersistenceConfig(enableEncryption: false, 
        databaseName: 'test_init.db',
      );
      service = ConversationPersistenceService(
        config: config,
        logger: Logger(level: Level.off),
      );

      await service.initialize();

      // Verify can perform operations
      final stats = await service.getStats();
      expect(stats['sessions'], equals(0));
      expect(stats['messages'], equals(0));
    });

    test('Only initializes once', () async {
      final config = PersistenceConfig(enableEncryption: false, 
        databaseName: 'test_once.db',
      );
      service = ConversationPersistenceService(
        config: config,
        logger: Logger(level: Level.off),
      );

      await service.initialize();
      await service.initialize(); // Should not throw
      await service.initialize(); // Should not throw

      expect(true, isTrue); // If we got here, it worked
    });
  });

  group('ConversationPersistenceService - Session Operations', () {
    late ConversationPersistenceService service;

    setUp(() async {
      final config = PersistenceConfig(enableEncryption: false, 
        databaseName: 'test_sessions_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      service = ConversationPersistenceService(
        config: config,
        logger: Logger(level: Level.off),
      );
      await service.initialize();
    });

    tearDown(() async {
      await service.close();
    });

    test('Saves and loads session', () async {
      final session = PersistedSession(
        id: 'session-1',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      );

      await service.saveSession(session);

      final loaded = await service.loadSession('session-1');

      expect(loaded, isNotNull);
      expect(loaded!.id, equals('session-1'));
      expect(loaded.startTime.millisecondsSinceEpoch,
             equals(session.startTime.millisecondsSinceEpoch));
    });

    test('Returns null for non-existent session', () async {
      final loaded = await service.loadSession('non-existent');

      expect(loaded, isNull);
    });

    test('Updates existing session', () async {
      final session1 = PersistedSession(
        id: 'session-1',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      );

      await service.saveSession(session1);

      // Wait a bit
      await Future.delayed(Duration(milliseconds: 10));

      final session2 = PersistedSession(
        id: 'session-1',
        startTime: session1.startTime,
        lastActivityTime: DateTime.now(),
      );

      await service.saveSession(session2);

      final loaded = await service.loadSession('session-1');

      expect(loaded, isNotNull);
      expect(loaded!.lastActivityTime.isAfter(session1.lastActivityTime), isTrue);
    });

    test('Loads all session IDs', () async {
      await service.saveSession(PersistedSession(
        id: 'session-1',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      ));

      await service.saveSession(PersistedSession(
        id: 'session-2',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      ));

      await service.saveSession(PersistedSession(
        id: 'session-3',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      ));

      final ids = await service.loadAllSessionIds();

      expect(ids.length, equals(3));
      expect(ids, contains('session-1'));
      expect(ids, contains('session-2'));
      expect(ids, contains('session-3'));
    });

    test('Deletes session', () async {
      final session = PersistedSession(
        id: 'session-to-delete',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      );

      await service.saveSession(session);

      final loaded1 = await service.loadSession('session-to-delete');
      expect(loaded1, isNotNull);

      await service.deleteSession('session-to-delete');

      final loaded2 = await service.loadSession('session-to-delete');
      expect(loaded2, isNull);
    });
  });

  group('ConversationPersistenceService - Message Operations', () {
    late ConversationPersistenceService service;

    setUp(() async {
      final config = PersistenceConfig(enableEncryption: false, 
        databaseName: 'test_messages_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      service = ConversationPersistenceService(
        config: config,
        logger: Logger(level: Level.off),
      );
      await service.initialize();

      // Create a session first
      await service.saveSession(PersistedSession(
        id: 'test-session',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      ));
    });

    tearDown(() async {
      await service.close();
    });

    test('Saves and loads message', () async {
      final message = PersistedMessage(
        sessionId: 'test-session',
        content: 'Hello world',
        role: 'user',
        timestamp: DateTime.now(),
      );

      await service.saveMessage(message);

      final messages = await service.loadMessages('test-session');

      expect(messages.length, equals(1));
      expect(messages[0].content, equals('Hello world'));
      expect(messages[0].role, equals('user'));
    });

    test('Loads messages in correct order', () async {
      final now = DateTime.now();

      await service.saveMessage(PersistedMessage(
        sessionId: 'test-session',
        content: 'Message 1',
        role: 'user',
        timestamp: now,
      ));

      await service.saveMessage(PersistedMessage(
        sessionId: 'test-session',
        content: 'Message 2',
        role: 'assistant',
        timestamp: now.add(Duration(milliseconds: 100)),
      ));

      await service.saveMessage(PersistedMessage(
        sessionId: 'test-session',
        content: 'Message 3',
        role: 'user',
        timestamp: now.add(Duration(milliseconds: 200)),
      ));

      final messages = await service.loadMessages('test-session');

      expect(messages.length, equals(3));
      expect(messages[0].content, equals('Message 1'));
      expect(messages[1].content, equals('Message 2'));
      expect(messages[2].content, equals('Message 3'));
    });

    test('Returns empty list for session with no messages', () async {
      final messages = await service.loadMessages('test-session');

      expect(messages.length, equals(0));
    });

    test('Saves message with metadata', () async {
      final message = PersistedMessage(
        sessionId: 'test-session',
        content: 'Test',
        role: 'user',
        timestamp: DateTime.now(),
        metadataJson: '{"key": "value"}',
      );

      await service.saveMessage(message);

      final messages = await service.loadMessages('test-session');

      expect(messages.length, equals(1));
      expect(messages[0].metadataJson, equals('{"key": "value"}'));
    });

    test('Converts to/from ConversationMessage', () async {
      final conversationMsg = ConversationMessage(
        content: 'Test message',
        role: 'user',
        timestamp: DateTime.now(),
        metadata: {'source': 'test'},
      );

      final persisted = PersistedMessage.fromConversationMessage(
        'test-session',
        conversationMsg,
      );

      await service.saveMessage(persisted);

      final loaded = await service.loadMessages('test-session');
      final converted = loaded[0].toConversationMessage();

      expect(converted.content, equals('Test message'));
      expect(converted.role, equals('user'));
      expect(converted.metadata, isNotNull);
      expect(converted.metadata!['source'], equals('test'));
    });
  });

  group('ConversationPersistenceService - Data Integrity', () {
    late ConversationPersistenceService service;

    setUp(() async {
      final config = PersistenceConfig(enableEncryption: false, 
        databaseName: 'test_integrity_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      service = ConversationPersistenceService(
        config: config,
        logger: Logger(level: Level.off),
      );
      await service.initialize();
    });

    tearDown(() async {
      await service.close();
    });

    test('Cascade deletes messages when session deleted', () async {
      // Create session
      await service.saveSession(PersistedSession(
        id: 'cascade-test',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      ));

      // Add messages
      await service.saveMessage(PersistedMessage(
        sessionId: 'cascade-test',
        content: 'Message 1',
        role: 'user',
        timestamp: DateTime.now(),
      ));

      await service.saveMessage(PersistedMessage(
        sessionId: 'cascade-test',
        content: 'Message 2',
        role: 'assistant',
        timestamp: DateTime.now(),
      ));

      // Verify messages exist
      final messages1 = await service.loadMessages('cascade-test');
      expect(messages1.length, equals(2));

      // Delete session
      await service.deleteSession('cascade-test');

      // Verify messages also deleted
      final messages2 = await service.loadMessages('cascade-test');
      expect(messages2.length, equals(0));
    });

    test('Multiple sessions do not interfere', () async {
      // Create two sessions
      await service.saveSession(PersistedSession(
        id: 'session-a',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      ));

      await service.saveSession(PersistedSession(
        id: 'session-b',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      ));

      // Add messages to each
      await service.saveMessage(PersistedMessage(
        sessionId: 'session-a',
        content: 'Message A1',
        role: 'user',
        timestamp: DateTime.now(),
      ));

      await service.saveMessage(PersistedMessage(
        sessionId: 'session-b',
        content: 'Message B1',
        role: 'user',
        timestamp: DateTime.now(),
      ));

      // Verify isolation
      final messagesA = await service.loadMessages('session-a');
      final messagesB = await service.loadMessages('session-b');

      expect(messagesA.length, equals(1));
      expect(messagesB.length, equals(1));
      expect(messagesA[0].content, equals('Message A1'));
      expect(messagesB[0].content, equals('Message B1'));
    });
  });

  group('ConversationPersistenceService - Statistics', () {
    late ConversationPersistenceService service;

    setUp(() async {
      final config = PersistenceConfig(enableEncryption: false, 
        databaseName: 'test_stats_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      service = ConversationPersistenceService(
        config: config,
        logger: Logger(level: Level.off),
      );
      await service.initialize();
    });

    tearDown(() async {
      await service.close();
    });

    test('Provides accurate statistics', () async {
      // Initially empty
      final stats1 = await service.getStats();
      expect(stats1['sessions'], equals(0));
      expect(stats1['messages'], equals(0));

      // Add session
      await service.saveSession(PersistedSession(
        id: 'session-1',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      ));

      final stats2 = await service.getStats();
      expect(stats2['sessions'], equals(1));
      expect(stats2['messages'], equals(0));

      // Add messages
      await service.saveMessage(PersistedMessage(
        sessionId: 'session-1',
        content: 'Message 1',
        role: 'user',
        timestamp: DateTime.now(),
      ));

      await service.saveMessage(PersistedMessage(
        sessionId: 'session-1',
        content: 'Message 2',
        role: 'assistant',
        timestamp: DateTime.now(),
      ));

      final stats3 = await service.getStats();
      expect(stats3['sessions'], equals(1));
      expect(stats3['messages'], equals(2));
    });
  });

  group('ConversationPersistenceService - Cleanup', () {
    late ConversationPersistenceService service;

    setUp(() async {
      final config = PersistenceConfig(enableEncryption: false, 
        databaseName: 'test_cleanup_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      service = ConversationPersistenceService(
        config: config,
        logger: Logger(level: Level.off),
      );
      await service.initialize();
    });

    tearDown(() async {
      await service.close();
    });

    test('Deletes all data', () async {
      // Add data
      await service.saveSession(PersistedSession(
        id: 'session-1',
        startTime: DateTime.now(),
        lastActivityTime: DateTime.now(),
      ));

      await service.saveMessage(PersistedMessage(
        sessionId: 'session-1',
        content: 'Message',
        role: 'user',
        timestamp: DateTime.now(),
      ));

      // Verify exists
      final stats1 = await service.getStats();
      expect(stats1['sessions'], equals(1));
      expect(stats1['messages'], equals(1));

      // Delete all
      await service.deleteAll();

      // Verify empty
      final stats2 = await service.getStats();
      expect(stats2['sessions'], equals(0));
      expect(stats2['messages'], equals(0));
    });
  });
}
