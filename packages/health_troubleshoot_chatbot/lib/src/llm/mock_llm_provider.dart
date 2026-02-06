import 'package:step_sync_chatbot/src/llm/llm_provider.dart';
import 'package:step_sync_chatbot/src/llm/llm_response.dart';

/// Mock LLM provider for testing and development.
///
/// Simulates LLM responses without actually calling an external API.
class MockLLMProvider implements LLMProvider {
  final int simulatedDelayMs;
  final bool simulateSuccess;
  String? _mockResponse;

  MockLLMProvider({
    this.simulatedDelayMs = 800,
    this.simulateSuccess = true,
  });

  /// Set a custom mock response for testing.
  void setMockResponse(String response) {
    _mockResponse = response;
  }

  @override
  Future<LLMResponse> generateResponse({
    required String prompt,
    List<ConversationMessage>? conversationHistory,
    String? systemPrompt,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: simulatedDelayMs));

    if (!simulateSuccess) {
      return LLMResponse.error(
        errorMessage: 'Simulated error for testing',
        provider: 'Mock LLM',
        model: 'mock-model',
      );
    }

    // Generate mock response based on prompt
    final responseText = _mockResponse ?? _generateMockResponse(prompt);

    // Simulate token usage (rough estimate: ~4 chars per token)
    final promptTokens = (prompt.length / 4).ceil();
    final completionTokens = (responseText.length / 4).ceil();

    return LLMResponse(
      text: responseText,
      provider: 'Mock LLM',
      model: 'mock-model-v1',
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: promptTokens + completionTokens,
      estimatedCost: (promptTokens + completionTokens) * 0.000002, // $0.002 per 1K tokens
      responseTimeMs: simulatedDelayMs,
      success: true,
      timestamp: DateTime.now(),
      metadata: {'mock': true},
    );
  }

  String _generateMockResponse(String prompt) {
    final lowerPrompt = prompt.toLowerCase();

    // Intent-based mock responses (check more specific patterns first)

    // Check battery/background before sync (more specific)
    if (lowerPrompt.contains('battery') || lowerPrompt.contains('background')) {
      return 'Battery optimization settings can prevent background syncing. '
          'Let me help you adjust these settings.';
    }

    if (lowerPrompt.contains('permission') || lowerPrompt.contains('access')) {
      return 'It seems you\'re having permission issues. I can help you grant '
          'the necessary permissions to track your steps.';
    }

    if (lowerPrompt.contains('install') || lowerPrompt.contains('health connect')) {
      return 'You may need to install Health Connect from the Google Play Store. '
          'I can guide you through the installation process.';
    }

    if (lowerPrompt.contains('sync') || lowerPrompt.contains('not updating')) {
      return 'Step syncing issues can have several causes. Let me run a diagnostic '
          'to identify the problem.';
    }

    if (lowerPrompt.contains('multiple') || lowerPrompt.contains('apps') ||
        lowerPrompt.contains('sources')) {
      return 'Having multiple apps tracking steps can cause conflicts. '
          'I recommend selecting a primary data source.';
    }

    if (lowerPrompt.contains('error') || lowerPrompt.contains('failed')) {
      return 'I understand you\'re experiencing an error. Can you tell me more about '
          'when this error occurs?';
    }

    // Generic fallback
    return 'I\'m here to help you with step tracking issues. Could you provide more '
        'details about the problem you\'re experiencing?';
  }

  @override
  Future<bool> isAvailable() async {
    return true; // Mock is always available
  }

  @override
  String getProviderName() => 'Mock LLM';

  @override
  void dispose() {
    // Nothing to dispose
  }
}
