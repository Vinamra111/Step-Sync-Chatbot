/// Direct Groq API Test - See Raw Errors
///
/// This script calls Groq API directly to see actual error messages
/// without the fallback mechanism masking them.

import 'dart:io';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

void main() async {
  print('═' * 70);
  print('  GROQ API DIRECT TEST - Raw Error Diagnosis');
  print('═' * 70);
  print('');

  // Get API key
  final apiKey = Platform.environment['GROQ_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ ERROR: GROQ_API_KEY not set');
    exit(1);
  }

  print('✅ API key found: ${apiKey.substring(0, 12)}...');
  print('');

  try {
    print('Attempting direct Groq API call...');
    print('');

    final groq = ChatOpenAI(
      apiKey: apiKey,
      baseUrl: 'https://api.groq.com/openai/v1',
      defaultOptions: ChatOpenAIOptions(
        model: 'llama-3.3-70b-versatile',
        temperature: 0.7,
      ),
    );

    final messages = [
      ChatMessage.system(
        'You are a helpful assistant. Respond in one sentence.',
      ),
      ChatMessage.humanText('Hello! Can you hear me?'),
    ];

    print('Sending test message to Groq...');
    final startTime = DateTime.now();

    final response = await groq.invoke(
      PromptValue.chat(messages),
    ).timeout(const Duration(seconds: 30));

    final duration = DateTime.now().difference(startTime);

    print('');
    print('✅ SUCCESS!');
    print('Response Time: ${duration.inMilliseconds}ms');
    print('─' * 70);
    print('Response:');
    print(response.output.content);
    print('─' * 70);
    print('');
    print('✅ Groq API is working correctly!');
    print('');
    print('This means the issue is in the LLMResponseGenerator logic,');
    print('not with the Groq API itself.');
  } catch (e, stackTrace) {
    print('');
    print('❌ GROQ API ERROR DETECTED:');
    print('═' * 70);
    print('Error: $e');
    print('');
    print('Stack Trace:');
    print(stackTrace);
    print('═' * 70);
    print('');

    // Diagnose common errors
    final errorStr = e.toString();

    if (errorStr.contains('401') || errorStr.contains('Invalid API key')) {
      print('🔍 DIAGNOSIS: Invalid API Key');
      print('   - Check if API key is correct');
      print('   - Verify at https://console.groq.com/keys');
    } else if (errorStr.contains('429')) {
      print('🔍 DIAGNOSIS: Rate Limit Exceeded');
      print('   - Free tier: 30 requests/minute');
      print('   - Wait 60 seconds and try again');
      print('   - Check usage at https://console.groq.com/');
    } else if (errorStr.contains('quota') || errorStr.contains('limit')) {
      print('🔍 DIAGNOSIS: Quota Exhausted');
      print('   - Daily/monthly limit reached');
      print('   - Check dashboard at https://console.groq.com/');
      print('   - Upgrade plan or wait for reset');
    } else if (errorStr.contains('timeout') || errorStr.contains('Timeout')) {
      print('🔍 DIAGNOSIS: Connection Timeout');
      print('   - Network issue or API is slow');
      print('   - Check https://status.groq.com/');
      print('   - Try again in 30 seconds');
    } else {
      print('🔍 DIAGNOSIS: Unknown Error');
      print('   - Check error message above');
      print('   - Visit https://console.groq.com/docs/');
    }
  }

  print('');
  print('Test complete!');
}
