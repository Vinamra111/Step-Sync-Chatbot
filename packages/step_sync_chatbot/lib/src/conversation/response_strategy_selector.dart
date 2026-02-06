/// Response Strategy Selector - Decides template vs LLM for cost optimization
///
/// Implements "chatbot first" with intelligent cost management:
/// - Use LLM for most conversations (natural, engaging)
/// - Use templates for simple, repetitive responses (cost-efficient)
/// - Use hybrid for structured responses with dynamic details
///
/// Strategy prioritizes conversation quality while managing costs.

import 'package:logger/logger.dart';
import '../core/intents.dart';
import 'conversation_context.dart';

/// Response generation strategy
enum ResponseStrategy {
  /// Use template only (fast, free, predictable)
  template,

  /// Use LLM only (natural, contextual, costs money)
  llm,

  /// Use template structure + LLM details (best of both)
  hybrid,
}

/// Selects optimal response strategy based on context
class ResponseStrategySelector {
  final Logger _logger;

  /// Confidence threshold for template usage
  /// Lower = more templates (cheaper), Higher = more LLM (better quality)
  final double templateConfidenceThreshold;

  ResponseStrategySelector({
    Logger? logger,
    this.templateConfidenceThreshold = 0.85,
  }) : _logger = logger ?? Logger();

  /// Select response strategy based on intent, context, and conversation state
  ResponseStrategy selectStrategy({
    required UserIntent intent,
    required ConversationContext context,
    double intentConfidence = 1.0,
  }) {
    _logger.d('Selecting strategy for intent: ${intent.name} (confidence: $intentConfidence)');

    // 1. Simple intents → always use templates (fast, free)
    if (_isSimpleIntent(intent)) {
      _logger.d('Selected: TEMPLATE (simple intent)');
      return ResponseStrategy.template;
    }

    // 2. User frustrated → use LLM (empathy is critical)
    if (context.isFrustrated) {
      _logger.d('Selected: LLM (user frustrated - empathy needed)');
      return ResponseStrategy.llm;
    }

    // 3. Ambiguous intent → use LLM (better understanding)
    if (intentConfidence < templateConfidenceThreshold) {
      _logger.d('Selected: LLM (low intent confidence: $intentConfidence)');
      return ResponseStrategy.llm;
    }

    // 4. Troubleshooting with diagnostics → use hybrid
    //    (structured data + natural explanation)
    //    Check this BEFORE complex conversation to prioritize diagnostic flow
    if (_needsDiagnosticExplanation(intent)) {
      _logger.d('Selected: HYBRID (diagnostic + explanation)');
      return ResponseStrategy.hybrid;
    }

    // 5. Complex multi-turn → use LLM (context awareness needed)
    if (_isComplexConversation(context, intent)) {
      _logger.d('Selected: LLM (complex multi-turn conversation)');
      return ResponseStrategy.llm;
    }

    // 6. Default: Use LLM for better conversation quality
    //    (chatbot-first approach - prioritize quality)
    _logger.d('Selected: LLM (default - chatbot first)');
    return ResponseStrategy.llm;
  }

  /// Check if intent is simple enough for templates
  bool _isSimpleIntent(UserIntent intent) {
    // These intents have well-defined, predictable responses
    const simpleIntents = {
      UserIntent.greeting,           // "Hi! I'm Step Sync Assistant..."
      UserIntent.thanks,             // "You're welcome!"
    };

    return simpleIntents.contains(intent);
  }

  /// Check if conversation is complex (multi-turn, context-heavy)
  bool _isComplexConversation(
    ConversationContext context,
    UserIntent intent,
  ) {
    // Multi-turn conversation (back-and-forth)
    if (context.turnCount > 3) {
      return true;
    }

    // User is referencing previous messages
    if (_hasReferences(context)) {
      return true;
    }

    // Intent requires slot filling
    if (_requiresSlotFilling(intent)) {
      return true;
    }

    return false;
  }

