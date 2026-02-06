# Step Sync ChatBot - Integration Guide

This guide shows you how to integrate the Step Sync ChatBot into your Flutter application.

## Table of Contents
1. [Installation](#installation)
2. [Basic Setup](#basic-setup)
3. [Using the Chatbot](#using-the-chatbot)
4. [UI Integration](#ui-integration)
5. [Complete Example](#complete-example)
6. [Advanced Features](#advanced-features)

---

## Installation

### Step 1: Add to pubspec.yaml

Since this is a local package, add it as a path dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Step Sync ChatBot
  step_sync_chatbot:
    path: packages/step_sync_chatbot

  # Required dependencies (if not already in your app)
  flutter_riverpod: ^2.5.1
  logger: ^2.0.2
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Android Setup (for Battery Optimization)

Follow the instructions in [`android_integration.md`](android_integration.md) to:
1. Add permissions to AndroidManifest.xml
2. Create/update MainActivity.kt with method channel code

### Step 4: Set Up API Key

Get your free Groq API key from https://console.groq.com

**Option A: Environment Variable (Recommended for Development)**
```bash
export GROQ_API_KEY=your_key_here
```

**Option B: Secure Storage (Recommended for Production)**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'groq_api_key', value: 'your_key_here');
```

---

## Basic Setup

### Initialize Services

Create a service initialization file (e.g., `lib/services/chatbot_setup.dart`):

```dart
import 'package:step_sync_chatbot/step_sync_chatbot.dart';
import 'package:logger/logger.dart';

class ChatBotSetup {
  static GroqChatService? _groqService;
  static PHISanitizerService? _phiSanitizer;
  static LLMResponseGenerator? _responseGenerator;

  /// Initialize chatbot services
  static Future<void> initialize({required String apiKey}) async {
    final logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
      ),
    );

    // Initialize PHI sanitizer (privacy protection)
    _phiSanitizer = PHISanitizerService(strictMode: false);

    // Initialize Groq chat service (LLM)
    _groqService = GroqChatService(
      config: GroqChatConfig(
        apiKey: apiKey,
        model: 'llama-3.3-70b-versatile',
        temperature: 0.7,
        maxTokens: 1024,
        timeout: const Duration(seconds: 30),
      ),
      sanitizer: _phiSanitizer,
      logger: logger,
    );

    // Initialize LLM response generator
    _responseGenerator = LLMResponseGenerator(
      groqService: _groqService!,
      phiSanitizer: _phiSanitizer!,
      logger: logger,
    );
  }

  static GroqChatService get groqService => _groqService!;
  static PHISanitizerService get phiSanitizer => _phiSanitizer!;
  static LLMResponseGenerator get responseGenerator => _responseGenerator!;
}
```

### Initialize in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/chatbot_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get API key (from environment or secure storage)
  final apiKey = const String.fromEnvironment('GROQ_API_KEY');

  // Initialize chatbot
  await ChatBotSetup.initialize(apiKey: apiKey);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Sync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

## Using the Chatbot

### Simple Chat Screen

Create a basic chat screen (`lib/screens/chat_screen.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:step_sync_chatbot/step_sync_chatbot.dart';
import '../services/chatbot_setup.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Intent classifier
  final _intentClassifier = RuleBasedIntentClassifier();

  // Conversation context
  ConversationContext _context = ConversationContext.initial();

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addBotMessage('Hi! I\'m your Step Sync Assistant. How can I help you today?');
  }

  void _addBotMessage(String content) {
    setState(() {
      _messages.add(ChatMessage(
        content: content,
        role: 'assistant',
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String content) {
    setState(() {
      _messages.add(ChatMessage(
        content: content,
        role: 'user',
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message to chat
    _addUserMessage(message);
    _messageController.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      // Classify intent
      final intentResult = _intentClassifier.classify(message);

      // Update conversation context
      _context = _context.addUserMessage(
        message,
        intent: intentResult.intent,
      );

      // Generate response using LLM
      final response = await ChatBotSetup.responseGenerator.generate(
        userMessage: message,
        intent: intentResult.intent,
        context: _context,
      );

      // Add bot response to chat
      _addBotMessage(response);

      // Update context with bot response
      _context = _context.addBotMessage(response);

    } catch (e) {
      // Error handling - show fallback message
      _addBotMessage(
        'I\'m having trouble connecting right now, but I\'m here to help! '
        'Could you tell me more about what\'s happening with your steps?'
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Sync Assistant'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.role == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

### Add Chat Button to Your App

In your main screen (e.g., `lib/screens/home_screen.dart`):

```dart
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Sync'),
        actions: [
          // Chat button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat with Assistant',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your step tracking content here',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Need Help?'),
            ),
          ],
        ),
      ),
      // Floating chat button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
            ),
          );
        },
        child: const Icon(Icons.chat),
        tooltip: 'Chat with Assistant',
      ),
    );
  }
}
```

---

## UI Integration

### Option 1: Full Screen Chat
Use the `ChatScreen` widget shown above - opens in a new screen.

### Option 2: Bottom Sheet Chat
Open chat as a bottom sheet:

```dart
void _openChatBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const ChatScreen(),
      ),
    ),
  );
}
```

### Option 3: Floating Chat Widget
Create a draggable chat bubble:

```dart
// Add to your app - persistent across screens
class FloatingChatButton extends StatefulWidget {
  const FloatingChatButton({Key? key}) : super(key: key);

  @override
  State<FloatingChatButton> createState() => _FloatingChatButtonState();
}

class _FloatingChatButtonState extends State<FloatingChatButton> {
  Offset _position = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Draggable(
        feedback: _buildChatBubble(),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            _position = details.offset;
          });
        },
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatScreen(),
              ),
            );
          },
          child: _buildChatBubble(),
        ),
      ),
    );
  }

  Widget _buildChatBubble() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.chat,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
```

---

## Complete Example

Here's a complete minimal app:

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:step_sync_chatbot/step_sync_chatbot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize chatbot
  final apiKey = const String.fromEnvironment('GROQ_API_KEY',
      defaultValue: 'your_groq_api_key_here');

  await initializeChatBot(apiKey);

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> initializeChatBot(String apiKey) async {
  // Initialize services (simplified)
  // In production, use proper dependency injection
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Sync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeWithChat(),
    );
  }
}

class HomeWithChat extends StatelessWidget {
  const HomeWithChat({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Sync'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Track Your Steps',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Open chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimpleChatScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Need Help with Steps?'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Minimal chat screen
class SimpleChatScreen extends StatefulWidget {
  const SimpleChatScreen({Key? key}) : super(key: key);

  @override
  State<SimpleChatScreen> createState() => _SimpleChatScreenState();
}

class _SimpleChatScreenState extends State<SimpleChatScreen> {
  final _controller = TextEditingController();
  final List<String> _messages = ['Hi! How can I help with your steps?'];

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add('You: ${_controller.text}');
      _messages.add('Bot: I received your message!');
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_messages[index]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

Run with:
```bash
flutter run --dart-define=GROQ_API_KEY=your_key_here
```

---

## Advanced Features

### 1. Add Diagnostics

```dart
import 'package:step_sync_chatbot/src/diagnostics/battery_checker.dart';

// In your chat screen
final batteryChecker = BatteryChecker();

// Check battery optimization
final status = await batteryChecker.checkBatteryOptimization();

if (status == BatteryCheckResult.enabled) {
  // Show fix button
  ElevatedButton(
    onPressed: () async {
      await batteryChecker.requestBatteryOptimizationExemption();
    },
    child: const Text('Fix Battery Optimization'),
  );
}
```

### 2. Add Quick Reply Buttons

```dart
// Show quick replies after bot message
Widget _buildQuickReplies() {
  return Wrap(
    spacing: 8,
    children: [
      ActionChip(
        label: const Text('Check my steps'),
        onPressed: () => _sendPredefinedMessage('Check my steps'),
      ),
      ActionChip(
        label: const Text('Fix syncing'),
        onPressed: () => _sendPredefinedMessage('My steps aren\'t syncing'),
      ),
      ActionChip(
        label: const Text('Grant permissions'),
        onPressed: () => _sendPredefinedMessage('Grant permissions'),
      ),
    ],
  );
}
```

### 3. Add Conversation History

```dart
// Save conversation to local storage
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _saveConversation() async {
  final prefs = await SharedPreferences.getInstance();
  final messagesJson = _messages.map((m) => m.toJson()).toList();
  await prefs.setString('chat_history', jsonEncode(messagesJson));
}

Future<void> _loadConversation() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('chat_history');
  if (json != null) {
    final List decoded = jsonDecode(json);
    setState(() {
      _messages = decoded.map((m) => ChatMessage.fromJson(m)).toList();
    });
  }
}
```

---

## Next Steps

1. **Test the Integration**: Run the example and verify the chat works
2. **Customize UI**: Match the chat interface to your app's design
3. **Add Android Native Code**: Implement battery optimization detection
4. **Add Diagnostics**: Integrate health diagnostics for proactive help
5. **Production Checklist**:
   - [ ] Set `_kDevMode = false` in groq_chat_service.dart
   - [ ] Use secure storage for API key
   - [ ] Test on real devices (Android & iOS)
   - [ ] Add error tracking/monitoring
   - [ ] Configure rate limiting appropriately

---

## Troubleshooting

**Q: "I get errors about missing dependencies"**
A: Run `flutter pub get` and ensure all dependencies are in your app's pubspec.yaml

**Q: "Chat doesn't respond"**
A: Check that your Groq API key is valid and set correctly

**Q: "Battery optimization doesn't work"**
A: Ensure you've implemented the Android native code (MainActivity.kt)

**Q: "App crashes on startup"**
A: Check logs - likely missing API key or initialization issue

---

## Support

For issues or questions:
1. Check the test files for usage examples
2. Review the source code documentation
3. File an issue on GitHub

**API Key Setup**: https://console.groq.com
**Package Location**: `packages/step_sync_chatbot`
