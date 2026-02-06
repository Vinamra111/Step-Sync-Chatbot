import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('creates user message with factory', () {
      final message = ChatMessage.user(text: 'Hello');

      expect(message.text, 'Hello');
      expect(message.sender, MessageSender.user);
      expect(message.type, MessageType.text);
      expect(message.isError, false);
      expect(message.id, isNotEmpty);
    });

    test('creates bot message with factory', () {
      final message = ChatMessage.bot(text: 'Hi there!');

      expect(message.text, 'Hi there!');
      expect(message.sender, MessageSender.bot);
      expect(message.type, MessageType.text);
      expect(message.isError, false);
    });

    test('creates bot message with quick replies', () {
      final quickReplies = [
        QuickReply(label: 'Yes', value: 'yes'),
        QuickReply(label: 'No', value: 'no'),
      ];

      final message = ChatMessage.bot(
        text: 'Do you want to continue?',
        quickReplies: quickReplies,
      );

      expect(message.quickReplies, hasLength(2));
      expect(message.quickReplies![0].label, 'Yes');
      expect(message.quickReplies![1].value, 'no');
    });

    test('creates error message with factory', () {
      final message = ChatMessage.error(text: 'Something went wrong');

      expect(message.text, 'Something went wrong');
      expect(message.sender, MessageSender.bot);
      expect(message.isError, true);
    });

    test('allows custom message type and data', () {
      final message = ChatMessage.bot(
        text: 'Here are your steps',
        type: MessageType.stepChart,
        data: {'steps': 8247, 'date': '2026-01-12'},
      );

      expect(message.type, MessageType.stepChart);
      expect(message.data, isNotNull);
      expect(message.data!['steps'], 8247);
    });

    test('generates unique IDs for different messages', () {
      final message1 = ChatMessage.user(text: 'First');
      final message2 = ChatMessage.user(text: 'Second');

      expect(message1.id, isNot(equals(message2.id)));
    });
  });

  group('QuickReply', () {
    test('creates quick reply with label and value', () {
      final reply = QuickReply(label: 'Continue', value: 'continue');

      expect(reply.label, 'Continue');
      expect(reply.value, 'continue');
    });
  });
}
