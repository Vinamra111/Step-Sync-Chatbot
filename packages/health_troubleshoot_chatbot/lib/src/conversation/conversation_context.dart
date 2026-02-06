/// Conversation Context - Tracks conversation state for natural dialogue
///
/// Core component for "chatbot first" design - maintains context across
/// multiple turns to enable natural, flowing conversations.
///
/// Features:
/// - Track last 10 messages with timestamps
/// - Detect user sentiment (frustrated, happy, neutral)
/// - Maintain topic continuity for pronoun resolution
/// - Store user preferences (concise vs detailed)
/// - Reference tracking ("it", "that", "this")

import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/chat_message.dart';

part 'conversation_context.freezed.dart';

/// User sentiment level based on message analysis
enum SentimentLevel {
  veryFrustrated,  // "this is so annoying!!!"
  frustrated,      // "not working again"
  neutral,         // "my steps aren't syncing"
  satisfied,       // "it's working now"
  happy,           // "perfect! thank you!"
}

/// User preference for response style
enum ResponseStyle {
  concise,   // Short, to-the-point responses
  detailed,  // Detailed explanations with context
  balanced,  // Mix of both (default)
}

/// Message in conversation history
@freezed
class ConversationMessage with _$ConversationMessage {
  const factory ConversationMessage({
    required String text,
    required bool isUser,
    required DateTime timestamp,
    String? detectedIntent,
    SentimentLevel? sentiment,
  }) = _ConversationMessage;
}

/// Maintains conversation context for natural dialogue
class ConversationContext {
  /// Maximum messages to keep in context (performance/cost balance)
  static const int maxContextMessages = 10;

  /// Message history (last 10 messages)
  final List<ConversationMessage> _messages = [];

  /// Current topic being discussed
  String? currentTopic;

  /// Last detected sentiment
  SentimentLevel _currentSentiment = SentimentLevel.neutral;

  /// User's preferred response style (learned over time)
  ResponseStyle preferredStyle = ResponseStyle.balanced;

  /// Reference tracking for pronoun resolution
  String? lastMentionedApp;
  String? lastMentionedDevice;
  String? lastMentionedProblem;
  String? lastMentionedAction;

  /// Conversation metadata
  DateTime? conversationStartTime;
  int turnCount = 0;

  /// Add user message to context
  void addUserMessage(
    String text, {
    String? detectedIntent,
  }) {
    final sentiment = _detectSentiment(text);

    _messages.add(ConversationMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      detectedIntent: detectedIntent,
      sentiment: sentiment,
    ));

    _currentSentiment = sentiment;
    turnCount++;

    conversationStartTime ??= DateTime.now();

    // Update references
    _updateReferences(text);

