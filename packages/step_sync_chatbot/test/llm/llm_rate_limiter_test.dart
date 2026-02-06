import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/llm/llm_rate_limiter.dart';
import 'package:step_sync_chatbot/src/llm/llm_response.dart';

void main() {
  group('LLMRateLimiter', () {
    late LLMRateLimiter rateLimiter;

    setUp(() {
      rateLimiter = LLMRateLimiter(
        maxCallsPerHour: 100,
        maxCallsPerUserPerHour: 50,
        maxHourlyCostUSD: 10.0,
      );
    });

    tearDown(() {
      rateLimiter.reset();
    });

    group('Basic Rate Limiting', () {
      test('allows first call', () {
        // Arrange
        const userId = 'user123';

        // Act
        final canCall = rateLimiter.canMakeCall(userId);

        // Assert
        expect(canCall, isTrue);
      });

      test('blocks after exceeding per-user limit', () {
        // Arrange
        const userId = 'user123';
        rateLimiter = LLMRateLimiter(maxCallsPerUserPerHour: 3);

        // Act - Make 3 calls
        for (var i = 0; i < 3; i++) {
          expect(rateLimiter.canMakeCall(userId), isTrue);
          rateLimiter.recordCall(userId, _createMockResponse());
        }

        // Assert - 4th call should be blocked
        expect(rateLimiter.canMakeCall(userId), isFalse);
      });

      test('blocks after exceeding global limit', () {
        // Arrange
        rateLimiter = LLMRateLimiter(maxCallsPerHour: 5);

        // Act - Make 5 calls from different users
        for (var i = 0; i < 5; i++) {
          final userId = 'user$i';
          expect(rateLimiter.canMakeCall(userId), isTrue);
          rateLimiter.recordCall(userId, _createMockResponse());
        }

        // Assert - 6th call from new user should be blocked
        expect(rateLimiter.canMakeCall('user999'), isFalse);
      });

      test('allows different users independently', () {
        // Arrange
        rateLimiter = LLMRateLimiter(
          maxCallsPerHour: 100,
          maxCallsPerUserPerHour: 3,
        );

        // Act - User1 makes 3 calls
        for (var i = 0; i < 3; i++) {
          expect(rateLimiter.canMakeCall('user1'), isTrue);
          rateLimiter.recordCall('user1', _createMockResponse());
        }

        // Assert - User2 can still make calls
        expect(rateLimiter.canMakeCall('user2'), isTrue);
        rateLimiter.recordCall('user2', _createMockResponse());
        expect(rateLimiter.canMakeCall('user2'), isTrue);
      });
    });

    group('Cost-Based Limiting', () {
      test('blocks when cost limit exceeded', () {
        // Arrange
        rateLimiter = LLMRateLimiter(maxHourlyCostUSD: 1.0);
        const userId = 'user123';

        // Act - Make expensive call that exceeds budget
        rateLimiter.recordCall(
          userId,
          _createMockResponse(cost: 1.5),
        );

        // Assert - Next call should be blocked due to cost
        expect(rateLimiter.canMakeCall(userId), isFalse);
      });

      test('tracks cumulative cost', () {
        // Arrange
        rateLimiter = LLMRateLimiter(maxHourlyCostUSD: 1.0);
        const userId = 'user123';

        // Act - Make multiple cheap calls
        for (var i = 0; i < 5; i++) {
          rateLimiter.recordCall(
            userId,
            _createMockResponse(cost: 0.15),
          );
        }

        // Assert - Total cost = 0.75, should still allow
        expect(rateLimiter.canMakeCall(userId), isTrue);

        // Act - One more call brings total to 0.90
        rateLimiter.recordCall(userId, _createMockResponse(cost: 0.15));
        expect(rateLimiter.canMakeCall(userId), isTrue);

        // Act - Another call would exceed budget
        rateLimiter.recordCall(userId, _createMockResponse(cost: 0.15));
        expect(rateLimiter.canMakeCall(userId), isFalse);
      });
    });

    group('Statistics', () {
      test('getStats returns correct call count', () {
        // Arrange
        const userId = 'user123';

        // Act
        for (var i = 0; i < 5; i++) {
          rateLimiter.recordCall(userId, _createMockResponse());
        }

        final stats = rateLimiter.getStats();

        // Assert
        expect(stats.callsInLastHour, 5);
        expect(stats.totalCalls, 5);
      });

      test('getStats returns correct cost', () {
        // Arrange
        const userId = 'user123';

        // Act
        rateLimiter.recordCall(userId, _createMockResponse(cost: 0.10));
        rateLimiter.recordCall(userId, _createMockResponse(cost: 0.20));
        rateLimiter.recordCall(userId, _createMockResponse(cost: 0.30));

        final stats = rateLimiter.getStats();

        // Assert
        expect(stats.totalCostUSD, closeTo(0.60, 0.001));
      });

      test('getStats returns correct remaining budget', () {
        // Arrange
        rateLimiter = LLMRateLimiter(maxHourlyCostUSD: 5.0);
        const userId = 'user123';

        // Act
        rateLimiter.recordCall(userId, _createMockResponse(cost: 1.50));

        final stats = rateLimiter.getStats();

        // Assert
        expect(stats.remainingBudgetUSD, closeTo(3.50, 0.001));
      });

      test('getStats calculates average response time', () {
        // Arrange
        const userId = 'user123';

        // Act
        rateLimiter.recordCall(userId, _createMockResponse(responseTimeMs: 100));
        rateLimiter.recordCall(userId, _createMockResponse(responseTimeMs: 200));
        rateLimiter.recordCall(userId, _createMockResponse(responseTimeMs: 300));

        final stats = rateLimiter.getStats();

        // Assert
        expect(stats.averageResponseTimeMs, 200);
      });

      test('getStats tracks total tokens', () {
        // Arrange
        const userId = 'user123';

        // Act
        rateLimiter.recordCall(
          userId,
          _createMockResponse(promptTokens: 50, completionTokens: 100),
        );
        rateLimiter.recordCall(
          userId,
          _createMockResponse(promptTokens: 30, completionTokens: 70),
        );

        final stats = rateLimiter.getStats();

        // Assert
        expect(stats.totalTokensUsed, 250); // 150 + 100
      });

      test('getUserStats returns user-specific data', () {
        // Arrange
        const userId1 = 'user1';
        const userId2 = 'user2';

        // Act
        for (var i = 0; i < 3; i++) {
          rateLimiter.recordCall(userId1, _createMockResponse());
        }
        rateLimiter.recordCall(userId2, _createMockResponse());

        final user1Stats = rateLimiter.getUserStats(userId1);
        final user2Stats = rateLimiter.getUserStats(userId2);

        // Assert
        expect(user1Stats.callsInLastHour, 3);
        expect(user2Stats.callsInLastHour, 1);
      });

      test('getUserStats calculates remaining calls', () {
        // Arrange
        rateLimiter = LLMRateLimiter(maxCallsPerUserPerHour: 10);
        const userId = 'user123';

        // Act
        for (var i = 0; i < 3; i++) {
          rateLimiter.recordCall(userId, _createMockResponse());
        }

        final stats = rateLimiter.getUserStats(userId);

        // Assert
        expect(stats.remainingCallsThisHour, 7);
      });
    });

    group('Reset Functionality', () {
      test('reset clears all data', () {
        // Arrange
        const userId = 'user123';
        for (var i = 0; i < 5; i++) {
          rateLimiter.recordCall(userId, _createMockResponse(cost: 0.10));
        }

        // Act
        rateLimiter.reset();

        // Assert
        final stats = rateLimiter.getStats();
        expect(stats.callsInLastHour, 0);
        expect(stats.totalCostUSD, 0.0);
        expect(stats.totalTokensUsed, 0);
      });

      test('allows calls after reset', () {
        // Arrange
        rateLimiter = LLMRateLimiter(maxCallsPerUserPerHour: 2);
        const userId = 'user123';

        // Fill up limit
        rateLimiter.recordCall(userId, _createMockResponse());
        rateLimiter.recordCall(userId, _createMockResponse());
        expect(rateLimiter.canMakeCall(userId), isFalse);

        // Act
        rateLimiter.reset();

        // Assert
        expect(rateLimiter.canMakeCall(userId), isTrue);
      });
    });

    group('Edge Cases', () {
      test('handles zero-cost responses', () {
        // Arrange
        const userId = 'user123';

        // Act
        rateLimiter.recordCall(userId, _createMockResponse(cost: 0.0));

        final stats = rateLimiter.getStats();

        // Assert
        expect(stats.totalCostUSD, 0.0);
      });

      test('handles new user', () {
        // Arrange
        const newUser = 'brand_new_user';

        // Act
        final stats = rateLimiter.getUserStats(newUser);

        // Assert
        expect(stats.callsInLastHour, 0);
        expect(stats.remainingCallsThisHour, rateLimiter.maxCallsPerUserPerHour);
      });

      test('toString methods work', () {
        // Arrange
        const userId = 'user123';
        rateLimiter.recordCall(userId, _createMockResponse());

        // Act
        final globalStats = rateLimiter.getStats().toString();
        final userStats = rateLimiter.getUserStats(userId).toString();

        // Assert
        expect(globalStats, contains('LLM Usage Stats'));
        expect(userStats, contains('LLM Stats'));
      });
    });
  });
}

/// Helper function to create mock LLM responses for testing.
LLMResponse _createMockResponse({
  double cost = 0.001,
  int responseTimeMs = 100,
  int promptTokens = 10,
  int completionTokens = 20,
}) {
  return LLMResponse(
    text: 'Mock response',
    provider: 'Mock',
    model: 'mock-model',
    promptTokens: promptTokens,
    completionTokens: completionTokens,
    totalTokens: promptTokens + completionTokens,
    estimatedCost: cost,
    responseTimeMs: responseTimeMs,
    success: true,
    timestamp: DateTime.now(),
  );
}
