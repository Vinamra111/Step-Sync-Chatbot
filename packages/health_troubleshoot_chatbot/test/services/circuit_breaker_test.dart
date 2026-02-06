/// Tests for Circuit Breaker Pattern
///
/// Validates:
/// - State transitions (Closed → Open → Half-Open → Closed)
/// - Failure threshold detection
/// - Automatic recovery
/// - Metrics accuracy
/// - Concurrent operation safety
/// - Error handling

import 'package:test/test.dart';
import 'package:logger/logger.dart';
import '../../lib/src/services/circuit_breaker.dart';

void main() {
  group('CircuitBreaker - Basic State Transitions', () {
    late CircuitBreaker breaker;

    setUp(() {
      breaker = CircuitBreaker(
        config: CircuitBreakerConfig(
          failureThreshold: 3,
          successThreshold: 2,
          timeout: Duration(milliseconds: 100),
        ),
        logger: Logger(level: Level.off),
      );
    });

    test('Starts in CLOSED state', () {
      expect(breaker.state, equals(CircuitState.closed));
    });

    test('Remains CLOSED with successful calls', () async {
      for (int i = 0; i < 5; i++) {
        await breaker.execute(() async => 'success');
      }

      expect(breaker.state, equals(CircuitState.closed));

      final metrics = breaker.getMetrics();
      expect(metrics.successfulCalls, equals(5));
      expect(metrics.failedCalls, equals(0));
    });

    test('Transitions to OPEN after failure threshold', () async {
      // Fail 3 times (threshold)
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('Failure $i'));
        } catch (e) {
          // Expected
        }
      }

      expect(breaker.state, equals(CircuitState.open));
    });

    test('Stays CLOSED if failures below threshold', () async {
      // Fail 2 times (below threshold of 3)
      for (int i = 0; i < 2; i++) {
        try {
          await breaker.execute(() async => throw Exception('Failure'));
        } catch (e) {
          // Expected
        }
      }

      expect(breaker.state, equals(CircuitState.closed));
    });

    test('Rejects calls when OPEN', () async {
      // Force to OPEN state
      breaker.forceOpen();

      expect(
        () => breaker.execute(() async => 'test'),
        throwsA(isA<CircuitBreakerOpenException>()),
      );
    });

    test('Transitions to HALF-OPEN after timeout', () async {
      // Open circuit
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('Failure'));
        } catch (e) {}
      }

      expect(breaker.state, equals(CircuitState.open));

      // Wait for timeout
      await Future.delayed(Duration(milliseconds: 150));

      // Next call should transition to HALF-OPEN
      try {
        await breaker.execute(() async => 'test');
      } catch (e) {}

      expect(breaker.state, equals(CircuitState.halfOpen));
    });

    test('Transitions HALF-OPEN to CLOSED after success threshold', () async {
      breaker.forceOpen();

      // Wait for timeout
      await Future.delayed(Duration(milliseconds: 150));

      // First call transitions to HALF-OPEN
      await breaker.execute(() async => 'success1');
      expect(breaker.state, equals(CircuitState.halfOpen));

      // Second success should close circuit
      await breaker.execute(() async => 'success2');
      expect(breaker.state, equals(CircuitState.closed));
    });

    test('Transitions HALF-OPEN back to OPEN on failure', () async {
      breaker.forceOpen();

      // Wait for timeout
      await Future.delayed(Duration(milliseconds: 150));

      // Transition to HALF-OPEN with success
      await breaker.execute(() async => 'success');
      expect(breaker.state, equals(CircuitState.halfOpen));

      // Fail threshold times to re-open
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('Failure'));
        } catch (e) {}
      }

      expect(breaker.state, equals(CircuitState.open));
    });
  });

  group('CircuitBreaker - Metrics Tracking', () {
    late CircuitBreaker breaker;

    setUp(() {
      breaker = CircuitBreaker(
        config: CircuitBreakerConfig(
          failureThreshold: 5,
          successThreshold: 2,
          timeout: Duration(seconds: 60),
        ),
        logger: Logger(level: Level.off),
      );
    });

    test('Tracks successful calls', () async {
      await breaker.execute(() async => 'success1');
      await breaker.execute(() async => 'success2');
      await breaker.execute(() async => 'success3');

      final metrics = breaker.getMetrics();

      expect(metrics.successfulCalls, equals(3));
      expect(metrics.failedCalls, equals(0));
      expect(metrics.totalCalls, equals(3));
    });

    test('Tracks failed calls', () async {
      for (int i = 0; i < 4; i++) {
        try {
          await breaker.execute(() async => throw Exception('Failure'));
        } catch (e) {}
      }

      final metrics = breaker.getMetrics();

      expect(metrics.failedCalls, equals(4));
      expect(metrics.successfulCalls, equals(0));
      expect(metrics.totalCalls, equals(4));
    });

    test('Tracks rejected calls when OPEN', () async {
      breaker.forceOpen();

      for (int i = 0; i < 5; i++) {
        try {
          await breaker.execute(() async => 'test');
        } on CircuitBreakerOpenException {}
      }

      final metrics = breaker.getMetrics();

      expect(metrics.rejectedCalls, equals(5));
    });

    test('Calculates failure rate correctly', () async {
      // 3 successes, 2 failures = 40% failure rate
      await breaker.execute(() async => 'success1');
      await breaker.execute(() async => 'success2');
      try {
        await breaker.execute(() async => throw Exception('Failure1'));
      } catch (e) {}
      await breaker.execute(() async => 'success3');
      try {
        await breaker.execute(() async => throw Exception('Failure2'));
      } catch (e) {}

      final metrics = breaker.getMetrics();

      expect(metrics.failureRate, closeTo(0.4, 0.01));
    });

    test('Records last failure time', () async {
      final beforeFailure = DateTime.now();

      // Add small delay to ensure timestamp difference
      await Future.delayed(Duration(milliseconds: 10));

      try {
        await breaker.execute(() async => throw Exception('Failure'));
      } catch (e) {}

      await Future.delayed(Duration(milliseconds: 10));
      final afterFailure = DateTime.now();
      final metrics = breaker.getMetrics();

      expect(metrics.lastFailureTime, isNotNull);
      expect(
        metrics.lastFailureTime!.isAfter(beforeFailure) ||
            metrics.lastFailureTime!.isAtSameMomentAs(beforeFailure),
        isTrue,
      );
      expect(
        metrics.lastFailureTime!.isBefore(afterFailure) ||
            metrics.lastFailureTime!.isAtSameMomentAs(afterFailure),
        isTrue,
      );
    });

    test('Exports metrics to JSON', () async {
      await breaker.execute(() async => 'success');

      final metrics = breaker.getMetrics();
      final json = metrics.toJson();

      expect(json['totalCalls'], equals(1));
      expect(json['successfulCalls'], equals(1));
      expect(json['currentState'], contains('closed'));
    });
  });

  group('CircuitBreaker - Edge Cases', () {
    late CircuitBreaker breaker;

    setUp(() {
      breaker = CircuitBreaker(
        config: CircuitBreakerConfig(
          failureThreshold: 3,
          successThreshold: 2,
        ),
        logger: Logger(level: Level.off),
      );
    });

    test('Handles mixed success/failure patterns', () async {
      // Alternating success/failure - should not trip
      for (int i = 0; i < 10; i++) {
        if (i % 2 == 0) {
          await breaker.execute(() async => 'success');
        } else {
          try {
            await breaker.execute(() async => throw Exception('Failure'));
          } catch (e) {}
        }
      }

      // Should still be closed (no consecutive failures)
      expect(breaker.state, equals(CircuitState.closed));
    });

    test('Resets consecutive counters after success', () async {
      // 2 failures (below threshold)
      try {
        await breaker.execute(() async => throw Exception('Failure1'));
      } catch (e) {}
      try {
        await breaker.execute(() async => throw Exception('Failure2'));
      } catch (e) {}

      // 1 success resets counter
      await breaker.execute(() async => 'success');

      // 2 more failures (should not trip since counter reset)
      try {
        await breaker.execute(() async => throw Exception('Failure3'));
      } catch (e) {}
      try {
        await breaker.execute(() async => throw Exception('Failure4'));
      } catch (e) {}

      expect(breaker.state, equals(CircuitState.closed));
    });

    test('Handles exactly at threshold', () async {
      // Exactly 3 failures (threshold)
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('Failure'));
        } catch (e) {}
      }

      expect(breaker.state, equals(CircuitState.open));
    });

    test('Exception details are preserved', () async {
      final customException = Exception('Custom error message');

      try {
        await breaker.execute(() async => throw customException);
        fail('Should have thrown');
      } catch (e) {
        expect(e, equals(customException));
      }
    });

    test('CircuitBreakerOpenException includes next attempt time', () async {
      breaker.forceOpen();

      try {
        await breaker.execute(() async => 'test');
        fail('Should have thrown');
      } on CircuitBreakerOpenException catch (e) {
        expect(e.nextAttemptTime, isNotNull);
        expect(e.message, equals('Circuit breaker is open'));
      }
    });
  });

  group('CircuitBreaker - Reset and Manual Control', () {
    late CircuitBreaker breaker;

    setUp(() {
      breaker = CircuitBreaker(
        config: CircuitBreakerConfig(failureThreshold: 3),
        logger: Logger(level: Level.off),
      );
    });

    test('Reset clears all state', () async {
      // Generate some activity
      await breaker.execute(() async => 'success');
      try {
        await breaker.execute(() async => throw Exception('Failure'));
      } catch (e) {}

      breaker.reset();

      final metrics = breaker.getMetrics();
      expect(metrics.totalCalls, equals(0));
      expect(metrics.successfulCalls, equals(0));
      expect(metrics.failedCalls, equals(0));
      expect(breaker.state, equals(CircuitState.closed));
    });

    test('forceOpen manually opens circuit', () {
      breaker.forceOpen();
      expect(breaker.state, equals(CircuitState.open));
    });

    test('forceClosed manually closes circuit', () {
      breaker.forceOpen();
      expect(breaker.state, equals(CircuitState.open));

      breaker.forceClosed();
      expect(breaker.state, equals(CircuitState.closed));
    });

    test('Reset from OPEN state', () async {
      breaker.forceOpen();
      breaker.reset();

      // Should be able to execute calls again
      final result = await breaker.execute(() async => 'success');
      expect(result, equals('success'));
    });
  });

  group('CircuitBreaker - Concurrent Operations', () {
    late CircuitBreaker breaker;

    setUp(() {
      breaker = CircuitBreaker(
        config: CircuitBreakerConfig(
          failureThreshold: 10,
          successThreshold: 5,
        ),
        logger: Logger(level: Level.off),
      );
    });

    test('Handles concurrent successful calls', () async {
      final futures = <Future>[];

      for (int i = 0; i < 20; i++) {
        futures.add(breaker.execute(() async => 'success $i'));
      }

      await Future.wait(futures);

      final metrics = breaker.getMetrics();
      expect(metrics.successfulCalls, equals(20));
      expect(breaker.state, equals(CircuitState.closed));
    });

    test('Handles concurrent failed calls', () async {
      final futures = <Future>[];

      for (int i = 0; i < 15; i++) {
        futures.add(
          breaker
              .execute<String>(() async => throw Exception('Failure $i'))
              .then((_) {}, onError: (_) {}),
        );
      }

      await Future.wait(futures);

      final metrics = breaker.getMetrics();
      expect(metrics.failedCalls, equals(15));
      expect(breaker.state, equals(CircuitState.open));
    });

    test('Handles mixed concurrent operations', () async {
      final futures = <Future>[];

      // Mix of successes and failures
      for (int i = 0; i < 30; i++) {
        if (i % 3 == 0) {
          futures.add(
            breaker
                .execute<String>(() async => throw Exception('Failure'))
                .then((_) {}, onError: (_) {}),
          );
        } else {
          futures.add(breaker.execute(() async => 'success'));
        }
      }

      await Future.wait(futures);

      final metrics = breaker.getMetrics();
      expect(metrics.totalCalls, equals(30));
    });
  });

  group('CircuitBreaker - Configuration Variations', () {
    test('Works with low thresholds', () async {
      final breaker = CircuitBreaker(
        config: CircuitBreakerConfig(
          failureThreshold: 1,
          successThreshold: 1,
        ),
        logger: Logger(level: Level.off),
      );

      // Single failure opens
      try {
        await breaker.execute(() async => throw Exception('Failure'));
      } catch (e) {}

      expect(breaker.state, equals(CircuitState.open));
    });

    test('Works with high thresholds', () async {
      final breaker = CircuitBreaker(
        config: CircuitBreakerConfig(
          failureThreshold: 100,
          successThreshold: 50,
        ),
        logger: Logger(level: Level.off),
      );

      // 99 failures should not trip
      for (int i = 0; i < 99; i++) {
        try {
          await breaker.execute(() async => throw Exception('Failure'));
        } catch (e) {}
      }

      expect(breaker.state, equals(CircuitState.closed));

      // 100th failure trips
      try {
        await breaker.execute(() async => throw Exception('Failure 100'));
      } catch (e) {}

      expect(breaker.state, equals(CircuitState.open));
    });

    test('Works with custom window size', () async {
      final breaker = CircuitBreaker(
        config: CircuitBreakerConfig(
          failureThreshold: 5,
          windowSize: 20,
        ),
        logger: Logger(level: Level.off),
      );

      // Generate 20 calls
      for (int i = 0; i < 20; i++) {
        await breaker.execute(() async => 'success');
      }

      final metrics = breaker.getMetrics();
      expect(metrics.totalCalls, equals(20));
      expect(metrics.failureRate, equals(0.0));
    });
  });
}
