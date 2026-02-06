/// Voice Input Service
///
/// Handles speech-to-text functionality for voice input.
/// Features:
/// - Cross-platform speech recognition (iOS/Android)
/// - Real-time transcription
/// - Multi-language support
/// - Error handling and fallback
/// - Permission management
/// - Audio level monitoring

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

/// Voice input state
enum VoiceInputState {
  /// Service is idle
  idle,

  /// Initializing speech recognition
  initializing,

  /// Ready to listen
  ready,

  /// Currently listening
  listening,

  /// Processing speech
  processing,

  /// Error occurred
  error,

  /// Permission denied
  permissionDenied,

  /// Not available on this device
  notAvailable,
}

/// Voice input result
class VoiceInputResult {
  final String transcription;
  final double confidence;
  final bool isFinal;
  final DateTime timestamp;

  VoiceInputResult({
    required this.transcription,
    required this.confidence,
    required this.isFinal,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'VoiceInputResult(text: "$transcription", confidence: ${(confidence * 100).toStringAsFixed(1)}%, final: $isFinal)';
}

/// Voice input configuration
class VoiceInputConfig {
  /// Language code (e.g., "en-US", "es-ES", "zh-CN")
  final String languageCode;

  /// Enable partial results (real-time transcription)
  final bool enablePartialResults;

  /// Pause between words before finalizing (seconds)
  final Duration pauseDuration;

  /// Maximum listening duration
  final Duration maxListenDuration;

  /// Minimum confidence threshold (0.0-1.0)
  final double minConfidence;

  /// Enable haptic feedback on start/stop
  final bool enableHapticFeedback;

  const VoiceInputConfig({
    this.languageCode = 'en-US',
    this.enablePartialResults = true,
    this.pauseDuration = const Duration(seconds: 2),
    this.maxListenDuration = const Duration(seconds: 30),
    this.minConfidence = 0.7,
    this.enableHapticFeedback = true,
  });
}

/// Exception for voice input errors
class VoiceInputException implements Exception {
  final String message;
  final dynamic originalError;

  VoiceInputException(this.message, {this.originalError});

  @override
  String toString() => 'VoiceInputException: $message';
}

/// Voice Input Service
class VoiceInputService {
  final VoiceInputConfig config;
  final Logger _logger;
  final stt.SpeechToText _speech;

  /// Current state
  VoiceInputState _state = VoiceInputState.idle;
  VoiceInputState get state => _state;

  /// Stream of state changes
  final StreamController<VoiceInputState> _stateController =
      StreamController<VoiceInputState>.broadcast();
  Stream<VoiceInputState> get stateStream => _stateController.stream;

  /// Stream of transcription results
  final StreamController<VoiceInputResult> _resultController =
      StreamController<VoiceInputResult>.broadcast();
  Stream<VoiceInputResult> get resultStream => _resultController.stream;

  /// Stream of audio levels (0.0-1.0)
  final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  /// Available locales
  List<stt.LocaleName> _availableLocales = [];
  List<stt.LocaleName> get availableLocales => List.unmodifiable(_availableLocales);

  /// Whether speech recognition is available on this device
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Whether currently listening
  bool get isListening => _state == VoiceInputState.listening;

  VoiceInputService({
    VoiceInputConfig? config,
    Logger? logger,
    stt.SpeechToText? speech,
  })  : config = config ?? const VoiceInputConfig(),
        _logger = logger ?? Logger(),
        _speech = speech ?? stt.SpeechToText();

  /// Initialize the voice input service
  Future<bool> initialize() async {
    _logger.d('Initializing voice input service');
    _updateState(VoiceInputState.initializing);

    try {
      // Check microphone permission
      final permissionStatus = await _checkPermission();
      if (!permissionStatus) {
        _updateState(VoiceInputState.permissionDenied);
        _logger.w('Microphone permission denied');
        return false;
      }

      // Initialize speech recognition
      _isAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!_isAvailable) {
        _updateState(VoiceInputState.notAvailable);
        _logger.w('Speech recognition not available on this device');
        return false;
      }

      // Get available locales
      _availableLocales = await _speech.locales();
      _logger.i('Speech recognition initialized. Available locales: ${_availableLocales.length}');

      _updateState(VoiceInputState.ready);
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize voice input', error: e, stackTrace: stackTrace);
      _updateState(VoiceInputState.error);
      return false;
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!_isAvailable) {
      throw VoiceInputException('Speech recognition not available');
    }

    if (_state == VoiceInputState.listening) {
      _logger.w('Already listening');
      return;
    }

    _logger.d('Starting voice input');
    _updateState(VoiceInputState.listening);

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        localeId: config.languageCode,
        partialResults: config.enablePartialResults,
        listenFor: config.maxListenDuration,
        pauseFor: config.pauseDuration,
        onSoundLevelChange: (level) {
          // level ranges from -2.0 to 10.0, normalize to 0.0-1.0
          final normalizedLevel = ((level + 2.0) / 12.0).clamp(0.0, 1.0);
          _audioLevelController.add(normalizedLevel);
        },
      );

      _logger.i('Voice listening started');
    } catch (e) {
      _logger.e('Failed to start listening: $e');
      _updateState(VoiceInputState.error);
      throw VoiceInputException('Failed to start listening', originalError: e);
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (_state != VoiceInputState.listening) {
      return;
    }

    _logger.d('Stopping voice input');

    try {
      await _speech.stop();
      _updateState(VoiceInputState.ready);
      _logger.i('Voice listening stopped');
    } catch (e) {
      _logger.e('Failed to stop listening: $e');
      throw VoiceInputException('Failed to stop listening', originalError: e);
    }
  }

