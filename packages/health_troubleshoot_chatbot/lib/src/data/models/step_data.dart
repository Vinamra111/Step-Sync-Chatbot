import 'package:freezed_annotation/freezed_annotation.dart';

part 'step_data.freezed.dart';
part 'step_data.g.dart';

/// Represents step count data for a specific date.
@freezed
class StepData with _$StepData {
  const factory StepData({
    /// The date this step count is for (date only, no time).
    required DateTime date,

    /// Total step count for this date.
    required int steps,

    /// Source app/device that provided this data.
    required DataSource source,

    /// When this data was last synced.
    DateTime? lastSyncedAt,
  }) = _StepData;

  factory StepData.fromJson(Map<String, dynamic> json) =>
      _$StepDataFromJson(json);
}

/// Represents a data source (app/device) that provides step data.
@freezed
class DataSource with _$DataSource {
  const factory DataSource({
    /// Package name (Android) or bundle ID (iOS).
    required String id,

    /// User-friendly name (e.g., "Samsung Health", "Google Fit").
    required String name,

    /// Type of source.
    @Default(DataSourceType.app) DataSourceType type,

    /// Whether this is the user's preferred primary source.
    @Default(false) bool isPrimary,
  }) = _DataSource;

  factory DataSource.fromJson(Map<String, dynamic> json) =>
      _$DataSourceFromJson(json);

  /// Creates a data source from Health Connect metadata.
  factory DataSource.fromHealthConnect({
    required String packageName,
    required String appName,
  }) {
    return DataSource(
      id: packageName,
      name: appName,
      type: DataSourceType.app,
    );
  }

  /// Creates a data source for phone tracking.
  factory DataSource.phone() {
    return const DataSource(
      id: 'device.phone',
      name: 'Phone',
      type: DataSourceType.phone,
    );
  }

  /// Creates a data source for watch/wearable.
  factory DataSource.watch(String name) {
    return DataSource(
      id: 'device.watch',
      name: name,
      type: DataSourceType.watch,
    );
  }
}

/// Type of data source.
enum DataSourceType {
  app,
  phone,
  watch,
  unknown,
}
