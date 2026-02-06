import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/conversation/conversation_context.dart';

void main() {
  group('ConversationContext - Sentiment Detection', () {
    test('detects very frustrated sentiment with multiple exclamations', () {
      final context = ConversationContext();
      context.addUserMessage('this is so annoying!!!');

      expect(context.sentiment, SentimentLevel.veryFrustrated);
      expect(context.isFrustrated, isTrue);
    });

    test('detects very frustrated sentiment with strong negative words', () {
      final context = ConversationContext();
      context.addUserMessage('this app is terrible and useless');

      expect(context.sentiment, SentimentLevel.veryFrustrated);
    });

    test('detects frustrated sentiment with problem words', () {
      final context = ConversationContext();
      context.addUserMessage('my steps are not working');

      expect(context.sentiment, SentimentLevel.frustrated);
      expect(context.isFrustrated, isTrue);
    });

    test('detects happy sentiment with strong positive words', () {
      final context = ConversationContext();
      context.addUserMessage('perfect! this is amazing!');

      expect(context.sentiment, SentimentLevel.happy);
      expect(context.isHappy, isTrue);
    });

    test('detects satisfied sentiment with resolution words', () {
      final context = ConversationContext();
      context.addUserMessage('thanks, it is working now');

      expect(context.sentiment, SentimentLevel.satisfied);
      expect(context.isHappy, isTrue);
    });

    test('defaults to neutral sentiment for ambiguous messages', () {
      final context = ConversationContext();
      context.addUserMessage('what is step tracking');

      expect(context.sentiment, SentimentLevel.neutral);
      expect(context.isFrustrated, isFalse);
      expect(context.isHappy, isFalse);
    });

    test('sentiment changes with new messages', () {
      final context = ConversationContext();

      context.addUserMessage('this is broken!!!');
      expect(context.sentiment, SentimentLevel.veryFrustrated);

      context.addUserMessage('oh wait it works now');
      expect(context.sentiment, SentimentLevel.satisfied);
    });
  });

  group('ConversationContext - Reference Tracking', () {
    test('tracks mentioned app', () {
      final context = ConversationContext();
      context.addUserMessage('I use Samsung Health for tracking');

      expect(context.lastMentionedApp, 'samsung health');
    });

    test('tracks mentioned device', () {
      final context = ConversationContext();
      context.addUserMessage('I have an iPhone');

      expect(context.lastMentionedDevice, 'iphone');
    });

    test('tracks multiple apps, keeps last mentioned', () {
      final context = ConversationContext();
      context.addUserMessage('I use Google Fit and Samsung Health');

      // Should track the last mentioned one
      expect(context.lastMentionedApp, 'samsung health');
    });

    test('tracks problem type - syncing', () {
      final context = ConversationContext();
      context.addUserMessage('my steps are not syncing');

      expect(context.lastMentionedProblem, 'syncing');
    });

    test('tracks problem type - permissions', () {
      final context = ConversationContext();
      context.addUserMessage('permission denied error');

      expect(context.lastMentionedProblem, 'permissions');
    });

    test('tracks problem type - step count', () {
      final context = ConversationContext();
      context.addUserMessage('my step count is wrong');

      expect(context.lastMentionedProblem, 'step count accuracy');
    });

    test('tracks mentioned action', () {
      final context = ConversationContext();
      context.addUserMessage('should I grant permission?');

      expect(context.lastMentionedAction, 'grant permission');
    });
  });

  group('ConversationContext - Message History', () {
    test('adds user messages to history', () {
      final context = ConversationContext();
      context.addUserMessage('hello');

      expect(context.messageCount, 1);
      expect(context.userMessages.length, 1);
      expect(context.userMessages.first.text, 'hello');
      expect(context.userMessages.first.isUser, isTrue);
    });

    test('adds bot messages to history', () {
      final context = ConversationContext();
      context.addBotMessage('Hi! How can I help?');

      expect(context.messageCount, 1);
      expect(context.botMessages.length, 1);
      expect(context.botMessages.first.text, 'Hi! How can I help?');
      expect(context.botMessages.first.isUser, isFalse);
    });

    test('maintains conversation order', () {
      final context = ConversationContext();
      context.addUserMessage('hello');
      context.addBotMessage('Hi there!');
      context.addUserMessage('how are you');
      context.addBotMessage('Good!');

      expect(context.messageCount, 4);

      final recent = context.getRecentMessages(4);
      expect(recent[0].text, 'hello');
      expect(recent[0].isUser, isTrue);
      expect(recent[1].text, 'Hi there!');
      expect(recent[1].isUser, isFalse);
      expect(recent[2].text, 'how are you');
      expect(recent[3].text, 'Good!');
    });

    test('limits history to 10 messages', () {
      final context = ConversationContext();

      // Add 15 messages
      for (int i = 0; i < 15; i++) {
        context.addUserMessage('message $i');
      }

      expect(context.messageCount, 10);
      // Should keep last 10
      final recent = context.getRecentMessages(10);
      expect(recent.first.text, 'message 5'); // First kept message
      expect(recent.last.text, 'message 14'); // Last message
    });

    test('getRecentMessages returns limited count', () {
      final context = ConversationContext();
      for (int i = 0; i < 10; i++) {
        context.addUserMessage('message $i');
      }

      final recent = context.getRecentMessages(3);
      expect(recent.length, 3);
      expect(recent.first.text, 'message 7');
      expect(recent.last.text, 'message 9');
    });
  });

  group('ConversationContext - Metadata', () {
    test('tracks turn count', () {
      final context = ConversationContext();

      expect(context.turnCount, 0);

      context.addUserMessage('hello');
      expect(context.turnCount, 1);

      context.addBotMessage('hi');
      // Bot messages don't increment turn count
      expect(context.turnCount, 1);

      context.addUserMessage('how are you');
      expect(context.turnCount, 2);
    });

    test('tracks conversation start time', () {
      final context = ConversationContext();

      expect(context.conversationStartTime, isNull);

      context.addUserMessage('hello');

      expect(context.conversationStartTime, isNotNull);
      expect(context.duration.inSeconds, greaterThanOrEqualTo(0));
    });

    test('identifies new conversation', () {
      final context = ConversationContext();

      context.addUserMessage('hello');
      expect(context.isNewConversation, isTrue);

      context.addUserMessage('second message');
      expect(context.isNewConversation, isTrue);

      context.addUserMessage('third message');
      expect(context.isNewConversation, isFalse); // >2 turns
    });

    test('identifies long conversation', () {
      final context = ConversationContext();

      for (int i = 0; i < 10; i++) {
        context.addUserMessage('message $i');
      }

      expect(context.isLongConversation, isFalse); // 10 turns

      for (int i = 10; i < 16; i++) {
        context.addUserMessage('message $i');
      }

      expect(context.isLongConversation, isTrue); // >15 turns
    });
  });

  group('ConversationContext - Context Summary', () {
    test('builds context summary with sentiment', () {
      final context = ConversationContext();
      context.addUserMessage('this is so frustrating!!!');

      final summary = context.buildContextSummary();

      expect(summary, contains('frustrated'));
      expect(summary, contains('Messages exchanged: 1'));
    });

    test('includes mentioned app in summary', () {
      final context = ConversationContext();
      context.addUserMessage('I use Samsung Health');

      final summary = context.buildContextSummary();

      expect(summary, contains('samsung health'));
    });

    test('includes mentioned device in summary', () {
      final context = ConversationContext();
      context.addUserMessage('I have an Android phone');

      final summary = context.buildContextSummary();

      expect(summary, contains('android'));
    });

    test('includes current problem in summary', () {
      final context = ConversationContext();
      context.addUserMessage('my steps are not syncing');

      final summary = context.buildContextSummary();

      expect(summary, contains('syncing'));
    });
  });

  group('ConversationContext - Clear Functionality', () {
    test('clears all context data', () {
      final context = ConversationContext();

      // Add data
      context.addUserMessage('I use Samsung Health for step tracking');
      context.currentTopic = 'step tracking';

      expect(context.messageCount, greaterThan(0));
      expect(context.lastMentionedApp, isNotNull);
      expect(context.currentTopic, isNotNull);

      // Clear
      context.clear();

      expect(context.messageCount, 0);
      expect(context.lastMentionedApp, isNull);
      expect(context.lastMentionedDevice, isNull);
      expect(context.lastMentionedProblem, isNull);
      expect(context.currentTopic, isNull);
      expect(context.turnCount, 0);
      expect(context.conversationStartTime, isNull);
      expect(context.sentiment, SentimentLevel.neutral);
    });
  });

  group('ConversationContext - Sentiment Score', () {
    test('returns correct sentiment score for each level', () {
      final context = ConversationContext();

      context.addUserMessage('this is terrible!!!');
      expect(context.sentimentScore, 0.0); // very frustrated

      context.addUserMessage('not working');
      expect(context.sentimentScore, 0.25); // frustrated

      context.addUserMessage('hello');
      expect(context.sentimentScore, 0.5); // neutral

      context.addUserMessage('thanks');
      expect(context.sentimentScore, 0.75); // satisfied

      context.addUserMessage('perfect! amazing!');
      expect(context.sentimentScore, 1.0); // happy
    });
  });
}
