import 'intents.dart';

/// Rule-based intent classifier using pattern matching.
///
/// This classifier uses regex patterns to identify user intents.
/// It's fast, deterministic, and handles ~80% of common queries.
class RuleBasedIntentClassifier {
  /// Classify user input into an intent.
  IntentClassificationResult classify(String input) {
    final normalizedInput = input.toLowerCase().trim();

    // Check patterns in priority order (most specific first)
    for (final pattern in _intentPatterns) {
      final match = pattern.regex.firstMatch(normalizedInput);
      if (match != null) {
        return IntentClassificationResult(
          intent: pattern.intent,
          confidence: pattern.confidence,
          entities: _extractEntities(match, pattern.entityNames),
        );
      }
    }

    // No match found
    return IntentClassificationResult(
      intent: UserIntent.unclear,
      confidence: 0.3,
    );
  }

  /// Extract named entities from regex match.
  Map<String, dynamic> _extractEntities(
    RegExpMatch match,
    List<String> entityNames,
  ) {
    final entities = <String, dynamic>{};

    for (var i = 0; i < entityNames.length && i < match.groupCount; i++) {
      final groupValue = match.group(i + 1);
      if (groupValue != null) {
        entities[entityNames[i]] = groupValue;
      }
    }

    return entities;
  }
}

/// Intent pattern definition.
class _IntentPattern {
  final RegExp regex;
  final UserIntent intent;
  final double confidence;
  final List<String> entityNames;

  _IntentPattern({
    required this.regex,
    required this.intent,
    required this.confidence,
    this.entityNames = const [],
  });
}

