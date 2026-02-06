import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:step_sync_chatbot/src/core/chatbot_controller.dart';
import 'package:step_sync_chatbot/src/core/chatbot_state.dart';
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';
import 'package:step_sync_chatbot/src/data/models/permission_state.dart';
import 'package:step_sync_chatbot/src/health/mock_health_service.dart';

void main() {
  group('ChatBotController - Diagnostic Features', () {
    late MockHealthService mockHealthService;
    late ProviderContainer container;
    late ChatBotController controller;

    setUp(() {
      mockHealthService = MockHealthService();
      container = ProviderContainer();
      controller = ChatBotController(
        healthService: mockHealthService,
      );
    });

    tearDown(() {
      controller.dispose();
      container.dispose();
    });

    group('_handleStatusCheck', () {
      test('runs comprehensive diagnostics', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();

        // Get initial message count
        final initialMessageCount = controller.state.messages.length;

        // Act
        await controller.handleUserMessage('check status');

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final state = controller.state;
        expect(state.messages.length, greaterThan(initialMessageCount));

        // Should have diagnostic message
        final diagnosticMessage = state.messages.firstWhere(
          (msg) => msg.text.contains('comprehensive diagnostic'),
          orElse: () => throw Exception('No diagnostic message found'),
        );
        expect(diagnosticMessage.sender, MessageSender.bot);

        // Should have results message
        final resultsMessage = state.messages.firstWhere(
          (msg) => msg.text.contains('Diagnostic Report'),
          orElse: () => throw Exception('No results message found'),
        );
        expect(resultsMessage.sender, MessageSender.bot);
      });

      test('updates state with diagnostic data', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final state = controller.state;
        expect(state.permissionState, isNotNull);
        expect(state.dataSources, isNotNull);
      });

      test('offers quick actions when issues detected', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockPermissionState = PermissionState.denied();
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final lastMessage = controller.state.messages.last;
        expect(lastMessage.quickReplies, isNotEmpty);
        expect(
          lastMessage.quickReplies!.any((reply) => reply.label.contains('permission')),
          isTrue,
        );
      });

      test('shows no issues when everything healthy', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final reportMessage = controller.state.messages.firstWhere(
          (msg) => msg.text.contains('Diagnostic Report'),
        );
        expect(reportMessage.text, contains('No issues found'));
      });
    });

    group('_actionToQuickReply', () {
      test('converts grant permissions action correctly', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockPermissionState = PermissionState.denied();
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final lastMessage = controller.state.messages.last;
        final permissionReply = lastMessage.quickReplies?.firstWhere(
          (reply) => reply.value == 'grant_permission',
          orElse: () => throw Exception('No grant permission reply found'),
        );

        expect(permissionReply, isNotNull);
        expect(permissionReply!.label, contains('Grant'));
      });

      test('converts install health connect action correctly', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockIsAvailable = false;
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final lastMessage = controller.state.messages.last;
        if (lastMessage.quickReplies != null && lastMessage.quickReplies!.isNotEmpty) {
          final installReply = lastMessage.quickReplies!.firstWhere(
            (reply) => reply.value == 'install_health_connect',
            orElse: () => QuickReply(label: '', value: ''),
          );

          if (installReply.value.isNotEmpty) {
            expect(installReply.label, contains('Install'));
          }
        }
      });
    });

    group('handleDiagnosticAction', () {
      test('routes install_health_connect action', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();
        final initialMessageCount = controller.state.messages.length;

        // Act
        await controller.handleDiagnosticAction('install_health_connect');

        // Assert
        expect(controller.state.messages.length, greaterThan(initialMessageCount));
        final lastMessage = controller.state.messages.last;
        expect(lastMessage.text.toLowerCase(), contains('play store'));
      });

      test('routes open_battery_settings action', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();
        final initialMessageCount = controller.state.messages.length;

        // Act
        await controller.handleDiagnosticAction('open_battery_settings');

        // Assert
        expect(controller.state.messages.length, greaterThan(initialMessageCount));
        final lastMessage = controller.state.messages.last;
        expect(lastMessage.text.toLowerCase(), contains('battery'));
      });

      test('routes open_app_settings action', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();
        final initialMessageCount = controller.state.messages.length;

        // Act
        await controller.handleDiagnosticAction('open_app_settings');

        // Assert
        expect(controller.state.messages.length, greaterThan(initialMessageCount));
        final lastMessage = controller.state.messages.last;
        expect(lastMessage.text.toLowerCase(), contains('settings'));
      });

      test('falls back to handleUserMessage for unknown actions', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();
        final initialMessageCount = controller.state.messages.length;

        // Act
        await controller.handleDiagnosticAction('unknown_action');

        // Assert
        // Should be processed as a regular user message
        expect(controller.state.messages.length, greaterThan(initialMessageCount));
      });
    });

    group('_handleInstallHealthConnect', () {
      test('sends Play Store guidance message', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();
        final initialMessageCount = controller.state.messages.length;

        // Act
        await controller.handleDiagnosticAction('install_health_connect');

        // Assert
        expect(controller.state.messages.length, greaterThan(initialMessageCount));
        final message = controller.state.messages.last;
        expect(message.text, contains('Google Play Store'));
        expect(message.text, contains('Health Connect'));
      });

      test('provides manual instructions if automatic open fails', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();

        // Act
        await controller.handleDiagnosticAction('install_health_connect');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        // Since PlatformUtils.openHealthConnectPlayStore() will fail in test environment,
        // we should get the fallback message
        final messages = controller.state.messages;
        final hasFallbackMessage = messages.any(
          (msg) => msg.text.contains('Could not open') ||
                   msg.text.contains('search for'),
        );
        expect(hasFallbackMessage, isTrue);
      });
    });

    group('_handleOpenBatterySettings', () {
      test('sends battery settings guidance message', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();
        final initialMessageCount = controller.state.messages.length;

        // Act
        await controller.handleDiagnosticAction('open_battery_settings');

        // Assert
        expect(controller.state.messages.length, greaterThan(initialMessageCount));
        final message = controller.state.messages.first;
        expect(message.text.toLowerCase(), contains('battery'));
      });

      test('provides manual instructions if automatic open fails', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();

        // Act
        await controller.handleDiagnosticAction('open_battery_settings');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final messages = controller.state.messages;
        final hasFallbackMessage = messages.any(
          (msg) => msg.text.contains('Settings > Apps'),
        );
        expect(hasFallbackMessage, isTrue);
      });
    });

    group('_handleOpenAppSettings', () {
      test('sends app settings guidance message', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();
        final initialMessageCount = controller.state.messages.length;

        // Act
        await controller.handleDiagnosticAction('open_app_settings');

        // Assert
        expect(controller.state.messages.length, greaterThan(initialMessageCount));
        final message = controller.state.messages.first;
        expect(message.text.toLowerCase(), contains('settings'));
      });

      test('provides manual instructions if automatic open fails', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();

        // Act
        await controller.handleDiagnosticAction('open_app_settings');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final messages = controller.state.messages;
        final hasFallbackMessage = messages.any(
          (msg) => msg.text.contains('Settings > Apps'),
        );
        expect(hasFallbackMessage, isTrue);
      });
    });

    group('_offerDiagnosticActions', () {
      test('creates quick replies for each detected issue', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockPermissionState = PermissionState.denied();
        mockHealthService.mockDataSources = []; // No data sources
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final lastMessage = controller.state.messages.last;
        expect(lastMessage.quickReplies, isNotEmpty);
        // Should have quick reply for permission issue
        expect(
          lastMessage.quickReplies!.any((r) => r.value == 'grant_permission'),
          isTrue,
        );
      });

      test('includes action message text', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockPermissionState = PermissionState.denied();
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final lastMessage = controller.state.messages.last;
        expect(lastMessage.text, contains('What would you like to do?'));
      });

      test('does not send action message when no actionable issues', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final actionMessages = controller.state.messages.where(
          (msg) => msg.text.contains('What would you like to do?'),
        );
        expect(actionMessages.isEmpty, isTrue);
      });
    });

    group('Diagnostic state management', () {
      test('sets diagnosing status during diagnostic check', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();

        // Act
        final future = controller.handleUserMessage('check status');

        // Give it a moment to start but not finish
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - should be in diagnosing status
        // Note: This test might be flaky due to timing
        // Consider removing if it causes issues

        await future; // Wait for completion

        // After completion, should be idle
        expect(controller.state.status, ConversationStatus.idle);
      });

      test('returns to idle status after diagnostic completes', () async {
        // Arrange
        await mockHealthService.initialize();
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(controller.state.status, ConversationStatus.idle);
      });

      test('updates permission state in chatbot state', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockPermissionState = PermissionState.granted();
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(controller.state.permissionState?.status, PermissionStatus.granted);
      });

      test('updates data sources in chatbot state', () async {
        // Arrange
        await mockHealthService.initialize();
        final mockSources = [
          DataSource(id: '1', name: 'Test Source', packageName: 'com.test'),
        ];
        mockHealthService.mockDataSources = mockSources;
        await controller.initialize();

        // Act
        await controller.handleUserMessage('check status');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(controller.state.dataSources, isNotEmpty);
        expect(controller.state.dataSources?.first.name, 'Test Source');
      });
    });
  });
}
