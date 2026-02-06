/// User intents - now domain-agnostic!
///
/// This file exports the new class-based UserIntent system from the domain layer.
/// The old enum-based system has been replaced with a flexible class-based approach
/// that supports custom domain-specific intents.
///
/// Migration guide:
/// - Old: UserIntent.stepsNotSyncing
/// - New: UserIntent.metricNotSyncing (domain-agnostic)
///
/// The new system supports:
/// - Built-in common intents (greeting, metricNotSyncing, etc.)
/// - Domain-specific custom intents
/// - YAML-defined intents
/// - Plugin-defined intents

export '../domain/intent_classifier.dart' show UserIntent, IntentCategory, IntentClassificationResult, IntentClassifier;

/// Backward-compatible intent constants
///
/// These map old step-specific intents to new domain-agnostic intents.
/// Usage: Instead of UserIntent.stepsNotSyncing, use UserIntent.metricNotSyncing
class LegacyIntents {
  // Permission-related (mapped to new system)
  static UserIntent permissionDenied = UserIntent.permissionIssue;
  static UserIntent wantToGrantPermission = UserIntent.requestPermissions;
  static UserIntent whyPermissionNeeded = UserIntent.custom(
    id: 'why_permission_needed',
    displayName: 'Why Permission Needed',
    category: IntentCategory.information,
  );

  // Sync issues (NOW DOMAIN-AGNOSTIC)
  static UserIntent stepsNotSyncing = UserIntent.metricNotSyncing;
  static UserIntent syncDelayed = UserIntent.custom(
    id: 'sync_delayed',
    displayName: 'Sync Delayed',
    category: IntentCategory.troubleshooting,
  );

  // Data issues (NOW DOMAIN-AGNOSTIC)
  static UserIntent wrongStepCount = UserIntent.wrongCount;
  static UserIntent duplicateSteps = UserIntent.duplicateData;
  static UserIntent dataMissing = UserIntent.missingData;

  // Multi-app
  static UserIntent multipleAppsConflict = UserIntent.dataSourceConflict;
  static UserIntent multipleDataSources = UserIntent.dataSourceConflict;
  static UserIntent wantToSwitchSource = UserIntent.changeDataSource;

  // Technical
  static UserIntent batteryOptimizationIssue = UserIntent.custom(
    id: 'battery_optimization',
    displayName: 'Battery Optimization Issue',
    category: IntentCategory.troubleshooting,
  );
  static UserIntent batteryOptimization = batteryOptimizationIssue;
  static UserIntent healthConnectNotInstalled = UserIntent.custom(
    id: 'health_connect_not_installed',
    displayName: 'Health Connect Not Installed',
    category: IntentCategory.troubleshooting,
  );
  static UserIntent needsHealthConnect = healthConnectNotInstalled;

  // General (already domain-agnostic)
  static UserIntent greeting = UserIntent.greeting;
  static UserIntent thanks = UserIntent.thanks;
  static UserIntent checkingStatus = UserIntent.custom(
    id: 'checking_status',
    displayName: 'Checking Status',
    category: IntentCategory.information,
  );
  static UserIntent needHelp = UserIntent.help;

  // Unknown
  static UserIntent unclear = UserIntent.unknown;
}
