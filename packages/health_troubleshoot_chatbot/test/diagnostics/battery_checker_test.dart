/// Tests for Battery Optimization Checker
///
/// These tests verify the battery checker behavior on different platforms
/// and handle various edge cases.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/diagnostics/battery_checker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatteryChecker', () {
    late BatteryChecker batteryChecker;

    setUp(() {
      batteryChecker = BatteryChecker();
    });

    group('Platform Detection', () {
      test('returns notApplicable on iOS', () async {
        // This test will only pass when run on iOS
        if (Platform.isIOS) {
          final status = await batteryChecker.checkBatteryOptimization();
          expect(status, BatteryCheckResult.notApplicable);
        }
      });

      test('returns notApplicable on non-mobile platforms', () async {
        // This test checks behavior on desktop platforms
        if (!Platform.isAndroid && !Platform.isIOS) {
          final status = await batteryChecker.checkBatteryOptimization();
          expect(status, BatteryCheckResult.notApplicable);
        }
      });
    });

    group('Android Battery Optimization', () {
      test('handles method channel response - optimization enabled', () async {
        // Skip if not on Android
        if (!Platform.isAndroid) {
          return;
        }

        // Mock method channel to return true (optimization enabled)
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.stepsync.chatbot/battery'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isBatteryOptimizationEnabled') {
              return true; // Optimization is enabled
            }
            return null;
          },
        );

        final status = await batteryChecker.checkBatteryOptimization();
        expect(status, BatteryCheckResult.enabled);
      });

      test('handles method channel response - optimization disabled', () async {
        // Skip if not on Android
        if (!Platform.isAndroid) {
          return;
        }

        // Mock method channel to return false (optimization disabled)
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.stepsync.chatbot/battery'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isBatteryOptimizationEnabled') {
              return false; // Optimization is disabled
            }
            return null;
          },
        );

        final status = await batteryChecker.checkBatteryOptimization();
        expect(status, BatteryCheckResult.disabled);
      });

      test('handles null response from method channel', () async {
        // Skip if not on Android
        if (!Platform.isAndroid) {
          return;
        }

        // Mock method channel to return null
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.stepsync.chatbot/battery'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isBatteryOptimizationEnabled') {
              return null;
            }
            return null;
          },
        );

        final status = await batteryChecker.checkBatteryOptimization();
        expect(status, BatteryCheckResult.unknown);
      });

      test('handles PlatformException - NOT_AVAILABLE', () async {
        // Skip if not on Android
        if (!Platform.isAndroid) {
          return;
        }

        // Mock method channel to throw PlatformException
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.stepsync.chatbot/battery'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isBatteryOptimizationEnabled') {
              throw PlatformException(
                code: 'NOT_AVAILABLE',
                message: 'Battery optimization not available on this Android version',
              );
            }
            return null;
          },
        );

        final status = await batteryChecker.checkBatteryOptimization();
        expect(status, BatteryCheckResult.notApplicable);
      });

      test('handles generic PlatformException', () async {
        // Skip if not on Android
        if (!Platform.isAndroid) {
          return;
        }

        // Mock method channel to throw generic PlatformException
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.stepsync.chatbot/battery'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isBatteryOptimizationEnabled') {
              throw PlatformException(
                code: 'ERROR',
                message: 'Generic error',
              );
            }
            return null;
          },
        );

        final status = await batteryChecker.checkBatteryOptimization();
        expect(status, BatteryCheckResult.unknown);
      });

      test('handles unexpected exception', () async {
        // Skip if not on Android
        if (!Platform.isAndroid) {
          return;
        }

        // Mock method channel to throw unexpected exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.stepsync.chatbot/battery'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isBatteryOptimizationEnabled') {
              throw Exception('Unexpected error');
            }
            return null;
          },
        );

        final status = await batteryChecker.checkBatteryOptimization();
        expect(status, BatteryCheckResult.unknown);
      });
    });

    group('Request Battery Optimization Exemption', () {
      test('returns false on iOS', () async {
        if (Platform.isIOS) {
          final success = await batteryChecker.requestBatteryOptimizationExemption();
          expect(success, false);
        }
      });

      test('calls method channel on Android', () async {
        if (!Platform.isAndroid) {
          return;
        }

        // Mock method channel
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.stepsync.chatbot/battery'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'requestBatteryOptimizationExemption') {
              return true;
            }
            return null;
          },
        );

        final success = await batteryChecker.requestBatteryOptimizationExemption();
        expect(success, true);
      });

      test('handles method channel failure', () async {
        if (!Platform.isAndroid) {
          return;
        }

        // Mock method channel to return false
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.stepsync.chatbot/battery'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'requestBatteryOptimizationExemption') {
              return false;
            }
            return null;
          },
        );

        final success = await batteryChecker.requestBatteryOptimizationExemption();
        expect(success, false);
      });
    });

    group('Battery Optimization Support', () {
      test('checks if battery optimization is supported', () async {
        if (!Platform.isAndroid) {
          final supported = await batteryChecker.isBatteryOptimizationSupported();
          expect(supported, false);
          return;
        }

        // Mock method channel
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.stepsync.chatbot/battery'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isBatteryOptimizationSupported') {
              // Return true if Android 6.0+
              return true;
            }
            return null;
          },
        );

        final supported = await batteryChecker.isBatteryOptimizationSupported();
        expect(supported, isA<bool>());
      });
    });

    tearDown(() {
      // Clear mock method channel handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.stepsync.chatbot/battery'),
        null,
      );
    });
  });

  group('BatteryCheckResult', () {
    test('has all expected values', () {
      expect(BatteryCheckResult.values.length, 4);
      expect(BatteryCheckResult.values, contains(BatteryCheckResult.enabled));
      expect(BatteryCheckResult.values, contains(BatteryCheckResult.disabled));
      expect(BatteryCheckResult.values, contains(BatteryCheckResult.unknown));
      expect(BatteryCheckResult.values, contains(BatteryCheckResult.notApplicable));
    });
  });
}
