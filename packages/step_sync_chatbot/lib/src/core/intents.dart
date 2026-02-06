/// User intents that the chatbot can recognize.
enum UserIntent {
  // Permission-related
  permissionDenied,
  wantToGrantPermission,
  whyPermissionNeeded,

  // Sync issues
  stepsNotSyncing,
  syncDelayed,

  // Data issues
  wrongStepCount,
  duplicateSteps,
  dataMissing,

  // Multi-app
  multipleAppsConflict,
  multipleDataSources, // Alias for multipleAppsConflict
  wantToSwitchSource,

  // Technical
  batteryOptimizationIssue,
  batteryOptimization, // Alias for batteryOptimizationIssue
  healthConnectNotInstalled,
  needsHealthConnect, // Alias for healthConnectNotInstalled

  // General
  greeting,
  thanks,
  checkingStatus,
  needHelp,

  // Unknown
  unclear,
}

/// Result of intent classification.
class IntentClassificationResult {
  final UserIntent intent;
  final double confidence;
  final Map<String, dynamic> entities;

  IntentClassificationResult({
    required this.intent,
    required this.confidence,
    this.entities = const {},
  });
}
