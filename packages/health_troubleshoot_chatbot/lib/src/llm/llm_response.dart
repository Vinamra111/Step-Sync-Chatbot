import 'package:freezed_annotation/freezed_annotation.dart';

part 'llm_response.freezed.dart';
part 'llm_response.g.dart';

/// Response from an LLM provider.
@freezed
class LLMResponse with _$LLMResponse {
  const factory LLMResponse({
    /// Generated response text.
    required String text,

    /// Provider that generated the response.
    required String provider,

    /// Model used for generation.
    required String model,

    /// Number of tokens in the prompt.
    @Default(0) int promptTokens,

    /// Number of tokens in the completion.
    @Default(0) int completionTokens,

    /// Total tokens used.
    @Default(0) int totalTokens,

    /// Estimated cost in USD.
    @Default(0.0) double estimatedCost,

    /// Response time in milliseconds.
    @Default(0) int responseTimeMs,

    /// Whether the response was successful.
    @Default(true) bool success,

    /// Error message if failed.
    String? errorMessage,

    /// Timestamp when response was generated.
    DateTime? timestamp,

    /// Additional metadata from provider.
    @Default({}) Map<String, dynamic> metadata,
  }) = _LLMResponse;

  factory LLMResponse.fromJson(Map<String, dynamic> json) =>
      _$LLMResponseFromJson(json);

  /// Create an error response.
  factory LLMResponse.error({
    required String errorMessage,
    required String provider,
    String model = 'unknown',
  }) {
    return LLMResponse(
      text: '',
      provider: provider,
      model: model,
      success: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }
}
