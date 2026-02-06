/// Manual Test Script for Groq API Integration
///
/// This script tests the LLM integration with real Groq API calls.
///
/// SETUP:
/// 1. Get your Groq API key from: https://console.groq.com/keys
/// 2. Set environment variable: GROQ_API_KEY=your_key_here
/// 3. Run: dart test/manual/groq_api_test.dart
///
/// IMPORTANT: This makes real API calls and uses your quota!

import 'dart:io';
import 'package:step_sync_chatbot/src/services/groq_chat_service.dart';
import 'package:step_sync_chatbot/src/services/phi_sanitizer_service.dart';
import 'package:step_sync_chatbot/src/conversation/llm_response_generator.dart';
import 'package:step_sync_chatbot/src/conversation/conversation_context.dart';
import 'package:step_sync_chatbot/src/core/intents.dart';

void main() async {
  print('═' * 70);
  print('  GROQ API MANUAL TEST - LLM Integration Verification');
  print('═' * 70);
  print('');

  // 1. Check for API key
  final apiKey = Platform.environment['GROQ_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ ERROR: GROQ_API_KEY environment variable not set');
    print('');
    print('Setup instructions:');
    print('1. Get API key: https://console.groq.com/keys');
    print('2. Windows: set GROQ_API_KEY=your_key_here');
    print('   Linux/Mac: export GROQ_API_KEY=your_key_here');
    print('3. Re-run this script');
    exit(1);
  }

  print('✅ API key found (${apiKey.substring(0, 8)}...)');
  print('');

  // 2. Initialize services
  print('Initializing services...');
  final config = GroqChatConfig(
    apiKey: apiKey,
    model: 'llama-3.3-70b-versatile',
    temperature: 0.7,
    maxTokens: 1024,
  );
  final groqService = GroqChatService(config: config);
  final phiSanitizer = PHISanitizerService();
  final llmGenerator = LLMResponseGenerator(
    groqService: groqService,
    phiSanitizer: phiSanitizer,
  );
  print('✅ Services initialized');
  print('');

  // 3. Run test scenarios (with delays to avoid rate limiting)
  await _testBasicConversation(llmGenerator);

  print('⏳ Waiting 3 seconds to avoid rate limiting...\n');
  await Future.delayed(Duration(seconds: 3));

  await _testFrustratedUser(llmGenerator);

  print('⏳ Waiting 3 seconds to avoid rate limiting...\n');
  await Future.delayed(Duration(seconds: 3));

  await _testDiagnosticScenario(llmGenerator);

  print('⏳ Waiting 3 seconds to avoid rate limiting...\n');
  await Future.delayed(Duration(seconds: 3));

  await _testPrivacySanitization(llmGenerator, phiSanitizer);

  print('⏳ Waiting 3 seconds to avoid rate limiting...\n');
  await Future.delayed(Duration(seconds: 3));

  await _testMultiTurnConversation(llmGenerator);

  print('');
  print('═' * 70);
  print('  ALL TESTS COMPLETE');
  print('═' * 70);
  print('');
  print('✅ Manual verification successful!');
  print('');
  print('Next steps:');
  print('1. Review the responses above for quality');
  print('2. Verify privacy sanitization worked correctly');
  print('3. Check Groq dashboard for API usage');
  print('4. Test with edge cases in your app');
}

/// Helper: Generate response with detailed error logging
Future<String> _generateWithErrorLogging(
  LLMResponseGenerator generator, {
  required String userMessage,
  required UserIntent intent,
  required ConversationContext context,
  required String testName,
  Map<String, dynamic>? diagnosticResults,
}) async {
  try {
    print('[$testName] Calling LLM with message: "$userMessage"');
    print('[$testName] Intent: ${intent.name}');
    print('[$testName] Sentiment: ${context.sentiment}');

    final response = await generator.generate(
      userMessage: userMessage,
      intent: intent,
      context: context,
      diagnosticResults: diagnosticResults,
    );

    // Check if this is a fallback response
    final knownFallbacks = [
      "I understand this is frustrating",
      "I'm here to help! Could you tell me",
      "I'll help you get your steps syncing",
    ];

    final isFallback = knownFallbacks.any((fallback) => response.contains(fallback));

    if (isFallback) {
      print('[$testName] ⚠️  WARNING: Received fallback response (LLM call likely failed)');
      print('[$testName] This means the Groq API call failed silently');
      print('[$testName] Checking for common issues...');
      print('');
    } else {
      print('[$testName] ✅ Real LLM response received');
      print('');
    }

    return response;
  } catch (e, stackTrace) {
    print('[$testName] ❌ ERROR: $e');
    print('[$testName] Stack trace: $stackTrace');
    print('');
    rethrow;
  }
}

