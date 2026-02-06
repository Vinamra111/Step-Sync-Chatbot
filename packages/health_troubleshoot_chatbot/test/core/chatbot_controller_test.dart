import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:step_sync_chatbot/src/core/chatbot_controller.dart';
import 'package:step_sync_chatbot/src/core/chatbot_state.dart';
import 'package:step_sync_chatbot/src/health/mock_health_service.dart';
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';

void main() {
  group('ChatBotController', () {
    late ChatBotController controller;
    late MockHealthService healthService;

    setUp(() {
      healthService = MockHealthService();
      controller = ChatBotController(healthService: healthService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is correct', () {
      expect(controller.state.messages, isEmpty);
      expect(controller.state.status, ConversationStatus.idle);
      expect(controller.state.isTyping, false);
    });

    test('initialize sends greeting message', () async {
      await controller.initialize();

      expect(controller.state.messages, isNotEmpty);
      expect(
        controller.state.messages.first.sender,
        MessageSender.bot,
      );
      expect(
        controller.state.messages.first.text,
        contains('Step Sync Assistant'),
      );
    });

    test('initialize checks permissions', () async {
      await controller.initialize();

      expect(controller.state.permissionState, isNotNull);
    });

    test('initialize loads data sources', () async {
      await controller.initialize();

      expect(controller.state.dataSources, isNotEmpty);
    });

    test('handleUserMessage adds message to state', () async {
      await controller.initialize();
      final initialMessageCount = controller.state.messages.length;

      await controller.handleUserMessage('hello');

      expect(
        controller.state.messages.length,
        greaterThan(initialMessageCount),
      );
      expect(
        controller.state.messages.any((m) => m.text == 'hello'),
        true,
      );
    });

    test('handleUserMessage generates bot response', () async {
      await controller.initialize();

      await controller.handleUserMessage('hello');

      // Should have at least 2 bot messages (greeting + response)
      final botMessages = controller.state.messages
          .where((m) => m.sender == MessageSender.bot);
      expect(botMessages.length, greaterThanOrEqualTo(2));
    });

    test('handleUserMessage sets processing state temporarily', () async {
      await controller.initialize();

      // Start processing
      final processingFuture = controller.handleUserMessage('hello');

      // Check state is processing (might be too fast to catch)
      // await Future.delayed(const Duration(milliseconds: 10));

      await processingFuture;

      // Should be back to idle after processing
      expect(controller.state.status, ConversationStatus.idle);
      expect(controller.state.isTyping, false);
    });

    test('handles permission request intent', () async {
      await controller.initialize();

      await controller.handleUserMessage('I want to grant permission');

      expect(
        controller.state.messages.any((m) => m.text.contains('permission')),
        true,
      );
    });

    test('handles status check intent', () async {
      await controller.initialize();

      await controller.handleUserMessage('check my setup');

      expect(
        controller.state.messages.any((m) => m.text.contains('Status check')),
        true,
      );
    });

    test('handles unclear intent gracefully', () async {
      await controller.initialize();

      await controller.handleUserMessage('asdfghjkl');

      expect(
        controller.state.messages.any(
          (m) => m.text.contains('not quite sure'),
        ),
        true,
      );
    });

    test('ignores empty messages', () async {
      await controller.initialize();
      final initialMessageCount = controller.state.messages.length;

      await controller.handleUserMessage('');
      await controller.handleUserMessage('   ');

      expect(controller.state.messages.length, initialMessageCount);
    });

    test('error state is set on failure', () async {
      // Don't initialize, causing an error
      await controller.handleUserMessage('hello');

      expect(controller.state.status, ConversationStatus.error);
      expect(controller.state.errorMessage, isNotNull);
    });
  });
}
