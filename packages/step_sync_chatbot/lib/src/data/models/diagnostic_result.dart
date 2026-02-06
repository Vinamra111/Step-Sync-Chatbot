import 'package:freezed_annotation/freezed_annotation.dart';
import 'permission_state.dart';
import 'step_data.dart';

part 'diagnostic_result.freezed.dart';
part 'diagnostic_result.g.dart';

/// Result of a comprehensive system diagnostic check.
@freezed
class DiagnosticResult with _$DiagnosticResult {
  const factory DiagnosticResult({
    /// Permission check results.
    required PermissionState permissionState,

    /// Health Connect/HealthKit availability.
    required PlatformAvailability platformAvailability,

    /// Battery optimization status (Android only).
    BatteryOptimizationStatus? batteryOptimization,

    /// Data sources detected.
    @Default([]) List<DataSource> dataSources,

    /// Recent step data (if available).
    List<StepData>? recentStepData,

    /// Overall system health status.
    required SystemHealthStatus overallStatus,

    /// List of detected issues.
    @Default([]) List<DiagnosticIssue> issues,

    /// Timestamp when diagnostic was run.
    required DateTime timestamp,
  }) = _DiagnosticResult;

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticResultFromJson(json);
}

/// Platform availability status.
@freezed
class PlatformAvailability with _$PlatformAvailability {
  const factory PlatformAvailability({
    /// Whether the platform (Health Connect/HealthKit) is available.
    required bool isAvailable,

    /// Platform name (e.g., "Health Connect", "HealthKit").
    required String platformName,

    /// Whether installation is required (Android 9-13 only).
    @Default(false) bool requiresInstallation,

    /// Whether the platform is supported on this device.
    @Default(true) bool isSupported,

    /// Additional details about availability.
    String? details,
  }) = _PlatformAvailability;

  factory PlatformAvailability.fromJson(Map<String, dynamic> json) =>
      _$PlatformAvailabilityFromJson(json);

  /// Create availability status for Health Connect (installed).
  factory PlatformAvailability.healthConnectInstalled() {
    return const PlatformAvailability(
      isAvailable: true,
      platformName: 'Health Connect',
      requiresInstallation: false,
      isSupported: true,
    );
  }

  /// Create availability status for Health Connect (not installed).
  factory PlatformAvailability.healthConnectNotInstalled() {
    return const PlatformAvailability(
      isAvailable: false,
      platformName: 'Health Connect',
      requiresInstallation: true,
      isSupported: true,
      details: 'Health Connect app needs to be installed from Google Play Store',
    );
  }

  /// Create availability status for HealthKit.
  factory PlatformAvailability.healthKit({required bool available}) {
    return PlatformAvailability(
      isAvailable: available,
      platformName: 'HealthKit',
      requiresInstallation: false,
      isSupported: true,
    );
  }

  /// Create availability status for unsupported platform.
  factory PlatformAvailability.notSupported(String reason) {
    return PlatformAvailability(
      isAvailable: false,
      platformName: 'Unknown',
      requiresInstallation: false,
      isSupported: false,
      details: reason,
    );
  }
}

/// Battery optimization status (Android only).
@freezed
class BatteryOptimizationStatus with _$BatteryOptimizationStatus {
  const factory BatteryOptimizationStatus({
    /// Whether battery optimization is enabled for the app.
    required bool isOptimized,

    /// Whether this is blocking background sync.
    required bool isBlockingSync,

    /// User-friendly explanation.
    required String explanation,

    /// Recommended action.
    String? recommendedAction,
  }) = _BatteryOptimizationStatus;

  factory BatteryOptimizationStatus.fromJson(Map<String, dynamic> json) =>
      _$BatteryOptimizationStatusFromJson(json);

  /// Create status indicating battery optimization is enabled.
  factory BatteryOptimizationStatus.enabled() {
    return const BatteryOptimizationStatus(
      isOptimized: true,
      isBlockingSync: true,
      explanation: 'Battery optimization is limiting background sync. '
          'Steps only update when you open the app.',
      recommendedAction: 'Disable battery optimization for this app to enable '
          'automatic step syncing in the background.',
    );
  }

  /// Create status indicating battery optimization is disabled.
  factory BatteryOptimizationStatus.disabled() {
    return const BatteryOptimizationStatus(
      isOptimized: false,
      isBlockingSync: false,
      explanation: 'Battery optimization is disabled. Background sync is working normally.',
    );
  }

  /// Create status indicating unable to determine.
  factory BatteryOptimizationStatus.unknown() {
    return const BatteryOptimizationStatus(
      isOptimized: false,
      isBlockingSync: false,
      explanation: 'Unable to determine battery optimization status.',
    );
  }
}

/// Overall system health status.
enum SystemHealthStatus {
  /// Everything is working correctly.
  healthy,

