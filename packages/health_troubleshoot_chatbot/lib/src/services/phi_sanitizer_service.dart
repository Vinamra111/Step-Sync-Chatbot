/// Production-grade PHI Sanitizer Service
///
/// Removes Protected Health Information (PHI) from user messages
/// before sending to external LLM APIs (HIPAA-compliant).
///
/// Features:
/// - Multi-layer sanitization (numbers, dates, apps, devices)
/// - Validation to detect remaining PHI
/// - Detailed logging of sanitization actions
/// - Exception throwing if PHI detected after sanitization
/// - Configurable sanitization rules

import 'package:logger/logger.dart';

/// Exception thrown when PHI is detected after sanitization
class PHIDetectedException implements Exception {
  final String message;
  final String detectedContent;

  PHIDetectedException(this.message, this.detectedContent);

  @override
  String toString() {
    // SECURITY: Never include actual PHI content in exception string
    // Only include metadata (length) for debugging
    return 'PHIDetectedException: $message (content length: ${detectedContent.length} chars)';
  }
}

/// Result of sanitization operation
class SanitizationResult {
  final String sanitizedText;
  final String originalText;
  final bool wasSanitized;
  final List<String> replacements;

  SanitizationResult({
    required this.sanitizedText,
    required this.originalText,
    required this.wasSanitized,
    required this.replacements,
  });

  /// Whether any PHI was removed
  bool get hadPHI => wasSanitized;

  /// Number of replacements made
  int get replacementCount => replacements.length;
}

/// Production PHI Sanitizer Service
///
/// Sanitizes user input by removing:
/// - Step counts and numeric data
/// - Temporal references (dates, times)
/// - App names (Google Fit, Samsung Health, etc.)
/// - Device names (iPhone 15, Galaxy S24, etc.)
/// - Locations (city, address, GPS coordinates)
class PHISanitizerService {
  final Logger _logger;
  final bool _strictMode;

  PHISanitizerService({
    Logger? logger,
    bool strictMode = true,
  })  : _logger = logger ?? Logger(),
        _strictMode = strictMode;

  /// Sanitize user input by removing all PHI
  ///
  /// Returns [SanitizationResult] with sanitized text and metadata.
  /// Throws [PHIDetectedException] if PHI remains after sanitization in strict mode.
  SanitizationResult sanitize(String text) {
    final originalText = text;
    var sanitized = text;
    final replacements = <String>[];

    _logger.d('Sanitizing input (${text.length} chars)');

    // Pre-check: In strict mode, detect critical PHI before sanitization
    if (_strictMode) {
      _preValidateCriticalPHI(text);
    }

    // Layer 1: Temporal references (dates, times) - MUST run before numbers
    sanitized = _sanitizeTemporal(sanitized, replacements);

    // Layer 2: Numbers (step counts, calories, weight, heart rate, etc.)
    sanitized = _sanitizeNumbers(sanitized, replacements);

    // Layer 3: App names
    sanitized = _sanitizeAppNames(sanitized, replacements);

    // Layer 4: Device names
    sanitized = _sanitizeDeviceNames(sanitized, replacements);

    // Layer 5: Location data (city names, addresses)
    sanitized = _sanitizeLocations(sanitized, replacements);

    // Validation: Check for remaining PHI
    if (_strictMode && _detectRemainingPHI(sanitized)) {
      _logger.e('PHI detected after sanitization');
      throw PHIDetectedException(
        'Sensitive data detected after sanitization',
        sanitized,
      );
    }

    final wasSanitized = sanitized != originalText;
    if (wasSanitized) {
      _logger.i('Sanitization complete: ${replacements.length} replacements');
    } else {
      _logger.d('No PHI detected in input');
    }

    return SanitizationResult(
      sanitizedText: sanitized,
      originalText: originalText,
      wasSanitized: wasSanitized,
      replacements: replacements,
    );
  }

  /// Layer 1: Sanitize numbers
  String _sanitizeNumbers(String text, List<String> replacements) {
    final pattern = RegExp(r'\b\d{1,3}(,?\d{3})*(\.\d+)?\b');
    final matches = pattern.allMatches(text);

    if (matches.isNotEmpty) {
      replacements.add('numbers');
      return text.replaceAll(pattern, 'METRIC_VALUE');
    }
    return text;
  }

