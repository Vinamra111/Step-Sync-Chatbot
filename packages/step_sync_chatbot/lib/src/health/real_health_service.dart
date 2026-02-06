import 'dart:io';
import 'package:health_sync_flutter/health_sync_flutter.dart' as health_sdk;
import '../data/models/step_data.dart';
import '../data/models/permission_state.dart';
import 'health_service.dart';

/// Real implementation of HealthService that wraps the HealthSync SDK.
///
/// This service integrates with Health Connect on Android and HealthKit on iOS.
class RealHealthService implements HealthService {
  health_sdk.HealthConnectPlugin? _healthConnectPlugin;
  String? _primaryDataSourceId;
  final Map<DateTime, List<StepData>> _cache = {};
  static const _cacheValidityDuration = Duration(minutes: 5);
  DateTime? _lastCacheUpdate;

  @override
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _initializeAndroid();
    } else if (Platform.isIOS) {
      await _initializeIOS();
    } else {
      throw PlatformNotAvailableException(
        'Health data is only available on Android and iOS',
      );
    }
  }

  /// Initialize Android Health Connect
  Future<void> _initializeAndroid() async {
    _healthConnectPlugin = health_sdk.HealthConnectPlugin(
      config: const health_sdk.HealthConnectConfig(
        autoRequestPermissions: false, // We'll request manually
      ),
    );

    try {
      await _healthConnectPlugin!.initialize();

      // Check availability
      final availability = await _healthConnectPlugin!.checkAvailability();

      if (availability != health_sdk.HealthConnectAvailability.installed) {
        throw PlatformNotAvailableException(
          'Health Connect is ${availability == health_sdk.HealthConnectAvailability.notInstalled ? 'not installed' : 'not supported'}. '
          'Please install Health Connect from Google Play Store.',
        );
      }
    } catch (e) {
      if (e is PlatformNotAvailableException) rethrow;
      throw HealthServiceException('Failed to initialize Health Connect', e);
    }
  }

  /// Initialize iOS HealthKit
  Future<void> _initializeIOS() async {
    // TODO: Integrate iOS HealthKit when available
    // For now, throw to indicate not yet implemented
    throw HealthServiceException(
      'iOS HealthKit integration is not yet implemented in the chatbot. '
      'Please use Android with Health Connect for now.',
    );
  }

  @override
  Future<PermissionState> checkPermissions() async {
    try {
      if (Platform.isAndroid && _healthConnectPlugin != null) {
        final permissionsToCheck = [
          health_sdk.HealthConnectPermission.readSteps,
          health_sdk.HealthConnectPermission.readExercise,
        ];

        final statuses =
            await _healthConnectPlugin!.checkPermissions(permissionsToCheck);

        final stepsGranted = statuses
            .where((s) =>
                s.permission == health_sdk.HealthConnectPermission.readSteps)
            .any((s) => s.granted);

        final activityGranted = statuses
            .where((s) =>
                s.permission == health_sdk.HealthConnectPermission.readExercise)
            .any((s) => s.granted);

        final allGranted = stepsGranted && activityGranted;

        return PermissionState(
          stepsGranted: stepsGranted,
          activityGranted: activityGranted,
          status:
              allGranted ? PermissionStatus.granted : PermissionStatus.denied,
          lastCheckedAt: DateTime.now(),
        );
      } else if (Platform.isIOS) {
        // TODO: iOS HealthKit permission check
        throw HealthServiceException('iOS not yet implemented');
      }

      return PermissionState.unknown();
    } catch (e) {
      return PermissionState(
        stepsGranted: false,
        activityGranted: false,
        status: PermissionStatus.error,
        lastCheckedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<PermissionState> requestPermissions() async {
    try {
      if (Platform.isAndroid && _healthConnectPlugin != null) {
        final permissionsToRequest = [
          health_sdk.HealthConnectPermission.readSteps,
          health_sdk.HealthConnectPermission.readExercise,
        ];

        // Request permissions - this launches Health Connect UI
        await _healthConnectPlugin!.requestPermissions(permissionsToRequest);

        // CRITICAL: Health Connect uses async permission model
        // We need to poll for permission status as it processes asynchronously
        await Future.delayed(const Duration(seconds: 2));

        // Check actual permission status after request
        return await checkPermissions();
      } else if (Platform.isIOS) {
        // TODO: iOS HealthKit permission request
        throw HealthServiceException('iOS not yet implemented');
      }

      throw PlatformNotAvailableException('Platform not supported');
    } on health_sdk.HealthSyncError catch (e) {
      throw PermissionDeniedException('Permission request failed: $e');
    } catch (e) {
      throw HealthServiceException('Failed to request permissions', e);
    }
  }

  @override
  Future<List<StepData>> getStepData({
    required DateTime startDate,
    required DateTime endDate,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh && _isCacheValid()) {
      final cachedData = _getFromCache(startDate, endDate);
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
    }

    try {
      if (Platform.isAndroid && _healthConnectPlugin != null) {
        // Create query for step data
        final query = health_sdk.DataQuery(
          dataType: health_sdk.DataType.steps,
          startDate: startDate,
          endDate: endDate,
        );

        // Fetch raw data from Health Connect
        final rawData = await _healthConnectPlugin!.fetchData(query);

        // Convert to StepData and aggregate by day
        final stepDataList = await _aggregateStepsByDay(rawData);

        // Update cache
        _updateCache(stepDataList);

        return stepDataList;
      } else if (Platform.isIOS) {
        // TODO: iOS HealthKit data fetching
        throw HealthServiceException('iOS not yet implemented');
      }

      return [];
    } on health_sdk.HealthSyncError catch (e) {
      throw HealthServiceException('Failed to fetch step data', e);
    } catch (e) {
      throw HealthServiceException('Unexpected error fetching step data', e);
    }
  }

  /// Aggregate raw health data by day
  Future<List<StepData>> _aggregateStepsByDay(
    List<health_sdk.RawHealthData> rawData,
  ) async {
    // Group data by date
    final Map<DateTime, int> stepsByDate = {};
    final Map<DateTime, health_sdk.RawHealthData> latestDataByDate = {};

    for (final data in rawData) {
      // Extract date (without time)
      final date = DateTime(
        data.timestamp.year,
        data.timestamp.month,
        data.timestamp.day,
      );

      // Extract step count from raw data
      final count = data.raw['count'] as int? ?? 0;

      // Aggregate steps for this date
      stepsByDate[date] = (stepsByDate[date] ?? 0) + count;

      // Track latest data for source info
      if (!latestDataByDate.containsKey(date) ||
          data.timestamp.isAfter(latestDataByDate[date]!.timestamp)) {
        latestDataByDate[date] = data;
      }
    }

    // Convert to StepData list
    final stepDataList = <StepData>[];

    for (final entry in stepsByDate.entries) {
      final date = entry.key;
      final steps = entry.value;
      final latestData = latestDataByDate[date]!;

      // Extract data source information
      final sourceInfo =
          health_sdk.HealthConnectPlugin.getDataSource(latestData);
      final packageName = sourceInfo['packageName'] ?? 'unknown';
      final appName = sourceInfo['appName'] ?? 'Unknown App';

      final dataSource = DataSource.fromHealthConnect(
        packageName: packageName,
        appName: appName,
      );

      stepDataList.add(StepData(
        date: date,
        steps: steps,
        source: dataSource,
        lastSyncedAt: DateTime.now(),
      ));
    }

    // Sort by date
    stepDataList.sort((a, b) => a.date.compareTo(b.date));

    return stepDataList;
  }

  @override
  Future<List<DataSource>> getDataSources() async {
    try {
      if (Platform.isAndroid && _healthConnectPlugin != null) {
        // Fetch recent data to identify active sources
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 7));

        final query = health_sdk.DataQuery(
          dataType: health_sdk.DataType.steps,
          startDate: startDate,
          endDate: endDate,
        );

        final rawData = await _healthConnectPlugin!.fetchData(query);

        // Extract unique data sources
        final sourceMap = <String, DataSource>{};

        for (final data in rawData) {
          final sourceInfo =
              health_sdk.HealthConnectPlugin.getDataSource(data);
          final packageName = sourceInfo['packageName'] ?? 'unknown';
          final appName = sourceInfo['appName'] ?? 'Unknown App';

          if (!sourceMap.containsKey(packageName)) {
            sourceMap[packageName] = DataSource.fromHealthConnect(
              packageName: packageName,
              appName: appName,
            );
          }
        }

        // Mark primary source
        final sources = sourceMap.values.map((source) {
          if (_primaryDataSourceId != null && source.id == _primaryDataSourceId) {
            return source.copyWith(isPrimary: true);
          }
          return source;
        }).toList();

        return sources;
      } else if (Platform.isIOS) {
        // TODO: iOS HealthKit data sources
        throw HealthServiceException('iOS not yet implemented');
      }

      return [];
    } catch (e) {
      throw HealthServiceException('Failed to get data sources', e);
    }
  }

  @override
  Future<void> setPrimaryDataSource(String dataSourceId) async {
    _primaryDataSourceId = dataSourceId;
    // Clear cache to force refresh with new primary source
    _cache.clear();
  }

  @override
  Future<bool> isAvailable() async {
    try {
      if (Platform.isAndroid) {
        if (_healthConnectPlugin == null) {
          return false;
        }
        final availability = await _healthConnectPlugin!.checkAvailability();
        return availability == health_sdk.HealthConnectAvailability.installed;
      } else if (Platform.isIOS) {
        // TODO: Check iOS HealthKit availability
        return false; // Not yet implemented
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  String getPlatformName() {
    if (Platform.isAndroid) {
      return 'Health Connect';
    } else if (Platform.isIOS) {
      return 'HealthKit';
    }
    return 'Unknown';
  }

  @override
  void dispose() {
    _healthConnectPlugin?.dispose();
    _cache.clear();
  }

  // Cache management methods

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    final timeSinceUpdate = DateTime.now().difference(_lastCacheUpdate!);
    return timeSinceUpdate < _cacheValidityDuration;
  }

  List<StepData> _getFromCache(DateTime startDate, DateTime endDate) {
    final result = <StepData>[];

    for (final entry in _cache.entries) {
      final date = entry.key;
      if ((date.isAtSameMomentAs(startDate) || date.isAfter(startDate)) &&
          (date.isAtSameMomentAs(endDate) || date.isBefore(endDate))) {
        result.addAll(entry.value);
      }
    }

    return result;
  }

  void _updateCache(List<StepData> stepDataList) {
    for (final stepData in stepDataList) {
      _cache[stepData.date] = [stepData];
    }
    _lastCacheUpdate = DateTime.now();
  }
}
