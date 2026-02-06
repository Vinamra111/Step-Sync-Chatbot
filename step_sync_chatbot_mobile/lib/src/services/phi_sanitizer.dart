/// PHI Sanitizer Service - HIPAA Compliance
///
/// Detects and sanitizes Protected Health Information (PHI) before sending to LLM.
/// Prevents sensitive data from being transmitted to external APIs.

class PHISanitizer {
  /// Sanitize user input before sending to LLM
  static String sanitize(String input) {
    String sanitized = input;

    // Email addresses (e.g., john@example.com)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      '[EMAIL_REDACTED]',
    );

    // Phone numbers (various formats)
    // Matches: (123) 456-7890, 123-456-7890, 1234567890, +1-123-456-7890
    sanitized = sanitized.replaceAll(
      RegExp(r'[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}'),
      '[PHONE_REDACTED]',
    );

    // Dates (various formats: 12/31/2024, 2024-12-31, Dec 31 2024)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
      '[DATE_REDACTED]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b'),
      '[DATE_REDACTED]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \d{1,2},? \d{4}\b', caseSensitive: false),
      '[DATE_REDACTED]',
    );

    // Social Security Numbers (123-45-6789)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{3}-\d{2}-\d{4}\b'),
      '[SSN_REDACTED]',
    );

    // Medical Record Numbers (MRN: followed by digits)
    sanitized = sanitized.replaceAll(
      RegExp(r'\bMRN:?\s*\d+\b', caseSensitive: false),
      '[MRN_REDACTED]',
    );

    // Credit Card Numbers (16 digits with optional spaces/dashes)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
      '[CARD_REDACTED]',
    );

    // Device identifiers (IMEI, Serial numbers - 15+ consecutive digits)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{15,}\b'),
      '[DEVICE_ID_REDACTED]',
    );

    // Common name patterns with titles (Dr. John Smith, Mr. Smith)
    sanitized = sanitized.replaceAll(
      RegExp(r'\b(Dr|Mr|Mrs|Ms|Miss)\.?\s+[A-Z][a-z]+(\s+[A-Z][a-z]+)*\b'),
      '[NAME_REDACTED]',
    );

    // Full names in "My name is X" pattern
    sanitized = sanitized.replaceAllMapped(
      RegExp(r"\b(my name is|I am|I'm)\s+[A-Z][a-z]+(\s+[A-Z][a-z]+)*\b", caseSensitive: false),
      (match) => match.group(1)! + ' [NAME_REDACTED]',
    );

    return sanitized;
  }

  /// Check if input contains potential PHI
  static bool containsPHI(String input) {
    // Check for any PHI patterns
    return input != sanitize(input);
  }

  /// Get list of PHI types detected (for logging, not the actual values)
  static List<String> detectPHITypes(String input) {
    final List<String> types = [];

    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').hasMatch(input)) {
      types.add('email');
    }
    if (RegExp(r'[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}').hasMatch(input)) {
      types.add('phone');
    }
    if (RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b').hasMatch(input) ||
        RegExp(r'\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b').hasMatch(input)) {
      types.add('date');
    }
    if (RegExp(r'\b\d{3}-\d{2}-\d{4}\b').hasMatch(input)) {
      types.add('ssn');
    }
    if (RegExp(r'\bMRN:?\s*\d+\b', caseSensitive: false).hasMatch(input)) {
      types.add('mrn');
    }
    if (RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b').hasMatch(input)) {
      types.add('card');
    }
    if (RegExp(r'\b(Dr|Mr|Mrs|Ms|Miss)\.?\s+[A-Z][a-z]+').hasMatch(input) ||
        RegExp(r"my name is\s+[A-Z][a-z]+", caseSensitive: false).hasMatch(input)) {
      types.add('name');
    }

    return types;
  }
}
