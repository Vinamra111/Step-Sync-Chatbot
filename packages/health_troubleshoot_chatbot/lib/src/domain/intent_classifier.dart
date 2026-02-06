/// Intent classification abstraction
///
/// Determines what the user wants from their message.
/// Replaces the hardcoded UserIntent enum with a flexible class-based system.

/// Category of user intent
enum IntentCategory {
  /// General conversation (greetings, thanks, help)
  general,

  /// Troubleshooting (metric not syncing, wrong count, etc.)
  troubleshooting,

  /// Information requests (how does tracking work, what's my count)
  information,

  /// Configuration (change data source, permissions)
  configuration,

  /// Unknown/unclassified
  unknown,
}

/// Represents a user's intent
///
/// Unlike the old enum-based system, this allows dynamic intents
/// that can be defined in YAML configs or plugins.
class UserIntent {
  final String id;
  final String displayName;
  final IntentCategory category;
  final Map<String, dynamic> metadata;

  const UserIntent({
    required this.id,
    required this.displayName,
    required this.category,
    this.metadata = const {},
  });

  // ============================================================================
  // COMMON INTENTS (used across all domains)
  // ============================================================================

  /// User is greeting the bot
  static const greeting = UserIntent(
    id: 'greeting',
    displayName: 'Greeting',
    category: IntentCategory.general,
  );

  /// User is thanking the bot
  static const thanks = UserIntent(
    id: 'thanks',
    displayName: 'Thanks',
    category: IntentCategory.general,
  );

  /// User is asking for help
  static const help = UserIntent(
    id: 'help',
    displayName: 'Help Request',
    category: IntentCategory.general,
  );

  /// Metric is not syncing/updating
  static const metricNotSyncing = UserIntent(
    id: 'metric_not_syncing',
    displayName: 'Metric Not Syncing',
    category: IntentCategory.troubleshooting,
  );

  /// Wrong metric count/value
  static const wrongCount = UserIntent(
    id: 'wrong_count',
    displayName: 'Wrong Count',
    category: IntentCategory.troubleshooting,
  );

  /// Duplicate data issue
  static const duplicateData = UserIntent(
    id: 'duplicate_data',
    displayName: 'Duplicate Data',
    category: IntentCategory.troubleshooting,
  );

  /// Missing data
  static const missingData = UserIntent(
    id: 'missing_data',
    displayName: 'Missing Data',
    category: IntentCategory.troubleshooting,
  );

  /// Permission issues
  static const permissionIssue = UserIntent(
    id: 'permission_issue',
    displayName: 'Permission Issue',
    category: IntentCategory.troubleshooting,
  );

  /// Data source conflict
  static const dataSourceConflict = UserIntent(
    id: 'data_source_conflict',
    displayName: 'Data Source Conflict',
    category: IntentCategory.troubleshooting,
  );

  /// How does tracking work?
  static const howDoesItWork = UserIntent(
    id: 'how_does_it_work',
    displayName: 'How Does It Work',
    category: IntentCategory.information,
  );

  /// What's my current metric value?
  static const checkCurrentValue = UserIntent(
    id: 'check_current_value',
    displayName: 'Check Current Value',
    category: IntentCategory.information,
  );

  /// Change primary data source
  static const changeDataSource = UserIntent(
    id: 'change_data_source',
    displayName: 'Change Data Source',
    category: IntentCategory.configuration,
  );

  /// Request permissions
  static const requestPermissions = UserIntent(
    id: 'request_permissions',
    displayName: 'Request Permissions',
    category: IntentCategory.configuration,
  );

  /// Unknown intent
  static const unknown = UserIntent(
    id: 'unknown',
    displayName: 'Unknown',
    category: IntentCategory.unknown,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserIntent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserIntent($id)';

  /// Create a custom intent (for domain-specific intents)
  factory UserIntent.custom({
    required String id,
    required String displayName,
    IntentCategory category = IntentCategory.unknown,
    Map<String, dynamic> metadata = const {},
  }) {
    return UserIntent(
      id: id,
      displayName: displayName,
      category: category,
      metadata: metadata,
    );
  }
}

/// Result of intent classification
class IntentClassificationResult {
  final UserIntent intent;
  final double confidence;
  final Map<String, dynamic> extractedData;

  const IntentClassificationResult({
    required this.intent,
    required this.confidence,
    this.extractedData = const {},
  });

  /// Whether classification confidence is high enough to act on
  bool get isConfident => confidence >= 0.7;

  @override
  String toString() {
    return 'IntentClassificationResult(intent: ${intent.id}, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// Abstract intent classifier
///
/// Each domain provides its own implementation with domain-specific patterns.
abstract class IntentClassifier {
  /// Classify user input into an intent
  IntentClassificationResult classify(String input);

  /// Get all intents supported by this classifier
  List<UserIntent> getSupportedIntents();

  /// Whether this classifier supports a specific intent
  bool supportsIntent(UserIntent intent) {
    return getSupportedIntents().any((i) => i.id == intent.id);
  }
}
