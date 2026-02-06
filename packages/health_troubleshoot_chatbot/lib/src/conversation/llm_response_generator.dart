/// LLM Response Generator - Natural, context-aware responses using Groq
///
/// Core of "chatbot first" design - uses LLM to generate conversational
/// responses that feel human, not robotic.
///
/// Features:
/// - Context-aware prompt building from ConversationContext
/// - Sentiment-based tone adjustment
/// - Natural pronoun resolution using reference tracking
/// - PHI sanitization before LLM call
/// - Fallback to templates on failure

import 'package:logger/logger.dart';
import '../services/groq_chat_service.dart';
import '../services/phi_sanitizer_service.dart';
import '../core/intents.dart';
import 'conversation_context.dart';

/// LLM-powered response generator
class LLMResponseGenerator {
  final GroqChatService _groqService;
  final PHISanitizerService _phiSanitizer;
  final Logger _logger;

  LLMResponseGenerator({
    required GroqChatService groqService,
    required PHISanitizerService phiSanitizer,
    Logger? logger,
  })  : _groqService = groqService,
        _phiSanitizer = phiSanitizer,
        _logger = logger ?? Logger();

  /// Generate natural response using LLM
  ///
  /// Takes current user message, intent, conversation context, and optional
  /// diagnostic results to generate a natural, empathetic response.
  Future<String> generate({
    required String userMessage,
    required UserIntent intent,
    required ConversationContext context,
    Map<String, dynamic>? diagnosticResults,
  }) async {
    try {
      _logger.d('Generating LLM response for intent: ${intent.name}');

      // Build system prompt based on context
      final systemPrompt = _buildSystemPrompt(context, intent);

      // Build user prompt with conversation history
      final userPrompt = _buildUserPrompt(
        userMessage,
        context,
        diagnosticResults,
      );

      // Sanitize before sending to LLM (privacy-first)
      final sanitizedUserPrompt = _phiSanitizer.sanitize(userPrompt);

      // Generate response from LLM
      final response = await _groqService.sendMessage(
        sanitizedUserPrompt.sanitizedText,
        systemPrompt: systemPrompt,
      );

      _logger.i('LLM response generated successfully');

      return response.content;
    } catch (e) {
      _logger.e('LLM generation failed: $e');
      // Return graceful fallback
      return _buildFallbackResponse(intent, context);
    }
  }

  /// Build context-aware system prompt
  ///
  /// Adjusts personality, tone, and instructions based on:
  /// - User sentiment (frustrated → more empathetic)
  /// - Conversation length (new → introduce, long → summarize)
  /// - User preferences (concise vs detailed)
  String _buildSystemPrompt(
    ConversationContext context,
    UserIntent intent,
  ) {
    final sentiment = context.sentiment;
    final isNew = context.isNewConversation;
    final prefersConcise = context.preferredStyle == ResponseStyle.concise;

    return '''
You are Step Sync Assistant - a friendly, helpful chatbot that helps users with step tracking issues.

PERSONALITY:
- Conversational and warm (like a helpful friend, not a robot)
- ${_getEmpathyInstruction(sentiment)}
- Action-oriented (always give clear next steps)
- ${prefersConcise ? 'Concise (2 sentences max unless detail needed)' : 'Thorough (explain the "why")'}

CONVERSATION CONTEXT:
${context.buildContextSummary()}

${isNew ? 'This is a new conversation - introduce yourself briefly.' : 'Continue the ongoing conversation naturally.'}

IMPORTANT RULES:
1. NEVER mention specific numbers (PHI already sanitized to [NUMBER])
2. Use "your steps" not specific counts
3. ${sentiment == SentimentLevel.veryFrustrated || sentiment == SentimentLevel.frustrated ? 'Acknowledge frustration FIRST: "I get it, this is frustrating"' : 'Be encouraging'}
4. Always end with clear next action
5. Use emojis occasionally: ✓ 🎉 😊 (but not excessive)
6. Reference previous messages naturally (they're in the conversation history)
7. Don't repeat yourself—user can scroll up

HANDLING INCOMPLETE/VAGUE INPUTS:
8. If user sends incomplete sentence (e.g., "my step only", "steps not", "cant see"), ask clarifying question FIRST
9. Ignore grammatical mistakes and typos - understand the intent
10. For vague inputs, offer 2-3 specific options to choose from
11. NEVER say "I don't understand" - always infer and offer choices

EXAMPLES OF VAGUE INPUT HANDLING:
❌ BAD: "I don't understand what you mean by 'my step only'"
✅ GOOD: "I see you're asking about your steps! Are you asking me to:
   • Check your step count?
   • Troubleshoot why steps aren't syncing?
   • Explain how step tracking works?"

❌ BAD: "Your message is unclear"
✅ GOOD: "Happy to help with your steps! What would you like me to do:
   • View your current step count
   • Fix a syncing issue
   • Check your tracking status"

${_getIntentSpecificInstructions(intent)}

RESPONSE STYLE:
❌ BAD: "I have detected synchronization issues. Please grant permissions."
✅ GOOD: "Oh no! Let's fix that. I need permission to check your steps—just tap below and we'll be syncing in seconds."

${_getFewShotExamples(intent)}

Now respond to the user naturally:
''';
  }

