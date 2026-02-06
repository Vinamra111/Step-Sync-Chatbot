/// Direct HTTP Groq Test - Bypass LangChain to test direct API access
///
/// This test uses the new direct HTTP implementation to see if
/// bypassing LangChain resolves the Cloudflare/WAF blocking issues.

import 'dart:io';
import 'package:step_sync_chatbot/src/services/groq_direct_http_service.dart';
import 'package:step_sync_chatbot/src/services/groq_chat_service.dart';
import 'package:logger/logger.dart';

void main() async {
  print('═' * 70);
  print('  GROQ DIRECT HTTP TEST - Bypassing LangChain');
  print('═' * 70);
  print('');

  // Get API key
  final apiKey = Platform.environment['GROQ_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ ERROR: GROQ_API_KEY environment variable not set');
    print('');
    print('Set it with:');
    print('  export GROQ_API_KEY=your_key_here  # Linux/Mac');
    print('  set GROQ_API_KEY=your_key_here     # Windows');
    exit(1);
  }

  print('✅ API key found (${apiKey.substring(0, 10)}...)');
  print('');

  // Initialize direct HTTP service
  final logger = Logger(
    filter: ProductionFilter(),
    printer: SimplePrinter(printTime: false),
  );

  final directService = GroqDirectHTTPService(
    apiKey: apiKey,
    model: 'llama-3.3-70b-versatile',
    temperature: 0.7,
    maxTokens: 150,
    logger: logger,
  );

  print('✅ Direct HTTP service initialized');
  print('');

  // Test 1: Simple message
  print('─' * 70);
  print('TEST 1: Simple Greeting');
  print('─' * 70);
  print('Message: "Hello! Can you help me with my steps?"');
  print('');

  try {
    final startTime = DateTime.now();
    final response = await directService.sendMessage(
      'Hello! Can you help me with my steps?',
    );
    final duration = DateTime.now().difference(startTime);

    print('✅ SUCCESS!');
    print('Response time: ${duration.inMilliseconds}ms');
    print('Token count: ${response.tokenCount}');
    print('');
    print('Response:');
    print('─' * 70);
    print(response.content);
    print('─' * 70);
    print('');

    // Verify it's a real LLM response (not a fallback)
    if (response.content.length < 20 ||
        response.content.contains('I\'m here to help') ||
        response.content.contains('temporary connection issue')) {
      print('⚠️  WARNING: Response looks like a fallback template');
    } else {
      print('✅ Response appears to be real LLM output (conversational)');
    }
  } catch (e) {
    print('❌ FAILED: $e');
    if (e is GroqAPIException) {
      print('Status Code: ${e.statusCode}');
      print('Original Error: ${e.originalError}');
    }
  }

  print('');
  print('⏳ Waiting 3 seconds...');
  await Future.delayed(const Duration(seconds: 3));
  print('');

  // Test 2: Conversational message
  print('─' * 70);
  print('TEST 2: Problem Statement');
  print('─' * 70);
  print('Message: "My steps aren\'t syncing properly"');
  print('');

  try {
    final startTime = DateTime.now();
    final response = await directService.sendMessage(
      'My steps aren\'t syncing properly',
      systemPrompt: 'You are Step Sync Assistant. Help users fix step tracking issues. '
          'Be conversational, friendly, and action-oriented. '
          'Keep responses under 3 sentences.',
    );
    final duration = DateTime.now().difference(startTime);

    print('✅ SUCCESS!');
    print('Response time: ${duration.inMilliseconds}ms');
    print('Token count: ${response.tokenCount}');
    print('');
    print('Response:');
    print('─' * 70);
    print(response.content);
    print('─' * 70);
    print('');

    // Check response quality
    final lowerResponse = response.content.toLowerCase();
    if (lowerResponse.contains('sync') ||
        lowerResponse.contains('help') ||
        lowerResponse.contains('check') ||
        lowerResponse.contains('let')) {
      print('✅ Response is contextually relevant');
    } else {
      print('⚠️  Response relevance unclear');
    }
  } catch (e) {
    print('❌ FAILED: $e');
    if (e is GroqAPIException) {
      print('Status Code: ${e.statusCode}');
      print('Original Error: ${e.originalError}');
    }
  }

  print('');
  print('⏳ Waiting 3 seconds...');
  await Future.delayed(const Duration(seconds: 3));
  print('');

  // Test 3: With conversation history
  print('─' * 70);
  print('TEST 3: Multi-Turn Conversation');
  print('─' * 70);
  print('Turn 1: "I use Samsung Health"');
  print('Turn 2: "it is not working"');
  print('');

  try {
    // First turn
    final response1 = await directService.sendMessage(
      'I use Samsung Health',
    );

    print('Turn 1 Response:');
    print(response1.content);
    print('');

    await Future.delayed(const Duration(seconds: 2));

    // Second turn with history
    final history = [
      ConversationMessage(
        content: 'I use Samsung Health',
        role: 'user',
      ),
      ConversationMessage(
        content: response1.content,
        role: 'assistant',
      ),
    ];

    final response2 = await directService.sendMessage(
      'it is not working',
      conversationHistory: history,
    );

    print('Turn 2 Response:');
    print(response2.content);
    print('');

    // Verify context awareness
    if (response2.content.toLowerCase().contains('samsung')) {
      print('✅ Context maintained (Samsung Health mentioned)');
    } else {
      print('⚠️  Context may not be maintained (Samsung Health not mentioned)');
    }

    print('');
    print('✅ SUCCESS!');
  } catch (e) {
    print('❌ FAILED: $e');
    if (e is GroqAPIException) {
      print('Status Code: ${e.statusCode}');
      print('Original Error: ${e.originalError}');
    }
  }

  // Cleanup
  directService.dispose();

  print('');
  print('═' * 70);
  print('  TEST COMPLETE');
  print('═' * 70);
  print('');
  print('Summary:');
  print('- If all tests succeeded: Direct HTTP approach works! ✅');
  print('- If still getting 403: Groq may be blocking all traffic from your IP');
  print('- If getting timeouts: Network/firewall issue');
  print('- If getting 401: API key invalid');
  print('');
  print('Next steps if successful:');
  print('1. Update GroqChatService to use direct HTTP approach');
  print('2. Re-run full manual test suite');
  print('3. Verify in sample app');
  print('');
}
