import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/data/repositories/sqlite_conversation_repository.dart';
import 'package:step_sync_chatbot/src/data/models/conversation.dart';
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';
import 'package:step_sync_chatbot/src/data/models/user_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SQLiteConversationRepository', () {
    late SQLiteConversationRepository repository;

    setUp(() async {
      repository = SQLiteConversationRepository();
      await repository.initialize();
      // Clean up any existing data from previous tests
      await repository.deleteAllConversations('user_1');
      await repository.deleteAllConversations('user_2');
    });

    tearDown(() async {
      // Clean up test data
      await repository.deleteAllConversations('user_1');
      await repository.deleteAllConversations('user_2');
      await repository.close();
    });

    test('initialize creates database successfully', () async {
      // Repository should be initialized without errors
      expect(repository, isNotNull);
    });

    group('Conversation Management', () {
      test('saveConversation and loadConversation work correctly', () async {
        final msg1 = ChatMessage.user(text: 'Hello');
        await Future.delayed(const Duration(milliseconds: 2));
        final msg2 = ChatMessage.bot(text: 'Hi there!');

        final conversation = Conversation(
          id: 'test_conv_1',
          userId: 'user_1',
          messages: [msg1, msg2],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(conversation);

        final loaded = await repository.loadConversation('test_conv_1');

        expect(loaded, isNotNull);
        expect(loaded!.id, equals('test_conv_1'));
        expect(loaded.userId, equals('user_1'));
        expect(loaded.messages.length, equals(2));
        expect(loaded.messages[0].text, equals('Hello'));
        expect(loaded.messages[1].text, equals('Hi there!'));
        expect(loaded.status, equals(ConversationLifecycleStatus.active));
      });

      test('loadConversations returns conversations for user', () async {
        final msg1 = ChatMessage.user(text: 'Test 1');
        await Future.delayed(const Duration(milliseconds: 2));
        final msg2 = ChatMessage.user(text: 'Test 2');
        await Future.delayed(const Duration(milliseconds: 2));
        final msg3 = ChatMessage.user(text: 'Test 3');

        final conv1 = Conversation(
          id: 'conv_1',
          userId: 'user_1',
          messages: [msg1],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final conv2 = Conversation(
          id: 'conv_2',
          userId: 'user_1',
          messages: [msg2],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now().add(const Duration(seconds: 1)),
        );

        final conv3 = Conversation(
          id: 'conv_3',
          userId: 'user_2',
          messages: [msg3],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(conv1);
        await repository.saveConversation(conv2);
        await repository.saveConversation(conv3);

        final conversations =
            await repository.loadConversations(userId: 'user_1');

        expect(conversations.length, equals(2));
        expect(conversations[0].id, equals('conv_2')); // Most recent first
        expect(conversations[1].id, equals('conv_1'));
      });

      test('loadMostRecentConversation returns latest conversation', () async {
        final msg1 = ChatMessage.user(text: 'Old');
        await Future.delayed(const Duration(milliseconds: 2));
        final msg2 = ChatMessage.user(text: 'New');

        final conv1 = Conversation(
          id: 'conv_1',
          userId: 'user_1',
          messages: [msg1],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final conv2 = Conversation(
          id: 'conv_2',
          userId: 'user_1',
          messages: [msg2],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now().add(const Duration(seconds: 1)),
        );

        await repository.saveConversation(conv1);
        await repository.saveConversation(conv2);

        final recent = await repository.loadMostRecentConversation('user_1');

        expect(recent, isNotNull);
        expect(recent!.id, equals('conv_2'));
        expect(recent.messages[0].text, equals('New'));
      });

      test('deleteConversation removes conversation', () async {
        final conversation = Conversation(
          id: 'conv_to_delete',
          userId: 'user_1',
          messages: [ChatMessage.user(text: 'Delete me')],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(conversation);

        final beforeDelete =
            await repository.loadConversation('conv_to_delete');
        expect(beforeDelete, isNotNull);

        await repository.deleteConversation('conv_to_delete');

        final afterDelete = await repository.loadConversation('conv_to_delete');
        expect(afterDelete, isNull);
      });

      test('deleteAllConversations removes all user conversations', () async {
        final msg1 = ChatMessage.user(text: 'Test 1');
        await Future.delayed(const Duration(milliseconds: 2));
        final msg2 = ChatMessage.user(text: 'Test 2');

        final conv1 = Conversation(
          id: 'conv_1',
          userId: 'user_1',
          messages: [msg1],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final conv2 = Conversation(
          id: 'conv_2',
          userId: 'user_1',
          messages: [msg2],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(conv1);
        await repository.saveConversation(conv2);

        await repository.deleteAllConversations('user_1');

        final conversations =
            await repository.loadConversations(userId: 'user_1');
        expect(conversations.isEmpty, isTrue);
      });

      test('addMessageToConversation adds message to existing conversation',
          () async {
        final conversation = Conversation(
          id: 'conv_1',
          userId: 'user_1',
          messages: [ChatMessage.user(text: 'Initial message')],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(conversation);

        await repository.addMessageToConversation(
          conversationId: 'conv_1',
          message: ChatMessage.bot(text: 'Added message'),
        );

        final updated = await repository.loadConversation('conv_1');

        expect(updated, isNotNull);
        expect(updated!.messages.length, equals(2));
        expect(updated.messages[1].text, equals('Added message'));
      });
    });

    group('User Preferences', () {
      test('saveUserPreferences and loadUserPreferences work correctly',
          () async {
        final preferences = UserPreferences(
          userId: 'user_1',
          preferredDataSource: 'com.google.android.apps.fitness',
          notificationsEnabled: true,
          conversationStyle: ConversationStyle.detailed,
        );

        await repository.saveUserPreferences(preferences);

        final loaded = await repository.loadUserPreferences('user_1');

        expect(loaded, isNotNull);
        expect(loaded!.userId, equals('user_1'));
        expect(loaded.preferredDataSource,
            equals('com.google.android.apps.fitness'));
        expect(loaded.notificationsEnabled, isTrue);
        expect(loaded.conversationStyle, equals(ConversationStyle.detailed));
      });

      test('loadUserPreferences returns null for non-existent user', () async {
        final loaded = await repository.loadUserPreferences('non_existent');
        expect(loaded, isNull);
      });
    });

    group('Statistics', () {
      test('getStats returns correct statistics', () async {
        final msg1 = ChatMessage.user(text: 'Message 1');
        await Future.delayed(const Duration(milliseconds: 2));
        final msg2 = ChatMessage.bot(text: 'Response 1');
        await Future.delayed(const Duration(milliseconds: 2));
        final msg3 = ChatMessage.user(text: 'Message 2');
        await Future.delayed(const Duration(milliseconds: 2));
        final msg4 = ChatMessage.bot(text: 'Response 2');
        await Future.delayed(const Duration(milliseconds: 2));
        final msg5 = ChatMessage.user(text: 'Follow-up');

        final conv1 = Conversation(
          id: 'conv_1',
          userId: 'user_1',
          messages: [msg1, msg2],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        );

        final conv2 = Conversation(
          id: 'conv_2',
          userId: 'user_1',
          messages: [msg3, msg4, msg5],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(conv1);
        await repository.saveConversation(conv2);

        final stats = await repository.getStats('user_1');

        expect(stats.totalConversations, equals(2));
        expect(stats.totalMessages, equals(5));
        expect(stats.averageMessagesPerConversation, equals(2.5));
        expect(stats.firstConversationDate, isNotNull);
        expect(stats.lastConversationDate, isNotNull);
      });

      test('getStats returns empty for user with no conversations', () async {
        final stats = await repository.getStats('user_without_convos');

        expect(stats.totalConversations, equals(0));
        expect(stats.totalMessages, equals(0));
        expect(stats.averageMessagesPerConversation, equals(0));
      });
    });

    group('Cleanup', () {
      test('cleanupOldConversations removes conversations older than retention',
          () async {
        final msgOld = ChatMessage.user(text: 'Old');
        await Future.delayed(const Duration(milliseconds: 2));
        final msgRecent = ChatMessage.user(text: 'Recent');

        final oldConv = Conversation(
          id: 'old_conv',
          userId: 'user_1',
          messages: [msgOld],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now().subtract(const Duration(days: 100)),
          updatedAt: DateTime.now().subtract(const Duration(days: 100)),
        );

        final recentConv = Conversation(
          id: 'recent_conv',
          userId: 'user_1',
          messages: [msgRecent],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(oldConv);
        await repository.saveConversation(recentConv);

        final removedCount = await repository.cleanupOldConversations(
          userId: 'user_1',
          retentionDays: 90,
        );

        expect(removedCount, equals(1));

        final remaining = await repository.loadConversations(userId: 'user_1');
        expect(remaining.length, equals(1));
        expect(remaining[0].id, equals('recent_conv'));
      });
    });

    group('Complex Scenarios', () {
      test('updating conversation replaces messages', () async {
        final msgOriginal = ChatMessage.user(text: 'Original');

        final conversation = Conversation(
          id: 'conv_1',
          userId: 'user_1',
          messages: [msgOriginal],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(conversation);

        await Future.delayed(const Duration(milliseconds: 2));
        final msgAdded = ChatMessage.bot(text: 'Added');

        final updated = conversation.copyWith(
          messages: [msgOriginal, msgAdded],
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(updated);

        final loaded = await repository.loadConversation('conv_1');

        expect(loaded, isNotNull);
        expect(loaded!.messages.length, equals(2));
      });

      test('quick replies are persisted and loaded correctly', () async {
        final conversation = Conversation(
          id: 'conv_1',
          userId: 'user_1',
          messages: [
            ChatMessage.bot(
              text: 'Choose an option:',
              quickReplies: [
                QuickReply(label: 'Option 1', value: 'opt1'),
                QuickReply(label: 'Option 2', value: 'opt2'),
              ],
            ),
          ],
          status: ConversationLifecycleStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveConversation(conversation);

        final loaded = await repository.loadConversation('conv_1');

        expect(loaded, isNotNull);
        expect(loaded!.messages[0].quickReplies, isNotNull);
        expect(loaded.messages[0].quickReplies!.length, equals(2));
        expect(loaded.messages[0].quickReplies![0].label, equals('Option 1'));
        expect(loaded.messages[0].quickReplies![1].value, equals('opt2'));
      });
    });
  });
}
