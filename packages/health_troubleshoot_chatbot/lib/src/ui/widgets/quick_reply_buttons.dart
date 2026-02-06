import 'package:flutter/material.dart';
import '../../data/models/chat_message.dart';

/// Widget that displays quick reply buttons.
class QuickReplyButtons extends StatelessWidget {
  final List<QuickReply> quickReplies;
  final void Function(String value) onReplyTap;

  const QuickReplyButtons({
    Key? key,
    required this.quickReplies,
    required this.onReplyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: quickReplies.map((reply) {
          return _QuickReplyChip(
            reply: reply,
            onTap: () => onReplyTap(reply.value),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final QuickReply reply;
  final VoidCallback onTap;

  const _QuickReplyChip({
    Key? key,
    required this.reply,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            reply.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
