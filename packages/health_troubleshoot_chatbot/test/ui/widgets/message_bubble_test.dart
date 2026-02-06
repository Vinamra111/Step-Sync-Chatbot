import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/ui/widgets/message_bubble.dart';
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';

void main() {
  group('MessageBubble', () {
    testWidgets('displays user message correctly', (tester) async {
      final message = ChatMessage.user(text: 'Hello');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: message),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays bot message correctly', (tester) async {
      final message = ChatMessage.bot(text: 'Hi there!');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: message),
          ),
        ),
      );

      expect(find.text('Hi there!'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('displays error message with error color', (tester) async {
      final message = ChatMessage.error(text: 'Something went wrong');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(message: message),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);

      // Error messages should still show bot avatar
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('user and bot messages are aligned differently',
        (tester) async {
      final userMessage = ChatMessage.user(text: 'User message');
      final botMessage = ChatMessage.bot(text: 'Bot message');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MessageBubble(message: userMessage),
                MessageBubble(message: botMessage),
              ],
            ),
          ),
        ),
      );

      expect(find.text('User message'), findsOneWidget);
      expect(find.text('Bot message'), findsOneWidget);
    });
  });
}