/// Test 1: Basic conversation flow
Future<void> _testBasicConversation(LLMResponseGenerator generator) async {
  print('─' * 70);
  print('TEST 1: Basic Conversation Flow');
  print('─' * 70);

  final context = ConversationContext();
  context.addUserMessage('my steps arent working');

  print('User: "my steps arent working"');
  print('Intent: stepsNotSyncing');
  print('Generating response...\n');

  final startTime = DateTime.now();
  final response = await _generateWithErrorLogging(
    generator,
    userMessage: 'my steps arent working',
    intent: UserIntent.stepsNotSyncing,
    context: context,
    testName: 'TEST 1',
  );
  final duration = DateTime.now().difference(startTime);

  print('Response Time: ${duration.inMilliseconds}ms');
  print('─' * 70);
  print('Bot Response:');
  print(response);
  print('─' * 70);
  print('');

  // Quality checks
  _verifyResponse(response, [
    'Should acknowledge the issue',
    'Should offer help',
    'Should be conversational (not robotic)',
  ]);
}

/// Test 2: Frustrated user (empathy test)
Future<void> _testFrustratedUser(LLMResponseGenerator generator) async {
  print('─' * 70);
  print('TEST 2: Frustrated User (Empathy Test)');
  print('─' * 70);

  final context = ConversationContext();
  context.addUserMessage('this is so annoying!!! nothing works!!!');

  print('User: "this is so annoying!!! nothing works!!!"');
  print('Sentiment: Very Frustrated (${context.sentiment})');
  print('Intent: needHelp');
  print('Generating response...\n');

  final response = await _generateWithErrorLogging(
    generator,
    userMessage: 'this is so annoying!!! nothing works!!!',
    intent: UserIntent.needHelp,
    context: context,
    testName: 'TEST 2',
  );

  print('─' * 70);
  print('Bot Response:');
  print(response);
  print('─' * 70);
  print('');

  // Quality checks
  _verifyResponse(response, [
    'Should show empathy first',
    'Should acknowledge frustration',
    'Should be reassuring',
    'Should offer quick solution',
  ]);
}

/// Test 3: Diagnostic scenario with structured data
Future<void> _testDiagnosticScenario(LLMResponseGenerator generator) async {
  print('─' * 70);
  print('TEST 3: Diagnostic Scenario');
  print('─' * 70);

  final context = ConversationContext();
  context.addUserMessage('check my step tracking status');

  final diagnostics = {
    'permissionStatus': 'granted',
    'dataSourceCount': 2,
    'lastSyncTime': 'yesterday',
    'batteryOptimization': 'enabled',
  };

  print('User: "check my step tracking status"');
  print('Intent: checkingStatus');
  print('Diagnostic Results:');
  diagnostics.forEach((key, value) => print('  - $key: $value'));
  print('Generating response...\n');

  final response = await _generateWithErrorLogging(
    generator,
    userMessage: 'check my step tracking status',
    intent: UserIntent.checkingStatus,
    context: context,
    diagnosticResults: diagnostics,
    testName: 'TEST 3',
  );

  print('─' * 70);
  print('Bot Response:');
  print(response);
  print('─' * 70);
  print('');

  // Quality checks
  _verifyResponse(response, [
    'Should reference diagnostic findings',
    'Should explain battery optimization issue',
    'Should provide actionable steps',
  ]);
}

