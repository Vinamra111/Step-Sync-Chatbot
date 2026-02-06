import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/llm/mock_llm_provider.dart';
import 'package:step_sync_chatbot/src/llm/llm_provider.dart';

void main() {
  group('MockLLMProvider', () {
    late MockLLMProvider provider;

    setUp(() {
      provider = MockLLMProvider(simulatedDelayMs: 100);
    });

    tearDown(() {
      provider.dispose();
    });

    group('Basic Functionality', () {
      test('generates response successfully', () async {
        // Arrange
        const prompt = 'My steps are not syncing';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.success, isTrue);
        expect(response.text, isNotEmpty);
        expect(response.provider, 'Mock LLM');
        expect(response.model, 'mock-model-v1');
      });

      test('simulates delay', () async {
        // Arrange
        provider = MockLLMProvider(simulatedDelayMs: 500);
        const prompt = 'Test delay';
        final startTime = DateTime.now();

        // Act
        await provider.generateResponse(prompt: prompt);

        // Assert
        final endTime = DateTime.now();
        final elapsed = endTime.difference(startTime).inMilliseconds;
        expect(elapsed, greaterThanOrEqualTo(400)); // Allow some variance
      });

      test('returns token usage estimates', () async {
        // Arrange
        const prompt = 'Test prompt for token counting';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.promptTokens, greaterThan(0));
        expect(response.completionTokens, greaterThan(0));
        expect(response.totalTokens, response.promptTokens + response.completionTokens);
      });

      test('estimates cost', () async {
        // Arrange
        const prompt = 'Cost estimation test';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.estimatedCost, greaterThan(0));
        expect(response.estimatedCost, lessThan(0.01)); // Should be small for mock
      });

      test('includes response time', () async {
        // Arrange
        const prompt = 'Response time test';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.responseTimeMs, greaterThan(0));
      });

      test('includes timestamp', () async {
        // Arrange
        const prompt = 'Timestamp test';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.timestamp, isNotNull);
      });
    });

    group('Custom Responses', () {
      test('uses custom mock response when set', () async {
        // Arrange
        const customResponse = 'This is a custom test response';
        provider.setMockResponse(customResponse);

        // Act
        final response = await provider.generateResponse(prompt: 'anything');

        // Assert
        expect(response.text, customResponse);
      });

      test('generates intent-based responses for permissions', () async {
        // Arrange
        const prompt = 'I need to grant permissions';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.text.toLowerCase(), contains('permission'));
      });

      test('generates intent-based responses for syncing', () async {
        // Arrange
        const prompt = 'My steps are not syncing';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.text.toLowerCase(), contains('sync'));
      });

      test('generates intent-based responses for Health Connect', () async {
        // Arrange
        const prompt = 'Do I need to install Health Connect?';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.text.toLowerCase(), contains('health connect'));
      });

      test('generates intent-based responses for battery', () async {
        // Arrange
        const prompt = 'Battery optimization is blocking sync';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.text.toLowerCase(), contains('battery'));
      });

      test('generates generic response for unclear prompts', () async {
        // Arrange
        const prompt = 'xyz abc';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.text, isNotEmpty);
        expect(response.success, isTrue);
      });
    });

    group('Conversation History', () {
      test('accepts conversation history', () async {
        // Arrange
        const prompt = 'What about now?';
        final history = [
          ConversationMessage(role: 'user', content: 'Steps not syncing'),
          ConversationMessage(role: 'assistant', content: 'Let me help'),
        ];

        // Act
        final response = await provider.generateResponse(
          prompt: prompt,
          conversationHistory: history,
        );

        // Assert
        expect(response.success, isTrue);
      });

      test('accepts system prompt', () async {
        // Arrange
        const prompt = 'Help me';
        const systemPrompt = 'You are a helpful assistant';

        // Act
        final response = await provider.generateResponse(
          prompt: prompt,
          systemPrompt: systemPrompt,
        );

        // Assert
        expect(response.success, isTrue);
      });
    });

    group('Error Simulation', () {
      test('simulates error when configured', () async {
        // Arrange
        provider = MockLLMProvider(
          simulatedDelayMs: 100,
          simulateSuccess: false,
        );
        const prompt = 'This should fail';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.success, isFalse);
        expect(response.errorMessage, isNotNull);
        expect(response.text, isEmpty);
      });
    });

    group('Provider Info', () {
      test('returns provider name', () {
        // Act
        final name = provider.getProviderName();

        // Assert
        expect(name, 'Mock LLM');
      });

      test('is always available', () async {
        // Act
        final available = await provider.isAvailable();

        // Assert
        expect(available, isTrue);
      });
    });

    group('Metadata', () {
      test('includes mock flag in metadata', () async {
        // Arrange
        const prompt = 'Metadata test';

        // Act
        final response = await provider.generateResponse(prompt: prompt);

        // Assert
        expect(response.metadata['mock'], isTrue);
      });
    });
  });
}
