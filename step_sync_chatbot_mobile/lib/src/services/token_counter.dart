/// Token Counter Service - Context Window Management
///
/// Estimates token count and trims conversation history to fit within
/// model context limits (llama3-70b-8192 = 8000 tokens).

class TokenCounter {
  /// Model context limit (leave 500 tokens for response)
  static const int maxContextTokens = 7500;

  /// Overhead tokens per message (role, formatting, etc.)
  static const int overheadPerMessage = 4;

  /// Estimate token count for text (rough approximation)
  /// GPT/LLaMA tokenizers typically: 1 token ≈ 4 characters in English
  static int estimateTokens(String text) {
    // Split by whitespace and punctuation for better estimate
    final words = text.split(RegExp(r'[\s\n]+'));

    // Average: 1 word ≈ 1.3 tokens
    // Account for punctuation and special chars
    int tokenCount = (words.length * 1.3).ceil();

    // Add tokens for special characters
    final specialChars = RegExp(r'[^\w\s]').allMatches(text).length;
    tokenCount += (specialChars * 0.5).ceil();

    return tokenCount;
  }

  /// Calculate total tokens for a conversation
  static int calculateConversationTokens(List<Map<String, String>> messages) {
    int total = 0;

    for (final message in messages) {
      // Count tokens in content
      final content = message['content'] ?? '';
      total += estimateTokens(content);

      // Add overhead
      total += overheadPerMessage;
    }

    return total;
  }

  /// Trim conversation history to fit within token limit
  static List<Map<String, String>> trimToFit({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String currentMessage,
  }) {
    // Calculate tokens for fixed parts
    int systemTokens = estimateTokens(systemPrompt) + overheadPerMessage;
    int currentTokens = estimateTokens(currentMessage) + overheadPerMessage;
    int fixedTokens = systemTokens + currentTokens;

    // If even without history we exceed limit, truncate current message
    if (fixedTokens > maxContextTokens) {
      return []; // Return empty history
    }

    // Calculate remaining budget for history
    int remainingTokens = maxContextTokens - fixedTokens;

    // Start from most recent and work backwards
    List<Map<String, String>> trimmedHistory = [];
    int historyTokens = 0;

    for (int i = history.length - 1; i >= 0; i--) {
      final message = history[i];
      final messageTokens = estimateTokens(message['content'] ?? '') + overheadPerMessage;

      // Check if adding this message would exceed budget
      if (historyTokens + messageTokens > remainingTokens) {
        break; // Stop adding older messages
      }

      // Add to beginning of list (since we're going backwards)
      trimmedHistory.insert(0, message);
      historyTokens += messageTokens;
    }

    return trimmedHistory;
  }

  /// Get token usage statistics
  static Map<String, dynamic> getStats({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String currentMessage,
  }) {
    final systemTokens = estimateTokens(systemPrompt) + overheadPerMessage;
    final currentTokens = estimateTokens(currentMessage) + overheadPerMessage;
    final historyTokens = calculateConversationTokens(history);
    final totalTokens = systemTokens + currentTokens + historyTokens;

    return {
      'systemTokens': systemTokens,
      'currentTokens': currentTokens,
      'historyTokens': historyTokens,
      'totalTokens': totalTokens,
      'maxTokens': maxContextTokens,
      'remainingTokens': maxContextTokens - totalTokens,
      'percentUsed': ((totalTokens / maxContextTokens) * 100).toStringAsFixed(1),
      'willTrim': totalTokens > maxContextTokens,
    };
  }
}