  /// Check if user is referencing previous context
  bool _hasReferences(ConversationContext context) {
    if (context.messageCount == 0) return false;

    final lastUserMessage = context.userMessages.lastOrNull;
    if (lastUserMessage == null) return false;

    final lowerText = lastUserMessage.text.toLowerCase();

    // Check for pronouns and references
    final referencePatterns = [
      RegExp(r'\b(it|that|this|those|these)\b'),
      RegExp(r'\b(the same|like before|still|again)\b'),
      RegExp(r'\b(you said|you mentioned|earlier)\b'),
    ];

    return referencePatterns.any((p) => p.hasMatch(lowerText));
  }

  /// Check if intent requires slot filling (multi-turn gathering)
  bool _requiresSlotFilling(UserIntent intent) {
    // These intents typically need additional info
    const slotFillingIntents = {
      UserIntent.stepsNotSyncing,      // "When did it stop?" "Which app?"
      UserIntent.wrongStepCount,        // "What count do you see?"
      UserIntent.multipleAppsConflict,  // "Which apps?"
      UserIntent.dataMissing,           // "Which date range?"
    };

    return slotFillingIntents.contains(intent);
  }

  /// Check if intent needs diagnostic explanation
  bool _needsDiagnosticExplanation(UserIntent intent) {
    // These intents run diagnostics and need to explain results
    const diagnosticIntents = {
      UserIntent.stepsNotSyncing,
      UserIntent.wrongStepCount,
      UserIntent.batteryOptimization,
      UserIntent.permissionDenied,
      UserIntent.healthConnectNotInstalled,
    };

    return diagnosticIntents.contains(intent);
  }

  /// Calculate estimated cost for strategy (for analytics/monitoring)
  double estimatedCost(ResponseStrategy strategy) {
    switch (strategy) {
      case ResponseStrategy.template:
        return 0.0; // Free

      case ResponseStrategy.llm:
        // Groq Llama 3.3 70B: ~$0.0005 per call
        // (700 tokens input + 150 tokens output)
        return 0.0005;

      case ResponseStrategy.hybrid:
        // Template is free, but we still call LLM for enhancement
        // Smaller call (200 tokens) so cheaper
        return 0.0002;
    }
  }

  /// Get strategy recommendation with explanation (for debugging/analytics)
  Map<String, dynamic> explainStrategy({
    required UserIntent intent,
    required ConversationContext context,
    double intentConfidence = 1.0,
  }) {
    final strategy = selectStrategy(
      intent: intent,
      context: context,
      intentConfidence: intentConfidence,
    );

    return {
      'strategy': strategy.name,
      'intent': intent.name,
      'intentConfidence': intentConfidence,
      'turnCount': context.turnCount,
      'sentiment': context.sentiment.name,
      'estimatedCost': estimatedCost(strategy),
      'reasons': _getReasons(strategy, intent, context, intentConfidence),
    };
  }

  /// Get reasons for strategy selection
  List<String> _getReasons(
    ResponseStrategy strategy,
    UserIntent intent,
    ConversationContext context,
    double intentConfidence,
  ) {
    final reasons = <String>[];

    if (strategy == ResponseStrategy.template) {
      if (_isSimpleIntent(intent)) {
        reasons.add('Simple intent with standard response');
      }
    } else if (strategy == ResponseStrategy.llm) {
      if (context.isFrustrated) {
        reasons.add('User is frustrated - empathy needed');
      }
      if (intentConfidence < templateConfidenceThreshold) {
        reasons.add('Low intent confidence - LLM can clarify');
      }
      if (context.turnCount > 3) {
        reasons.add('Multi-turn conversation - context awareness needed');
      }
      if (_hasReferences(context)) {
        reasons.add('User referencing previous messages');
      }
      if (reasons.isEmpty) {
        reasons.add('Default: chatbot-first approach prioritizes quality');
      }
    } else {
      // Hybrid
      reasons.add('Diagnostic results need natural explanation');
    }

    return reasons;
  }
}
