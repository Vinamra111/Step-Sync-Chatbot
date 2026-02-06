import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/privacy/pii_detector.dart';
import 'package:step_sync_chatbot/src/privacy/sanitization_result.dart';

void main() {
  group('PIIDetector', () {
    late PIIDetector detector;

    setUp(() {
      detector = PIIDetector();
    });

    group('Number Sanitization', () {
      test('sanitizes step counts', () {
        // Arrange
        const input = 'I walked 10,000 steps yesterday';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, 'I walked [NUMBER] steps recently');
        expect(result.detectedEntities.length, 2); // number + date
        expect(
          result.detectedEntities.any((e) => e.type == EntityType.number),
          isTrue,
        );
      });

      test('keeps small numbers', () {
        // Arrange
        const input = 'I have 3 apps installed';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, contains('3'));
      });

      test('sanitizes large numbers without commas', () {
        // Arrange
        const input = 'I had 15000 steps';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, 'I had [NUMBER] steps');
      });
    });

    group('Date Sanitization', () {
      test('sanitizes relative dates', () {
        // Arrange
        final testCases = [
          'I walked yesterday',
          'My steps today are wrong',
          'Last week it was working',
          'This month has been bad',
        ];

        // Act & Assert
        for (final input in testCases) {
          final result = detector.sanitize(input);
          expect(result.sanitizedText.toLowerCase(), contains('recently'));
          expect(
            result.detectedEntities.any((e) => e.type == EntityType.date),
            isTrue,
            reason: 'Failed for: $input',
          );
        }
      });

      test('sanitizes day names', () {
        // Arrange
        const input = 'On Monday I had steps, but Tuesday was broken';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, contains('a recent day'));
        expect(
          result.detectedEntities.where((e) => e.type == EntityType.date).length,
          2,
        );
      });

      test('sanitizes ISO dates', () {
        // Arrange
        const input = 'Steps on 2024-01-15 were missing';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, 'Steps on [DATE] were missing');
      });

      test('sanitizes slash dates', () {
        // Arrange
        final testCases = [
          '01/15/2024',
          '1/15',
          '12/31',
        ];

        // Act & Assert
        for (final input in testCases) {
          final result = detector.sanitize('Date: $input');
          expect(result.sanitizedText, 'Date: [DATE]');
        }
      });
    });

    group('App Name Sanitization', () {
      test('sanitizes fitness app names', () {
        // Arrange
        final testCases = [
          ('Google Fit shows 10000 steps', 'fitness app'),
          ('Samsung Health is better', 'fitness app'),
          ('My Fitbit says different', 'fitness app'),
          ('Apple Health data is wrong', 'fitness app'),
        ];

        // Act & Assert
        for (final (input, expected) in testCases) {
          final result = detector.sanitize(input);
          expect(result.sanitizedText.toLowerCase(), contains(expected));
          expect(
            result.detectedEntities.any((e) => e.type == EntityType.appName),
            isTrue,
            reason: 'Failed for: $input',
          );
        }
      });

      test('sanitizes case-insensitive app names', () {
        // Arrange
        const input = 'GOOGLE FIT and samsung health conflict';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, contains('fitness app'));
      });
    });

    group('Device Name Sanitization', () {
      test('sanitizes phone models', () {
        // Arrange
        final testCases = [
          'iPhone 15 Pro',
          'Galaxy S24',
          'Pixel 8',
        ];

        // Act & Assert
        for (final input in testCases) {
          final result = detector.sanitize('My $input is not syncing');
          expect(result.sanitizedText, 'My phone is not syncing');
          expect(
            result.detectedEntities.any((e) => e.type == EntityType.deviceName),
            isTrue,
          );
        }
      });

      test('sanitizes watch names', () {
        // Arrange
        final testCases = [
          'Apple Watch Series 9',
          'Galaxy Watch 6',
          'Fitbit Sense',
        ];

        // Act & Assert
        for (final input in testCases) {
          final result = detector.sanitize('My $input shows different data');
          expect(result.sanitizedText, 'My wearable device shows different data');
        }
      });
    });

    group('Name Sanitization', () {
      test('sanitizes names after "I\'m"', () {
        // Arrange
        const input = 'I\'m John Smith and I need help';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, 'I\'m [USER] and I need help');
        expect(
          result.detectedEntities.any((e) => e.type == EntityType.name),
          isTrue,
        );
      });

      test('sanitizes names after "my name is"', () {
        // Arrange
        const input = 'My name is Jane Doe';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, 'My name is [USER]');
      });
    });

    group('Email Sanitization', () {
      test('sanitizes email addresses', () {
        // Arrange
        final testCases = [
          'john@example.com',
          'test.user+tag@domain.co.uk',
          'admin@company.org',
        ];

        // Act & Assert
        for (final email in testCases) {
          final result = detector.sanitize('Contact me at $email');
          expect(result.sanitizedText, 'Contact me at [EMAIL]');
          expect(
            result.detectedEntities.any((e) => e.type == EntityType.email),
            isTrue,
          );
        }
      });
    });

    group('Phone Number Sanitization', () {
      test('sanitizes various phone formats', () {
        // Arrange
        final testCases = [
          '(123) 456-7890',
          '123-456-7890',
          '123.456.7890',
          '1234567890',
        ];

        // Act & Assert
        for (final phone in testCases) {
          final result = detector.sanitize('Call me at $phone');
          expect(result.sanitizedText, 'Call me at [PHONE]');
          expect(
            result.detectedEntities.any((e) => e.type == EntityType.phoneNumber),
            isTrue,
          );
        }
      });
    });

    group('Safety Checks', () {
      test('marks text with critical PII as unsafe', () {
        // Arrange
        final criticalCases = [
          'john@example.com',
          '123-456-7890',
          'I\'m John Doe',
        ];

        // Act & Assert
        for (final input in criticalCases) {
          final result = detector.sanitize(input);
          expect(result.isSafe, isFalse, reason: 'Should block: $input');
        }
      });

      test('marks text without critical PII as safe', () {
        // Arrange
        final safeCases = [
          'I walked 10000 steps yesterday',
          'Google Fit shows different numbers',
          'My iPhone is not syncing',
        ];

        // Act & Assert
        for (final input in safeCases) {
          final result = detector.sanitize(input);
          expect(result.isSafe, isTrue, reason: 'Should allow: $input');
        }
      });
    });

    group('Complex Scenarios', () {
      test('sanitizes multiple entity types', () {
        // Arrange
        const input = 'I\'m John and I walked 10000 steps yesterday on my iPhone 15';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.detectedEntities.length, greaterThan(2));
        expect(result.detectedEntities.any((e) => e.type == EntityType.name), isTrue);
        expect(result.detectedEntities.any((e) => e.type == EntityType.number), isTrue);
        expect(result.detectedEntities.any((e) => e.type == EntityType.date), isTrue);
        expect(result.detectedEntities.any((e) => e.type == EntityType.deviceName), isTrue);
      });

      test('preserves non-sensitive content', () {
        // Arrange
        const input = 'Steps are not syncing properly';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, input);
        expect(result.detectedEntities, isEmpty);
        expect(result.isSafe, isTrue);
      });

      test('handles empty input', () {
        // Arrange
        const input = '';

        // Act
        final result = detector.sanitize(input);

        // Assert
        expect(result.sanitizedText, isEmpty);
        expect(result.detectedEntities, isEmpty);
        expect(result.isSafe, isTrue);
      });
    });

    group('EntityType Extension', () {
      test('isCritical returns correct values', () {
        expect(EntityType.email.isCritical, isTrue);
        expect(EntityType.phoneNumber.isCritical, isTrue);
        expect(EntityType.name.isCritical, isTrue);
        expect(EntityType.number.isCritical, isFalse);
        expect(EntityType.date.isCritical, isFalse);
        expect(EntityType.appName.isCritical, isFalse);
      });

      test('emoji returns non-empty string', () {
        for (final type in EntityType.values) {
          expect(type.emoji, isNotEmpty);
        }
      });

      test('label returns non-empty string', () {
        for (final type in EntityType.values) {
          expect(type.label, isNotEmpty);
        }
      });
    });
  });
}
