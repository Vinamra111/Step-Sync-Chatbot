import 'package:step_sync_chatbot/src/data/models/chat_message.dart';
import 'package:step_sync_chatbot/src/llm/llm_provider.dart';

/// Manages conversation context for LLM interactions.
///
/// This tracks recent messages and converts them to the format
/// expected by LLM providers.
class ConversationContext {
  final int maxContextMessages;
  final List<ChatMessage> _messages = [];

  ConversationContext({
    this.maxContextMessages = 10,
  });

  /// Add a message to the context.
  void addMessage(ChatMessage message) {
    _messages.add(message);

    // Keep only the most recent N messages
    while (_messages.length > maxContextMessages) {
      _messages.removeAt(0);
    }
  }

  /// Get conversation history in LLM provider format.
  ///
  /// Converts ChatMessage objects to ConversationMessage format.
  List<ConversationMessage> getHistory() {
    return _messages.map((msg) {
      final role = msg.sender == MessageSender.user ? 'user' : 'assistant';
      return ConversationMessage(
        role: role,
        content: msg.text,
      );
    }).toList();
  }

  /// Clear the conversation context.
  void clear() {
    _messages.clear();
  }

  /// Get the number of messages in context.
  int get messageCount => _messages.length;

  /// Check if context is empty.
  bool get isEmpty => _messages.isEmpty;

  /// Get a summary of the conversation for debugging.
  String getSummary() {
    if (_messages.isEmpty) {
      return 'No messages in context';
    }

    final buffer = StringBuffer();
    buffer.writeln('Conversation Context (${_messages.length} messages):');

    for (var i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final role = msg.sender == MessageSender.user ? 'USER' : 'BOT';
      final preview = msg.text.length > 50
          ? '${msg.text.substring(0, 50)}...'
          : msg.text;
      buffer.writeln('${i + 1}. [$role] $preview');
    }

    return buffer.toString();
  }
}
