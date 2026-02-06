/// Simplified demo that works without external SDK dependencies.
/// This demonstrates the chatbot's conversation capabilities.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import only the models and core logic, not the full SDK
import 'package:step_sync_chatbot/src/data/models/chat_message.dart';
import 'package:step_sync_chatbot/src/core/intents.dart';
import 'package:step_sync_chatbot/src/core/rule_based_intent_classifier.dart';
import 'package:step_sync_chatbot/src/privacy/pii_detector.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SimpleDemoApp(),
    ),
  );
}

class SimpleDemoApp extends StatelessWidget {
  const SimpleDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Sync ChatBot - Simple Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SimpleDemoHome(),
    );
  }
}

class SimpleDemoHome extends StatelessWidget {
  const SimpleDemoHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Sync ChatBot - Demo'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Step Sync ChatBot',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Intelligent troubleshooting assistant for step tracking',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              _buildFeatureCard(
                context,
                icon: Icons.security,
                title: 'Privacy Demo',
                subtitle: 'See how PHI/PII is sanitized',
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyDemoScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                icon: Icons.psychology,
                title: 'Intent Classification Demo',
                subtitle: 'See how the bot understands queries',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IntentDemoScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context,
                icon: Icons.chat,
                title: 'Conversation Demo',
                subtitle: 'Interactive chatbot conversation',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConversationDemoScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Privacy Demo Screen
class PrivacyDemoScreen extends StatefulWidget {
  const PrivacyDemoScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyDemoScreen> createState() => _PrivacyDemoScreenState();
}

class _PrivacyDemoScreenState extends State<PrivacyDemoScreen> {
  final _controller = TextEditingController();
  String _sanitizedText = '';
  bool _isSafe = true;
  List<String> _detectedEntities = [];

  final _examples = [
    'I walked 10,000 steps yesterday',
    'My iPhone 15 is not syncing',
    'Google Fit shows different numbers',
    'My email is john@example.com',
    'Call me at 555-1234',
  ];

