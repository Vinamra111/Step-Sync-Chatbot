import 'package:step_sync_chatbot/src/privacy/sanitization_result.dart';

/// Service for detecting and removing Personal Health Information (PHI)
/// and Personally Identifiable Information (PII) from text.
///
/// This ensures that no sensitive data is sent to external AI services.
class PIIDetector {
  /// Detect and sanitize PHI/PII from the given text.
  ///
  /// Returns a [SanitizationResult] with:
  /// - Sanitized text safe for sending to LLM
  /// - List of detected entities
  /// - Whether the text is safe to send
  SanitizationResult sanitize(String text) {
    final detectedEntities = <DetectedEntity>[];
    String sanitized = text;

    // IMPORTANT: Sanitize specific patterns BEFORE generic patterns
    // Otherwise generic patterns (like numbers) will destroy structured data (like dates)

    // 1. Detect and remove email addresses (contains numbers, must be first)
    sanitized = _sanitizeEmails(sanitized, detectedEntities);

    // 2. Detect and remove phone numbers (contains numbers, must be before number sanitization)
    sanitized = _sanitizePhoneNumbers(sanitized, detectedEntities);

    // 3. Detect and remove dates (contains numbers, must be before number sanitization)
    sanitized = _sanitizeDates(sanitized, detectedEntities);

    // 4. Detect and remove device names (contains model numbers, must be before generic numbers)
    sanitized = _sanitizeDeviceNames(sanitized, detectedEntities);

    // 5. Detect and remove numbers (generic pattern, must come AFTER structured patterns)
    sanitized = _sanitizeNumbers(sanitized, detectedEntities);

    // 6. Detect and remove app names (data source identifiers)
    sanitized = _sanitizeAppNames(sanitized, detectedEntities);

    // 7. Detect and remove names (using common patterns)
    sanitized = _sanitizeNames(sanitized, detectedEntities);

    // Determine if safe to send
    final isSafe = _isSafeToSend(detectedEntities);

    return SanitizationResult(
      originalText: text,
      sanitizedText: sanitized.trim(),
      detectedEntities: detectedEntities,
      isSafe: isSafe,
    );
  }

  /// Sanitize numbers (step counts, ages, etc.)
  String _sanitizeNumbers(String text, List<DetectedEntity> entities) {
    // Match numbers with optional commas: 10,000 or 10000
    final numberPattern = RegExp(r'\b\d{1,3}(?:,?\d{3})*\b');

    return text.replaceAllMapped(numberPattern, (match) {
      final number = match.group(0)!;

      // Keep small numbers (likely not sensitive: 1, 2, 3, etc.)
      final numericValue = int.tryParse(number.replaceAll(',', '')) ?? 0;
      if (numericValue < 10) {
        return number;
      }

      entities.add(DetectedEntity(
        type: EntityType.number,
        originalValue: number,
        sanitizedValue: '[NUMBER]',
        startIndex: match.start,
        endIndex: match.end,
      ));

      return '[NUMBER]';
    });
  }

  /// Sanitize dates (yesterday, Tuesday, Jan 5, 2024-01-01, etc.)
  String _sanitizeDates(String text, List<DetectedEntity> entities) {
    String sanitized = text;

    // Relative dates
    final relativeDates = [
      'today', 'yesterday', 'tomorrow',
      'last week', 'this week', 'next week',
      'last month', 'this month', 'next month',
      'last year', 'this year',
    ];

    for (final dateWord in relativeDates) {
      final pattern = RegExp(r'\b' + dateWord + r'\b', caseSensitive: false);
      if (pattern.hasMatch(sanitized)) {
        entities.add(DetectedEntity(
          type: EntityType.date,
          originalValue: dateWord,
          sanitizedValue: 'recently',
          startIndex: 0,
          endIndex: 0,
        ));
        sanitized = sanitized.replaceAll(pattern, 'recently');
      }
    }

    // Day names
    final dayNames = [
      'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday',
    ];

    for (final day in dayNames) {
      final pattern = RegExp(r'\b' + day + r'\b', caseSensitive: false);
      if (pattern.hasMatch(sanitized)) {
        entities.add(DetectedEntity(
          type: EntityType.date,
          originalValue: day,
          sanitizedValue: 'a recent day',
          startIndex: 0,
          endIndex: 0,
        ));
        sanitized = sanitized.replaceAll(pattern, 'a recent day');
      }
    }

    // ISO dates (2024-01-15)
    final isoDatePattern = RegExp(r'\b\d{4}-\d{2}-\d{2}\b');
    sanitized = sanitized.replaceAllMapped(isoDatePattern, (match) {
      entities.add(DetectedEntity(
        type: EntityType.date,
        originalValue: match.group(0)!,
        sanitizedValue: '[DATE]',
        startIndex: match.start,
        endIndex: match.end,
      ));
      return '[DATE]';
    });

    // Month/Day formats (Jan 5, January 15, 01/15, 1/15/2024)
    final datePattern = RegExp(r'\b\d{1,2}/\d{1,2}(?:/\d{2,4})?\b');
    sanitized = sanitized.replaceAllMapped(datePattern, (match) {
      entities.add(DetectedEntity(
        type: EntityType.date,
        originalValue: match.group(0)!,
        sanitizedValue: '[DATE]',
        startIndex: match.start,
        endIndex: match.end,
      ));
      return '[DATE]';
    });

    return sanitized;
  }

