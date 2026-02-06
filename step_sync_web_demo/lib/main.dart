/// Step Sync ChatBot - Web Demo with Full Groq LLM Support
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() => runApp(const StepSyncWebApp());

class StepSyncWebApp extends StatelessWidget {
  const StepSyncWebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Sync ChatBot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  bool _loading = false;
  final _log = Logger();

  static const _apiKey = 'YOUR_GROQ_API_KEY_HERE'; // Replace with your actual Groq API key
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';

  @override
  void initState() {
    super.initState();
    _add(true, 'Hi! I\'m your Step Sync assistant. I can help you troubleshoot step tracking issues.\n\nWhat brings you here today?');
  }

  void _add(bool isBot, String text) {
    setState(() => _messages.add(ChatMessage(text, isBot, DateTime.now())));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Duration(milliseconds: 300), curve: Curves.ease);
    });
  }

  Future<void> _send() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;

    _add(false, msg);
    _controller.clear();
    setState(() => _loading = true);

    try {
      final history = _messages.map((m) => {'role': m.isBot ? 'assistant' : 'user', 'content': m.text}).toList();
      final body = {
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'system', 'content': 'You are a Step Sync troubleshooting assistant - an expert at helping users resolve step tracking issues.\n\n━━━ CORE IDENTITY ━━━\n• You are a human support specialist (NEVER reveal you\'re AI/LLM/bot)\n• Show empathy and acknowledge user frustration\n• Be conversational, patient, and encouraging\n\n━━━ CONVERSATION STAGES ━━━\n\n**STAGE 1 - GREETING:**\nUser says hi/hello → Greet warmly, ask "What brings you here?" or "How can I help?"\nExample: "Hi! I\'m here to help with step tracking issues. What\'s going on with your steps?"\n\n**STAGE 2 - DISCOVERY:**\nUser mentions problem → Ask 2-3 specific questions using bullet points:\n• Device type (iPhone/Android/model)\n• App being used (Apple Health/Google Fit/etc.)\n• When it started (today/after update/always)\n\nExample: "I can help! Let me understand your setup:\n\n• **What device are you using?**\n• **Which app tracks your steps?**\n• **When did this start?**"\n\n**STAGE 3 - SOLUTION:**\nAfter understanding → Provide 2-4 actionable steps (most common fix first)\nUse numbered lists, explain WHY each step helps\n\nExample: "Based on Android, here\'s what to check:\n\n**1. Battery Optimization** (most common issue)\nSettings → Battery → [App] → Don\'t optimize\n\n**2. Background Data**\nSettings → Apps → [App] → enable background data\n\nTry these and let me know!"\n\n━━━ RESPONSE STYLE ━━━\n• Length: 3-6 sentences OR short paragraph + 2-4 bullets\n• Use **bold** for key terms\n• Break up text for readability\n• NOT too short (unhelpful) or too long (overwhelming)\n• Positive tone: "Let\'s get this working" not "It\'s broken"\n\n━━━ SPECIAL CASES ━━━\n• Can\'t "check" remotely: "I can\'t access your device, but I can guide you!"\n• Vague input: Ask clarifying question\n• Don\'t know: "I\'m not certain, but here\'s what typically works..."\n• Medical data: "I focus on technical issues. For health concerns, consult your doctor."'},
          ...history,
          {'role': 'user', 'content': msg}
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      };

      final res = await http.post(Uri.parse(_url), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'}, body: jsonEncode(body));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _add(true, data['choices'][0]['message']['content']);
      } else {
        _add(true, 'Error: ${res.statusCode}');
      }
    } catch (e) {
      _log.e(e);
      _add(true, 'I\'m having trouble connecting. Try:\n\n• Check battery optimization\n• Verify permissions\n• Restart device');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Icon(Icons.chat_bubble_outline), SizedBox(width: 8), Text('Step Sync Assistant')]),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) {
                  return Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle), child: Icon(Icons.smart_toy, color: Colors.white, size: 24)),
                    SizedBox(width: 12),
                    Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('Typing...')]))
                  ]);
                }
                final msg = _messages[i];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.isBot) ...[
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle), child: Icon(Icons.smart_toy, color: Colors.white, size: 24)),
                        SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: msg.isBot ? Colors.grey.shade200 : Colors.blue, borderRadius: BorderRadius.circular(20)),
                          child: msg.isBot
                              ? MarkdownBody(
                                  data: msg.text,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(color: Colors.black87, fontSize: 15, height: 1.5),
                                    strong: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                                    listBullet: TextStyle(color: Colors.black87),
                                  ),
                                )
                              : Text(
                                  msg.text,
                                  style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                                ),
                        ),
                      ),
                      if (!msg.isBot) ...[
                        SizedBox(width: 12),
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle), child: Icon(Icons.person, color: Colors.blue)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _loading ? null : _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime time;
  ChatMessage(this.text, this.isBot, this.time);
}
