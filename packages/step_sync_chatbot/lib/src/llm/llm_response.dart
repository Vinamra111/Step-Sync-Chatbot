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

/// A chunk of streaming response from an LLM provider.
///
/// Used for ChatGPT-like token-by-token streaming.
@freezed
class LLMStreamChunk with _$LLMStreamChunk {
  const factory LLMStreamChunk({
    /// The incremental text content for this chunk.
    /// Example: "Hello" → " there" → "!" → "[DONE]"
    required String content,

    /// Whether this is the final chunk in the stream.
    @Default(false) bool isComplete,

    /// Finish reason (if complete): "stop", "length", "error"
    String? finishReason,

    /// Token usage (only available on final chunk).
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,

    /// Metadata for this chunk.
    @Default({}) Map<String, dynamic> metadata,
  }) = _LLMStreamChunk;

  factory LLMStreamChunk.fromJson(Map<String, dynamic> json) =>
      _$LLMStreamChunkFromJson(json);

  /// Create a content chunk (partial response).
  factory LLMStreamChunk.content(String text) {
    return LLMStreamChunk(content: text);
  }

  /// Create the final chunk (marks completion).
  factory LLMStreamChunk.done({
    String finishReason = 'stop',
    int? promptTokens,
    int? completionTokens,
  }) {
    return LLMStreamChunk(
      content: '',
      isComplete: true,
      finishReason: finishReason,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: (promptTokens ?? 0) + (completionTokens ?? 0),
    );
  }

  /// Create an error chunk.
  factory LLMStreamChunk.error(String errorMessage) {
    return LLMStreamChunk(
      content: '',
      isComplete: true,
      finishReason: 'error',
      metadata: {'error': errorMessage},
    );
  }
}
