/// Groq API Test with SSL Certificate Fix
///
/// This test bypasses SSL certificate verification for testing purposes.
/// WARNING: Only use this for local testing! Never in production!

import 'dart:io';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

void main() async {
  print('═' * 70);
  print('  GROQ API TEST - SSL Certificate Fix');
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

  // Create custom HTTP client that accepts all certificates (TESTING ONLY!)
  final httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      print('⚠️  Accepting certificate for $host (testing mode)');
      return true; // Accept all certificates
    };

  final ioClient = IOClient(httpClient);

  try {
    print('Attempting Groq API call with SSL fix...');
    print('');

    final groq = ChatOpenAI(
      apiKey: apiKey,
      baseUrl: 'https://api.groq.com/openai/v1',
      defaultOptions: ChatOpenAIOptions(
        model: 'llama-3.3-70b-versatile',
        temperature: 0.7,
      ),
      client: ioClient, // Use custom HTTP client
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
    print('✅ Groq API is working with SSL fix!');
    print('');
    print('The issue was Windows SSL certificate verification.');
    print('You need to apply this fix to the production code.');
  } catch (e, stackTrace) {
    print('');
    print('❌ ERROR (even with SSL fix):');
    print('═' * 70);
    print('Error: $e');
    print('');
    print('Stack Trace:');
    print(stackTrace);
    print('═' * 70);
  } finally {
    ioClient.close();
    httpClient.close();
  }

  print('');
  print('Test complete!');
}