  void _sanitize() {
    final detector = PIIDetector();
    final result = detector.sanitize(_controller.text);

    setState(() {
      _sanitizedText = result.sanitizedText;
      _isSafe = result.isSafe;
      _detectedEntities = result.detectedEntities
          .map((e) => '${e.type.name}: "${e.originalValue}"')
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Demo'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PHI/PII Sanitization',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter text to see how sensitive information is detected and sanitized before sending to cloud AI.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter text',
                border: OutlineInputBorder(),
                hintText: 'Try: "I walked 10,000 steps yesterday"',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _sanitize,
              icon: const Icon(Icons.security),
              label: const Text('Sanitize'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _examples
                  .map((example) => ActionChip(
                        label: Text(example),
                        onPressed: () {
                          _controller.text = example;
                          _sanitize();
                        },
                      ))
                  .toList(),
            ),
            if (_sanitizedText.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                color: _isSafe ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isSafe ? Icons.check_circle : Icons.cancel,
                            color: _isSafe ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSafe ? 'Safe to send' : 'Blocked (critical PII)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isSafe ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const Text(
                        'Sanitized Text:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_sanitizedText, style: const TextStyle(fontSize: 16)),
                      if (_detectedEntities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Detected Entities:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._detectedEntities.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $e'),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Intent Classification Demo Screen
class IntentDemoScreen extends StatefulWidget {
  const IntentDemoScreen({Key? key}) : super(key: key);

  @override
  State<IntentDemoScreen> createState() => _IntentDemoScreenState();
}

class _IntentDemoScreenState extends State<IntentDemoScreen> {
  final _controller = TextEditingController();
  UserIntent? _detectedIntent;
  double _confidence = 0.0;

  final _examples = [
    'My steps are not syncing',
    'How do I grant permissions?',
    'Why do you need access to my data?',
    'I have multiple apps tracking steps',
    'Battery optimization is blocking sync',
  ];

  void _classify() {
    final classifier = RuleBasedIntentClassifier();
    final result = classifier.classify(_controller.text);

    setState(() {
      _detectedIntent = result.intent;
      _confidence = result.confidence;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intent Classification'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Intent Recognition',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'See how the chatbot understands what users are asking.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter user query',
                border: OutlineInputBorder(),
                hintText: 'Try: "My steps are not syncing"',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _classify,
              icon: const Icon(Icons.psychology),
              label: const Text('Classify Intent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _examples
                  .map((example) => ActionChip(
                        label: Text(example),
                        onPressed: () {
                          _controller.text = example;
                          _classify();
                        },
                      ))
                  .toList(),
            ),
            if (_detectedIntent != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.purple[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Intent:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _detectedIntent!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Confidence:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _confidence,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _confidence > 0.7 ? Colors.green : Colors.orange,
                        ),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _confidence > 0.7 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple Conversation Demo
class ConversationDemoScreen extends StatefulWidget {
  const ConversationDemoScreen({Key? key}) : super(key: key);

  @override
  State<ConversationDemoScreen> createState() => _ConversationDemoScreenState();
}

class _ConversationDemoScreenState extends State<ConversationDemoScreen> {
  final List<ChatMessage> _messages = [];
  final _controller = TextEditingController();
  final _classifier = RuleBasedIntentClassifier();

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      'Hi! I\'m Step Sync Assistant. I can help you troubleshoot step tracking issues.\n\nTry asking:\n• "My steps are not syncing"\n• "How do I grant permissions?"\n• "Why multiple apps show different steps?"',
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();
    _addUserMessage(userText);
    _controller.clear();

    // Classify intent
    final result = _classifier.classify(userText);

    // Generate response based on intent
    String botResponse;
    switch (result.intent) {
      case UserIntent.stepsNotSyncing:
        botResponse =
            'Let me help you figure out why your steps aren\'t syncing.\n\n'
            'Common causes:\n'
            '• Permissions not granted\n'
            '• Battery optimization blocking background sync\n'
            '• Health Connect not installed (Android)\n\n'
            'Would you like me to run a diagnostic?';
        break;
      case UserIntent.whyPermissionNeeded:
        botResponse =
            'Great question! Here\'s why I need permissions:\n\n'
            '📊 Step Count Permission:\n'
            '   • Read your daily step data\n'
            '   • Detect syncing issues\n\n'
            '🏃 Activity Data Permission:\n'
            '   • Identify data sources (Fitbit, watch, etc.)\n'
            '   • Filter duplicate entries\n\n'
            '🔒 Your privacy is protected:\n'
            '   • Data stays on device\n'
            '   • Never shared with AI\n'
            '   • Encrypted in transit';
        break;
      case UserIntent.multipleAppsConflict:
      case UserIntent.multipleDataSources:
        botResponse =
            'Having multiple apps tracking steps can cause conflicts!\n\n'
            'I can help you:\n'
            '1. View all your data sources\n'
            '2. Choose a primary source\n'
            '3. Filter out duplicates\n\n'
            'Which app do you primarily use? (Google Fit, Samsung Health, Fitbit, etc.)';
        break;
      case UserIntent.batteryOptimizationIssue:
      case UserIntent.batteryOptimization:
        botResponse =
            '⚡ Battery optimization is likely blocking background sync.\n\n'
            'To fix this:\n'
            '1. Open Settings\n'
            '2. Find this app\n'
            '3. Tap \'Battery\'\n'
            '4. Select \'Unrestricted\'\n\n'
            'This lets us sync steps automatically in the background.';
        break;
      case UserIntent.greeting:
        botResponse =
            'Hello! How can I help you today?\n\n'
            'I specialize in:\n'
            '• Troubleshooting sync issues\n'
            '• Setting up permissions\n'
            '• Managing multiple data sources';
        break;
      default:
        botResponse =
            'I understand you\'re experiencing an issue. Could you tell me more details?\n\n'
            'For example:\n'
            '• When did the problem start?\n'
            '• What error messages do you see?\n'
            '• Which app are you using?';
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage(botResponse);
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage.user(
        text: text,
      ));
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage.bot(
        text: text,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot Demo'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.sender == MessageSender.user;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.orange,
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
