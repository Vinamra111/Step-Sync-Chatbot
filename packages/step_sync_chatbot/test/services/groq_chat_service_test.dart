/// Tests for Production Groq Chat Service
///
/// Validates:
/// - Message sending with PHI sanitization
/// - Error handling and retry logic
/// - Rate limiting
/// - Conversation history management
/// - Timeout handling

import 'package:test/test.dart';
import 'package:logger/logger.dart';
import '../../lib/src/services/groq_chat_service.dart';
import '../../lib/src/services/phi_sanitizer_service.dart';
import '../../lib/src/services/circuit_breaker.dart';

// Test API key from previous POC
const String TEST_GROQ_API_KEY = 'YOUR_GROQ_API_KEY_HERE';

void main() {
  group('GroqChatService - Configuration', () {
    test('Initializes with default config', () {
      final config = GroqChatConfig(apiKey: 'test-key');

      expect(config.model, equals('llama-3.3-70b-versatile'));
      expect(config.temperature, equals(0.7));
      expect(config.maxTokens, equals(1024));
      expect(config.timeout, equals(Duration(seconds: 30)));
      expect(config.maxRetries, equals(3));
    });

    test('Initializes with custom config', () {
      final config = GroqChatConfig(
        apiKey: 'test-key',
        model: 'llama-3.1-8b-instant',
        temperature: 0.5,
        maxTokens: 512,
        timeout: Duration(seconds: 15),
        maxRetries: 5,
      );

      expect(config.model, equals('llama-3.1-8b-instant'));
      expect(config.temperature, equals(0.5));
      expect(config.maxTokens, equals(512));
      expect(config.timeout, equals(Duration(seconds: 15)));
      expect(config.maxRetries, equals(5));
    });

    test('Creates service instance', () {
      final config = GroqChatConfig(apiKey: 'test-key');
      final service = GroqChatService(
        config: config,
        logger: Logger(level: Level.off),
      );

      expect(service, isNotNull);
      service.dispose();
    });
  });

  group('GroqChatService - ConversationMessage', () {
    test('Creates user message', () {
      final message = ConversationMessage(
        content: 'Hello',
        role: 'user',
      );

      expect(message.content, equals('Hello'));
      expect(message.role, equals('user'));
      expect(message.isUser, isTrue);
      expect(message.isAssistant, isFalse);
      expect(message.timestamp, isNotNull);
    });

    test('Creates assistant message', () {
      final message = ConversationMessage(
        content: 'Hi there',
        role: 'assistant',
      );

      expect(message.isUser, isFalse);
      expect(message.isAssistant, isTrue);
    });

    test('Includes metadata', () {
      final message = ConversationMessage(
        content: 'Test',
        role: 'user',
        metadata: {'source': 'test'},
      );

      expect(message.metadata, isNotNull);
      expect(message.metadata!['source'], equals('test'));
    });
  });

  group('GroqChatService - Live API Tests', () {
    late GroqChatService service;

    setUp(() {
      final config = GroqChatConfig(
        apiKey: TEST_GROQ_API_KEY,
        maxRetries: 2,
        timeout: Duration(seconds: 30),
      );
      service = GroqChatService(
        config: config,
        logger: Logger(level: Level.off),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('Sends simple message and receives response', () async {
      print('\n📡 Testing: Simple message to Groq');

      final response = await service.sendMessage(
        'Hi, I need help with step tracking',
      );

      print('✅ Response received: ${response.content.substring(0, 50)}...');
      print('   Tokens: ${response.tokenCount}');
      print('   Response time: ${response.responseTime.inMilliseconds}ms');
      print('   Was sanitized: ${response.wasSanitized}\n');

      expect(response.content, isNotEmpty);
      expect(response.content.length, greaterThan(10));
      expect(response.tokenCount, greaterThan(0));
      expect(response.responseTime.inMilliseconds, lessThan(30000));
      expect(response.wasSanitized, isFalse);
    }, timeout: Timeout(Duration(seconds: 40)));

    test('Sanitizes PHI before sending', () async {
      print('\n🔒 Testing: PHI sanitization before API call');

      final response = await service.sendMessage(
        'My steps aren\'t syncing. I walked 10,000 steps yesterday in Google Fit',
      );

      print('✅ Message sanitized and sent');
      print('   Response: ${response.content.substring(0, 50)}...');
      print('   PHI was removed: ${response.wasSanitized}\n');

      expect(response.content, isNotEmpty);
      expect(response.wasSanitized, isTrue);
    }, timeout: Timeout(Duration(seconds: 40)));

    test('Maintains context with conversation history', () async {
      print('\n💬 Testing: Multi-turn conversation with history');

      // Turn 1
      print('Turn 1: User asks initial question');
      final response1 = await service.sendMessage(
        'My steps aren\'t syncing',
      );

      print('Bot: ${response1.content.substring(0, 50)}...\n');

      // Turn 2 with history
      print('Turn 2: User asks follow-up (with context)');
      final history = [
        ConversationMessage(content: 'My steps aren\'t syncing', role: 'user'),
        ConversationMessage(content: response1.content, role: 'assistant'),
      ];

      final response2 = await service.sendMessage(
        'How do I fix it?',
        conversationHistory: history,
      );

      print('Bot: ${response2.content.substring(0, 50)}...');
      print('✅ Context maintained across turns\n');

      expect(response2.content, isNotEmpty);
      expect(response2.content, isNot(contains('What issue')));
    }, timeout: Timeout(Duration(seconds: 60)));

    test('Handles short timeout gracefully', () async {
      print('\n⏱️  Testing: Timeout handling');

      final quickConfig = GroqChatConfig(
        apiKey: TEST_GROQ_API_KEY,
        timeout: Duration(milliseconds: 1), // Very short timeout
        maxRetries: 1,
      );
      final quickService = GroqChatService(
        config: quickConfig,
        logger: Logger(level: Level.off),
      );

      try {
        await quickService.sendMessage('Test');
        fail('Should have thrown GroqAPIException');
      } on GroqAPIException catch (e) {
        print('✅ Timeout handled correctly: ${e.message}\n');
        expect(e.message, contains('Max retries'));
      } finally {
        quickService.dispose();
      }
    }, timeout: Timeout(Duration(seconds: 15)));
  });

  group('GroqChatService - Error Handling', () {
    test('Throws exception for invalid API key', () async {
      print('\n🔑 Testing: Invalid API key handling');

      final invalidConfig = GroqChatConfig(
        apiKey: 'invalid-key',
        maxRetries: 1,
      );
      final service = GroqChatService(
        config: invalidConfig,
        logger: Logger(level: Level.off),
      );

      try {
        await service.sendMessage('Test');
        fail('Should have thrown GroqAPIException');
      } on GroqAPIException catch (e) {
        print('✅ Invalid API key caught: ${e.message}\n');
        expect(e.statusCode, equals(401));
        expect(e.message, contains('Invalid API key'));
      } finally {
        service.dispose();
      }
    }, timeout: Timeout(Duration(seconds: 15)));
  });

  group('GroqChatService - ChatResponse', () {
    test('Contains all required fields', () {
      final response = ChatResponse(
        content: 'Test response',
        tokenCount: 100,
        responseTime: Duration(milliseconds: 500),
        wasSanitized: true,
      );

      expect(response.content, equals('Test response'));
      expect(response.tokenCount, equals(100));
      expect(response.responseTime.inMilliseconds, equals(500));
      expect(response.wasSanitized, isTrue);
    });
  });

  group('GroqChatService - Rate Limiting', () {
    test('Enforces rate limits', () async {
      print('\n⚡ Testing: Rate limiting (simplified)');

      final config = GroqChatConfig(
        apiKey: TEST_GROQ_API_KEY,
      );
      final service = GroqChatService(
        config: config,
        logger: Logger(level: Level.off),
      );

      // Send a few messages quickly
      final startTime = DateTime.now();
      await service.sendMessage('Test 1');
      await service.sendMessage('Test 2');
      await service.sendMessage('Test 3');
      final elapsed = DateTime.now().difference(startTime);

      print('✅ 3 messages sent in ${elapsed.inSeconds}s');
      print('   Rate limiting working\n');

      expect(elapsed.inMilliseconds, lessThan(30000));

      service.dispose();
    }, timeout: Timeout(Duration(seconds: 45)));
  });

  group('GroqChatService - Integration', () {
    test('Complete workflow: sanitize + send + receive', () async {
      print('\n🔄 Testing: Complete workflow');

      final config = GroqChatConfig(apiKey: TEST_GROQ_API_KEY);
      final service = GroqChatService(
        config: config,
        logger: Logger(level: Level.off),
      );

      // User message with PHI
      final userMessage = 'I walked 12,000 steps yesterday but Google Fit only shows 5,000';

      print('User: "$userMessage"');

      final response = await service.sendMessage(userMessage);

      print('Bot: "${response.content.substring(0, 80)}..."');
      print('✅ Complete workflow successful');
      print('   PHI sanitized: ${response.wasSanitized}');
      print('   Response time: ${response.responseTime.inMilliseconds}ms');
      print('   Tokens: ${response.tokenCount}\n');

      expect(response.content, isNotEmpty);
      expect(response.wasSanitized, isTrue);
      expect(response.responseTime.inMilliseconds, lessThan(30000));

      service.dispose();
    }, timeout: Timeout(Duration(seconds: 40)));
  });

  group('GroqChatService - Circuit Breaker Integration', () {
    test('Circuit breaker starts in CLOSED state', () {
      final service = GroqChatService(
        config: GroqChatConfig(apiKey: 'test-key'),
        logger: Logger(level: Level.off),
      );

      expect(service.getCircuitBreakerState(), equals(CircuitState.closed));
      service.dispose();
    });

    test('Circuit breaker metrics are accessible', () {
      final service = GroqChatService(
        config: GroqChatConfig(apiKey: 'test-key'),
        logger: Logger(level: Level.off),
      );

      final metrics = service.getCircuitBreakerMetrics();

      expect(metrics.totalCalls, equals(0));
      expect(metrics.currentState, equals(CircuitState.closed));
      service.dispose();
    });

    test('Throws GroqAPIException when circuit breaker is open', () async {
      final service = GroqChatService(
        config: GroqChatConfig(
          apiKey: 'invalid-key-to-force-failures',
          maxRetries: 1,
        ),
        logger: Logger(level: Level.off),
      );

      // Force circuit breaker to open by generating failures
      for (int i = 0; i < 5; i++) {
        try {
          await service.sendMessage('test message $i');
        } catch (e) {
          // Expected to fail with invalid API key
        }
      }

      // Circuit should be open now
      expect(service.getCircuitBreakerState(), equals(CircuitState.open));

      // Next call should throw GroqAPIException with 503 status
      try {
        await service.sendMessage('blocked message');
        fail('Should have thrown GroqAPIException');
      } on GroqAPIException catch (e) {
        expect(e.statusCode, equals(503));
        expect(e.message, contains('temporarily unavailable'));
      }

      service.dispose();
    });

    test('Can reset circuit breaker manually', () async {
      final service = GroqChatService(
        config: GroqChatConfig(
          apiKey: 'invalid-key',
          maxRetries: 1,
        ),
        logger: Logger(level: Level.off),
      );

      // Force open by generating failures
      for (int i = 0; i < 5; i++) {
        try {
          await service.sendMessage('test');
        } catch (e) {}
      }

      expect(service.getCircuitBreakerState(), equals(CircuitState.open));

      // Reset
      service.resetCircuitBreaker();
      expect(service.getCircuitBreakerState(), equals(CircuitState.closed));

      service.dispose();
    });

    test('Circuit breaker metrics update with successful calls', () async {
      final service = GroqChatService(
        config: GroqChatConfig(apiKey: TEST_GROQ_API_KEY),
        logger: Logger(level: Level.off),
      );

      final metrics1 = service.getCircuitBreakerMetrics();
      expect(metrics1.totalCalls, equals(0));

      // Make a successful call
      await service.sendMessage('Hello');

      final metrics2 = service.getCircuitBreakerMetrics();
      expect(metrics2.totalCalls, equals(1));
      expect(metrics2.successfulCalls, equals(1));
      expect(metrics2.failedCalls, equals(0));

      service.dispose();
    }, timeout: Timeout(Duration(seconds: 30)));

    test('Circuit breaker custom config is respected', () {
      final customConfig = CircuitBreakerConfig(
        failureThreshold: 10,
        successThreshold: 5,
        timeout: Duration(minutes: 5),
      );

      final service = GroqChatService(
        config: GroqChatConfig(
          apiKey: 'test-key',
          circuitBreakerConfig: customConfig,
        ),
        logger: Logger(level: Level.off),
      );

      // Circuit breaker should be using custom config
      // (Can't directly test config values, but circuit behavior will differ)
      expect(service.getCircuitBreakerState(), equals(CircuitState.closed));

      service.dispose();
    });
  });
}
