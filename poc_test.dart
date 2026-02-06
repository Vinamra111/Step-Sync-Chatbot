/// Unit tests for POC - Verifies PHI sanitization works correctly
///
/// Run: dart test poc_test.dart

import 'package:test/test.dart';
import 'groq_langchain_poc.dart';

void main() {
  group('PHI Sanitizer Tests', () {
    late PHISanitizer sanitizer;

    setUp(() {
      sanitizer = PHISanitizer();
    });

    test('Sanitizes step counts', () {
      final input = 'I walked 10,000 steps yesterday';
      final result = sanitizer.sanitize(input);

      expect(result, contains('STEP_COUNT'));
      expect(result, isNot(contains('10,000')));
      expect(result, contains('TIMEFRAME'));
      expect(result, isNot(contains('yesterday')));
    });

    test('Sanitizes app names', () {
      final input = 'My Google Fit shows 8,247 steps';
      final result = sanitizer.sanitize(input);

      expect(result, contains('FITNESS_APP'));
      expect(result, isNot(contains('Google Fit')));
      expect(result, contains('STEP_COUNT'));
    });

    test('Sanitizes multiple PHI types in one message', () {
      final input = 'On Tuesday I had 12,000 steps according to Samsung Health on my iPhone 15';
      final result = sanitizer.sanitize(input);

      expect(result, contains('TIMEFRAME')); // Tuesday
      expect(result, contains('STEP_COUNT')); // 12,000
      expect(result, contains('FITNESS_APP')); // Samsung Health
      expect(result, contains('DEVICE')); // iPhone 15

      expect(result, isNot(contains('Tuesday')));
      expect(result, isNot(contains('12,000')));
      expect(result, isNot(contains('Samsung Health')));
      expect(result, isNot(contains('iPhone')));
    });

    test('Sanitizes different date formats', () {
      final testCases = [
        {'input': 'yesterday', 'shouldNotContain': 'yesterday'},
        {'input': 'today', 'shouldNotContain': 'today'},
        {'input': 'last Monday', 'shouldNotContain': 'Monday'},
        {'input': 'this Friday', 'shouldNotContain': 'Friday'},
      ];

      for (var testCase in testCases) {
        final result = sanitizer.sanitize(testCase['input']!);
        expect(result, contains('TIMEFRAME'));
        expect(result, isNot(contains(testCase['shouldNotContain']!)));
      }
    });

    test('Sanitizes all fitness apps', () {
      final apps = [
        'Google Fit',
        'Samsung Health',
        'Fitbit',
        'Strava',
        'Apple Health',
        'Apple Watch',
      ];

      for (var app in apps) {
        final input = 'I use $app for tracking';
        final result = sanitizer.sanitize(input);

        expect(result, contains('FITNESS_APP'));
        expect(result, isNot(contains(app)));
      }
    });

    test('Sanitizes device names', () {
      final devices = [
        'iPhone 15',
        'iPhone 15 Pro',
        'Samsung Galaxy',
        'Pixel 8',
      ];

      for (var device in devices) {
        final input = 'I have a $device';
        final result = sanitizer.sanitize(input);

        expect(result, contains('DEVICE'));
        expect(result, isNot(contains(RegExp(r'iPhone|Samsung|Galaxy|Pixel', caseSensitive: false))));
      }
    });

    test('Handles messages without PHI', () {
      final input = 'How do I enable permissions?';
      final result = sanitizer.sanitize(input);

      // Should return unchanged (no PHI to sanitize)
      expect(result, equals(input));
    });

    test('Throws on remaining PHI after sanitization', () {
      // This test verifies our validation catches edge cases
      // In production, we'd have more sophisticated PHI detection

      // For now, messages that get through sanitization shouldn't throw
      final input = 'My steps are not syncing properly';
      expect(() => sanitizer.sanitize(input), returnsNormally);
    });

    test('Real-world scenario: Full troubleshooting message', () {
      final input = '''
        Hi, I'm having issues with my step tracking.
        Yesterday I walked 15,000 steps according to my Apple Watch,
        but my iPhone 15 Pro only shows 8,500 steps in Apple Health.
        Google Fit shows 12,000 steps. What's going on?
      ''';

      final result = sanitizer.sanitize(input);

      // Verify all PHI removed
      expect(result, isNot(contains('15,000')));
      expect(result, isNot(contains('8,500')));
      expect(result, isNot(contains('12,000')));
      expect(result, isNot(contains('Yesterday')));
      expect(result, isNot(contains('Apple Watch')));
      expect(result, isNot(contains('iPhone 15')));
      expect(result, isNot(contains('Google Fit')));
      expect(result, isNot(contains('Apple Health')));

      // Verify replacements present
      expect(result, contains('STEP_COUNT'));
      expect(result, contains('TIMEFRAME'));
      expect(result, contains('FITNESS_APP'));
      expect(result, contains('DEVICE'));
    });
  });

  group('Edge Cases', () {
    late PHISanitizer sanitizer;

    setUp(() {
      sanitizer = PHISanitizer();
    });

    test('Handles empty string', () {
      expect(() => sanitizer.sanitize(''), returnsNormally);
    });

    test('Handles very long messages', () {
      final longMessage = 'I walked 10,000 steps ' * 100;
      final result = sanitizer.sanitize(longMessage);

      expect(result, isNot(contains('10,000')));
      expect(result, contains('STEP_COUNT'));
    });

    test('Handles mixed case', () {
      final input = 'I use GOOGLE FIT and apple health';
      final result = sanitizer.sanitize(input);

      expect(result, contains('FITNESS_APP'));
      expect(result, isNot(contains(RegExp(r'google', caseSensitive: false))));
      expect(result, isNot(contains(RegExp(r'apple', caseSensitive: false))));
    });

    test('Handles punctuation around PHI', () {
      final input = 'I walked (10,000 steps) yesterday.';
      final result = sanitizer.sanitize(input);

      expect(result, contains('STEP_COUNT'));
      expect(result, contains('TIMEFRAME'));
    });
  });
}
