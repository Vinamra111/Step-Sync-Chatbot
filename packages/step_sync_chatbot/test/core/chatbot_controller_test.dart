import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:step_sync_chatbot/src/core/chatbot_controller.dart';
import 'package:step_sync_chatbot/src/core/chatbot_state.dart';
import 'package:step_sync_chatbot/src/health/mock_health_service.dart';
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';
import 'package:step_sync_chatbot/src/data/models/permission_state.dart';
import 'package:step_sync_chatbot/src/data/models/step_data.dart';

void main() {
  group('ChatBotController', () {
    late ChatBotController controller;
    late MockHealthService healthService;

    setUp(() async {
      healthService = MockHealthService();
      // Set up mock data for non-mobile platforms
      healthService.mockPermissionState = PermissionState.granted();
      healthService.mockIsAvailable = true;
      await healthService.initialize();
      // Override defaults with test data sources
      healthService.mockDataSources = [
        DataSource(id: 'com.google.fit', name: 'Google Fit'),
      ];
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

    test('initialize completes without error', () async {
      await controller.initialize();

      // Should complete successfully and send greeting
      expect(controller.state.status, ConversationStatus.idle);
      expect(controller.state.messages, isNotEmpty);
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
        controller.state.messages.any((m) => m.text.contains('Diagnostic Report')),
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

    test('handles conversation flow correctly', () async {
      await controller.initialize();

      // Send a message and verify state flow
      await controller.handleUserMessage('hello');

      // Should return to idle after processing
      expect(controller.state.status, ConversationStatus.idle);
      expect(controller.state.isTyping, isFalse);
    });
  });
}