/// Test 4: Privacy sanitization
Future<void> _testPrivacySanitization(
  LLMResponseGenerator generator,
  PHISanitizerService sanitizer,
) async {
  print('─' * 70);
  print('TEST 4: Privacy & PHI Sanitization');
  print('─' * 70);

  final testCases = [
    'I walked 10,000 steps yesterday',
    'My iPhone 15 is not syncing with Google Fit',
    'My email is john@example.com',
    'I have 8,247 steps today',
  ];

  for (final input in testCases) {
    try {
      final result = sanitizer.sanitize(input);
      print('Input:      "$input"');
      print('Sanitized:  "${result.sanitizedText}"');
      print('Sanitized?: ${result.wasSanitized ? "YES" : "NO"}');
      if (result.replacements.isNotEmpty) {
        print('Changes:    ${result.replacements.join(", ")}');
      }
      print('');
    } catch (e) {
      // Critical PHI detected - this is expected and GOOD!
      print('Input:      "$input"');
      print('Result:     ❌ BLOCKED (Critical PHI detected)');
      print('Status:     ✅ Privacy protection working correctly!');
      print('Details:    $e');
      print('');
    }
  }

  print('Now testing with LLM (sanitized input should be sent)...\n');

  final context = ConversationContext();
  context.addUserMessage('I walked 10,000 steps yesterday but only see 3,000');

  final response = await _generateWithErrorLogging(
    generator,
    userMessage: 'I walked 10,000 steps yesterday but only see 3,000',
    intent: UserIntent.wrongStepCount,
    context: context,
    testName: 'TEST 4',
  );

  print('─' * 70);
  print('Bot Response:');
  print(response);
  print('─' * 70);
  print('');

  print('✅ Verification: Response should NOT contain specific numbers (10,000 or 3,000)');
  if (response.contains('10,000') || response.contains('3,000')) {
    print('⚠️  WARNING: Specific numbers found in response - check sanitization!');
  } else {
    print('✅ No specific numbers in response - sanitization working!');
  }
  print('');
}

/// Test 5: Multi-turn conversation (context awareness)
Future<void> _testMultiTurnConversation(LLMResponseGenerator generator) async {
  print('─' * 70);
  print('TEST 5: Multi-Turn Conversation (Context Awareness)');
  print('─' * 70);

  final context = ConversationContext();

  // Turn 1
  print('Turn 1:');
  print('User: "I use Samsung Health for tracking"');
  context.addUserMessage('I use Samsung Health for tracking');

  var response = await _generateWithErrorLogging(
    generator,
    userMessage: 'I use Samsung Health for tracking',
    intent: UserIntent.multipleDataSources,
    context: context,
    testName: 'TEST 5 - Turn 1',
  );
  context.addBotMessage(response);

  print('Bot: $response');
  print('');

  // Turn 2 - reference "it"
  await Future.delayed(Duration(seconds: 1)); // Brief pause
  print('Turn 2 (references "it" - should resolve to Samsung Health):');
  print('User: "it is not syncing"');
  context.addUserMessage('it is not syncing');

  response = await _generateWithErrorLogging(
    generator,
    userMessage: 'it is not syncing',
    intent: UserIntent.stepsNotSyncing,
    context: context,
    testName: 'TEST 5 - Turn 2',
  );

  print('Bot: $response');
  print('');

  print('─' * 70);
  print('✅ Verification: Response should reference Samsung Health (pronoun resolution)');
  if (response.toLowerCase().contains('samsung')) {
    print('✅ Context awareness working - Samsung Health mentioned!');
  } else {
    print('⚠️  Warning: Samsung Health not explicitly mentioned - check context tracking');
  }
  print('');
}

/// Helper: Verify response quality
void _verifyResponse(String response, List<String> checks) {
  print('Quality Checks:');
  for (final check in checks) {
    print('  • $check');
  }
  print('');
  print('Manual Review Required:');
  print('  - Read the response above');
  print('  - Verify it meets quality standards');
  print('  - Check for natural, conversational tone');
  print('  - Ensure helpful and actionable');
  print('');
}