  /// Cancel current listening session
  Future<void> cancel() async {
    if (_state != VoiceInputState.listening) {
      return;
    }

    _logger.d('Cancelling voice input');

    try {
      await _speech.cancel();
      _updateState(VoiceInputState.ready);
      _logger.i('Voice input cancelled');
    } catch (e) {
      _logger.e('Failed to cancel listening: $e');
    }
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isPermanentlyDenied) {
      // Request permission
      return await requestPermission();
    }

    return false;
  }

  /// Handle speech status changes
  void _onSpeechStatus(String status) {
    _logger.d('Speech status: $status');

    switch (status) {
      case 'listening':
        _updateState(VoiceInputState.listening);
        break;
      case 'notListening':
        if (_state == VoiceInputState.listening) {
          _updateState(VoiceInputState.ready);
        }
        break;
      case 'done':
        _updateState(VoiceInputState.ready);
        break;
    }
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    _logger.e('Speech error: $error');
    _updateState(VoiceInputState.error);

    // Emit error result
    _resultController.add(VoiceInputResult(
      transcription: '',
      confidence: 0.0,
      isFinal: true,
    ));
  }

  /// Handle speech recognition results
  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    final transcription = result.recognizedWords;
    final confidence = result.hasConfidenceRating ? result.confidence : 1.0;
    final isFinal = result.finalResult;

    _logger.d('Speech result: "$transcription" (confidence: ${(confidence * 100).toStringAsFixed(1)}%, final: $isFinal)');

    // Only emit if confidence meets threshold
    if (confidence >= config.minConfidence || isFinal) {
      _resultController.add(VoiceInputResult(
        transcription: transcription,
        confidence: confidence,
        isFinal: isFinal,
      ));
    }

    // Update state when final
    if (isFinal) {
      _updateState(VoiceInputState.ready);
    }
  }

  /// Update state and notify listeners
  void _updateState(VoiceInputState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
      _logger.d('Voice input state: $newState');
    }
  }

  /// Get status information
  Map<String, dynamic> getStatus() {
    return {
      'state': _state.toString(),
      'isAvailable': _isAvailable,
      'isListening': isListening,
      'language': config.languageCode,
      'availableLocales': _availableLocales.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _logger.d('Disposing voice input service');

    // Cancel any active listening
    if (isListening) {
      _speech.cancel();
    }

    // Close streams
    _stateController.close();
    _resultController.close();
    _audioLevelController.close();
  }
}
