/// Streaming Groq Chat Service
///
/// Implements Server-Sent Events (SSE) streaming for ChatGPT-like experience.
/// Features:
/// - Token-by-token streaming
/// - Real-time progressive display
/// - Cancellation support
/// - Error handling with graceful fallback

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../llm/llm_response.dart';
import 'phi_sanitizer_service.dart';
import 'groq_chat_service.dart';

/// Exception for streaming errors
class StreamingException implements Exception {
  final String message;
  final dynamic originalError;

  StreamingException(this.message, {this.originalError});

  @override
  String toString() => 'StreamingException: $message';
}

/// Groq Streaming Service with SSE support
class GroqStreamingService {
  final String apiKey;
  final String model;
  final Logger _logger;
  final PHISanitizerService _sanitizer;

  GroqStreamingService({
    required this.apiKey,
    this.model = 'llama-3.3-70b-versatile',
    Logger? logger,
    PHISanitizerService? sanitizer,
  })  : _logger = logger ?? Logger(),
        _sanitizer = sanitizer ?? PHISanitizerService(strictMode: false);

  /// Generate streaming response (ChatGPT-like experience)
  ///
  /// Returns a stream of [LLMStreamChunk] objects for progressive display.
  ///
  /// Example usage:
  /// ```dart
  /// String fullResponse = '';
  /// await for (final chunk in service.generateStreamingResponse('Hello')) {
  ///   fullResponse += chunk.content;
  ///   print(chunk.content); // Display progressively
  ///   if (chunk.isComplete) break;
  /// }
  /// ```
  Stream<LLMStreamChunk> generateStreamingResponse(
    String message, {
    List<ConversationMessage>? conversationHistory,
    String? systemPrompt,
  }) async* {
    _logger.d('Starting streaming response for message (${message.length} chars)');

    // Sanitize input
    final sanitizationResult = _sanitizer.sanitize(message);
    if (sanitizationResult.wasSanitized) {
      _logger.w('PHI sanitized: ${sanitizationResult.replacementCount} replacements');
    }

    // Build request body
    final requestBody = _buildStreamingRequest(
      sanitizationResult.sanitizedText,
      conversationHistory,
      systemPrompt,
    );

    try {
      // Create HTTP client and request
      final client = http.Client();
      final request = http.Request(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });

      request.body = jsonEncode(requestBody);

      // Send request and get streaming response
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        _logger.e('Streaming API error: ${streamedResponse.statusCode} - $errorBody');
        yield LLMStreamChunk.error('API error: ${streamedResponse.statusCode}');
        return;
      }

      _logger.d('Streaming started successfully');

      // Process SSE stream
      int promptTokens = 0;
      int completionTokens = 0;
      String finishReason = 'stop';

      await for (final chunk in _processSSEStream(streamedResponse.stream)) {
        if (chunk.isComplete) {
          // Store token counts from final chunk
          if (chunk.promptTokens != null) promptTokens = chunk.promptTokens!;
          if (chunk.completionTokens != null) completionTokens = chunk.completionTokens!;
          if (chunk.finishReason != null) finishReason = chunk.finishReason!;
        }

        yield chunk;

        // Stop if complete
        if (chunk.isComplete) {
          break;
        }
      }

      _logger.i('Streaming completed: $completionTokens tokens, finish: $finishReason');

      // Clean up
      client.close();
    } catch (e, stackTrace) {
      _logger.e('Streaming error: $e', error: e, stackTrace: stackTrace);
      yield LLMStreamChunk.error('Streaming failed: ${e.toString()}');
    }
  }

  /// Process Server-Sent Events (SSE) stream
  Stream<LLMStreamChunk> _processSSEStream(Stream<List<int>> byteStream) async* {
    String buffer = '';

    await for (final bytes in byteStream) {
      final chunk = utf8.decode(bytes);
      buffer += chunk;

      // Split by newlines to process complete SSE events
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // Keep incomplete line in buffer

      for (final line in lines) {
        if (line.isEmpty) continue;

        // SSE format: "data: {json}"
        if (line.startsWith('data: ')) {
          final jsonData = line.substring(6); // Remove "data: " prefix

          // Check for [DONE] marker
          if (jsonData.trim() == '[DONE]') {
            yield LLMStreamChunk.done();
            return;
          }

          try {
            final data = jsonDecode(jsonData) as Map<String, dynamic>;
            final streamChunk = _parseStreamChunk(data);

            if (streamChunk != null) {
              yield streamChunk;
            }
          } catch (e) {
            _logger.w('Failed to parse SSE chunk: $e');
            // Continue processing other chunks
          }
        }
      }
    }
  }

  /// Parse individual stream chunk from Groq API
  LLMStreamChunk? _parseStreamChunk(Map<String, dynamic> data) {
    try {
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        return null;
      }

      final choice = choices[0] as Map<String, dynamic>;
      final delta = choice['delta'] as Map<String, dynamic>?;

      if (delta == null) {
        return null;
      }

      // Extract content
      final content = delta['content'] as String? ?? '';

      // Check if this is the final chunk
      final finishReason = choice['finish_reason'] as String?;
      if (finishReason != null) {
        // Extract token usage (only available on final chunk)
        final usage = data['usage'] as Map<String, dynamic>?;
        if (usage != null) {
          return LLMStreamChunk.done(
            finishReason: finishReason,
            promptTokens: usage['prompt_tokens'] as int?,
            completionTokens: usage['completion_tokens'] as int?,
          );
        }

        return LLMStreamChunk.done(finishReason: finishReason);
      }

      // Return content chunk
      if (content.isNotEmpty) {
        return LLMStreamChunk.content(content);
      }

      return null;
    } catch (e) {
      _logger.w('Error parsing stream chunk: $e');
      return null;
    }
  }

  /// Build request body for streaming API call
  Map<String, dynamic> _buildStreamingRequest(
    String userMessage,
    List<ConversationMessage>? history,
    String? systemPrompt,
  ) {
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': systemPrompt ??
            'You are Step Sync Assistant. Help users fix step tracking issues. '
            'Be conversational, friendly, and action-oriented. '
            'Keep responses under 3 sentences unless more detail is needed.',
      },
    ];

    // Add conversation history
    if (history != null && history.isNotEmpty) {
      for (final msg in history) {
        messages.add({
          'role': msg.role,
          'content': msg.content,
        });
      }
    }

    // Add current user message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    return {
      'model': model,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 1024,
      'stream': true, // Enable streaming
    };
  }

  /// Cancel a streaming response (if in progress)
  ///
  /// Note: HTTP streams can't be truly cancelled mid-flight,
  /// but the consumer can stop listening to the stream.
  void cancelStream() {
    _logger.d('Stream cancellation requested');
    // The consumer should call StreamSubscription.cancel()
    // on their end when they want to stop receiving chunks.
  }
}