  /// Get empathy instruction based on sentiment
  String _getEmpathyInstruction(SentimentLevel sentiment) {
    switch (sentiment) {
      case SentimentLevel.veryFrustrated:
        return 'VERY empathetic and apologetic (user is very frustrated - acknowledge feelings first, then solve FAST)';
      case SentimentLevel.frustrated:
        return 'Empathetic (acknowledge frustration, then provide solution)';
      case SentimentLevel.neutral:
        return 'Helpful and friendly (standard approach)';
      case SentimentLevel.satisfied:
        return 'Encouraging and supportive (build on progress)';
      case SentimentLevel.happy:
        return 'Enthusiastic (celebrate success with user!)';
    }
  }

  /// Get intent-specific instructions
  String _getIntentSpecificInstructions(UserIntent intent) {
    switch (intent) {
      case UserIntent.whyPermissionNeeded:
        return 'Explain WHY you need permission (transparency builds trust).';
      case UserIntent.stepsNotSyncing:
        return 'Run diagnostics first, then explain issue and solution.';
      case UserIntent.wrongStepCount:
        return 'Explain multiple data sources can cause conflicts.';
      case UserIntent.batteryOptimization:
        return 'Explain battery optimization blocks background sync.';
      case UserIntent.multipleAppsConflict:
        return 'Help user choose primary source (watch > phone usually).';
      case UserIntent.greeting:
        return 'Be warm and friendly. Offer proactive help check.';
      case UserIntent.thanks:
        return 'Be gracious. Offer additional help if needed.';
      case UserIntent.needHelp:
        return 'Offer quick reply options for common issues.';
      default:
        return 'Be helpful and guide user to resolution.';
    }
  }

  /// Get few-shot examples for intent
  String _getFewShotExamples(UserIntent intent) {
    switch (intent) {
      case UserIntent.stepsNotSyncing:
        return '''
EXAMPLE CONVERSATION:
User: "my steps arent working"
Assistant: "Oh no! Let me run a quick check to see what's blocking your steps... [checking] Found it! Your battery optimization is blocking background sync. Want me to walk you through fixing that?"
''';

      case UserIntent.whyPermissionNeeded:
        return '''
EXAMPLE CONVERSATION:
User: "why do you need permission?"
Assistant: "Great question! I need permission to read your step data so I can spot issues like duplicate entries or missing syncs. Your data stays private—I never share it with anyone. Ready to grant it?"
''';

      case UserIntent.needHelp:
        return '''
EXAMPLE CONVERSATION (Handling Vague Input):
User: "my step only"
Assistant: "I see you're asking about your steps! What would you like me to do:
   • Check your current step count ✓
   • Fix syncing issues 🔧
   • Review your tracking setup 📊
Just let me know which one!"

User: "steps not"
Assistant: "Looks like something's up with your steps! Are you saying:
   • Steps aren't syncing?
   • Steps aren't showing up?
   • Step count seems wrong?
Which one sounds right?"

User: "cant see"
Assistant: "Happy to help! What can't you see:
   • Your step count?
   • Your tracking history?
   • Your connected apps?
Let me know and I'll get you sorted!"
''';

      default:
        return '';
    }
  }

