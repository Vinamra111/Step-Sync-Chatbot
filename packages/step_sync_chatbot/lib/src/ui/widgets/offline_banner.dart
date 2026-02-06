/// Offline Banner Widget
///
/// Displays offline status and queued message count.
/// Features:
/// - Animated appearance/disappearance
/// - Connection quality indicator
/// - Queued message count
/// - Retry button
/// - Dismissible (optional)

import 'package:flutter/material.dart';
import '../../services/offline_service.dart';
import '../../services/network_monitor.dart';

/// Offline banner widget
class OfflineBanner extends StatefulWidget {
  final OfflineStatus status;
  final VoidCallback? onRetry;
  final VoidCallback? onTapQueuedMessages;
  final bool dismissible;

  const OfflineBanner({
    Key? key,
    required this.status,
    this.onRetry,
    this.onTapQueuedMessages,
    this.dismissible = false,
  }) : super(key: key);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation.drive(
        Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ),
      ),
      child: _buildBanner(context),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: _getBannerColor(theme),
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Status icon
              Icon(
                _getStatusIcon(),
                color: Colors.white,
                size: 20,
              ),

              const SizedBox(width: 12),

              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getStatusText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_getSubtitleText() != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _getSubtitleText()!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Queued messages indicator
              if (widget.status.queuedMessageCount > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onTapQueuedMessages,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.status.queuedMessageCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Retry button
              if (!widget.status.isOnline && widget.onRetry != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],

              // Dismiss button
              if (widget.dismissible) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white,
                  onPressed: _dismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBannerColor(ThemeData theme) {
    if (!widget.status.isOnline) {
      return Colors.orange.shade700; // Offline
    }

    if (widget.status.isProcessingQueue) {
      return Colors.blue.shade700; // Syncing
    }

    switch (widget.status.connectionQuality) {
      case ConnectionQuality.excellent:
        return Colors.green.shade700;
      case ConnectionQuality.good:
        return Colors.lightGreen.shade700;
      case ConnectionQuality.poor:
        return Colors.orange.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _getStatusIcon() {
    if (!widget.status.isOnline) {
      return Icons.cloud_off;
    }

    if (widget.status.isProcessingQueue) {
      return Icons.sync;
    }

    switch (widget.status.connectionType) {
      case ConnectionType.wifi:
        return Icons.wifi;
      case ConnectionType.mobile:
        return Icons.signal_cellular_4_bar;
      case ConnectionType.ethernet:
        return Icons.settings_ethernet;
      default:
        return Icons.cloud_done;
    }
  }

  String _getStatusText() {
    if (!widget.status.isOnline) {
      return 'Offline Mode';
    }

    if (widget.status.isProcessingQueue) {
      return 'Syncing Messages...';
    }

    switch (widget.status.connectionQuality) {
      case ConnectionQuality.excellent:
        return 'Connected (Excellent)';
      case ConnectionQuality.good:
        return 'Connected (Good)';
      case ConnectionQuality.poor:
        return 'Connected (Poor)';
      default:
        return 'Connected';
    }
  }

  String? _getSubtitleText() {
    if (!widget.status.isOnline) {
      if (widget.status.queuedMessageCount > 0) {
        return '${widget.status.queuedMessageCount} message${widget.status.queuedMessageCount == 1 ? '' : 's'} queued';
      }
      return 'Limited functionality available';
    }

    if (widget.status.isProcessingQueue) {
      return 'Sending queued messages...';
    }

    return null;
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _dismissed = true;
        });
      }
    });
  }
}

/// Queued messages list dialog
class QueuedMessagesDialog extends StatelessWidget {
  final List<dynamic> queuedMessages;
  final VoidCallback? onClearAll;

  const QueuedMessagesDialog({
    Key? key,
    required this.queuedMessages,
    this.onClearAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.schedule, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Queued Messages'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: queuedMessages.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No queued messages')),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: queuedMessages.length,
                itemBuilder: (context, index) {
                  final message = queuedMessages[index];
                  return _buildMessageItem(context, message);
                },
              ),
      ),
      actions: [
        if (queuedMessages.isNotEmpty && onClearAll != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClearAll?.call();
            },
            child: const Text('Clear All'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildMessageItem(BuildContext context, dynamic message) {
    final theme = Theme.of(context);

    // Extract message details (adjust based on your QueuedMessage structure)
    final messageText = message.toString();
    final truncated = messageText.length > 100
        ? '${messageText.substring(0, 100)}...'
        : messageText;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.message,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        title: Text(
          truncated,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: const Text('Waiting to send...'),
        trailing: Icon(
          Icons.schedule,
          color: Colors.orange,
          size: 18,
        ),
      ),
    );
  }
}

/// Connection quality indicator
class ConnectionQualityIndicator extends StatelessWidget {
  final ConnectionQuality quality;
  final double size;

  const ConnectionQualityIndicator({
    Key? key,
    required this.quality,
    this.size = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBar(0),
        const SizedBox(width: 2),
        _buildBar(1),
        const SizedBox(width: 2),
        _buildBar(2),
      ],
    );
  }

  Widget _buildBar(int index) {
    final isActive = _getActiveBarCount() > index;

    return Container(
      width: size * 0.3,
      height: size * (0.4 + index * 0.3),
      decoration: BoxDecoration(
        color: isActive ? _getColor() : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  int _getActiveBarCount() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 3;
      case ConnectionQuality.good:
        return 2;
      case ConnectionQuality.poor:
        return 1;
      default:
        return 0;
    }
  }

  Color _getColor() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.poor:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
