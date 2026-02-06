import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/health/mock_health_service.dart';
import 'package:step_sync_chatbot/src/data/models/permission_state.dart';

void main() {
  group('MockHealthService', () {
    late MockHealthService healthService;

    setUp(() {
      healthService = MockHealthService();
    });

    tearDown(() {
      healthService.dispose();
    });

    test('initializes successfully', () async {
      await healthService.initialize();

      final sources = await healthService.getDataSources();
      expect(sources, isNotEmpty);
    });

    test('initial permission state is unknown', () async {
      final state = await healthService.checkPermissions();
      expect(state.status, PermissionStatus.unknown);
      expect(state.stepsGranted, false);
      expect(state.activityGranted, false);
    });

    test('requesting permissions grants them', () async {
      await healthService.initialize();

      final state = await healthService.requestPermissions();

      expect(state.status, PermissionStatus.granted);
      expect(state.stepsGranted, true);
      expect(state.activityGranted, true);
    });

    test('gets step data for date range', () async {
      await healthService.initialize();

      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 7);

      final stepData = await healthService.getStepData(
        startDate: startDate,
        endDate: endDate,
      );

      expect(stepData, hasLength(7));
      expect(stepData.first.date.day, 1);
      expect(stepData.last.date.day, 7);
      expect(stepData.every((data) => data.steps > 0), true);
    });

    test('gets data sources', () async {
      await healthService.initialize();

      final sources = await healthService.getDataSources();

      expect(sources, isNotEmpty);
      expect(sources.every((s) => s.name.isNotEmpty), true);
    });

    test('sets primary data source', () async {
      await healthService.initialize();

      final sources = await healthService.getDataSources();
      final firstSourceId = sources.first.id;

      await healthService.setPrimaryDataSource(firstSourceId);

      final updatedSources = await healthService.getDataSources();
      final primarySource = updatedSources.firstWhere((s) => s.isPrimary);

      expect(primarySource.id, firstSourceId);
    });

    test('reports platform is available', () async {
      final available = await healthService.isAvailable();
      expect(available, true);
    });

    test('returns platform name', () {
      final platformName = healthService.getPlatformName();
      // When running tests on desktop, platform is 'Unknown'
      expect(platformName, isIn(['Health Connect', 'HealthKit', 'Unknown']));
    });

    test('allows manually setting permission state for testing', () async {
      healthService.setPermissionState(PermissionState.denied());

      final state = await healthService.checkPermissions();
      expect(state.status, PermissionStatus.denied);
    });

    test('step data has source information', () async {
      await healthService.initialize();

      final stepData = await healthService.getStepData(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );

      expect(stepData.first.source, isNotNull);
      expect(stepData.first.source.name, isNotEmpty);
    });

    test('step data has sync timestamp', () async {
      await healthService.initialize();

      final stepData = await healthService.getStepData(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );

      expect(stepData.first.lastSyncedAt, isNotNull);
    });
  });
}
