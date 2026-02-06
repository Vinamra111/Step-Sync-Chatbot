/// Health metric data access abstraction
///
/// Handles reading/writing health data for a specific metric.
/// Generic type T represents the metric value type (int for steps, double for sleep).

import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/data_source.dart';

part 'health_metric_adapter.freezed.dart';
part 'health_metric_adapter.g.dart';

/// Generic health metric data model
///
/// Replaces the hardcoded StepData model with a flexible generic.
///
/// Examples:
/// - HealthMetricData<int> for steps (value = step count)
/// - HealthMetricData<double> for sleep (value = hours slept)
/// - HealthMetricData<int> for water (value = ounces)
@freezed
class HealthMetricData<T> with _$HealthMetricData<T> {
  const factory HealthMetricData({
    /// Date/time of the measurement
    required DateTime date,

    /// The metric value (generic type)
    /// - int for steps, calories, water oz
    /// - double for sleep hours, weight, distance
    required T value,

    /// Data source that provided this data
    required DataSource source,

    /// When this data was last synced
    DateTime? lastSyncedAt,

    /// Additional metadata
    @Default({}) Map<String, dynamic> metadata,
  }) = _HealthMetricData<T>;

  factory HealthMetricData.fromJson(Map<String, dynamic> json) =>
      _$HealthMetricDataFromJson(json);
}

/// Type aliases for common metric types (backward compatibility)
typedef StepData = HealthMetricData<int>;
typedef SleepData = HealthMetricData<double>;
typedef WaterData = HealthMetricData<int>;
typedef CalorieData = HealthMetricData<int>;
typedef WeightData = HealthMetricData<double>;
typedef HeartRateData = HealthMetricData<int>;

/// Abstract health metric adapter
///
/// Each domain provides its own implementation to read/write health data.
abstract class HealthMetricAdapter<T> {
  /// Get metric data for a date range
  Future<List<HealthMetricData<T>>> getMetricData({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get today's metric value
  Future<T?> getTodayValue();

  /// Get metric value for a specific date
  Future<T?> getValueForDate(DateTime date);

  /// Get all available data sources for this metric
  Future<List<DataSource>> getDataSources();

  /// Get the currently selected primary data source
  Future<DataSource?> getPrimaryDataSource();

  /// Set the primary data source
  Future<void> setPrimaryDataSource(String dataSourceId);

  /// Request permissions to access this metric
  Future<bool> requestPermissions();

  /// Check if permissions are granted
  Future<bool> hasPermissions();

  /// Sync latest data from health platform
  Future<void> syncData();

  /// Get last sync time
  Future<DateTime?> getLastSyncTime();

  /// Delete data for a date range (if supported)
  Future<void> deleteData({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Write manual data entry (if supported)
  Future<void> writeData({
    required DateTime date,
    required T value,
    Map<String, dynamic>? metadata,
  });

  /// Get metric unit (e.g., "steps", "hours", "oz")
  String get metricUnit;

  /// Get metric name (e.g., "steps", "sleep hours", "water intake")
  String get metricName;

  /// Format metric value for display
  ///
  /// Example:
  /// - formatValue(10000) → "10,000 steps"
  /// - formatValue(7.5) → "7.5 hours"
  String formatValue(T value);

  /// Parse metric value from string
  ///
  /// Example:
  /// - parseValue("10000") → 10000
  /// - parseValue("7.5") → 7.5
  T? parseValue(String input);

  /// Validate metric value
  ///
  /// Checks if value is in valid range for this metric
  bool isValidValue(T value);

  /// Get recommended daily goal (if applicable)
  T? getRecommendedDailyGoal() => null;

  /// Get minimum valid value (if applicable)
  T? getMinValue() => null;

  /// Get maximum valid value (if applicable)
  T? getMaxValue() => null;
}

/// Base class for metric adapters
///
/// Provides common functionality for domain-specific adapters.
abstract class BaseHealthMetricAdapter<T> implements HealthMetricAdapter<T> {
  @override
  String formatValue(T value) {
    if (value is int) {
      // Format with commas: 10000 → 10,000
      final formatted = value.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},',
          );
      return '$formatted $metricUnit';
    } else if (value is double) {
      // Format with 1 decimal place: 7.5 → 7.5
      final formatted = (value as double).toStringAsFixed(1);
      return '$formatted $metricUnit';
    }

    return '$value $metricUnit';
  }

  @override
  T? parseValue(String input) {
    // Remove commas and whitespace
    final cleaned = input.replaceAll(RegExp(r'[,\s]'), '');

    try {
      if (T == int) {
        return int.parse(cleaned) as T;
      } else if (T == double) {
        return double.parse(cleaned) as T;
      }
    } catch (e) {
      return null;
    }

    return null;
  }
}
