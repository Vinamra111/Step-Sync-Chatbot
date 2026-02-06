import 'dart:io';
import 'health_service.dart';
import '../data/models/step_data.dart';
import '../data/models/permission_state.dart';

/// Mock implementation of HealthService for testing and development.
///
/// This mock simulates the behavior of Health Connect/HealthKit without
/// requiring actual platform integration.
class MockHealthService implements HealthService {
  PermissionState _permissionState = PermissionState.unknown();
  final List<DataSource> _dataSources = [];
  String? _primaryDataSourceId;
  bool _isAvailable = true;
  List<StepData>? _mockStepData;
  String? _mockError;

  // Public properties for testing
  set mockPermissionState(PermissionState state) => _permissionState = state;
  set mockDataSources(List<DataSource> sources) {
    _dataSources.clear();
    _dataSources.addAll(sources);
  }
  set mockIsAvailable(bool available) => _isAvailable = available;
  set mockStepData(List<StepData>? data) => _mockStepData = data;
  set mockError(String? error) => _mockError = error;

  @override
  Future<void> initialize() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Set up mock data sources
    if (Platform.isAndroid) {
      _dataSources.addAll([
        DataSource.fromHealthConnect(
          packageName: 'com.google.android.apps.fitness',
          appName: 'Google Fit',
        ),
        DataSource.fromHealthConnect(
          packageName: 'com.samsung.android.app.health',
          appName: 'Samsung Health',
        ),
      ]);
    } else if (Platform.isIOS) {
      _dataSources.addAll([
        DataSource.phone(),
        DataSource.watch('Apple Watch'),
      ]);
    }
  }

  @override
  Future<PermissionState> checkPermissions() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (_mockError != null) throw Exception(_mockError);
    return _permissionState;
  }

  @override
  Future<PermissionState> requestPermissions() async {
    // Simulate Health Connect async delay (5-30 seconds, we'll use 2 for testing)
    if (Platform.isAndroid) {
      await Future.delayed(const Duration(seconds: 2));
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Auto-grant in mock
    _permissionState = PermissionState.granted();
    return _permissionState;
  }

  @override
  Future<List<StepData>> getStepData({
    required DateTime startDate,
    required DateTime endDate,
    bool forceRefresh = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Return mock data if set
    if (_mockStepData != null) {
      return _mockStepData!;
    }

    // Generate mock step data
    final days = endDate.difference(startDate).inDays + 1;
    final stepData = <StepData>[];

    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final steps = 5000 + (i * 500); // Gradually increasing steps

      stepData.add(StepData(
        date: DateTime(date.year, date.month, date.day),
        steps: steps,
        source: _dataSources.isNotEmpty
            ? _dataSources.first
            : DataSource.phone(),
        lastSyncedAt: DateTime.now(),
      ));
    }

    return stepData;
  }

  @override
  Future<List<DataSource>> getDataSources() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_dataSources);
  }

  @override
  Future<void> setPrimaryDataSource(String dataSourceId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _primaryDataSourceId = dataSourceId;

    // Update isPrimary flag
    for (var i = 0; i < _dataSources.length; i++) {
      _dataSources[i] = _dataSources[i].copyWith(
        isPrimary: _dataSources[i].id == dataSourceId,
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _isAvailable;
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
    // Nothing to dispose in mock
  }

  /// Helper for testing: manually set permission state.
  void setPermissionState(PermissionState state) {
    _permissionState = state;
  }

  /// Helper for testing: manually set data sources.
  void setDataSources(List<DataSource> sources) {
    _dataSources.clear();
    _dataSources.addAll(sources);
  }
}
