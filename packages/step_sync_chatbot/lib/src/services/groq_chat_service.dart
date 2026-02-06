/// Production Groq Chat Service
///
/// Wraps Groq API via LangChain with:
/// - Error handling and retry logic
/// - Rate limiting
/// - Response validation
/// - Timeout handling
/// - Automatic PHI sanitization

import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'phi_sanitizer_service.dart';
import 'circuit_breaker.dart';
import 'token_counter.dart';

// Development mode flag - set to false before production deployment
const bool _kDevMode = true;

/// Exception for Groq API errors
class GroqAPIException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  GroqAPIException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'GroqAPIException: $message (status: $statusCode)';
}

/// Configuration for Groq chat service
class GroqChatConfig {
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;
  final CircuitBreakerConfig? circuitBreakerConfig;

  const GroqChatConfig({
    required this.apiKey,
    this.model = 'llama-3.3-70b-versatile',
    this.temperature = 0.7,
    this.maxTokens = 1024,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.circuitBreakerConfig,
  });
}

/// Conversation message with metadata (renamed to avoid conflict with LangChain's ChatMessage)
class ConversationMessage {
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ConversationMessage({
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// Response from chat service
class ChatResponse {
  final String content;
  final int tokenCount;
  final Duration responseTime;
  final bool wasSanitized;

  ChatResponse({
    required this.content,
    required this.tokenCount,
    required this.responseTime,
    required this.wasSanitized,
  });
}

/// Production Groq Chat Service
class GroqChatService {
  final GroqChatConfig config;
  final PHISanitizerService _sanitizer;
  final Logger _logger;
  final CircuitBreaker _circuitBreaker;
  final TokenCounter _tokenCounter;
  late final ChatOpenAI _groq;

  // Rate limiting
  final List<DateTime> _requestTimes = [];
  static const _maxRequestsPerMinute = 30; // Groq free tier limit

  GroqChatService({
    required this.config,
    PHISanitizerService? sanitizer,
    Logger? logger,
    CircuitBreaker? circuitBreaker,
    TokenCounter? tokenCounter,
  })  : _sanitizer = sanitizer ?? PHISanitizerService(strictMode: false),
        _logger = logger ?? Logger(),
        _circuitBreaker = circuitBreaker ??
            CircuitBreaker(
              config: config.circuitBreakerConfig ??
                  const CircuitBreakerConfig(
                    failureThreshold: 5,
                    successThreshold: 2,
                    timeout: Duration(seconds: 60),
                  ),
              logger: logger,
            ),
        _tokenCounter = tokenCounter ??
            TokenCounter(
              config: const TokenCounterConfig(
                model: TokenizerModel.llama3,
                maxContextTokens: 8000,
                safetyMargin: 500,
              ),
            ) {
    _initializeGroq();
  }

  void _initializeGroq() {
    // Create custom HTTP client to handle SSL certificates on Windows
    final httpClient = HttpClient();

    // DEVELOPMENT ONLY: Accept all certificates in dev mode
    // TODO: Set _kDevMode = false before production deployment!
    if (_kDevMode) {
      httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          _logger.w('Accepting SSL certificate for $host (DEV MODE ONLY)');
          return true; // Accept all certificates in dev mode
        };
    }

    // Add User-Agent header to help with Cloudflare/WAF
    httpClient.userAgent = 'Step-Sync-ChatBot/1.0 (Dart; Flutter)';

    final ioClient = IOClient(httpClient);

    _groq = ChatOpenAI(
      apiKey: config.apiKey,
      baseUrl: 'https://api.groq.com/openai/v1',
      defaultOptions: ChatOpenAIOptions(
        model: config.model,
        temperature: config.temperature,
        maxTokens: config.maxTokens,
      ),
      client: ioClient, // Use custom HTTP client
    );
    _logger.i('Groq Chat Service initialized: ${config.model}');
  }

  /// Send a message and get response with automatic PHI sanitization
  Future<ChatResponse> sendMessage(
    String message, {
    List<ConversationMessage>? conversationHistory,
    String? systemPrompt,
  }) async {
    _logger.d('Sending message (${message.length} chars)');

    // Sanitize input
    final sanitizationResult = _sanitizer.sanitize(message);
    if (sanitizationResult.wasSanitized) {
      _logger.w('PHI sanitized from message: ${sanitizationResult.replacementCount} replacements');
    }

    // Rate limiting check
    await _checkRateLimit();

    // Build conversation
    final messages = _buildMessages(
      sanitizationResult.sanitizedText,
      conversationHistory,
      systemPrompt: systemPrompt,
    );

    // Send with retry logic wrapped in circuit breaker
    final startTime = DateTime.now();

    try {
      final response = await _circuitBreaker.execute(() async {
        return await _sendWithRetry(messages);
      });

      final responseTime = DateTime.now().difference(startTime);
      _logger.i('Response received (${responseTime.inMilliseconds}ms)');

      return ChatResponse(
        content: response,
        tokenCount: _estimateTokenCount(response),
        responseTime: responseTime,
        wasSanitized: sanitizationResult.wasSanitized,
      );
    } on CircuitBreakerOpenException catch (e) {
      _logger.e('Circuit breaker open - service unavailable: $e');
      throw GroqAPIException(
        'Groq API service temporarily unavailable',
        statusCode: 503,
        originalError: e,
      );
    }
  }

  /// Send message with retry logic
  Future<String> _sendWithRetry(List<ChatMessage> messages) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < config.maxRetries) {
      try {
        attempt++;
        _logger.d('API call attempt $attempt/${config.maxRetries}');

        final response = await _groq
            .invoke(
              PromptValue.chat(messages),
            )
            .timeout(config.timeout);

        return response.output.content;
      } on TimeoutException catch (e) {
        lastError = e;
        _logger.w('Request timeout (attempt $attempt)');

        if (attempt < config.maxRetries) {
          await Future.delayed(config.retryDelay * attempt);
        }
      } catch (e) {
        lastError = Exception(e.toString());
        _logger.e('API error (attempt $attempt): $e');

        // Don't retry on authentication errors
        if (e.toString().contains('401') || e.toString().contains('Invalid API key')) {
          throw GroqAPIException(
            'Invalid API key',
            statusCode: 401,
            originalError: e,
          );
        }

        // Don't retry on rate limit errors (wait longer)
        if (e.toString().contains('429')) {
          if (attempt < config.maxRetries) {
            _logger.w('Rate limit hit, waiting longer...');
            await Future.delayed(Duration(seconds: 5 * attempt));
          } else {
            throw GroqAPIException(
              'Rate limit exceeded',
              statusCode: 429,
              originalError: e,
            );
          }
        } else if (attempt < config.maxRetries) {
          await Future.delayed(config.retryDelay * attempt);
        }
      }
    }

    throw GroqAPIException(
      'Max retries exceeded',
      originalError: lastError,
    );
  }

