/// Voice Input Button Widget
///
/// Animated microphone button with visual feedback.
/// Features:
/// - Animated microphone icon
/// - Pulsing effect while listening
/// - Audio level visualization
/// - State-aware colors
/// - Haptic feedback

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/voice_input_service.dart';

/// Voice input button with animation
class VoiceInputButton extends StatefulWidget {
  final VoiceInputState state;
  final VoidCallback? onPressed;
  final double audioLevel;

  const VoiceInputButton({
    Key? key,
    required this.state,
    this.onPressed,
    this.audioLevel = 0.0,
  }) : super(key: key);

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsing animation for listening state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.state == VoiceInputState.listening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isListening = widget.state == VoiceInputState.listening;
    final isDisabled = widget.state == VoiceInputState.notAvailable ||
        widget.state == VoiceInputState.permissionDenied ||
        widget.onPressed == null;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onPressed?.call();
            },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isListening
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20 * _pulseAnimation.value,
                        spreadRadius: 5 * _pulseAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Audio level ring (only when listening)
                if (isListening)
                  CustomPaint(
                    size: const Size(56, 56),
                    painter: AudioLevelPainter(
                      level: widget.audioLevel,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                // Main button
                Material(
                  color: _getButtonColor(theme, isDisabled),
                  shape: const CircleBorder(),
                  elevation: isListening ? 8 : 2,
                  child: InkWell(
                    onTap: isDisabled ? null : widget.onPressed,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        _getIcon(),
                        color: _getIconColor(theme, isDisabled),
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Loading indicator (when initializing)
                if (widget.state == VoiceInputState.initializing)
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.state) {
      case VoiceInputState.listening:
        return Icons.mic;
      case VoiceInputState.processing:
        return Icons.more_horiz;
      case VoiceInputState.error:
        return Icons.error_outline;
      case VoiceInputState.permissionDenied:
        return Icons.mic_off;
      case VoiceInputState.notAvailable:
        return Icons.mic_none;
      default:
        return Icons.mic_none;
    }
  }

  Color _getButtonColor(ThemeData theme, bool isDisabled) {
    if (isDisabled) {
      return theme.colorScheme.surfaceVariant;
    }

    switch (widget.state) {
      case VoiceInputState.listening:
        return theme.colorScheme.primary;
      case VoiceInputState.error:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primaryContainer;
    }
  }

  Color _getIconColor(ThemeData theme, bool isDisabled) {
    if (isDisabled) {
      return theme.colorScheme.onSurfaceVariant.withOpacity(0.5);
    }

    switch (widget.state) {
      case VoiceInputState.listening:
        return theme.colorScheme.onPrimary;
      case VoiceInputState.error:
        return theme.colorScheme.onError;
      default:
        return theme.colorScheme.onPrimaryContainer;
    }
  }
}

/// Custom painter for audio level visualization
class AudioLevelPainter extends CustomPainter {
  final double level; // 0.0 to 1.0
  final Color color;

  AudioLevelPainter({
    required this.level,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw audio level ring
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Scale ring based on audio level
    final ringRadius = radius + (10 * level);
    canvas.drawCircle(center, ringRadius, paint);
  }

  @override
  bool shouldRepaint(AudioLevelPainter oldDelegate) {
    return oldDelegate.level != level;
  }
}

/// Voice input overlay with waveform
class VoiceInputOverlay extends StatelessWidget {
  final VoiceInputState state;
  final String? partialTranscription;
  final double audioLevel;
  final VoidCallback? onCancel;

  const VoiceInputOverlay({
    Key? key,
    required this.state,
    this.partialTranscription,
    this.audioLevel = 0.0,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state != VoiceInputState.listening) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform visualization
          SizedBox(
            height: 60,
            child: AnimatedWaveform(audioLevel: audioLevel),
          ),

          const SizedBox(height: 16),

          // Status text
          Text(
            'Listening...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Partial transcription
          if (partialTranscription != null && partialTranscription!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                partialTranscription!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Text(
              'Speak now...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 16),

          // Cancel button
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated waveform visualization
class AnimatedWaveform extends StatefulWidget {
  final double audioLevel;

  const AnimatedWaveform({
    Key? key,
    required this.audioLevel,
  }) : super(key: key);

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 60),
          painter: WaveformPainter(
            audioLevel: widget.audioLevel,
            phase: _controller.value,
            color: theme.colorScheme.primary,
          ),
        );
      },
    );
  }
}

/// Custom painter for waveform
class WaveformPainter extends CustomPainter {
  final double audioLevel;
  final double phase;
  final Color color;

  WaveformPainter({
    required this.audioLevel,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final barCount = 40;
    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      // Create wave effect with phase shift
      final angle = (i / barCount) * 2 * 3.14159 + (phase * 2 * 3.14159);
      final baseHeight = size.height * 0.1;
      final levelHeight = size.height * 0.4 * audioLevel;
      final barHeight = baseHeight + levelHeight * (0.5 + 0.5 * (angle.sin()));

      final x = i * barWidth;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth * 0.6,
          height: barHeight,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.audioLevel != audioLevel || oldDelegate.phase != phase;
  }
}
