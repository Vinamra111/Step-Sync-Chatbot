import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/core/conversation_templates.dart';
import 'package:step_sync_chatbot/src/core/intents.dart';
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';

void main() {
  group('ConversationTemplates', () {
    test('greeting response includes quick replies', () {
      final response = ConversationTemplates.getResponse(UserIntent.greeting);

      expect(response.sender, MessageSender.bot);
      expect(response.text, contains('Step Sync Assistant'));
      expect(response.quickReplies, isNotNull);
      expect(response.quickReplies, hasLength(3));
    });

    test('thanks response is friendly', () {
      final response = ConversationTemplates.getResponse(UserIntent.thanks);

      expect(response.text, contains('welcome'));
      expect(response.quickReplies, isNotNull);
    });

    test('why permission needed explains clearly', () {
      final response = ConversationTemplates.getResponse(
        UserIntent.whyPermissionNeeded,
      );

      expect(response.text, contains('Step Count Permission'));
      expect(response.text, contains('Activity Data Permission'));
      expect(response.text, contains('private'));
      expect(response.quickReplies, hasLength(2));
    });

    test('permission denied offers to help', () {
      final response = ConversationTemplates.getResponse(
        UserIntent.permissionDenied,
      );

      expect(response.text, contains('denied'));
      expect(response.text, contains('grant permission'));
      expect(response.quickReplies, hasLength(2));
    });

    test('steps not syncing asks for timeline', () {
      final response = ConversationTemplates.getResponse(
        UserIntent.stepsNotSyncing,
      );

      expect(response.text, contains('When did you last see'));
      expect(response.quickReplies, hasLength(4));
      expect(response.quickReplies![0].label, 'Today');
      expect(response.quickReplies![3].label, 'Never synced');
    });

    test('wrong step count explains possible causes', () {
      final response = ConversationTemplates.getResponse(
        UserIntent.wrongStepCount,
      );

      expect(response.text, contains('Multiple apps'));
      expect(response.text, contains('Manual entries'));
      expect(response.text, contains('Different algorithms'));
    });

    test('duplicate steps mentions multiple apps', () {
      final response = ConversationTemplates.getResponse(
        UserIntent.duplicateSteps,
      );

      expect(response.text, contains('multiple apps'));
      expect(response.text, contains('tracking'));
    });

    test('health connect not installed provides clear steps', () {
      final response = ConversationTemplates.getResponse(
        UserIntent.healthConnectNotInstalled,
      );

      expect(response.text, contains('Health Connect app'));
      expect(response.text, contains('Play Store'));
      expect(response.quickReplies, hasLength(2));
      expect(response.quickReplies![0].label, 'Open Play Store');
    });

    test('checking status shows diagnostic steps', () {
      final response = ConversationTemplates.getResponse(
        UserIntent.checkingStatus,
      );

      expect(response.text, contains('Checking'));
      expect(response.text, contains('Permissions'));
      expect(response.text, contains('Data sources'));
      expect(response.text, contains('Sync status'));
    });

    test('need help offers common options', () {
      final response = ConversationTemplates.getResponse(
        UserIntent.needHelp,
      );

      expect(response.text, contains('help'));
      expect(response.quickReplies, hasLength(4));
    });

    test('unclear intent provides options', () {
      final response = ConversationTemplates.getResponse(
        UserIntent.unclear,
      );

      expect(response.text, contains('not quite sure'));
      expect(response.quickReplies, hasLength(4));
      expect(response.quickReplies![0].label, 'Permissions & Settings');
    });

    test('all responses are bot messages', () {
      for (final intent in UserIntent.values) {
        final response = ConversationTemplates.getResponse(intent);
        expect(response.sender, MessageSender.bot);
        expect(response.text, isNotEmpty);
      }
    });

    test('no response is marked as error', () {
      for (final intent in UserIntent.values) {
        final response = ConversationTemplates.getResponse(intent);
        expect(response.isError, false);
      }
    });
  });
}
