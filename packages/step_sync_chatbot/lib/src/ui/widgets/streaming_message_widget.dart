/// Streaming Message Widget
///
/// Displays a message that's being streamed token-by-token (ChatGPT-like).
/// Features:
/// - Progressive text display
/// - Typing cursor animation
/// - Smooth animations
/// - Optimized rebuilds

import 'package:flutter/material.dart';

/// Widget for displaying streaming (partial) messages
class StreamingMessageWidget extends StatefulWidget {
  final String content;
  final bool isComplete;
  final VoidCallback? onCancel;

  const StreamingMessageWidget({
    Key? key,
    required this.content,
    this.isComplete = false,
    this.onCancel,
  }) : super(key: key);

  @override
  State<StreamingMessageWidget> createState() => _StreamingMessageWidgetState();
}

class _StreamingMessageWidgetState extends State<StreamingMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();

    // Blinking cursor animation (only if not complete)
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 530),
      vsync: this,
    );

    if (!widget.isComplete) {
      _cursorController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StreamingMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Stop cursor animation when complete
    if (widget.isComplete && !oldWidget.isComplete) {
      _cursorController.stop();
    } else if (!widget.isComplete && oldWidget.isComplete) {
      _cursorController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Streaming text with cursor
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // Blinking cursor (only if not complete)
              if (!widget.isComplete)
                FadeTransition(
                  opacity: _cursorController,
                  child: Container(
                    width: 2,
                    height: 20,
                    margin: const EdgeInsets.only(left: 2, bottom: 2),
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),

          // Cancel button (only while streaming)
          if (!widget.isComplete && widget.onCancel != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.stop, size: 16),
              label: const Text('Stop generating'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Typing indicator for when streaming is starting
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.15;
              final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
              final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2)
                  .clamp(0.3, 1.0);

              return Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(opacity),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Helper widget to display either regular message or streaming message
class AdaptiveMessageBubble extends StatelessWidget {
  final String content;
  final bool isBot;
  final bool isStreaming;
  final VoidCallback? onCancelStreaming;

  const AdaptiveMessageBubble({
    Key? key,
    required this.content,
    required this.isBot,
    this.isStreaming = false,
    this.onCancelStreaming,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isStreaming && isBot) {
      // Show streaming widget for bot messages being streamed
      return Align(
        alignment: Alignment.centerLeft,
        child: StreamingMessageWidget(
          content: content,
          isComplete: false,
          onCancel: onCancelStreaming,
        ),
      );
    }

    // Regular message bubble
    final theme = Theme.of(context);
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isBot
              ? theme.colorScheme.surfaceVariant
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: isBot
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