/// Intent patterns ordered by specificity (most specific first).
final _intentPatterns = [
  // Greetings
  _IntentPattern(
    regex: RegExp(r'^(hi|hello|hey|good morning|good afternoon|good evening)'),
    intent: UserIntent.greeting,
    confidence: 0.95,
  ),

  // Thanks
  _IntentPattern(
    regex: RegExp(r'\b(thank you|thanks|thx|appreciate it)\b'),
    intent: UserIntent.thanks,
    confidence: 0.95,
  ),

  // Permission - Why needed
  _IntentPattern(
    regex: RegExp(r'\b(why|what).*(need|want|require).*(permission|access)\b'),
    intent: UserIntent.whyPermissionNeeded,
    confidence: 0.90,
  ),

  // Permission - Want to grant
  _IntentPattern(
    regex: RegExp(r'\b(grant|give|allow|enable).*(permission|access)\b'),
    intent: UserIntent.wantToGrantPermission,
    confidence: 0.90,
  ),

  // Permission - Denied
  _IntentPattern(
    regex: RegExp(r'\b(permission|access).*(denied|blocked|not allowed)\b'),
    intent: UserIntent.permissionDenied,
    confidence: 0.90,
  ),

  // Steps not syncing
  _IntentPattern(
    regex: RegExp(r"\b(steps?|step count).*(not|n't|isn't|aren't).*(sync|update|show|appear)"),
    intent: UserIntent.stepsNotSyncing,
    confidence: 0.92,
  ),

  // Sync delayed
  _IntentPattern(
    regex: RegExp(r'\b(sync|update).*(slow|delay|late|behind)\b'),
    intent: UserIntent.syncDelayed,
    confidence: 0.88,
  ),

  // Wrong step count
  _IntentPattern(
    regex: RegExp(r'\b(wrong|incorrect|different|off).*(steps?|step count|count)\b'),
    intent: UserIntent.wrongStepCount,
    confidence: 0.90,
  ),

  // Duplicate steps
  _IntentPattern(
    regex: RegExp(r'\b(duplicate|double|twice|multiple).*(steps?|count)\b'),
    intent: UserIntent.duplicateSteps,
    confidence: 0.88,
  ),

  // Data missing
  _IntentPattern(
    regex: RegExp(r'\b(missing|lost|disappeared).*(steps?|data)\b'),
    intent: UserIntent.dataMissing,
    confidence: 0.88,
  ),

  // Multiple apps conflict
  _IntentPattern(
    regex: RegExp(r'\b(multiple|different|several).*(apps?|sources?)\b'),
    intent: UserIntent.multipleAppsConflict,
    confidence: 0.85,
  ),

  // Want to switch source
  _IntentPattern(
    regex: RegExp(r'\b(switch|change|use).*(app|source|data source)\b'),
    intent: UserIntent.wantToSwitchSource,
    confidence: 0.85,
  ),

  // Battery optimization
  _IntentPattern(
    regex: RegExp(r'\b(battery|power).*(saver|optimization|saving)\b'),
    intent: UserIntent.batteryOptimizationIssue,
    confidence: 0.85,
  ),

  // Health Connect not installed
  _IntentPattern(
    regex: RegExp(r"\bhealth connect.*(not|n't|isn't).*(installed|available|found)\b"),
    intent: UserIntent.healthConnectNotInstalled,
    confidence: 0.90,
  ),

  // Checking status - more general pattern
  _IntentPattern(
    regex: RegExp(r'\b(check|test|verify|see).*(status|setup|working)\b'),
    intent: UserIntent.checkingStatus,
    confidence: 0.80,
  ),

  // Need help - catch-all
  _IntentPattern(
    regex: RegExp(r'\b(help|assist|support|problem|issue|fix)\b'),
    intent: UserIntent.needHelp,
    confidence: 0.75,
  ),

  // FUZZY MATCHING FOR INCOMPLETE/VAGUE INPUTS
  // These patterns handle typos, incomplete sentences, and grammatical errors

  // "my step" / "my steps" variations (incomplete)
  _IntentPattern(
    regex: RegExp(r'\bmy\s+steps?\s*(only|not)?$', caseSensitive: false),
    intent: UserIntent.needHelp,
    confidence: 0.65,
  ),

  // "steps not" / "step not" (incomplete)
  _IntentPattern(
    regex: RegExp(r'\bsteps?\s+(not|no|dont|doesn\'?t?)\s*$', caseSensitive: false),
    intent: UserIntent.stepsNotSyncing,
    confidence: 0.70,
  ),

  // "cant see" / "can't see" / "cannot see" (incomplete)
  _IntentPattern(
    regex: RegExp(r'\b(can\'?t|cannot|cant)\s+(see|find|view)\s*', caseSensitive: false),
    intent: UserIntent.needHelp,
    confidence: 0.68,
  ),

  // "not working" / "doesnt work" (very vague)
  _IntentPattern(
    regex: RegExp(r'\b(not|n\'?t|isn\'?t|doesn\'?t?)\s+(work|working)\s*', caseSensitive: false),
    intent: UserIntent.needHelp,
    confidence: 0.65,
  ),

  // Single word queries: "steps", "sync", "help"
  _IntentPattern(
    regex: RegExp(r'^(steps?|sync|help|fix|check|status)$', caseSensitive: false),
    intent: UserIntent.needHelp,
    confidence: 0.60,
  ),

  // Typo variations of common words
  _IntentPattern(
    regex: RegExp(r'\b(stpes|setp|stp|syc|halp|hlep)\b', caseSensitive: false),
    intent: UserIntent.needHelp,
    confidence: 0.62,
  ),

  // "show me" / "view" variations (incomplete)
  _IntentPattern(
    regex: RegExp(r'\b(show|view|display|see)\s+(me|my)?\s*$', caseSensitive: false),
    intent: UserIntent.checkingStatus,
    confidence: 0.65,
  ),

  // Questions with just "why" or "how"
  _IntentPattern(
    regex: RegExp(r'^(why|how|what|where)\s*\??$', caseSensitive: false),
    intent: UserIntent.needHelp,
    confidence: 0.55,
  ),
];
