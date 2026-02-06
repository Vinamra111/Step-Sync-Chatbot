/// Conversation Context Tracker
///
/// Tracks multi-turn conversation context including:
/// - Mentioned apps
/// - Current problems
/// - User preferences
/// - Pronoun resolution

class ConversationContext {
  /// Mentioned health/fitness apps
  String? mentionedApp;

  /// Current problem being discussed
  String? currentProblem;

  /// User's device/platform details
  Map<String, String> deviceInfo = {};

  /// Turn count in current conversation
  int turnCount = 0;

  /// Last user sentiment
  String? lastSentiment;

  /// History of topics discussed
  List<String> topics = [];

  /// Timestamp of last interaction
  DateTime lastInteraction = DateTime.now();

  /// Update context from user message
  void updateFromMessage(String message) {
    final lower = message.toLowerCase();
    turnCount++;
    lastInteraction = DateTime.now();

    // Detect mentioned apps
    final apps = {
      'samsung health': 'Samsung Health',
      'google fit': 'Google Fit',
      'apple health': 'Apple Health',
      'healthkit': 'HealthKit',
      'fitbit': 'Fitbit',
      'garmin': 'Garmin Connect',
      'strava': 'Strava',
      'myfitnesspal': 'MyFitnessPal',
    };

    for (final entry in apps.entries) {
      if (lower.contains(entry.key)) {
        mentionedApp = entry.value;
        if (!topics.contains('app:${entry.value}')) {
          topics.add('app:${entry.value}');
        }
        break;
      }
    }

    // Detect current problem
    final problems = {
      'not syncing': 'sync_issue',
      'not working': 'functionality_issue',
      'not tracking': 'tracking_issue',
      'permission': 'permission_issue',
      'battery': 'battery_issue',
      'no steps': 'no_data',
      'wrong count': 'data_accuracy',
    };

    for (final entry in problems.entries) {
      if (lower.contains(entry.key)) {
        currentProblem = entry.value;
        if (!topics.contains('problem:${entry.value}')) {
          topics.add('problem:${entry.value}');
        }
        break;
      }
    }
  }

  /// Resolve pronoun references (it, this, that, etc.)
  String resolvePronoun(String message) {
    final lower = message.toLowerCase();

    // If message contains pronoun and we have context
    if ((lower.contains(' it ') || lower.startsWith('it ')) && mentionedApp != null) {
      return message.replaceAllMapped(
        RegExp(r'\bit\b', caseSensitive: false),
        (match) => mentionedApp!,
      );
    }

    if ((lower.contains(' this ') || lower.startsWith('this ')) && currentProblem != null) {
      return message.replaceAllMapped(
        RegExp(r'\bthis\b', caseSensitive: false),
        (match) => 'this ${_problemToText(currentProblem!)}',
      );
    }

    return message;
  }

  /// Convert problem code to readable text
  String _problemToText(String problemCode) {
    switch (problemCode) {
      case 'sync_issue':
        return 'syncing issue';
      case 'functionality_issue':
        return 'problem';
      case 'tracking_issue':
        return 'tracking issue';
      case 'permission_issue':
        return 'permission issue';
      case 'battery_issue':
        return 'battery issue';
      case 'no_data':
        return 'missing steps issue';
      case 'data_accuracy':
        return 'step count accuracy issue';
      default:
        return 'issue';
    }
  }

  /// Get context summary for LLM
  String getContextSummary() {
    final parts = <String>[];

    if (mentionedApp != null) {
      parts.add('User is using $mentionedApp');
    }

    if (currentProblem != null) {
      parts.add('Current issue: ${_problemToText(currentProblem!)}');
    }

    if (turnCount > 1) {
      parts.add('This is turn $turnCount of the conversation');
    }

    if (deviceInfo.isNotEmpty) {
      final device = deviceInfo['name'] ?? 'device';
      parts.add('User device: $device');
    }

    if (topics.isNotEmpty && topics.length > 1) {
      parts.add('Previously discussed: ${topics.take(3).join(", ")}');
    }

    return parts.isEmpty ? '' : '\n\n**Context:** ${parts.join(" • ")}\n';
  }

  /// Check if context is stale (inactive for > 10 minutes)
  bool isStale() {
    return DateTime.now().difference(lastInteraction).inMinutes > 10;
  }

  /// Reset context (start fresh conversation)
  void reset() {
    mentionedApp = null;
    currentProblem = null;
    deviceInfo.clear();
    turnCount = 0;
    lastSentiment = null;
    topics.clear();
    lastInteraction = DateTime.now();
  }

  /// Export context as map for debugging
  Map<String, dynamic> toMap() {
    return {
      'mentionedApp': mentionedApp,
      'currentProblem': currentProblem,
      'turnCount': turnCount,
      'lastSentiment': lastSentiment,
      'topics': topics,
      'lastInteraction': lastInteraction.toIso8601String(),
      'isStale': isStale(),
    };
  }
}
