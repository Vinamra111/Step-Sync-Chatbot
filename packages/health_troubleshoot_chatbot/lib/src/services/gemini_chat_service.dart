/// Google Gemini Chat Service - Free LLM API (Direct HTTP)
///
/// Uses Google's Gemini REST API directly to bypass SSL certificate issues.
/// Features:
/// - Direct HTTP calls with SSL bypass for development
/// - Generous free tier (15 requests/minute for Flash, 2 req/min for Pro)
/// - Excellent quality responses
/// - No Cloudflare/WAF blocking

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logger/logger.dart';
import 'groq_chat_service.dart'; // For reusing models

// Development mode flag - set to false before production deployment
const bool _kDevMode = true;

/// Configuration for Gemini chat service
class GeminiChatConfig {
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final Duration timeout;

  const GeminiChatConfig({
    required this.apiKey,
    this.model = 'gemini-pro', // Fast and free
    this.temperature = 0.7,
    this.maxTokens = 1024,
    this.timeout = const Duration(seconds: 30),
  });
}

/// Google Gemini Chat Service (Direct HTTP Implementation)
class GeminiChatService {
  final GeminiChatConfig config;
  final Logger _logger;
  late final http.Client _httpClient;

  GeminiChatService({
    required this.config,
    Logger? logger,
  }) : _logger = logger ?? Logger() {
    _initializeHttpClient();
  }

  void _initializeHttpClient() {
    final httpClient = HttpClient();

    // DEVELOPMENT ONLY: Accept all certificates in dev mode
    if (_kDevMode) {
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        _logger.w('Accepting SSL certificate for $host (DEV MODE ONLY)');
        return true;
      };
    }

    // Set User-Agent
    httpClient.userAgent = 'Step-Sync-ChatBot/1.0 (Dart; Flutter)';

    _httpClient = IOClient(httpClient);
    _logger.i('Gemini Chat Service initialized: ${config.model}');
  }

  /// Send a message and get response
  Future<ChatResponse> sendMessage(
    String message, {
    List<ConversationMessage>? conversationHistory,
    String? systemPrompt,
  }) async {
    _logger.d('Sending message to Gemini (${message.length} chars)');

    final startTime = DateTime.now();

    try {
      // Build the full prompt
      final fullPrompt = _buildPrompt(
        message,
        conversationHistory,
        systemPrompt: systemPrompt,
      );

      _logger.d('Full prompt length: ${fullPrompt.length} chars');

      // Build request URL
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=${config.apiKey}',
      );

      // Build request body
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': fullPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': config.temperature,
          'maxOutputTokens': config.maxTokens,
        },
      };

      _logger.d('Sending request to Gemini API');

      // Make HTTP POST request
      final response = await _httpClient
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(config.timeout);

      _logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Extract text from response
        final candidates = responseData['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw GeminiAPIException('No candidates in response');
        }

        final content = candidates[0]['content'] as Map<String, dynamic>?;
        if (content == null) {
          throw GeminiAPIException('No content in response');
        }

        final parts = content['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          throw GeminiAPIException('No parts in content');
        }

        final text = parts[0]['text'] as String?;
        if (text == null || text.isEmpty) {
          throw GeminiAPIException('Empty text in response');
        }

        final responseTime = DateTime.now().difference(startTime);
        _logger.i('✅ Gemini response received (${responseTime.inMilliseconds}ms)');

        return ChatResponse(
          content: text,
          tokenCount: _estimateTokenCount(text),
          responseTime: responseTime,
          wasSanitized: false,
        );
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw GeminiAPIException(
          'Invalid request: ${errorData['error']['message']}',
          statusCode: 400,
          originalError: errorData,
        );
      } else if (response.statusCode == 403) {
        throw GeminiAPIException(
          'Invalid API key',
          statusCode: 403,
          originalError: response.body,
        );
      } else if (response.statusCode == 429) {
        throw GeminiAPIException(
          'Rate limit exceeded',
          statusCode: 429,
          originalError: response.body,
        );
      } else {
        throw GeminiAPIException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
          originalError: response.body,
        );
      }
    } on TimeoutException catch (e) {
      _logger.e('❌ Gemini request timeout: $e');
      throw GeminiAPIException(
        'Request timeout after ${config.timeout.inSeconds}s',
        originalError: e,
      );
    } on SocketException catch (e) {
      _logger.e('❌ Network error: $e');
      throw GeminiAPIException(
        'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      if (e is GeminiAPIException) rethrow;
      _logger.e('❌ Unexpected error: $e');
      throw GeminiAPIException(
        'Unexpected error: $e',
        originalError: e,
      );
    }
  }

  /// Build full prompt with system instructions and conversation history
  String _buildPrompt(
    String userMessage,
    List<ConversationMessage>? history, {
    String? systemPrompt,
  }) {
    final buffer = StringBuffer();

    // Add system prompt as instructions
    buffer.writeln('SYSTEM INSTRUCTIONS:');
    buffer.writeln(
      systemPrompt ??
          'You are Step Sync Assistant. Help users fix step tracking issues. '
              'Be conversational, friendly, and action-oriented. '
              'Keep responses under 3 sentences unless more detail is needed.',
    );
    buffer.writeln();

    // Add conversation history
    if (history != null && history.isNotEmpty) {
      buffer.writeln('CONVERSATION HISTORY:');
      for (final msg in history) {
        final role = msg.isUser ? 'User' : 'Assistant';
        buffer.writeln('$role: ${msg.content}');
      }
      buffer.writeln();
    }

    // Add current user message
    buffer.writeln('USER:');
    buffer.writeln(userMessage);
    buffer.writeln();
    buffer.writeln('ASSISTANT:');

    return buffer.toString();
  }

  /// Estimate token count (simple approximation)
  int _estimateTokenCount(String text) {
    // Rough approximation: 1 token ≈ 4 characters
    return (text.length / 4).ceil();
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
    _logger.d('Gemini Chat Service disposed');
  }
}

/// Exception for Gemini API errors
class GeminiAPIException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  GeminiAPIException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'GeminiAPIException: $message (status: $statusCode)';
}
