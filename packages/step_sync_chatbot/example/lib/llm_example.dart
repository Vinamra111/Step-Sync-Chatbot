/// Example demonstrating LLM integration with Step Sync ChatBot.
///
/// This shows how to:
/// 1. Configure Azure OpenAI provider
/// 2. Set up hybrid intent routing
/// 3. Enable privacy-first PHI sanitization
/// 4. Monitor costs and rate limits
///
/// IMPORTANT: This example requires an Azure OpenAI account with HIPAA BAA.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:step_sync_chatbot/step_sync_chatbot.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LLMExampleApp(),
    ),
  );
}

class LLMExampleApp extends StatelessWidget {
  const LLMExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LLM Integration Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LLMExampleHome(),
    );
  }
}

class LLMExampleHome extends StatelessWidget {
  const LLMExampleHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Integration Examples'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.psychology,
              size: 100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            const Text(
              'LLM-Powered Chatbot',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Intelligent conversational AI with privacy-first PHI protection',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Choose an LLM mode:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _openChatWithMockLLM(context);
              },
              icon: const Icon(Icons.memory),
              label: const Text('Mock LLM (No API Required)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                _openChatWithAzureOpenAI(context);
              },
              icon: const Icon(Icons.cloud),
              label: const Text('Azure OpenAI (API Required)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                _showPrivacyDemo(context);
              },
              icon: const Icon(Icons.security),
              label: const Text('Privacy Demo (PHI Sanitization)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                _showRateLimitDemo(context);
              },
              icon: const Icon(Icons.speed),
              label: const Text('Rate Limit & Cost Monitor'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                _showLLMInfoDialog(context);
              },
              child: const Text('About LLM Integration'),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatWithMockLLM(BuildContext context) {
    // Create mock LLM provider
    final mockLLM = MockLLMProvider(
      simulatedDelayMs: 800, // Simulate realistic API delay
    );

    // Create hybrid router with mock LLM
    final router = HybridIntentRouter(llmProvider: mockLLM);

    // Note: In a real implementation, you'd integrate this with ChatBotController
    // For now, just show a dialog explaining the setup

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mock LLM Configured'),
        content: const SingleChildScrollView(
          child: Text(
            'The Mock LLM provider is now configured.\n\n'
            'How it works:\n'
            '• Simulates LLM responses locally\n'
            '• No API calls or costs\n'
            '• ~800ms simulated delay\n'
            '• Intent-based mock responses\n\n'
            'Privacy:\n'
            '• All data stays on device\n'
            '• PHI sanitization still applied\n'
            '• Safe for testing with real data\n\n'
            'Perfect for:\n'
            '• Development\n'
            '• Testing\n'
            '• Offline demonstrations',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _openChatWithAzureOpenAI(BuildContext context) {
    // Show configuration dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Azure OpenAI Setup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To use Azure OpenAI, you need:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('1. Azure OpenAI account'),
              const Text('2. Deployment created (e.g., gpt-4o-mini)'),
              const Text('3. API key'),
              const Text('4. Endpoint URL'),
              const Text('5. HIPAA BAA signed (for production)'),
              const SizedBox(height: 16),
              const Text(
                'Example configuration:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[200],
                child: const Text(
                  'final azureProvider = AzureOpenAIProvider(\n'
                  '  endpoint: "your-endpoint.openai.azure.com",\n'
                  '  apiKey: "your-api-key",\n'
                  '  deploymentName: "gpt-4o-mini",\n'
                  '  maxTokens: 500,\n'
                  '  temperature: 0.7,\n'
                  ');',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Costs (estimated):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Input: \$0.150 per 1M tokens'),
              const Text('• Output: \$0.600 per 1M tokens'),
              const Text('• Typical query: ~\$0.001-0.005'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDemo(BuildContext context) {
    // Create PII detector
    final detector = PIIDetector();

    // Show demo dialog with examples
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Demo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PHI/PII Sanitization Examples:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSanitizationExample(
                detector,
                'I walked 10,000 steps yesterday',
              ),
              const Divider(),
              _buildSanitizationExample(
                detector,
                'My iPhone 15 is not syncing',
              ),
              const Divider(),
              _buildSanitizationExample(
                detector,
                'Google Fit shows different numbers',
              ),
              const Divider(),
              _buildSanitizationExample(
                detector,
                'My email is john@example.com',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.green[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Privacy Guarantee',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Critical PII (emails, phones, names) blocks sending entirely.\n\n'
                      'All other data is sanitized before sending to cloud.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSanitizationExample(PIIDetector detector, String input) {
    final result = detector.sanitize(input);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(input, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          'Sanitized:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          result.sanitizedText,
          style: const TextStyle(fontSize: 14, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              result.isSafe ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: result.isSafe ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              result.isSafe ? 'Safe to send' : 'Blocked (critical PII)',
              style: TextStyle(
                fontSize: 12,
                color: result.isSafe ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showRateLimitDemo(BuildContext context) {
    // Create rate limiter
    final rateLimiter = LLMRateLimiter(
      maxCallsPerHour: 100,
      maxCallsPerUserPerHour: 50,
      maxHourlyCostUSD: 10.0,
    );

    // Simulate some usage
    for (var i = 0; i < 25; i++) {
      rateLimiter.recordCall(
        'demo_user',
        LLMResponse(
          text: 'Response $i',
          provider: 'Demo',
          model: 'demo',
          promptTokens: 50,
          completionTokens: 100,
          totalTokens: 150,
          estimatedCost: 0.0003,
          responseTimeMs: 800,
          timestamp: DateTime.now(),
        ),
      );
    }

    final stats = rateLimiter.getStats();
    final userStats = rateLimiter.getUserStats('demo_user');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Limit & Cost Monitor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Global Statistics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatRow('Calls (last hour)', '${stats.callsInLastHour}'),
              _buildStatRow(
                'Total cost',
                '\$${stats.totalCostUSD.toStringAsFixed(4)}',
              ),
              _buildStatRow(
                'Remaining budget',
                '\$${stats.remainingBudgetUSD.toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Avg response time',
                '${stats.averageResponseTimeMs}ms',
              ),
              _buildStatRow('Total tokens', '${stats.totalTokensUsed}'),
              const Divider(),
              const Text(
                'User Statistics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatRow('User calls', '${userStats.callsInLastHour}'),
              _buildStatRow(
                'Remaining calls',
                '${userStats.remainingCallsThisHour}',
              ),
              _buildStatRow(
                'User cost',
                '\$${userStats.totalCostUSD.toStringAsFixed(4)}',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.orange[50],
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Cost Controls',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Rate limiting prevents excessive API costs:\n'
                      '• 100 calls/hour globally\n'
                      '• 50 calls/hour per user\n'
                      '• \$10/hour cost cap\n\n'
                      'Calls are blocked when limits exceeded.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showLLMInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About LLM Integration'),
        content: const SingleChildScrollView(
          child: Text(
            'Phase 5: LLM Integration & Advanced Intelligence\n\n'
            'Features:\n'
            '• Azure OpenAI provider with HIPAA support\n'
            '• Mock LLM provider for development\n'
            '• Privacy-first PHI sanitization\n'
            '• Hybrid intent routing (rule-based → LLM)\n'
            '• Conversation context management\n'
            '• Rate limiting and cost monitoring\n\n'
            'Privacy Guarantees:\n'
            '• Critical PII never sent to cloud\n'
            '• All data sanitized before transmission\n'
            '• Step counts, dates, app names removed\n'
            '• Device names, emails, phones blocked\n\n'
            'Cost Control:\n'
            '• Per-user rate limiting\n'
            '• Global hourly caps\n'
            '• Cost monitoring and alerts\n'
            '• Estimated \$0.001-0.005 per query\n\n'
            'Routing Strategy:\n'
            '1. Rule-based (80%) - Free, instant\n'
            '2. On-device ML (15%) - Free, fast [TODO]\n'
            '3. Cloud LLM (5%) - Paid, comprehensive',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
