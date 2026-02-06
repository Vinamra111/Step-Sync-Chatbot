import '../data/models/step_data.dart';
import '../data/models/permission_state.dart';

/// Service for interacting with health data (Health Connect on Android, HealthKit on iOS).
///
/// This is the main interface for the chatbot to access health data.
abstract class HealthService {
  /// Initialize the health service.
  ///
  /// Must be called before using any other methods.
  Future<void> initialize();

  /// Check current permission state.
  Future<PermissionState> checkPermissions();

  /// Request health data permissions from the user.
  ///
  /// On Android, this launches Health Connect and waits 5-30 seconds for async processing.
  /// On iOS, this shows the HealthKit permission dialog.
  Future<PermissionState> requestPermissions();

  /// Get step data for a date range.
  ///
  /// Returns step data aggregated by day.
  /// If [forceRefresh] is true, bypasses cache and fetches fresh data.
  Future<List<StepData>> getStepData({
    required DateTime startDate,
    required DateTime endDate,
    bool forceRefresh = false,
  });

  /// Get all data sources currently providing step data.
  Future<List<DataSource>> getDataSources();

  /// Set the preferred primary data source.
  ///
  /// The chatbot will prioritize data from this source when multiple sources exist.
  Future<void> setPrimaryDataSource(String dataSourceId);

  /// Check if the health platform is available on this device.
  ///
  /// Returns true if Health Connect (Android) or HealthKit (iOS) is available.
  Future<bool> isAvailable();

  /// Get the platform-specific health platform name.
  String getPlatformName();

  /// Dispose resources.
  void dispose();
}

/// Exception thrown when health service operations fail.
class HealthServiceException implements Exception {
  final String message;
  final Object? cause;

  HealthServiceException(this.message, [this.cause]);

  @override
  String toString() => 'HealthServiceException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Exception thrown when permissions are not granted.
class PermissionDeniedException extends HealthServiceException {
  PermissionDeniedException(String message) : super(message);
}

/// Exception thrown when the health platform is not available.
class PlatformNotAvailableException extends HealthServiceException {
  PlatformNotAvailableException(String message) : super(message);
}