  /// Build user prompt with conversation history
  String _buildUserPrompt(
    String currentMessage,
    ConversationContext context,
    Map<String, dynamic>? diagnosticResults,
  ) {
    final buffer = StringBuffer();

    // Add recent conversation history (last 5 messages)
    final recentMessages = context.getRecentMessages(5);
    if (recentMessages.isNotEmpty) {
      buffer.writeln('RECENT CONVERSATION:');
      for (final msg in recentMessages) {
        final sender = msg.isUser ? 'User' : 'Assistant';
        buffer.writeln('$sender: ${msg.text}');
      }
      buffer.writeln();
    }

    // Add diagnostic results if available
    if (diagnosticResults != null && diagnosticResults.isNotEmpty) {
      buffer.writeln('DIAGNOSTIC RESULTS:');
      diagnosticResults.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }

    // Add current user message
    buffer.writeln('USER\'S LATEST MESSAGE:');
    buffer.writeln(currentMessage);

    return buffer.toString();
  }

  /// Build fallback response when LLM fails
  String _buildFallbackResponse(
    UserIntent intent,
    ConversationContext context,
  ) {
    // Sentiment-aware fallback
    if (context.isFrustrated) {
      return "I understand this is frustrating. Let me help you fix this right away. "
          "I'm having a temporary connection issue, but I can still guide you through the solution.";
    }

    // Intent-specific fallback
    switch (intent) {
      case UserIntent.greeting:
        return "Hi! I'm your Step Sync Assistant. How can I help you today?";

      case UserIntent.stepsNotSyncing:
        return "I'll help you get your steps syncing. Let me run a quick diagnostic to find the issue.";

      case UserIntent.whyPermissionNeeded:
        return "I need permission to access your step data to help troubleshoot any issues. "
            "Your data stays private and is never shared.";

      case UserIntent.thanks:
        return "You're welcome! Let me know if you need anything else.";

      default:
        return "I'm here to help! Could you tell me a bit more about what's happening with your steps?";
    }
  }

  /// Generate enhancement for hybrid template approach
  ///
  /// Takes a template and enhances it with LLM-generated details
  Future<String> generateEnhancement({
    required String templateMessage,
    required ConversationContext context,
    String? placeholder = '[LLM_ENHANCEMENT]',
  }) async {
    try {
      // Extract the part that needs LLM enhancement
      if (!templateMessage.contains(placeholder!)) {
        return templateMessage; // No enhancement needed
      }

      // Build prompt for enhancement
      final systemPrompt = '''
You are enhancing a response template with contextual details.
Keep it conversational and natural.
${_getEmpathyInstruction(context.sentiment)}
Maximum 2 sentences.
''';

      final userPrompt = '''
Template: $templateMessage

Context: ${context.buildContextSummary()}

Fill in the $placeholder with relevant contextual information.
Output ONLY the replacement text for the placeholder, nothing else.
''';

      final response = await _groqService.sendMessage(
        userPrompt,
        systemPrompt: systemPrompt,
      );

      return templateMessage.replaceAll(placeholder, response.content.trim());
    } catch (e) {
      _logger.w('Enhancement failed, returning template as-is: $e');
      return templateMessage.replaceAll(placeholder!, '');
    }
  }
}
