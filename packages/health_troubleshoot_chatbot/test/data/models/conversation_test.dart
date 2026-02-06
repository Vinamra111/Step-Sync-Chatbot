import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/data/models/conversation.dart';
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';

void main() {
  group('Conversation', () {
    test('creates new conversation with factory', () {
      final conversation = Conversation.create(userId: 'user-123');

      expect(conversation.userId, 'user-123');
      expect(conversation.messages, isEmpty);
      expect(conversation.isActive, true);
      expect(conversation.id, startsWith('conv_'));
      expect(conversation.createdAt, isA<DateTime>());
      expect(conversation.updatedAt, isA<DateTime>());
    });

    test('allows custom conversation ID', () {
      final conversation = Conversation.create(
        userId: 'user-123',
        id: 'custom-id',
      );

      expect(conversation.id, 'custom-id');
    });

    test('stores messages in conversation', () {
      final message1 = ChatMessage.user(text: 'Hello');
      final message2 = ChatMessage.bot(text: 'Hi there!');

      final conversation = Conversation.create(userId: 'user-123')
          .copyWith(messages: [message1, message2]);

      expect(conversation.messages, hasLength(2));
      expect(conversation.messages[0].text, 'Hello');
      expect(conversation.messages[1].text, 'Hi there!');
    });

    test('stores metadata in conversation', () {
      final conversation = Conversation.create(userId: 'user-123').copyWith(
        metadata: {
          'platform': 'android',
          'permissions_granted': true,
        },
      );

      expect(conversation.metadata, isNotNull);
      expect(conversation.metadata!['platform'], 'android');
      expect(conversation.metadata!['permissions_granted'], true);
    });

    test('can mark conversation as inactive', () {
      final conversation = Conversation.create(userId: 'user-123')
          .copyWith(isActive: false);

      expect(conversation.isActive, false);
    });
  });
}
