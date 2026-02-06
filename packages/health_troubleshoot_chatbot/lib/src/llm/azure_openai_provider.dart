import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:step_sync_chatbot/src/llm/llm_provider.dart';
import 'package:step_sync_chatbot/src/llm/llm_response.dart';

/// Azure OpenAI LLM provider with HIPAA-compliant configuration.
///
/// Requires Azure OpenAI account with:
/// - Business Associate Agreement (BAA) signed
/// - Data residency configured
/// - No training on customer data guarantee
class AzureOpenAIProvider implements LLMProvider {
  final String endpoint;
  final String apiKey;
  final String deploymentName;
  final String apiVersion;
  final int maxTokens;
  final double temperature;
  final http.Client? httpClient;

  AzureOpenAIProvider({
    required this.endpoint,
    required this.apiKey,
    required this.deploymentName,
    this.apiVersion = '2024-02-15-preview',
    this.maxTokens = 500,
    this.temperature = 0.7,
    this.httpClient,
  });

  @override
  Future<LLMResponse> generateResponse({
    required String prompt,
    List<ConversationMessage>? conversationHistory,
    String? systemPrompt,
  }) async {
    final startTime = DateTime.now();

    try {
      // Build messages array
      final messages = <Map<String, dynamic>>[];

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }

      // Add conversation history
      if (conversationHistory != null) {
        messages.addAll(
          conversationHistory.map((msg) => msg.toJson()).toList(),
        );
      }

      // Add current user prompt
      messages.add({
        'role': 'user',
        'content': prompt,
      });

      // Build request URL
      final url = Uri.parse(
        '$endpoint/openai/deployments/$deploymentName/chat/completions?api-version=$apiVersion',
      );

      // Build request body
      final requestBody = {
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'top_p': 0.95,
        'frequency_penalty': 0,
        'presence_penalty': 0,
      };

      // Make API request
      final client = httpClient ?? http.Client();
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'api-key': apiKey,
        },
        body: jsonEncode(requestBody),
      );

      final endTime = DateTime.now();
      final responseTimeMs = endTime.difference(startTime).inMilliseconds;

      // Handle response
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        final choices = jsonResponse['choices'] as List;
        if (choices.isEmpty) {
          return LLMResponse.error(
            errorMessage: 'No response choices returned from Azure OpenAI',
            provider: 'Azure OpenAI',
            model: deploymentName,
          );
        }

        final firstChoice = choices[0] as Map<String, dynamic>;
        final message = firstChoice['message'] as Map<String, dynamic>;
        final content = message['content'] as String;

        // Extract usage information
        final usage = jsonResponse['usage'] as Map<String, dynamic>?;
        final promptTokens = usage?['prompt_tokens'] as int? ?? 0;
        final completionTokens = usage?['completion_tokens'] as int? ?? 0;
        final totalTokens = usage?['total_tokens'] as int? ?? 0;

        // Estimate cost (GPT-4o-mini pricing as of 2024)
        // Input: $0.150 per 1M tokens, Output: $0.600 per 1M tokens
        final estimatedCost = (promptTokens * 0.150 / 1000000) +
            (completionTokens * 0.600 / 1000000);

        return LLMResponse(
          text: content,
          provider: 'Azure OpenAI',
          model: deploymentName,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          totalTokens: totalTokens,
          estimatedCost: estimatedCost,
          responseTimeMs: responseTimeMs,
          success: true,
          timestamp: DateTime.now(),
          metadata: {
            'finish_reason': firstChoice['finish_reason'],
          },
        );
      } else {
        // Handle error response
        String errorMessage;
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>;
          errorMessage = error['message'] as String? ?? 'Unknown error';
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        }

        return LLMResponse.error(
          errorMessage: errorMessage,
          provider: 'Azure OpenAI',
          model: deploymentName,
        );
      }
    } catch (e) {
      return LLMResponse.error(
        errorMessage: 'Failed to call Azure OpenAI: $e',
        provider: 'Azure OpenAI',
        model: deploymentName,
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    // Simple check: verify endpoint and API key are provided
    if (endpoint.isEmpty || apiKey.isEmpty || deploymentName.isEmpty) {
      return false;
    }

    // TODO: Optionally ping the API to verify it's reachable
    return true;
  }

  @override
  String getProviderName() => 'Azure OpenAI';

  @override
  void dispose() {
    // Close HTTP client if we own it
    if (httpClient != null) {
      httpClient!.close();
    }
  }
}