  /// Build message list for API
  List<ChatMessage> _buildMessages(
    String userMessage,
    List<ConversationMessage>? history, {
    String? systemPrompt,
  }) {
    final messages = <ChatMessage>[
      ChatMessage.system(
        systemPrompt ??
        'You are Step Sync Assistant. Help users fix step tracking issues. '
        'Be conversational, friendly, and action-oriented. '
        'Keep responses under 3 sentences unless more detail is needed.',
      ),
    ];

    // Add conversation history
    if (history != null && history.isNotEmpty) {
      for (final msg in history) {
        if (msg.isUser) {
          messages.add(ChatMessage.humanText(msg.content));
        } else {
          messages.add(ChatMessage.ai(msg.content));
        }
      }
    }

    // Add current message
    messages.add(ChatMessage.humanText(userMessage));

    return messages;
  }

  /// Check rate limiting (30 requests per minute)
  Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

    // Remove old requests
    _requestTimes.removeWhere((time) => time.isBefore(oneMinuteAgo));

    // Check if at limit
    if (_requestTimes.length >= _maxRequestsPerMinute) {
      final oldestRequest = _requestTimes.first;
      final waitTime = oldestRequest.add(const Duration(minutes: 1)).difference(now);

      if (waitTime.inMilliseconds > 0) {
        _logger.w('Rate limit reached, waiting ${waitTime.inSeconds}s');
        await Future.delayed(waitTime);
      }
    }

    _requestTimes.add(now);
  }

  /// Estimate token count using TokenCounter
  int _estimateTokenCount(String text) {
    return _tokenCounter.countTokens(text);
  }

  /// Get circuit breaker metrics for monitoring
  CircuitBreakerMetrics getCircuitBreakerMetrics() {
    return _circuitBreaker.getMetrics();
  }

  /// Get circuit breaker state
  CircuitState getCircuitBreakerState() {
    return _circuitBreaker.state;
  }

  /// Reset circuit breaker (for testing/manual intervention)
  void resetCircuitBreaker() {
    _circuitBreaker.reset();
    _logger.i('Circuit breaker reset');
  }

  /// Dispose resources
  void dispose() {
    _logger.d('Groq Chat Service disposed');
  }
}
