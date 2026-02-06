import 'package:step_sync_chatbot/src/llm/llm_response.dart';

/// Abstract interface for Language Model providers.
///
/// This allows swapping between different LLM providers
/// (Azure OpenAI, AWS Bedrock, local models, etc.)
abstract class LLMProvider {
  /// Generate a response from the LLM.
  ///
  /// [prompt]: The sanitized user input
  /// [conversationHistory]: Previous messages for context (optional)
  /// [systemPrompt]: System instructions for the LLM
  ///
  /// Returns a [LLMResponse] with the generated text and metadata.
  Future<LLMResponse> generateResponse({
    required String prompt,
    List<ConversationMessage>? conversationHistory,
    String? systemPrompt,
  });

  /// Check if the provider is available and configured.
  Future<bool> isAvailable();

  /// Get the provider name (e.g., "Azure OpenAI", "AWS Bedrock").
  String getProviderName();

  /// Dispose resources.
  void dispose();
}

/// A single message in conversation history.
class ConversationMessage {
  final String role; // "user", "assistant", "system"
  final String content;

  ConversationMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}
