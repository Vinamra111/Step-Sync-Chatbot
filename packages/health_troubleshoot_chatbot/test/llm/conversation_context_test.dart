import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';
import 'package:step_sync_chatbot/src/llm/conversation_context.dart';

void main() {
  group('ConversationContext', () {
    late ConversationContext context;

    setUp(() {
      context = ConversationContext(maxContextMessages: 5);
    });

    group('Basic Operations', () {
      test('starts empty', () {
        // Assert
        expect(context.isEmpty, isTrue);
        expect(context.messageCount, 0);
      });

      test('adds messages', () {
        // Arrange
        final message = ChatMessage.user(text: 'Hello');

        // Act
        context.addMessage(message);

        // Assert
        expect(context.isEmpty, isFalse);
        expect(context.messageCount, 1);
      });

      test('adds multiple messages', () {
        // Arrange & Act
        for (var i = 0; i < 3; i++) {
          context.addMessage(ChatMessage.user(text: 'Message $i'));
        }

        // Assert
        expect(context.messageCount, 3);
      });

      test('clears messages', () {
        // Arrange
        context.addMessage(ChatMessage.user(text: 'Test'));
        context.addMessage(ChatMessage.bot(text: 'Response'));

        // Act
        context.clear();

        // Assert
        expect(context.isEmpty, isTrue);
        expect(context.messageCount, 0);
      });
    });

    group('Max Context Messages', () {
      test('respects max context limit', () {
        // Arrange
        context = ConversationContext(maxContextMessages: 3);

        // Act - Add 5 messages
        for (var i = 0; i < 5; i++) {
          context.addMessage(ChatMessage.user(text: 'Message $i'));
        }

        // Assert - Should only keep last 3
        expect(context.messageCount, 3);
      });

      test('removes oldest messages first', () {
        // Arrange
        context = ConversationContext(maxContextMessages: 3);

        // Act - Add 4 messages
        context.addMessage(ChatMessage.user(text: 'Message 0'));
        context.addMessage(ChatMessage.user(text: 'Message 1'));
        context.addMessage(ChatMessage.user(text: 'Message 2'));
        context.addMessage(ChatMessage.user(text: 'Message 3'));

        // Assert - Should have messages 1, 2, 3 (0 was removed)
        final history = context.getHistory();
        expect(history.length, 3);
        expect(history[0].content, 'Message 1');
        expect(history[1].content, 'Message 2');
        expect(history[2].content, 'Message 3');
      });

      test('handles limit of 1', () {
        // Arrange
        context = ConversationContext(maxContextMessages: 1);

        // Act
        context.addMessage(ChatMessage.user(text: 'First'));
        context.addMessage(ChatMessage.user(text: 'Second'));

        // Assert
        expect(context.messageCount, 1);
        final history = context.getHistory();
        expect(history[0].content, 'Second');
      });
    });

    group('History Conversion', () {
      test('converts user messages to correct role', () {
        // Arrange
        context.addMessage(ChatMessage.user(text: 'User message'));

        // Act
        final history = context.getHistory();

        // Assert
        expect(history.length, 1);
        expect(history[0].role, 'user');
        expect(history[0].content, 'User message');
      });

      test('converts bot messages to correct role', () {
        // Arrange
        context.addMessage(ChatMessage.bot(text: 'Bot response'));

        // Act
        final history = context.getHistory();

        // Assert
        expect(history.length, 1);
        expect(history[0].role, 'assistant');
        expect(history[0].content, 'Bot response');
      });

      test('maintains conversation order', () {
        // Arrange
        context.addMessage(ChatMessage.user(text: 'First user'));
        context.addMessage(ChatMessage.bot(text: 'First bot'));
        context.addMessage(ChatMessage.user(text: 'Second user'));
        context.addMessage(ChatMessage.bot(text: 'Second bot'));

        // Act
        final history = context.getHistory();

        // Assert
        expect(history.length, 4);
        expect(history[0].content, 'First user');
        expect(history[0].role, 'user');
        expect(history[1].content, 'First bot');
        expect(history[1].role, 'assistant');
        expect(history[2].content, 'Second user');
        expect(history[2].role, 'user');
        expect(history[3].content, 'Second bot');
        expect(history[3].role, 'assistant');
      });

      test('returns empty list when no messages', () {
        // Act
        final history = context.getHistory();

        // Assert
        expect(history, isEmpty);
      });
    });

    group('Summary Generation', () {
      test('generates summary for empty context', () {
        // Act
        final summary = context.getSummary();

        // Assert
        expect(summary, contains('No messages'));
      });

      test('generates summary with message count', () {
        // Arrange
        context.addMessage(ChatMessage.user(text: 'Test 1'));
        context.addMessage(ChatMessage.bot(text: 'Test 2'));

        // Act
        final summary = context.getSummary();

        // Assert
        expect(summary, contains('2 messages'));
      });

      test('includes message previews in summary', () {
        // Arrange
        context.addMessage(ChatMessage.user(text: 'Hello world'));

        // Act
        final summary = context.getSummary();

        // Assert
        expect(summary, contains('[USER]'));
        expect(summary, contains('Hello world'));
      });

      test('truncates long messages in summary', () {
        // Arrange
        final longText = 'A' * 100; // 100 character string
        context.addMessage(ChatMessage.user(text: longText));

        // Act
        final summary = context.getSummary();

        // Assert
        expect(summary, contains('...'));
        expect(summary.length, lessThan(longText.length + 100));
      });

      test('shows BOT label for bot messages', () {
        // Arrange
        context.addMessage(ChatMessage.bot(text: 'Bot response'));

        // Act
        final summary = context.getSummary();

        // Assert
        expect(summary, contains('[BOT]'));
      });

      test('numbers messages in summary', () {
        // Arrange
        context.addMessage(ChatMessage.user(text: 'First'));
        context.addMessage(ChatMessage.bot(text: 'Second'));
        context.addMessage(ChatMessage.user(text: 'Third'));

        // Act
        final summary = context.getSummary();

        // Assert
        expect(summary, contains('1.'));
        expect(summary, contains('2.'));
        expect(summary, contains('3.'));
      });
    });

    group('Edge Cases', () {
      test('handles error messages', () {
        // Arrange
        context.addMessage(ChatMessage.error(text: 'Error occurred'));

        // Act
        final history = context.getHistory();

        // Assert
        expect(history.length, 1);
        expect(history[0].role, 'assistant'); // Error messages treated as bot
      });

      test('handles messages with quick replies', () {
        // Arrange
        context.addMessage(
          ChatMessage.bot(
            text: 'Choose an option',
            quickReplies: [
              QuickReply(label: 'Option 1', value: 'opt1'),
            ],
          ),
        );

        // Act
        final history = context.getHistory();

        // Assert
        expect(history.length, 1);
        expect(history[0].content, 'Choose an option');
      });

      test('handles empty message text', () {
        // Arrange
        context.addMessage(ChatMessage.user(text: ''));

        // Act
        final history = context.getHistory();

        // Assert
        expect(history.length, 1);
        expect(history[0].content, '');
      });

      test('handles special characters in messages', () {
        // Arrange
        const specialText = 'Hello\nWorld\t"with\'quotes"';
        context.addMessage(ChatMessage.user(text: specialText));

        // Act
        final history = context.getHistory();

        // Assert
        expect(history[0].content, specialText);
      });
    });

    group('Performance', () {
      test('handles many message additions efficiently', () {
        // Arrange
        context = ConversationContext(maxContextMessages: 100);

        // Act
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 1000; i++) {
          context.addMessage(ChatMessage.user(text: 'Message $i'));
        }
        stopwatch.stop();

        // Assert
        expect(context.messageCount, 100); // Should cap at max
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });
    });
  });
}
