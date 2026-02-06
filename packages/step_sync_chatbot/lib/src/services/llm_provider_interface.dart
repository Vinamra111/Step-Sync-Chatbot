/// LLM Provider Interface - Abstraction for multiple AI providers
///
/// Allows switching between Groq, Azure OpenAI, or other providers
/// while maintaining consistent API and privacy guarantees.

import '../services/groq_chat_service.dart';

/// Abstract interface for LLM chat providers
abstract class LLMChatProvider {
  /// Send a message and get response
  ///
  /// Implementations must handle:
  /// - Rate limiting
  /// - Error handling and retries
  /// - Timeout management
  /// - Response validation
  Future<ChatResponse> sendMessage(
    String message, {
    List<ConversationMessage>? conversationHistory,
    String? systemPrompt,
  });

  /// Get provider name for logging/monitoring
  String get providerName;

  /// Check if provider is available
  Future<bool> isAvailable();

  /// Dispose resources
  void dispose();
}

/// Provider type enum
enum LLMProviderType {
  groq,
  azureOpenAI,
  openAI,
  anthropic,
}

/// Provider configuration
class LLMProviderConfig {
  final LLMProviderType type;
  final String apiKey;
  final String? endpoint; // For Azure OpenAI
  final String? deploymentName; // For Azure OpenAI
  final String model;
  final double temperature;
  final int maxTokens;
  final Duration timeout;

  const LLMProviderConfig({
    required this.type,
    required this.apiKey,
    this.endpoint,
    this.deploymentName,
    this.model = 'gpt-4',
    this.temperature = 0.7,
    this.maxTokens = 1024,
    this.timeout = const Duration(seconds: 30),
  });

  /// Create Groq configuration
  factory LLMProviderConfig.groq({
    required String apiKey,
    String model = 'llama-3.3-70b-versatile',
    double temperature = 0.7,
    int maxTokens = 1024,
  }) {
    return LLMProviderConfig(
      type: LLMProviderType.groq,
      apiKey: apiKey,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// Create Azure OpenAI configuration
  factory LLMProviderConfig.azureOpenAI({
    required String apiKey,
    required String endpoint,
    required String deploymentName,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) {
    return LLMProviderConfig(
      type: LLMProviderType.azureOpenAI,
      apiKey: apiKey,
      endpoint: endpoint,
      deploymentName: deploymentName,
      model: deploymentName, // Azure uses deployment name as model
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }
}
