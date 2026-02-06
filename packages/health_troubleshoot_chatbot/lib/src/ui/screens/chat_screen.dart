import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/chatbot_config.dart';
import '../../core/chatbot_controller.dart';
import '../../health/health_service.dart';
import '../../health/mock_health_service.dart';
import '../../health/real_health_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/quick_reply_buttons.dart';

/// Provider for the chatbot controller.
///
/// Creates a controller with the appropriate health service and repository based on config.
final chatBotControllerProvider =
    StateNotifierProvider.family<ChatBotController, dynamic, ChatBotConfig?>(
  (ref, config) {
    // Determine which health service to use
    HealthService healthService;

    if (config?.healthService != null) {
      // Use provided health service from config
      healthService = config!.healthService!;
    } else if (config?.debugMode == true) {
      // Development mode: use mock service
      healthService = MockHealthService();
    } else {
      // Production mode: use real service
      healthService = RealHealthService();
    }

    return ChatBotController(
      healthService: healthService,
      conversationRepository: config?.conversationRepository,
      userId: config?.userId,
    );
  },
);

/// Main chat screen for the Step Sync chatbot.
class ChatScreen extends ConsumerStatefulWidget {
  /// Optional configuration for the chatbot.
  /// If null, uses default configuration with mock service for development.
  final ChatBotConfig? config;

  const ChatScreen({Key? key, this.config}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize chatbot when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatBotControllerProvider(widget.config).notifier).initialize(
            loadPreviousConversation:
                widget.config?.loadPreviousConversation ?? false,
          );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatBotControllerProvider(widget.config));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Sync Assistant'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(state),
          ),
          if (state.isTyping) _buildTypingIndicator(),
          _buildQuickRepliesArea(state),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList(dynamic state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return MessageBubble(message: message);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy,
              size: 14,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          const Text('Typing...'),
        ],
      ),
    );
  }

  Widget _buildQuickRepliesArea(dynamic state) {
    // Get quick replies from the last bot message
    if (state.messages.isEmpty) return const SizedBox.shrink();

    final lastMessage = state.messages.last;
    if (lastMessage.quickReplies == null ||
        lastMessage.quickReplies.isEmpty) {
      return const SizedBox.shrink();
    }

    return QuickReplyButtons(
      quickReplies: lastMessage.quickReplies,
      onReplyTap: _handleQuickReply,
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _handleSendMessage,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatBotControllerProvider(widget.config).notifier).handleUserMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _handleQuickReply(String value) {
    // Treat quick reply as user input
    ref.read(chatBotControllerProvider(widget.config).notifier).handleUserMessage(value);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Delay to allow message to be added to list
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
}
