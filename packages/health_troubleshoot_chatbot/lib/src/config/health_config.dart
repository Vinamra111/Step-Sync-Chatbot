/// Configuration for health data integration.
///
/// Defines how the chatbot should interact with health data sources
/// (Health Connect on Android, HealthKit on iOS).
class HealthDataConfig {
  /// Whether to enable background sync of health data.
  ///
  /// When enabled, the chatbot will periodically sync step data in the
  /// background to keep the cache fresh.
  final bool enableBackgroundSync;

  /// How often to sync data in the background (in hours).
  final int syncIntervalHours;

  /// How many days of step data to keep in the local cache.
  final int cacheRetentionDays;

  /// Whether to enable fraud detection (filter manual entries, anomalies).
  final bool enableFraudDetection;

  /// Maximum steps per day threshold for anomaly detection.
  /// Steps above this are flagged as suspicious.
  final int maxDailySteps;

  const HealthDataConfig({
    this.enableBackgroundSync = true,
    this.cacheRetentionDays = 30,
    this.syncIntervalHours = 6,
    this.enableFraudDetection = true,
    this.maxDailySteps = 100000,
  });

  /// Creates default configuration with sensible defaults.
  factory HealthDataConfig.defaults() {
    return const HealthDataConfig(
      enableBackgroundSync: true,
      cacheRetentionDays: 30,
      syncIntervalHours: 6,
    );
  }
}
