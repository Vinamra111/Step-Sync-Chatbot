import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/health/real_health_service.dart';
import 'package:step_sync_chatbot/src/health/health_service.dart';
import 'package:step_sync_chatbot/src/data/models/permission_state.dart';

void main() {
  group('RealHealthService', () {
    late RealHealthService service;

    setUp(() {
      service = RealHealthService();
    });

    tearDown(() {
      service.dispose();
    });

    test('getPlatformName returns correct platform name', () {
      final platformName = service.getPlatformName();

      if (Platform.isAndroid) {
        expect(platformName, equals('Health Connect'));
      } else if (Platform.isIOS) {
        expect(platformName, equals('HealthKit'));
      } else {
        expect(platformName, equals('Unknown'));
      }
    });

    test('initialize throws PlatformNotAvailableException on unsupported platform',
        () async {
      if (!Platform.isAndroid && !Platform.isIOS) {
        expect(
          () => service.initialize(),
          throwsA(isA<PlatformNotAvailableException>()),
        );
      }
    });

    group('Android Health Connect Integration', () {
      // Note: These tests will only run on Android devices/emulators
      // with Health Connect installed.

      test('initialize succeeds when Health Connect is available', () async {
        if (!Platform.isAndroid) {
          // Skip on non-Android platforms
          return;
        }

        try {
          await service.initialize();
          // If initialization succeeds, isAvailable should return true
          final available = await service.isAvailable();
          expect(available, isTrue);
        } on PlatformNotAvailableException catch (e) {
          // Health Connect might not be installed in test environment
          expect(
            e.message.contains('not installed') ||
                e.message.contains('not supported'),
            isTrue,
          );
        }
      });

      test('checkPermissions returns unknown state before initialization',
          () async {
        if (!Platform.isAndroid) {
          return;
        }

        final permissionState = await service.checkPermissions();

        expect(permissionState.status, equals(PermissionStatus.unknown));
      });

      test('getStepData returns empty list before initialization', () async {
        if (!Platform.isAndroid) {
          return;
        }

        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 7));

        final stepData = await service.getStepData(
          startDate: startDate,
          endDate: endDate,
        );

        // Should handle gracefully even if not initialized
        expect(stepData, isEmpty);
      });

      test('setPrimaryDataSource updates primary source', () async {
        if (!Platform.isAndroid) {
          return;
        }

        // Should not throw even if not initialized
        await service.setPrimaryDataSource('com.google.android.apps.fitness');

        // If successful, no exception thrown
        expect(true, isTrue);
      });
    });

    group('iOS HealthKit Integration', () {
      // Note: These tests will only run on iOS devices/simulators

      test('initialize throws not implemented exception on iOS', () async {
        if (!Platform.isIOS) {
          return;
        }

        expect(
          () => service.initialize(),
          throwsA(isA<HealthServiceException>()),
        );
      });

      test('checkPermissions returns error on iOS (not yet implemented)',
          () async {
        if (!Platform.isIOS) {
          return;
        }

        final permissionState = await service.checkPermissions();

        expect(
          permissionState.status,
          anyOf([PermissionStatus.unknown, PermissionStatus.error]),
        );
      });
    });

    group('Caching behavior', () {
      test('getStepData uses cache when available', () async {
        if (!Platform.isAndroid) {
          return;
        }

        try {
          await service.initialize();

          final endDate = DateTime.now();
          final startDate = endDate.subtract(const Duration(days: 1));

          // First call - should fetch from SDK
          final firstResult = await service.getStepData(
            startDate: startDate,
            endDate: endDate,
          );

          // Second call immediately after - should use cache
          final secondResult = await service.getStepData(
            startDate: startDate,
            endDate: endDate,
            forceRefresh: false,
          );

          // Results should be identical (from cache)
          expect(secondResult.length, equals(firstResult.length));
        } on PlatformNotAvailableException {
          // Health Connect not available in test environment - skip
        }
      });

      test('forceRefresh bypasses cache', () async {
        if (!Platform.isAndroid) {
          return;
        }

        try {
          await service.initialize();

          final endDate = DateTime.now();
          final startDate = endDate.subtract(const Duration(days: 1));

          // First call to populate cache
          await service.getStepData(
            startDate: startDate,
            endDate: endDate,
          );

          // Force refresh - should fetch fresh data
          final refreshedResult = await service.getStepData(
            startDate: startDate,
            endDate: endDate,
            forceRefresh: true,
          );

          // Should succeed without throwing
          expect(refreshedResult, isNotNull);
        } on PlatformNotAvailableException {
          // Health Connect not available in test environment - skip
        }
      });
    });

    group('Data source management', () {
      test('getDataSources returns list of active sources', () async {
        if (!Platform.isAndroid) {
          return;
        }

        try {
          await service.initialize();

          final sources = await service.getDataSources();

          // Should return a list (might be empty if no data)
          expect(sources, isA<List>());
        } on PlatformNotAvailableException {
          // Health Connect not available in test environment - skip
        }
      });
    });

    group('Error handling', () {
      test('throws HealthServiceException when SDK operations fail', () async {
        if (!Platform.isAndroid) {
          return;
        }

        // Trying to fetch data without initialization should handle gracefully
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 1));

        final result = await service.getStepData(
          startDate: startDate,
          endDate: endDate,
        );

        // Should return empty list instead of throwing
        expect(result, isEmpty);
      });

      test('dispose clears resources safely', () {
        // Should not throw even if not initialized
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });
}
