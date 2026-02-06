import 'package:flutter/material.dart';
import '../../data/models/chat_message.dart';

/// Widget that displays a single chat message bubble.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildBotAvatar(theme),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getBubbleColor(theme, isUser),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (message.quickReplies != null &&
                      message.quickReplies!.isNotEmpty)
                    _buildQuickReplies(context),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(theme),
        ],
      ),
    );
  }

  Widget _buildBotAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.smart_toy,
        size: 18,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildUserAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.secondaryContainer,
      child: Icon(
        Icons.person,
        size: 18,
        color: theme.colorScheme.onSecondaryContainer,
      ),
    );
  }

  Color _getBubbleColor(ThemeData theme, bool isUser) {
    if (message.isError) {
      return theme.colorScheme.errorContainer;
    }
    return isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceVariant;
  }

  Widget _buildQuickReplies(BuildContext context) {
    // This will be populated by the parent widget with callbacks
    // For now, just show the structure
    return const SizedBox.shrink();
  }
}
