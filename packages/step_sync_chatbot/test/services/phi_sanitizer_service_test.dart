/// Tests for Production PHI Sanitizer Service
///
/// Validates:
/// - All PHI types are sanitized
/// - No false positives (safe text unchanged)
/// - Strict mode detects remaining PHI
/// - SanitizationResult metadata is correct

import 'package:test/test.dart';
import 'package:logger/logger.dart';
import '../../lib/src/services/phi_sanitizer_service.dart';

void main() {
  group('PHISanitizerService - Basic Sanitization', () {
    late PHISanitizerService sanitizer;

    setUp(() {
      sanitizer = PHISanitizerService(
        logger: Logger(level: Level.off), // Disable logs in tests
        strictMode: false, // Disable strict mode for basic tests
      );
    });

    test('Sanitizes step counts', () {
      final result = sanitizer.sanitize('I walked 10,000 steps yesterday');

      expect(result.sanitizedText, contains('METRIC_VALUE'));
      expect(result.sanitizedText, contains('TIMEFRAME'));
      expect(result.sanitizedText, isNot(contains('10,000')));
      expect(result.sanitizedText, isNot(contains('yesterday')));
      expect(result.wasSanitized, isTrue);
      expect(result.replacementCount, greaterThan(0));
    });

    test('Sanitizes app names', () {
      final result = sanitizer.sanitize('My Google Fit shows 8,247 steps');

      expect(result.sanitizedText, contains('FITNESS_APP'));
      expect(result.sanitizedText, isNot(contains('Google Fit')));
      expect(result.wasSanitized, isTrue);
    });

    test('Sanitizes device names', () {
      final result = sanitizer.sanitize('My iPhone 15 Pro tracked 7,500 steps');

      expect(result.sanitizedText, contains('DEVICE'));
      expect(result.sanitizedText, isNot(contains('iPhone')));
      expect(result.wasSanitized, isTrue);
    });

    test('Sanitizes complex message with multiple PHI types', () {
      final input = 'On Tuesday I had 12,000 steps according to Samsung Health on my iPhone 15';
      final result = sanitizer.sanitize(input);

      expect(result.sanitizedText, contains('TIMEFRAME'));
      expect(result.sanitizedText, contains('METRIC_VALUE'));
      expect(result.sanitizedText, contains('FITNESS_APP'));
      expect(result.sanitizedText, contains('DEVICE'));

      expect(result.sanitizedText, isNot(contains('Tuesday')));
      expect(result.sanitizedText, isNot(contains('12,000')));
      expect(result.sanitizedText, isNot(contains('Samsung Health')));
      expect(result.sanitizedText, isNot(contains('iPhone')));
    });

    test('Handles messages without PHI', () {
      final input = 'How do I enable permissions?';
      final result = sanitizer.sanitize(input);

      expect(result.sanitizedText, equals(input));
      expect(result.wasSanitized, isFalse);
      expect(result.replacementCount, equals(0));
    });
  });

  group('PHISanitizerService - Date Formats', () {
    late PHISanitizerService sanitizer;

    setUp(() {
      sanitizer = PHISanitizerService(
        logger: Logger(level: Level.off),
        strictMode: false,
      );
    });

    test('Sanitizes days of week', () {
      final days = ['Monday', 'tuesday', 'WEDNESDAY', 'Friday'];

      for (final day in days) {
        final result = sanitizer.sanitize('I walked on $day');
        expect(result.sanitizedText, contains('TIMEFRAME'));
        expect(result.sanitizedText, isNot(contains(RegExp(day, caseSensitive: false))));
      }
    });

    test('Sanitizes relative dates', () {
      final dates = ['yesterday', 'today', 'tomorrow', 'last week', 'this Monday'];

      for (final date in dates) {
        final result = sanitizer.sanitize('My steps synced $date');
        expect(result.sanitizedText, contains('TIMEFRAME'));
      }
    });

    test('Sanitizes month names', () {
      final months = ['January', 'february', 'MARCH', 'December'];

      for (final month in months) {
        final result = sanitizer.sanitize('In $month I walked a lot');
        expect(result.sanitizedText, contains('TIMEFRAME'));
      }
    });

    test('Sanitizes date formats', () {
      final dates = ['12/31/2023', '01-15-2024', '5/6/23'];

      for (final date in dates) {
        final result = sanitizer.sanitize('On $date I had many steps');
        expect(result.sanitizedText, contains('TIMEFRAME'));
        expect(result.sanitizedText, isNot(contains(date)));
      }
    });
  });

  group('PHISanitizerService - App Names', () {
    late PHISanitizerService sanitizer;

    setUp(() {
      sanitizer = PHISanitizerService(
        logger: Logger(level: Level.off),
        strictMode: false,
      );
    });

    test('Sanitizes all fitness apps', () {
      final apps = [
        'Google Fit',
        'Samsung Health',
        'Fitbit',
        'Strava',
        'Apple Health',
        'Apple Watch',
        'Health Connect',
        'MyFitnessPal',
        'Garmin',
      ];

      for (final app in apps) {
        final result = sanitizer.sanitize('I use $app for tracking');
        expect(result.sanitizedText, contains('FITNESS_APP'));
        expect(result.sanitizedText, isNot(contains(app)));
      }
    });

    test('Sanitizes case-insensitive app names', () {
      final result1 = sanitizer.sanitize('I use GOOGLE FIT daily');
      final result2 = sanitizer.sanitize('I use google fit daily');

      expect(result1.sanitizedText, contains('FITNESS_APP'));
      expect(result2.sanitizedText, contains('FITNESS_APP'));
    });
  });

  group('PHISanitizerService - Device Names', () {
    late PHISanitizerService sanitizer;

    setUp(() {
      sanitizer = PHISanitizerService(
        logger: Logger(level: Level.off),
        strictMode: false,
      );
    });

    test('Sanitizes iPhone models', () {
      final devices = [
        'iPhone 15',
        'iPhone 15 Pro',
        'iPhone 15 Pro Max',
        'iPhone 14',
      ];

      for (final device in devices) {
        final result = sanitizer.sanitize('I have a $device');
        expect(result.sanitizedText, contains('DEVICE'));
        expect(result.sanitizedText, isNot(contains('iPhone')));
      }
    });

    test('Sanitizes Android devices', () {
      final devices = [
        'Samsung Galaxy S24',
        'Pixel 8 Pro',
        'OnePlus 12',
        'Xiaomi 13',
      ];

      for (final device in devices) {
        final result = sanitizer.sanitize('I have a $device');
        expect(result.sanitizedText, contains('DEVICE'));
      }
    });
  });

  group('PHISanitizerService - Location Data', () {
    late PHISanitizerService sanitizer;

    setUp(() {
      sanitizer = PHISanitizerService(
        logger: Logger(level: Level.off),
        strictMode: false,
      );
    });

    test('Sanitizes location names', () {
      final locations = [
        'in New York',
        'at Central Park',
        'near San Francisco',
        'from Los Angeles',
      ];

      for (final location in locations) {
        final result = sanitizer.sanitize('I walked $location');
        expect(result.sanitizedText, contains('LOCATION'));
      }
    });
  });

  group('PHISanitizerService - Strict Mode', () {
    late PHISanitizerService sanitizer;

    setUp(() {
      sanitizer = PHISanitizerService(
        logger: Logger(level: Level.off),
        strictMode: true, // Enable strict mode
      );
    });

    test('Throws exception if email detected', () {
      expect(
        () => sanitizer.sanitize('Contact me at user@example.com'),
        throwsA(isA<PHIDetectedException>()),
      );
    });

    test('Throws exception if phone number detected', () {
      expect(
        () => sanitizer.sanitize('Call me at 555-123-4567'),
        throwsA(isA<PHIDetectedException>()),
      );
    });

    test('Allows safe text in strict mode', () {
      final result = sanitizer.sanitize('How do I enable permissions?');
      expect(result.sanitizedText, equals('How do I enable permissions?'));
    });
  });

  group('PHISanitizerService - Edge Cases', () {
    late PHISanitizerService sanitizer;

    setUp(() {
      sanitizer = PHISanitizerService(
        logger: Logger(level: Level.off),
        strictMode: false,
      );
    });

    test('Handles empty string', () {
      final result = sanitizer.sanitize('');
      expect(result.sanitizedText, equals(''));
      expect(result.wasSanitized, isFalse);
    });

    test('Handles very long messages', () {
      final longMessage = 'I walked 10,000 steps ' * 50;
      final result = sanitizer.sanitize(longMessage);

      expect(result.sanitizedText, isNot(contains('10,000')));
      expect(result.sanitizedText, contains('METRIC_VALUE'));
    });

    test('Handles mixed case input', () {
      final result = sanitizer.sanitize('I use GOOGLE FIT and apple health');

      expect(result.sanitizedText, contains('FITNESS_APP'));
      expect(result.sanitizedText, isNot(contains(RegExp('google', caseSensitive: false))));
      expect(result.sanitizedText, isNot(contains(RegExp('apple', caseSensitive: false))));
    });

    test('Handles punctuation around PHI', () {
      final result = sanitizer.sanitize('I walked (10,000 steps) yesterday!');

      expect(result.sanitizedText, contains('METRIC_VALUE'));
      expect(result.sanitizedText, contains('TIMEFRAME'));
      expect(result.sanitizedText, isNot(contains('10,000')));
    });

    test('Handles decimal numbers', () {
      final result = sanitizer.sanitize('I lost 5.5 pounds');

      expect(result.sanitizedText, contains('METRIC_VALUE'));
      expect(result.sanitizedText, isNot(contains('5.5')));
    });
  });

  group('PHISanitizerService - SanitizationResult', () {
    late PHISanitizerService sanitizer;

    setUp(() {
      sanitizer = PHISanitizerService(
        logger: Logger(level: Level.off),
        strictMode: false,
      );
    });

    test('Returns correct metadata for sanitized text', () {
      final input = 'I walked 10,000 steps yesterday in Google Fit';
      final result = sanitizer.sanitize(input);

      expect(result.originalText, equals(input));
      expect(result.sanitizedText, isNot(equals(input)));
      expect(result.wasSanitized, isTrue);
      expect(result.hadPHI, isTrue);
      expect(result.replacementCount, greaterThan(0));
      expect(result.replacements, isNotEmpty);
    });

    test('Returns correct metadata for non-sanitized text', () {
      final input = 'How do I fix permissions?';
      final result = sanitizer.sanitize(input);

      expect(result.originalText, equals(input));
      expect(result.sanitizedText, equals(input));
      expect(result.wasSanitized, isFalse);
      expect(result.hadPHI, isFalse);
      expect(result.replacementCount, equals(0));
      expect(result.replacements, isEmpty);
    });
  });
}
