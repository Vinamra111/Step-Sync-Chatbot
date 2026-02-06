import 'package:step_sync_chatbot/src/core/intents.dart';
import 'package:step_sync_chatbot/src/core/rule_based_intent_classifier.dart';
import 'package:step_sync_chatbot/src/llm/llm_provider.dart';
import 'package:step_sync_chatbot/src/llm/llm_response.dart';
import 'package:step_sync_chatbot/src/privacy/pii_detector.dart';
import 'package:step_sync_chatbot/src/privacy/sanitization_result.dart';

/// Result of intent routing through the hybrid system.
class RoutingResult {
  final UserIntent intent;
  final Map<String, dynamic> entities;
  final RoutingStrategy strategyUsed;
  final double confidence;
  final SanitizationResult? sanitizationResult;
  final LLMResponse? llmResponse;
  final String? errorMessage;

  RoutingResult({
    required this.intent,
    required this.entities,
    required this.strategyUsed,
    required this.confidence,
    this.sanitizationResult,
    this.llmResponse,
    this.errorMessage,
  });
}

/// Strategy used to route the intent.
enum RoutingStrategy {
  /// Rule-based pattern matching (fastest, no cost)
  ruleBased,

  /// On-device ML model (fast, no cost, no network)
  onDeviceML,

  /// Cloud LLM (slowest, has cost, requires network)
  cloudLLM,

  /// Failed to classify
  failed,
}

/// Hybrid intent router that intelligently chooses between:
/// 1. Rule-based classification (80% of queries)
/// 2. On-device ML (15% of queries) - NOT YET IMPLEMENTED
/// 3. Cloud LLM (5% of queries)
class HybridIntentRouter {
  final RuleBasedIntentClassifier _ruleBasedClassifier;
  final PIIDetector _piiDetector;
  final LLMProvider? _llmProvider;

  // Confidence thresholds
  final double _ruleBasedThreshold = 0.7;

  // System prompt for LLM
  static const String _systemPrompt = '''
You are a helpful assistant for a step tracking app. Your role is to classify user intents and provide brief, actionable responses.

The user may be experiencing issues with:
- Permission grants for health data
- Step syncing across devices and apps
- Health Connect installation (Android)
- Battery optimization blocking background sync
- Multiple data sources causing conflicts

Classify the user's intent and respond concisely. Focus on the problem, not the solution details.
''';

  HybridIntentRouter({
    RuleBasedIntentClassifier? ruleBasedClassifier,
    PIIDetector? piiDetector,
    LLMProvider? llmProvider,
  })  : _ruleBasedClassifier = ruleBasedClassifier ?? RuleBasedIntentClassifier(),
        _piiDetector = piiDetector ?? PIIDetector(),
        _llmProvider = llmProvider;

  /// Route the user input through the hybrid system.
  ///
  /// Strategy priority:
  /// 1. Try rule-based first (fast, free)
  /// 2. If low confidence and LLM available, try cloud LLM
  /// 3. Otherwise use best available classification
  Future<RoutingResult> route(String userInput) async {
    // Step 1: Try rule-based classification
    final ruleBasedResult = _ruleBasedClassifier.classify(userInput);

    // If high confidence, use rule-based result
    if (ruleBasedResult.confidence >= _ruleBasedThreshold) {
      return RoutingResult(
        intent: ruleBasedResult.intent,
        entities: ruleBasedResult.entities,
        strategyUsed: RoutingStrategy.ruleBased,
        confidence: ruleBasedResult.confidence,
      );
    }

    // Step 2: If low confidence and LLM available, try cloud LLM
    if (_llmProvider != null) {
      final llmResult = await _tryCloudLLM(userInput);
      if (llmResult != null) {
        return llmResult;
      }
    }

    // Step 3: Fall back to rule-based result (even if low confidence)
    return RoutingResult(
      intent: ruleBasedResult.intent,
      entities: ruleBasedResult.entities,
      strategyUsed: RoutingStrategy.ruleBased,
      confidence: ruleBasedResult.confidence,
    );
  }

  /// Try to classify using cloud LLM.
  Future<RoutingResult?> _tryCloudLLM(String userInput) async {
    try {
      // Step 1: Sanitize input for privacy
      final sanitizationResult = _piiDetector.sanitize(userInput);

      // Step 2: Check if safe to send
      if (!sanitizationResult.isSafe) {
        // Contains critical PII, don't send to cloud
        return RoutingResult(
          intent: UserIntent.unclear,
          entities: {},
          strategyUsed: RoutingStrategy.failed,
          confidence: 0.0,
          sanitizationResult: sanitizationResult,
          errorMessage: 'Input contains sensitive information that cannot be sent to cloud',
        );
      }

      // Step 3: Call LLM with sanitized input
      final llmResponse = await _llmProvider!.generateResponse(
        prompt: sanitizationResult.sanitizedText,
        systemPrompt: _systemPrompt,
      );

      if (!llmResponse.success) {
        return null; // Fall back to rule-based
      }

      // Step 4: Parse LLM response to extract intent
      final intent = _parseIntentFromLLMResponse(llmResponse.text);

      return RoutingResult(
        intent: intent,
        entities: {}, // LLM doesn't extract entities yet
        strategyUsed: RoutingStrategy.cloudLLM,
        confidence: 0.9, // High confidence if LLM responded
        sanitizationResult: sanitizationResult,
        llmResponse: llmResponse,
      );
    } catch (e) {
      // LLM failed, fall back to rule-based
      return null;
    }
  }

  /// Parse intent from LLM response text.
  ///
  /// This is a simple heuristic-based parser. In production, you might:
  /// - Use structured output from LLM (JSON mode)
  /// - Train a classifier on LLM responses
  /// - Use LLM to directly output intent enum
  UserIntent _parseIntentFromLLMResponse(String response) {
    final lower = response.toLowerCase();

    // Map keywords in LLM response to intents
    if (lower.contains('permission') || lower.contains('grant') || lower.contains('access')) {
      return UserIntent.wantToGrantPermission;
    }

    if (lower.contains('sync') || lower.contains('updating') || lower.contains('not working')) {
      return UserIntent.stepsNotSyncing;
    }

    if (lower.contains('status') || lower.contains('check') || lower.contains('diagnostic')) {
      return UserIntent.checkingStatus;
    }

    if (lower.contains('install') || lower.contains('health connect')) {
      return UserIntent.needsHealthConnect;
    }

    if (lower.contains('battery') || lower.contains('background') || lower.contains('optimization')) {
      return UserIntent.batteryOptimization;
    }

    if (lower.contains('multiple') || lower.contains('apps') || lower.contains('sources') || lower.contains('conflict')) {
      return UserIntent.multipleDataSources;
    }

    if (lower.contains('hello') || lower.contains('hi') || lower.contains('help')) {
      return UserIntent.greeting;
    }

    // Default to unknown
    return UserIntent.unclear;
  }

  /// Get statistics about routing strategy usage.
  Map<RoutingStrategy, int> getRoutingStats() {
    // TODO: Implement tracking of strategy usage
    // This would track how often each strategy is used for analytics
    return {
      RoutingStrategy.ruleBased: 0,
      RoutingStrategy.onDeviceML: 0,
      RoutingStrategy.cloudLLM: 0,
      RoutingStrategy.failed: 0,
    };
  }
}