  /// Some non-critical issues detected.
  warning,

  /// Critical issues preventing functionality.
  error,

  /// Unable to determine status.
  unknown,
}

extension SystemHealthStatusExtension on SystemHealthStatus {
  String get emoji {
    switch (this) {
      case SystemHealthStatus.healthy:
        return '✅';
      case SystemHealthStatus.warning:
        return '⚠️';
      case SystemHealthStatus.error:
        return '❌';
      case SystemHealthStatus.unknown:
        return '❓';
    }
  }

  String get label {
    switch (this) {
      case SystemHealthStatus.healthy:
        return 'Healthy';
      case SystemHealthStatus.warning:
        return 'Needs Attention';
      case SystemHealthStatus.error:
        return 'Critical Issue';
      case SystemHealthStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Individual diagnostic issue detected.
@freezed
class DiagnosticIssue with _$DiagnosticIssue {
  const factory DiagnosticIssue({
    /// Severity of the issue.
    required IssueSeverity severity,

    /// Category of the issue.
    required IssueCategory category,

    /// Short title of the issue.
    required String title,

    /// Detailed description.
    required String description,

    /// Suggested fix/resolution.
    String? suggestedFix,

    /// Action that can be taken to fix.
    IssueAction? action,
  }) = _DiagnosticIssue;

  factory DiagnosticIssue.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticIssueFromJson(json);

  /// Create issue for missing permissions.
  factory DiagnosticIssue.permissionsDenied() {
    return const DiagnosticIssue(
      severity: IssueSeverity.critical,
      category: IssueCategory.permissions,
      title: 'Permissions Not Granted',
      description: 'Step tracking permissions have not been granted. '
          'The app cannot access your step data without these permissions.',
      suggestedFix: 'Tap the button below to grant permissions.',
      action: IssueAction.grantPermissions,
    );
  }

  /// Create issue for Health Connect not installed.
  factory DiagnosticIssue.healthConnectNotInstalled() {
    return const DiagnosticIssue(
      severity: IssueSeverity.critical,
      category: IssueCategory.platform,
      title: 'Health Connect Not Installed',
      description: 'Your Android version requires the Health Connect app '
          'to be installed from Google Play Store.',
      suggestedFix: 'Install Health Connect from the Play Store.',
      action: IssueAction.installHealthConnect,
    );
  }

  /// Create issue for battery optimization.
  factory DiagnosticIssue.batteryOptimization() {
    return const DiagnosticIssue(
      severity: IssueSeverity.warning,
      category: IssueCategory.system,
      title: 'Battery Optimization Enabled',
      description: 'Battery optimization is limiting background sync. '
          'Steps only update when you open the app.',
      suggestedFix: 'Disable battery optimization for this app.',
      action: IssueAction.openBatterySettings,
    );
  }

  /// Create issue for no data sources.
  factory DiagnosticIssue.noDataSources() {
    return const DiagnosticIssue(
      severity: IssueSeverity.warning,
      category: IssueCategory.dataSources,
      title: 'No Data Sources Found',
      description: 'No apps are currently providing step data. '
          'You may need to connect a fitness app or wearable device.',
      suggestedFix: 'Connect a fitness app like Google Fit, Samsung Health, or a wearable device.',
    );
  }

  /// Create issue for multiple conflicting sources.
  factory DiagnosticIssue.multipleDataSources(int count) {
    return DiagnosticIssue(
      severity: IssueSeverity.info,
      category: IssueCategory.dataSources,
      title: 'Multiple Data Sources Detected',
      description: '$count apps are providing step data. '
          'This might cause duplicate or conflicting counts.',
      suggestedFix: 'Select a primary data source to prioritize.',
      action: IssueAction.selectPrimarySource,
    );
  }
}

/// Severity level of an issue.
enum IssueSeverity {
  /// Informational only, no action needed.
  info,

  /// Minor issue, recommended to fix.
  warning,

  /// Major issue, should fix soon.
  error,

  /// Critical issue, blocking functionality.
  critical,
}

extension IssueSeverityExtension on IssueSeverity {
  String get emoji {
    switch (this) {
      case IssueSeverity.info:
        return 'ℹ️';
      case IssueSeverity.warning:
        return '⚠️';
      case IssueSeverity.error:
        return '❌';
      case IssueSeverity.critical:
        return '🚨';
    }
  }
}

/// Category of diagnostic issue.
enum IssueCategory {
  permissions,
  platform,
  system,
  dataSources,
  sync,
  unknown,
}

/// Action that can be taken to resolve an issue.
enum IssueAction {
  grantPermissions,
  installHealthConnect,
  openBatterySettings,
  openAppSettings,
  selectPrimarySource,
  contactSupport,
}