  /// Layer 2: Sanitize temporal references
  String _sanitizeTemporal(String text, List<String> replacements) {
    final patterns = [
      // Days of week
      RegExp(
        r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
        caseSensitive: false,
      ),
      // Relative dates
      RegExp(
        r'\b(yesterday|today|tomorrow|tonight|last\s+\w+|this\s+\w+|next\s+\w+)\b',
        caseSensitive: false,
      ),
      // Specific dates (MM/DD/YYYY, DD-MM-YYYY, etc.)
      RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
      // Month names
      RegExp(
        r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\b',
        caseSensitive: false,
      ),
    ];

    var sanitized = text;
    for (final pattern in patterns) {
      if (pattern.hasMatch(sanitized)) {
        replacements.add('temporal');
        sanitized = sanitized.replaceAll(pattern, 'TIMEFRAME');
      }
    }
    return sanitized;
  }

  /// Layer 3: Sanitize app names
  String _sanitizeAppNames(String text, List<String> replacements) {
    final pattern = RegExp(
      r'\b(Google Fit|Samsung Health|Fitbit|Strava|Apple Health|Apple Watch|Health Connect|MyFitnessPal|Garmin|Nike Run Club)\b',
      caseSensitive: false,
    );

    if (pattern.hasMatch(text)) {
      replacements.add('apps');
      return text.replaceAll(pattern, 'FITNESS_APP');
    }
    return text;
  }

  /// Layer 4: Sanitize device names
  String _sanitizeDeviceNames(String text, List<String> replacements) {
    final patterns = [
      // iPhone models
      RegExp(
        r'\b(iPhone)\s*\d*\s*(Pro|Plus|Max|Mini)?',
        caseSensitive: false,
      ),
      // Android devices
      RegExp(
        r'\b(Samsung|Galaxy|Pixel|OnePlus|Xiaomi)\s*\w*\s*\d*\s*(Pro|Plus|Ultra)?',
        caseSensitive: false,
      ),
    ];

    var sanitized = text;
    for (final pattern in patterns) {
      if (pattern.hasMatch(sanitized)) {
        replacements.add('devices');
        sanitized = sanitized.replaceAll(pattern, 'DEVICE');
      }
    }
    return sanitized;
  }

  /// Layer 5: Sanitize location data
  String _sanitizeLocations(String text, List<String> replacements) {
    // Match common location patterns (e.g., "in New York", "at Central Park")
    final pattern = RegExp(
      r'\b(in|at|near|from)\s+[A-Z][a-z]+(\s+[A-Z][a-z]+)*\b',
    );

    if (pattern.hasMatch(text)) {
      replacements.add('locations');
      return text.replaceAll(pattern, 'at LOCATION');
    }
    return text;
  }

  /// Pre-validate for critical PHI before sanitization (strict mode only)
  void _preValidateCriticalPHI(String text) {
    // Check for email addresses
    if (RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b').hasMatch(text)) {
      throw PHIDetectedException(
        'Email address detected in input',
        text,
      );
    }

    // Check for phone numbers
    if (RegExp(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b').hasMatch(text)) {
      throw PHIDetectedException(
        'Phone number detected in input',
        text,
      );
    }

    // Check for SSN patterns
    if (RegExp(r'\b\d{3}-\d{2}-\d{4}\b').hasMatch(text)) {
      throw PHIDetectedException(
        'SSN pattern detected in input',
        text,
      );
    }
  }

  /// Detect remaining PHI after sanitization
  bool _detectRemainingPHI(String text) {
    // Check for numbers longer than 3 digits (not already replaced)
    if (RegExp(r'\b\d{4,}\b').hasMatch(text)) {
      return true;
    }

    // Check for specific date patterns
    if (RegExp(r'\b\d{1,2}/\d{1,2}/\d{2,4}\b').hasMatch(text)) {
      return true;
    }

    // Check for email addresses
    if (RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b').hasMatch(text)) {
      return true;
    }

    // Check for phone numbers
    if (RegExp(r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b').hasMatch(text)) {
      return true;
    }

    return false;
  }
}
