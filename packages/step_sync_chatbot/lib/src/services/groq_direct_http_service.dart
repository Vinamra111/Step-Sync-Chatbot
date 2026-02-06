/// Direct HTTP Groq Chat Service - Bypasses LangChain for more control
///
/// This implementation makes direct HTTP requests to Groq API,
/// giving us complete control over headers and request formatting
/// to work around Cloudflare/WAF blocking issues.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logger/logger.dart';
import 'groq_chat_service.dart'; // For reusing models

// Development mode flag
const bool _kDevMode = true;

/// Direct HTTP implementation of Groq API
class GroqDirectHTTPService {
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final Duration timeout;
  final Logger _logger;
  late final http.Client _httpClient;

  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  GroqDirectHTTPService({
    required this.apiKey,
    this.model = 'llama-3.3-70b-versatile',
    this.temperature = 0.7,
    this.maxTokens = 1024,
    this.timeout = const Duration(seconds: 30),
    Logger? logger,
  }) : _logger = logger ?? Logger() {
    _initializeHttpClient();
  }

  void _initializeHttpClient() {
    final httpClient = HttpClient();

    // DEVELOPMENT ONLY: Accept all certificates
    if (_kDevMode) {
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        _logger.w('Accepting SSL certificate for $host (DEV MODE ONLY)');
        return true;
      };
    }

    // Set User-Agent to mimic a standard browser/client
    httpClient.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

    _httpClient = IOClient(httpClient);
    _logger.i('Direct HTTP Groq client initialized');
  }

  /// Send message directly to Groq API via HTTP
  Future<ChatResponse> sendMessage(
    String message, {
    List<ConversationMessage>? conversationHistory,
    String? systemPrompt,
  }) async {
    final startTime = DateTime.now();

    try {
      // Build messages array
      final messages = _buildMessages(message, conversationHistory, systemPrompt: systemPrompt);

      // Build request body
      final requestBody = {
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      };

      _logger.d('Sending direct HTTP request to Groq API');
      _logger.d('Request body: ${jsonEncode(requestBody)}');

      // Make HTTP POST request
      final response = await _httpClient
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              // Additional headers to appear more like a legitimate client
              'Accept-Encoding': 'gzip, deflate, br',
              'Accept-Language': 'en-US,en;q=0.9',
              'Origin': 'https://groq.com',
              'Referer': 'https://groq.com/',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      _logger.d('Response status: ${response.statusCode}');
      _logger.d('Response headers: ${response.headers}');
      _logger.d('Response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final content = responseData['choices'][0]['message']['content'] as String;
        final responseTime = DateTime.now().difference(startTime);

        _logger.i('✅ Direct HTTP request successful (${responseTime.inMilliseconds}ms)');

        return ChatResponse(
          content: content,
          tokenCount: _estimateTokenCount(content),
          responseTime: responseTime,
          wasSanitized: false, // Sanitization happens before this call
        );
      } else if (response.statusCode == 401) {
        throw GroqAPIException(
          'Invalid API key',
          statusCode: 401,
          originalError: response.body,
        );
      } else if (response.statusCode == 429) {
        throw GroqAPIException(
          'Rate limit exceeded',
          statusCode: 429,
          originalError: response.body,
        );
      } else if (response.statusCode == 403) {
        _logger.e('❌ HTTP 403 Forbidden - Cloudflare/WAF still blocking');
        _logger.e('Response body: ${response.body}');
        throw GroqAPIException(
          'Access forbidden - possible Cloudflare/WAF block',
          statusCode: 403,
          originalError: response.body,
        );
      } else {
        throw GroqAPIException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
          originalError: response.body,
        );
      }
    } on TimeoutException catch (e) {
      _logger.e('❌ Request timeout');
      throw GroqAPIException(
        'Request timeout after ${timeout.inSeconds}s',
        originalError: e,
      );
    } on SocketException catch (e) {
      _logger.e('❌ Network error: $e');
      throw GroqAPIException(
        'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      _logger.e('❌ Unexpected error: $e');
      throw GroqAPIException(
        'Unexpected error: $e',
        originalError: e,
      );
    }
  }

  /// Build messages array in OpenAI chat format
  List<Map<String, String>> _buildMessages(
    String userMessage,
    List<ConversationMessage>? history, {
    String? systemPrompt,
  }) {
    final messages = <Map<String, String>>[];

    // Add system prompt
    messages.add({
      'role': 'system',
      'content': systemPrompt ??
          'You are Step Sync Assistant. Help users fix step tracking issues. '
              'Be conversational, friendly, and action-oriented. '
              'Keep responses under 3 sentences unless more detail is needed.',
    });

    // Add conversation history
    if (history != null && history.isNotEmpty) {
      for (final msg in history) {
        messages.add({
          'role': msg.role, // 'user' or 'assistant'
          'content': msg.content,
        });
      }
    }

    // Add current message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    return messages;
  }

  /// Estimate token count (simple approximation)
  int _estimateTokenCount(String text) {
    // Rough approximation: 1 token ≈ 4 characters
    return (text.length / 4).ceil();
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
    _logger.d('Direct HTTP Groq client disposed');
  }
}