  /// Sanitize fitness app names
  String _sanitizeAppNames(String text, List<DetectedEntity> entities) {
    final appNames = [
      'google fit', 'samsung health', 'fitbit', 'strava',
      'apple health', 'healthkit', 'health connect',
      'garmin', 'polar', 'whoop', 'oura', 'myfitnesspal',
      'nike run club', 'runkeeper', 'endomondo',
    ];

    String sanitized = text;

    for (final app in appNames) {
      final pattern = RegExp(r'\b' + app + r'\b', caseSensitive: false);
      if (pattern.hasMatch(sanitized)) {
        entities.add(DetectedEntity(
          type: EntityType.appName,
          originalValue: app,
          sanitizedValue: 'fitness app',
          startIndex: 0,
          endIndex: 0,
        ));
        sanitized = sanitized.replaceAll(pattern, 'fitness app');
      }
    }

    return sanitized;
  }

  /// Sanitize device names
  String _sanitizeDeviceNames(String text, List<DetectedEntity> entities) {
    // IMPORTANT: Process watches BEFORE phones because "Apple Watch" contains "Apple"
    String sanitized = text;

    // Watches - must come first
    // Matches: "Apple Watch Series 9", "Galaxy Watch 6", "Fitbit Sense"
    // Pattern: Brand + model info
    // Note: Fitbit alone (without model) is treated as app name, not device
    final watchPattern = RegExp(
      r'\b(?:(?:Apple Watch|Galaxy Watch|Garmin|Wear OS)(?:\s+(?:Series|Ultra|SE|Pro)\s+\d+|\s+(?:Series|Ultra|SE|Pro)|\s+\d+)?|Fitbit\s+(?:Sense|Charge|Versa|Venu)(?:\s+\d+)?)\b',
      caseSensitive: false,
    );

    sanitized = sanitized.replaceAllMapped(watchPattern, (match) {
      entities.add(DetectedEntity(
        type: EntityType.deviceName,
        originalValue: match.group(0)!,
        sanitizedValue: 'wearable device',
        startIndex: match.start,
        endIndex: match.end,
      ));
      return 'wearable device';
    });

    // Phone models - comes after watches
    // Matches: "iPhone 15 Pro", "Galaxy S24", "Pixel 8"
    // Pattern: Brand + optional (number + variant OR variant + number OR just number OR just variant)
    final phonePattern = RegExp(
      r'\b(?:iPhone|iPad|Galaxy|Pixel|OnePlus|Xiaomi|Huawei)(?:\s+\d+\s+(?:Pro|Max|Plus|Mini|Ultra|SE)|\s+(?:Pro|Max|Plus|Mini|Ultra|SE)\s+\d+|\s+\d+|\s+[A-Z]\d+)?\b',
      caseSensitive: false,
    );

    sanitized = sanitized.replaceAllMapped(phonePattern, (match) {
      entities.add(DetectedEntity(
        type: EntityType.deviceName,
        originalValue: match.group(0)!,
        sanitizedValue: 'phone',
        startIndex: match.start,
        endIndex: match.end,
      ));
      return 'phone';
    });

    return sanitized;
  }

  /// Sanitize potential names (simple heuristic-based)
  String _sanitizeNames(String text, List<DetectedEntity> entities) {
    // Pattern: "I'm [Name]" or "my name is [Name]"
    // Use case-insensitive for prefix, but name MUST be capitalized (not "and", "the", etc.)
    final namePattern = RegExp(
      r"\b(?:[Ii]'m|[Mm]y name is|[Ii] am)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b",
    );

    return text.replaceAllMapped(namePattern, (match) {
      final name = match.group(1)!;
      entities.add(DetectedEntity(
        type: EntityType.name,
        originalValue: name,
        sanitizedValue: '[USER]',
        startIndex: match.start,
        endIndex: match.end,
      ));

      // Keep the prefix, replace the name
      final prefix = match.group(0)!.substring(0, match.group(0)!.indexOf(name));
      return '$prefix[USER]';
    });
  }

  /// Sanitize email addresses
  String _sanitizeEmails(String text, List<DetectedEntity> entities) {
    final emailPattern = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );

    return text.replaceAllMapped(emailPattern, (match) {
      entities.add(DetectedEntity(
        type: EntityType.email,
        originalValue: match.group(0)!,
        sanitizedValue: '[EMAIL]',
        startIndex: match.start,
        endIndex: match.end,
      ));
      return '[EMAIL]';
    });
  }

  /// Sanitize phone numbers
  String _sanitizePhoneNumbers(String text, List<DetectedEntity> entities) {
    // Matches: (123) 456-7890, 123-456-7890, 123.456.7890, 1234567890
    // Note: No \b at start because it doesn't work with opening parenthesis
    final phonePattern = RegExp(
      r'(?:\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})\b',
    );

    return text.replaceAllMapped(phonePattern, (match) {
      entities.add(DetectedEntity(
        type: EntityType.phoneNumber,
        originalValue: match.group(0)!,
        sanitizedValue: '[PHONE]',
        startIndex: match.start,
        endIndex: match.end,
      ));
      return '[PHONE]';
    });
  }

  /// Determine if the text is safe to send to LLM after sanitization.
  ///
  /// Critical entities block sending, others just get sanitized.
  bool _isSafeToSend(List<DetectedEntity> entities) {
    // Check for critical entities that should block sending
    final criticalTypes = [
      EntityType.email,
      EntityType.phoneNumber,
      EntityType.name,
    ];

    final hasCritical = entities.any(
      (entity) => criticalTypes.contains(entity.type),
    );

    // If critical PII detected, don't send even after sanitization
    // (defense in depth - shouldn't send queries with user names, emails, phones)
    return !hasCritical;
  }
}
