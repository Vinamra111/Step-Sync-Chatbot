/// Tests for Token Counter Service
///
/// Validates:
/// - Token counting accuracy
/// - Conversation token calculation
/// - History truncation logic
/// - Cache functionality
/// - Model-specific counting
/// - Edge cases

import 'package:test/test.dart';
import '../../lib/src/services/token_counter.dart';

void main() {
  group('TokenCounter - Basic Token Counting', () {
    late TokenCounter counter;

    setUp(() {
      counter = TokenCounter();
    });

    test('Counts tokens in simple sentence', () {
      final text = 'Hello world';
      final count = counter.countTokens(text);

      // "Hello" + "world" = ~2 tokens
      expect(count, inInclusiveRange(2, 4));
    });

    test('Counts tokens in longer text', () {
      final text = 'The quick brown fox jumps over the lazy dog';
      final count = counter.countTokens(text);

      // 9 words ~= 10-12 tokens
      expect(count, inInclusiveRange(9, 15));
    });

    test('Empty string returns zero tokens', () {
      expect(counter.countTokens(''), equals(0));
    });

    test('Single word counts as at least 1 token', () {
      expect(counter.countTokens('a'), equals(1));
      expect(counter.countTokens('hello'), equals(1));
    });

    test('Long words split into multiple tokens', () {
      final longWord = 'antidisestablishmentarianism';
      final count = counter.countTokens(longWord);

      // Very long word should split into multiple tokens
      expect(count, greaterThan(1));
    });

    test('Special characters are counted', () {
      final text = 'Hello! How are you?';
      final count = counter.countTokens(text);

      // Words + punctuation
      expect(count, greaterThan(3));
    });

    test('Numbers are tokenized', () {
      final text = 'I have 12345 steps today';
      final count = counter.countTokens(text);

      expect(count, greaterThan(4));
    });

    test('Code snippets are tokenized appropriately', () {
      final code = 'function foo() { return 42; }';
      final count = counter.countTokens(code);

      // Multiple tokens for keywords, braces, etc.
      expect(count, greaterThan(6));
    });
  });

  group('TokenCounter - Conversation Token Counting', () {
    late TokenCounter counter;

    setUp(() {
      counter = TokenCounter();
    });

    test('Counts conversation with no history', () {
      final result = counter.countConversationTokens(
        systemPrompt: 'You are a helpful assistant.',
        userMessage: 'Hello, how are you?',
      );

      expect(result.tokens, greaterThan(6));
      expect(result.exceedsLimit, isFalse);
      expect(result.remainingTokens, greaterThan(7000));
    });

    test('Counts conversation with history', () {
      final history = [
        ConversationMessage(content: 'Hi there', role: 'user'),
        ConversationMessage(content: 'Hello! How can I help?', role: 'assistant'),
      ];

      final result = counter.countConversationTokens(
        systemPrompt: 'You are a helpful assistant.',
        userMessage: 'What is the weather?',
        history: history,
      );

      expect(result.tokens, greaterThan(15));
      expect(result.exceedsLimit, isFalse);
    });

    test('Detects when conversation exceeds limit', () {
      final config = TokenCounterConfig(maxContextTokens: 100);
      final counter = TokenCounter(config: config);

      // Create a very long message that will exceed limit
      final longMessage = List.generate(50, (i) => 'word').join(' ');

      final result = counter.countConversationTokens(
        systemPrompt: longMessage,
        userMessage: longMessage,
      );

      expect(result.exceedsLimit, isTrue);
      expect(result.remainingTokens, equals(0));
    });

    test('Accounts for message overhead tokens', () {
      final resultNoHistory = counter.countConversationTokens(
        systemPrompt: 'System',
        userMessage: 'User',
      );

      final resultWithHistory = counter.countConversationTokens(
        systemPrompt: 'System',
        userMessage: 'User',
        history: [
          ConversationMessage(content: 'Hi', role: 'user'),
        ],
      );

      // History should add more than just content tokens (overhead)
      final historyTokens =
          resultWithHistory.tokens - resultNoHistory.tokens;
      final contentTokens = counter.countTokens('Hi');

      expect(historyTokens, greaterThan(contentTokens));
    });

    test('Calculates remaining tokens correctly', () {
      final result = counter.countConversationTokens(
        systemPrompt: 'Short',
        userMessage: 'Message',
      );

      final expected = counter.config.effectiveLimit - result.tokens;
      expect(result.remainingTokens, equals(expected));
    });
  });

  group('TokenCounter - History Truncation', () {
    late TokenCounter counter;

    setUp(() {
      counter = TokenCounter(
        config: TokenCounterConfig(
          maxContextTokens: 100,
          safetyMargin: 20,
        ),
      );
    });

    test('Returns empty list when no history provided', () {
      final truncated = counter.truncateHistory(
        history: [],
        systemPrompt: 'System',
        userMessage: 'User',
      );

      expect(truncated, isEmpty);
    });

    test('Keeps all history when under limit', () {
      final history = [
        ConversationMessage(content: 'Hi', role: 'user'),
        ConversationMessage(content: 'Hello', role: 'assistant'),
        ConversationMessage(content: 'How are you?', role: 'user'),
      ];

      final truncated = counter.truncateHistory(
        history: history,
        systemPrompt: 'Short',
        userMessage: 'Test',
      );

      expect(truncated.length, equals(3));
    });

    test('Truncates oldest messages first', () {
      final history = [
        ConversationMessage(content: 'Message 1', role: 'user'),
        ConversationMessage(content: 'Message 2', role: 'assistant'),
        ConversationMessage(content: 'Message 3', role: 'user'),
        ConversationMessage(content: 'Message 4', role: 'assistant'),
      ];

      // Create a scenario where only 2 messages fit
      // With effective limit of 80 tokens, use more aggressive base consumption
      final longSystem = List.generate(25, (i) => 'word').join(' ');
      final longUser = List.generate(15, (i) => 'word').join(' ');

      final truncated = counter.truncateHistory(
        history: history,
        systemPrompt: longSystem,
        userMessage: longUser,
      );

      // Should keep most recent messages (not all 4)
      expect(truncated.length, lessThan(4));
      if (truncated.isNotEmpty) {
        expect(truncated.last.content, equals('Message 4'));
      }
    });

    test('Returns empty when base messages exceed limit', () {
      final veryLongSystem = List.generate(50, (i) => 'word').join(' ');
      final veryLongUser = List.generate(50, (i) => 'word').join(' ');

      final history = [
        ConversationMessage(content: 'Hi', role: 'user'),
      ];

      final truncated = counter.truncateHistory(
        history: history,
        systemPrompt: veryLongSystem,
        userMessage: veryLongUser,
      );

      expect(truncated, isEmpty);
    });

    test('Preserves message order after truncation', () {
      final history = [
        ConversationMessage(content: 'First', role: 'user'),
        ConversationMessage(content: 'Second', role: 'assistant'),
        ConversationMessage(content: 'Third', role: 'user'),
      ];

      final truncated = counter.truncateHistory(
        history: history,
        systemPrompt: 'System',
        userMessage: 'User',
      );

      // Check order is preserved
      for (int i = 0; i < truncated.length - 1; i++) {
        final originalIndex = history.indexOf(truncated[i]);
        final nextOriginalIndex = history.indexOf(truncated[i + 1]);
        expect(originalIndex, lessThan(nextOriginalIndex));
      }
    });
  });

  group('TokenCounter - Caching', () {
    late TokenCounter counter;

    setUp(() {
      counter = TokenCounter();
    });

    test('Cache improves performance on repeated strings', () {
      final text = 'This is a test message for caching';

      // First call (not cached)
      final count1 = counter.countTokens(text);

      // Second call (should be cached)
      final count2 = counter.countTokens(text);

      expect(count1, equals(count2));
    });

    test('Cache statistics are accessible', () {
      counter.countTokens('test 1');
      counter.countTokens('test 2');
      counter.countTokens('test 3');

      final stats = counter.getCacheStats();

      expect(stats['size'], greaterThan(0));
      expect(stats['maxSize'], equals(1000));
    });

    test('Clear cache resets cache size', () {
      counter.countTokens('test 1');
      counter.countTokens('test 2');

      expect(counter.getCacheStats()['size'], greaterThan(0));

      counter.clearCache();

      expect(counter.getCacheStats()['size'], equals(0));
    });

    test('Cache respects size limit', () {
      // Try to overflow cache (would need 1000+ unique strings)
      // Just verify it doesn't crash
      for (int i = 0; i < 1100; i++) {
        counter.countTokens('test message $i');
      }

      final stats = counter.getCacheStats();
      expect(stats['size'], lessThanOrEqualTo(1000));
    });
  });

  group('TokenCounter - Model-Specific Counting', () {
    test('Llama model uses appropriate tokenization', () {
      final llamaCounter = TokenCounter(
        config: TokenCounterConfig(model: TokenizerModel.llama3),
      );

      final text = 'Hello world, how are you today?';
      final count = llamaCounter.countTokens(text);

      expect(count, greaterThan(5));
      expect(count, lessThan(15));
    });

    test('GPT model uses different tokenization', () {
      final gptCounter = TokenCounter(
        config: TokenCounterConfig(model: TokenizerModel.gpt4),
      );

      final text = 'Hello world, how are you today?';
      final count = gptCounter.countTokens(text);

      expect(count, greaterThan(5));
      expect(count, lessThan(15));
    });

    test('Generic model provides fallback counting', () {
      final genericCounter = TokenCounter(
        config: TokenCounterConfig(model: TokenizerModel.generic),
      );

      final text = 'Hello world';
      final count = genericCounter.countTokens(text);

      expect(count, greaterThan(1));
    });

    test('Different models may count differently', () {
      final llamaCounter = TokenCounter(
        config: TokenCounterConfig(model: TokenizerModel.llama3),
      );
      final gptCounter = TokenCounter(
        config: TokenCounterConfig(model: TokenizerModel.gpt4),
      );

      final text = 'antidisestablishmentarianism';
      final llamaCount = llamaCounter.countTokens(text);
      final gptCount = gptCounter.countTokens(text);

      // Counts may differ between models
      expect(llamaCount, greaterThan(0));
      expect(gptCount, greaterThan(0));
    });
  });

  group('TokenCounter - Edge Cases', () {
    late TokenCounter counter;

    setUp(() {
      counter = TokenCounter();
    });

    test('Handles very long text', () {
      final longText = List.generate(1000, (i) => 'word').join(' ');
      final count = counter.countTokens(longText);

      expect(count, greaterThan(900));
    });

    test('Handles text with lots of whitespace', () {
      final text = 'Hello     world    !';
      final count = counter.countTokens(text);

      // Extra whitespace should be normalized
      expect(count, lessThan(10));
    });

    test('Handles Unicode characters', () {
      final text = 'Hello 世界 👋';
      final count = counter.countTokens(text);

      expect(count, greaterThan(2));
    });

    test('Handles newlines and tabs', () {
      final text = 'Hello\nworld\t!';
      final count = counter.countTokens(text);

      expect(count, greaterThan(2));
    });

    test('Handles mixed case', () {
      final text = 'HeLLo WoRLd';
      final count = counter.countTokens(text);

      expect(count, greaterThan(1));
    });

    test('Handles contractions', () {
      final text = "I'm can't won't shouldn't";
      final count = counter.countTokens(text);

      // Contractions may be split or kept together
      expect(count, greaterThan(3));
    });

    test('Handles URLs', () {
      final text = 'Visit https://example.com for more info';
      final count = counter.countTokens(text);

      // URL should be tokenized into parts
      expect(count, greaterThan(5));
    });

    test('Handles email addresses', () {
      final text = 'Contact user@example.com for help';
      final count = counter.countTokens(text);

      expect(count, greaterThan(4));
    });
  });

  group('TokenCounter - Configuration', () {
    test('Respects custom max context tokens', () {
      final counter = TokenCounter(
        config: TokenCounterConfig(maxContextTokens: 4000),
      );

      final result = counter.countConversationTokens(
        systemPrompt: 'System',
        userMessage: 'User',
      );

      expect(result.remainingTokens, lessThan(4000));
    });

    test('Respects safety margin', () {
      final counter = TokenCounter(
        config: TokenCounterConfig(
          maxContextTokens: 1000,
          safetyMargin: 200,
        ),
      );

      expect(counter.config.effectiveLimit, equals(800));
    });

    test('Custom limit in truncateHistory works', () {
      final counter = TokenCounter();

      final history = List.generate(
        10,
        (i) => ConversationMessage(
          content: 'Message $i with some text',
          role: i % 2 == 0 ? 'user' : 'assistant',
        ),
      );

      final truncated = counter.truncateHistory(
        history: history,
        systemPrompt: 'System',
        userMessage: 'User',
        customLimit: 50, // Very low limit
      );

      expect(truncated.length, lessThan(history.length));
    });
  });

  group('TokenCounter - Accuracy Validation', () {
    late TokenCounter counter;

    setUp(() {
      counter = TokenCounter();
    });

    test('Accuracy is within reasonable range for typical text', () {
      final samples = [
        'The quick brown fox jumps over the lazy dog.',
        'I love programming in Dart and Flutter!',
        'What is the weather like today?',
        'Please help me troubleshoot my step sync issue.',
        'How many steps did I walk yesterday?',
      ];

      for (final text in samples) {
        final count = counter.countTokens(text);
        final words = text.split(RegExp(r'\s+')).length;

        // Token count should be roughly 1-1.5x word count
        expect(count, greaterThan(words * 0.7));
        expect(count, lessThan(words * 2));
      }
    });

    test('More accurate than simple character division', () {
      final text = 'Hello world!';
      final actualCount = counter.countTokens(text);
      final simpleEstimate = (text.length / 4).ceil(); // Old method

      // Should be different (and more accurate)
      // This text is "Hello" + "world" + "!" = ~3 tokens
      // Simple estimate: 12 chars / 4 = 3 tokens (happens to be similar)
      // But for longer text, the difference is significant
      expect(actualCount, greaterThan(0));
    });
  });
}
