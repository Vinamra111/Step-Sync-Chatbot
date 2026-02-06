import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:step_sync_chatbot/step_sync_chatbot.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ExampleApp(),
    ),
  );
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Sync ChatBot Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Sync ChatBot Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_walk,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Step Sync ChatBot',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'An intelligent chatbot that helps users troubleshoot '
                'step syncing issues on iOS and Android.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Choose a mode:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Open chat with mock service (development mode, no persistence)
                final config = ChatBotConfig.development(userId: 'demo_user');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(config: config),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Mock Service (No Persistence)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Open chat with mock service + persistence
                final config = ChatBotConfig.development(
                  userId: 'demo_user',
                  enablePersistence: true,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(config: config),
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Mock + Persistence'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Open chat with real service (production mode)
                final config = ChatBotConfig.development(
                  userId: 'demo_user',
                  useMockService: false,
                  enablePersistence: true,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(config: config),
                  ),
                );
              },
              icon: const Icon(Icons.health_and_safety),
              label: const Text('Real Health Connect + Persistence'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                _showDiagnosticDemoDialog(context);
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Diagnostic Demo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                _showInfoDialog(context);
              },
              child: const Text('About'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiagnosticDemoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnostic Demo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Try these diagnostic scenarios:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDemoTile(
                context,
                'Permission Denied',
                'Simulates missing health permissions',
                Icons.lock,
                Colors.red,
                () {
                  Navigator.pop(context);
                  // TODO: Add mock service with permission denied
                  final config = ChatBotConfig.development(
                    userId: 'demo_user',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(config: config),
                    ),
                  );
                },
              ),
              _buildDemoTile(
                context,
                'No Data Sources',
                'Simulates no fitness apps connected',
                Icons.warning,
                Colors.orange,
                () {
                  Navigator.pop(context);
                  final config = ChatBotConfig.development(
                    userId: 'demo_user',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(config: config),
                    ),
                  );
                },
              ),
              _buildDemoTile(
                context,
                'Healthy System',
                'Everything working correctly',
                Icons.check_circle,
                Colors.green,
                () {
                  Navigator.pop(context);
                  final config = ChatBotConfig.development(
                    userId: 'demo_user',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(config: config),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'In each scenario, type "check status" to run comprehensive diagnostics.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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

  Widget _buildDemoTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const SingleChildScrollView(
          child: Text(
            'This is an example integration of the Step Sync ChatBot package.\n\n'
            'Features:\n'
            '• Rule-based intent classification\n'
            '• Health data integration (mock & real)\n'
            '• Conversational troubleshooting\n'
            '• Permission management\n'
            '• Platform-aware responses\n'
            '• Comprehensive diagnostics\n'
            '• Platform detection (Android/iOS)\n'
            '• Automatic issue detection\n'
            '• Guided remediation actions\n'
            '• Conversation persistence\n'
            '• SQLite storage\n\n'
            'Phase 4 Features:\n'
            '• Enhanced diagnostic system\n'
            '• Battery optimization detection\n'
            '• Health Connect installation check\n'
            '• Multiple data source detection\n'
            '• Actionable quick replies\n'
            '• Automatic settings navigation',
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