    // Trim to max size
    if (_messages.length > maxContextMessages) {
      _messages.removeAt(0);
    }
  }

  /// Add bot message to context
  void addBotMessage(String text) {
    _messages.add(ConversationMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Trim to max size
    if (_messages.length > maxContextMessages) {
      _messages.removeAt(0);
    }
  }

  /// Get recent message history for LLM context
  List<ConversationMessage> getRecentMessages([int? count]) {
    final limit = count ?? maxContextMessages;
    final startIndex = _messages.length > limit
        ? _messages.length - limit
        : 0;
    return _messages.sublist(startIndex);
  }

  /// Get all user messages
  List<ConversationMessage> get userMessages =>
      _messages.where((m) => m.isUser).toList();

  /// Get all bot messages
  List<ConversationMessage> get botMessages =>
      _messages.where((m) => !m.isUser).toList();

  /// Current user sentiment
  SentimentLevel get sentiment => _currentSentiment;

  /// Total message count
  int get messageCount => _messages.length;

  /// Conversation duration
  Duration get duration {
    if (conversationStartTime == null) return Duration.zero;
    return DateTime.now().difference(conversationStartTime!);
  }

  /// Check if user seems frustrated
  bool get isFrustrated =>
      _currentSentiment == SentimentLevel.frustrated ||
      _currentSentiment == SentimentLevel.veryFrustrated;

  /// Check if user is happy/satisfied
  bool get isHappy =>
      _currentSentiment == SentimentLevel.happy ||
      _currentSentiment == SentimentLevel.satisfied;

  /// Get sentiment intensity (0.0 = very frustrated, 1.0 = very happy)
  double get sentimentScore {
    switch (_currentSentiment) {
      case SentimentLevel.veryFrustrated:
        return 0.0;
      case SentimentLevel.frustrated:
        return 0.25;
      case SentimentLevel.neutral:
        return 0.5;
      case SentimentLevel.satisfied:
        return 0.75;
      case SentimentLevel.happy:
        return 1.0;
    }
  }

  /// Detect sentiment from user message
  SentimentLevel _detectSentiment(String text) {
    final lowerText = text.toLowerCase();

    // Very frustrated indicators
    final veryFrustratedPatterns = [
      RegExp(r'!!+'),              // Multiple exclamation marks
      RegExp(r'so (annoying|frustrating|angry)'),
      RegExp(r'(hate|terrible|awful|useless)'),
      RegExp(r'(wtf|wth|omg)'),
      RegExp(r'(still|again|always) (not|broken|failing)'),
    ];

    if (veryFrustratedPatterns.any((p) => p.hasMatch(lowerText))) {
      return SentimentLevel.veryFrustrated;
    }

    // Frustrated indicators
    final frustratedPatterns = [
      RegExp(r'(not working|broken|failing|issue)'),
      RegExp(r'(annoying|frustrating)'),
      RegExp(r'(wrong|incorrect|missing)'),
      RegExp(r'(why (isnt|doesnt|wont))'),
    ];

    if (frustratedPatterns.any((p) => p.hasMatch(lowerText))) {
      return SentimentLevel.frustrated;
    }

    // Happy indicators
    final happyPatterns = [
      RegExp(r'(perfect|awesome|amazing|excellent)'),
      RegExp(r'(love|great|fantastic)'),
      RegExp(r'(thank you|thanks).*(!|much)'),
      RegExp(r'🎉|😊|❤️|👍'),
    ];

    if (happyPatterns.any((p) => p.hasMatch(lowerText))) {
      return SentimentLevel.happy;
    }

    // Satisfied indicators
    final satisfiedPatterns = [
      RegExp(r'(works|working|fixed|resolved)'),
      RegExp(r'(got it|understand|makes sense)'),
      RegExp(r'(thank|thanks)'),
      RegExp(r'(good|great|perfect|awesome)'),
      RegExp(r'✓|✅'),
    ];

    if (satisfiedPatterns.any((p) => p.hasMatch(lowerText))) {
      return SentimentLevel.satisfied;
    }

    // Default to neutral
    return SentimentLevel.neutral;
  }

  /// Update reference tracking for pronoun resolution
  void _updateReferences(String text) {
    final lowerText = text.toLowerCase();

    // Track mentioned apps (keep checking to find the LAST mentioned)
    final apps = [
      'google fit', 'samsung health', 'fitbit', 'strava',
      'apple health', 'health connect', 'my fitness pal'
    ];
    for (final app in apps) {
      if (lowerText.contains(app)) {
        lastMentionedApp = app;
        // Don't break - continue to find the last mentioned app
      }
    }

    // Track mentioned devices (keep checking to find the LAST mentioned)
    final devices = [
      'iphone', 'android', 'galaxy', 'pixel', 'watch', 'fitbit'
    ];
    for (final device in devices) {
      if (lowerText.contains(device)) {
        lastMentionedDevice = device;
        // Don't break - continue to find the last mentioned device
      }
    }

    // Track mentioned problems
    if (lowerText.contains('sync')) {
      lastMentionedProblem = 'syncing';
    } else if (lowerText.contains('permission')) {
      lastMentionedProblem = 'permissions';
    } else if (lowerText.contains('count') || lowerText.contains('wrong')) {
      lastMentionedProblem = 'step count accuracy';
    }

    // Track mentioned actions
    if (lowerText.contains('grant') || lowerText.contains('allow')) {
      lastMentionedAction = 'grant permission';
    } else if (lowerText.contains('check') || lowerText.contains('verify')) {
      lastMentionedAction = 'check status';
    }
  }

  /// Build context summary for LLM prompts
  String buildContextSummary() {
    final buffer = StringBuffer();

    if (currentTopic != null) {
      buffer.writeln('Current topic: $currentTopic');
    }

    buffer.writeln('User sentiment: ${_sentimentLabel(_currentSentiment)}');
    buffer.writeln('Messages exchanged: $turnCount');
    buffer.writeln('Preferred style: ${preferredStyle.name}');

    if (lastMentionedApp != null) {
      buffer.writeln('Discussing app: $lastMentionedApp');
    }

    if (lastMentionedDevice != null) {
      buffer.writeln('User device: $lastMentionedDevice');
    }

    if (lastMentionedProblem != null) {
      buffer.writeln('Current issue: $lastMentionedProblem');
    }

    return buffer.toString();
  }

  /// Get sentiment label for prompts
  String _sentimentLabel(SentimentLevel level) {
    switch (level) {
      case SentimentLevel.veryFrustrated:
        return 'very frustrated (be extra empathetic and fast)';
      case SentimentLevel.frustrated:
        return 'frustrated (acknowledge frustration first)';
      case SentimentLevel.neutral:
        return 'neutral (be helpful and friendly)';
      case SentimentLevel.satisfied:
        return 'satisfied (encourage and guide)';
      case SentimentLevel.happy:
        return 'happy (celebrate success with them)';
    }
  }

  /// Clear context (start fresh conversation)
  void clear() {
    _messages.clear();
    currentTopic = null;
    _currentSentiment = SentimentLevel.neutral;
    lastMentionedApp = null;
    lastMentionedDevice = null;
    lastMentionedProblem = null;
    lastMentionedAction = null;
    conversationStartTime = null;
    turnCount = 0;
  }

  /// Check if conversation is getting long (might need summarization)
  bool get isLongConversation => turnCount > 15;

  /// Check if conversation just started
  bool get isNewConversation => turnCount <= 2;
}
