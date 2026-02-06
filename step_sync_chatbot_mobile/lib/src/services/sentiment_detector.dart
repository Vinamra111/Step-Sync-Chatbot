/// Sentiment Detector Service - Detects User Frustration
///
/// Analyzes user messages to detect emotional state,
/// especially frustration, to provide empathetic responses.

enum Sentiment {
  /// User is neutral
  neutral,

  /// User is happy/satisfied
  positive,

  /// User is frustrated/angry
  frustrated,

  /// User is very frustrated/angry
  veryFrustrated,
}

class SentimentDetector {
  /// Detect sentiment from user message
  static Sentiment detect(String message) {
    final lower = message.toLowerCase();

    // Check for very frustrated indicators (multiple exclamations, strong words)
    final exclamationCount = '!!!'.allMatches(message).length;
    if (exclamationCount >= 2) {
      return Sentiment.veryFrustrated;
    }

    // Count frustration indicators
    int frustrationScore = 0;

    // Strong negative words
    final strongNegatives = [
      'hate', 'terrible', 'awful', 'worst', 'horrible', 'useless',
      'garbage', 'crap', 'stupid', 'ridiculous', 'pathetic',
      'frustrated', 'frustrating', 'annoying', 'annoyed', 'angry',
    ];
    for (final word in strongNegatives) {
      if (lower.contains(word)) frustrationScore += 3;
    }

    // Exclamation marks
    final exclamations = RegExp(r'!+').allMatches(message).length;
    frustrationScore += exclamations;

    // All caps words (3+ chars)
    final capsWords = RegExp(r'\b[A-Z]{3,}\b').allMatches(message).length;
    frustrationScore += capsWords * 2;

    // Question marks indicating confusion/frustration
    final questions = RegExp(r'\?+').allMatches(message).length;
    if (questions >= 2) frustrationScore += 1;

    // Repetition (e.g., "why why why", "not not not")
    if (RegExp(r'\b(\w+)\s+\1\b').hasMatch(lower)) frustrationScore += 2;

    // Negative phrases
    final negativePhrases = [
      'not working', 'doesn\'t work', 'won\'t work', 'can\'t',
      'still not', 'nothing works', 'this sucks', 'fed up',
      'had enough', 'waste of time', 'so frustrated',
    ];
    for (final phrase in negativePhrases) {
      if (lower.contains(phrase)) frustrationScore += 2;
    }

    // Determine sentiment based on score
    if (frustrationScore >= 6) {
      return Sentiment.veryFrustrated;
    } else if (frustrationScore >= 3) {
      return Sentiment.frustrated;
    }

    // Check for positive indicators
    final positiveWords = [
      'thanks', 'thank you', 'great', 'awesome', 'perfect',
      'excellent', 'love', 'helpful', 'works', 'fixed',
    ];
    for (final word in positiveWords) {
      if (lower.contains(word)) {
        return Sentiment.positive;
      }
    }

    return Sentiment.neutral;
  }

  /// Get empathetic system prompt based on sentiment
  static String getEmpatheticPrompt(Sentiment sentiment) {
    switch (sentiment) {
      case Sentiment.veryFrustrated:
        return '''
**USER IS VERY FRUSTRATED - USE MAXIMUM EMPATHY**

The user is extremely frustrated. Your response must:
1. **Immediately acknowledge their frustration** - "I can see this has been really frustrating for you"
2. **Apologize sincerely** - "I'm truly sorry you're experiencing this"
3. **Take ownership** - "Let me make this right"
4. **Provide CLEAR, DIRECT solutions** - No vague advice
5. **Be concise** - They're frustrated, don't overwhelm them

Tone: Warm, understanding, solution-focused
Length: Keep it brief but caring (3-4 sentences + solution)
NO: Generic advice, "have you tried...", asking more questions
YES: "I found the issue", "Here's exactly what to do", specific steps
''';

      case Sentiment.frustrated:
        return '''
**USER IS FRUSTRATED - USE EMPATHY**

The user is frustrated. Your response should:
1. **Acknowledge their frustration** - "I understand this is frustrating"
2. **Show you're on their side** - "Let's fix this together"
3. **Be solution-focused** - Provide clear next steps
4. **Be encouraging** - "We'll get this working"

Tone: Understanding, supportive, proactive
Length: 4-5 sentences
''';

      case Sentiment.positive:
        return '''
**USER IS SATISFIED**

The user seems happy/satisfied. Your response should:
1. **Match their positive tone** - Be upbeat
2. **Reinforce success** - "Great to hear it's working!"
3. **Offer additional help** - "Is there anything else?"

Tone: Friendly, encouraging
''';

      case Sentiment.neutral:
        return '''
**USER IS NEUTRAL**

Standard professional tone:
1. **Be helpful and clear**
2. **Provide specific guidance**
3. **Stay friendly but focused**

Tone: Professional, helpful
''';
    }
  }

  /// Check if sentiment requires special handling
  static bool requiresSpecialHandling(Sentiment sentiment) {
    return sentiment == Sentiment.frustrated || sentiment == Sentiment.veryFrustrated;
  }
}
