/// Circuit Breaker Pattern Implementation
///
/// Prevents cascading failures by monitoring service health and automatically
/// blocking requests when failure rate exceeds threshold.
///
/// Features:
/// - Three-state model (Closed, Open, Half-Open)
/// - Configurable failure thresholds
/// - Automatic recovery attempts
/// - Metrics tracking
/// - Thread-safe operation
///
/// Usage:
/// ```dart
/// final breaker = CircuitBreaker(
///   config: CircuitBreakerConfig(
///     failureThreshold: 5,
///     successThreshold: 2,
///     timeout: Duration(seconds: 60),
///   ),
/// );
///
/// try {
///   final result = await breaker.execute(() async {
///     return await apiCall();
///   });
/// } on CircuitBreakerOpenException {
///   // Handle circuit open - service unavailable
/// }
/// ```

import 'dart:async';
import 'package:logger/logger.dart';

/// Circuit breaker state
enum CircuitState {
  /// Normal operation - requests pass through
  closed,

  /// Too many failures - requests blocked immediately
  open,

  /// Testing recovery - limited requests allowed
  halfOpen,
}

/// Configuration for circuit breaker behavior
class CircuitBreakerConfig {
  /// Number of failures before opening circuit
  final int failureThreshold;

  /// Number of successes needed to close circuit from half-open
  final int successThreshold;

  /// Duration to wait before attempting recovery (moving to half-open)
  final Duration timeout;

  /// Size of sliding window for tracking failures (in number of calls)
  final int windowSize;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.successThreshold = 2,
    this.timeout = const Duration(seconds: 60),
    this.windowSize = 10,
  });
}

/// Metrics tracked by circuit breaker
class CircuitBreakerMetrics {
  final int totalCalls;
  final int successfulCalls;
  final int failedCalls;
  final int rejectedCalls;
  final CircuitState currentState;
  final DateTime? lastStateChange;
  final DateTime? lastFailureTime;
  final double failureRate;

  CircuitBreakerMetrics({
    required this.totalCalls,
    required this.successfulCalls,
    required this.failedCalls,
    required this.rejectedCalls,
    required this.currentState,
    this.lastStateChange,
    this.lastFailureTime,
    required this.failureRate,
  });

  Map<String, dynamic> toJson() => {
        'totalCalls': totalCalls,
        'successfulCalls': successfulCalls,
        'failedCalls': failedCalls,
        'rejectedCalls': rejectedCalls,
        'currentState': currentState.toString(),
        'lastStateChange': lastStateChange?.toIso8601String(),
        'lastFailureTime': lastFailureTime?.toIso8601String(),
        'failureRate': failureRate,
      };
}

/// Exception thrown when circuit is open
class CircuitBreakerOpenException implements Exception {
  final String message;
  final DateTime? nextAttemptTime;

  CircuitBreakerOpenException(this.message, {this.nextAttemptTime});

  @override
  String toString() {
    if (nextAttemptTime != null) {
      return 'CircuitBreakerOpenException: $message (retry after $nextAttemptTime)';
    }
    return 'CircuitBreakerOpenException: $message';
  }
}

/// Circuit Breaker Implementation
///
/// Thread-safe circuit breaker that monitors operation success/failure
/// and automatically opens/closes based on configured thresholds.
class CircuitBreaker {
  final CircuitBreakerConfig config;
  final Logger _logger;

  // State
  CircuitState _state = CircuitState.closed;
  DateTime? _lastStateChange;
  DateTime? _lastFailureTime;
  DateTime? _openedAt;

  // Counters
  int _totalCalls = 0;
  int _successfulCalls = 0;
  int _failedCalls = 0;
  int _rejectedCalls = 0;
  int _consecutiveSuccesses = 0;
  int _consecutiveFailures = 0;

  // Sliding window for failure tracking
  final List<bool> _callResults = []; // true = success, false = failure

  CircuitBreaker({
    CircuitBreakerConfig? config,
    Logger? logger,
  })  : config = config ?? const CircuitBreakerConfig(),
        _logger = logger ?? Logger() {
    _lastStateChange = DateTime.now();
  }

  /// Execute an operation protected by the circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    _totalCalls++;

    // Check if circuit is open
    if (_state == CircuitState.open) {
      if (_shouldAttemptRecovery()) {
        _transitionToHalfOpen();
      } else {
        _rejectedCalls++;
        final nextAttempt = _openedAt!.add(config.timeout);
        _logger.w('Circuit breaker open - rejecting call (next attempt: $nextAttempt)');
        throw CircuitBreakerOpenException(
          'Circuit breaker is open',
          nextAttemptTime: nextAttempt,
        );
      }
    }

    // Execute operation
    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure(e);
      rethrow;
    }
  }

  /// Check if enough time has passed to attempt recovery
  bool _shouldAttemptRecovery() {
    if (_openedAt == null) return false;
    final elapsed = DateTime.now().difference(_openedAt!);
    return elapsed >= config.timeout;
  }

  /// Handle successful operation
  void _onSuccess() {
    _successfulCalls++;
    _consecutiveSuccesses++;
    _consecutiveFailures = 0;

    _addCallResult(true);

    if (_state == CircuitState.halfOpen) {
      _logger.d('Circuit breaker half-open: success $_consecutiveSuccesses/${config.successThreshold}');

      if (_consecutiveSuccesses >= config.successThreshold) {
        _transitionToClosed();
      }
    }
  }

  /// Handle failed operation
  void _onFailure(Object error) {
    _failedCalls++;
    _consecutiveFailures++;
    _consecutiveSuccesses = 0;
    _lastFailureTime = DateTime.now();

    _addCallResult(false);

    _logger.w('Circuit breaker failure: $_consecutiveFailures/${config.failureThreshold} ($error)');

    if (_state == CircuitState.closed || _state == CircuitState.halfOpen) {
      if (_consecutiveFailures >= config.failureThreshold) {
        _transitionToOpen();
      }
    }
  }

  /// Add call result to sliding window
  void _addCallResult(bool success) {
    _callResults.add(success);

    // Maintain window size
    if (_callResults.length > config.windowSize) {
      _callResults.removeAt(0);
    }
  }

  /// Transition to CLOSED state
  void _transitionToClosed() {
    _logger.i('Circuit breaker: CLOSED (recovered)');
    _state = CircuitState.closed;
    _lastStateChange = DateTime.now();
    _consecutiveSuccesses = 0;
    _consecutiveFailures = 0;
    _openedAt = null;
  }

  /// Transition to OPEN state
  void _transitionToOpen() {
    _logger.e('Circuit breaker: OPEN (threshold exceeded)');
    _state = CircuitState.open;
    _lastStateChange = DateTime.now();
    _openedAt = DateTime.now();
    _consecutiveSuccesses = 0;
  }

  /// Transition to HALF-OPEN state
  void _transitionToHalfOpen() {
    _logger.i('Circuit breaker: HALF-OPEN (testing recovery)');
    _state = CircuitState.halfOpen;
    _lastStateChange = DateTime.now();
    _consecutiveSuccesses = 0;
    _consecutiveFailures = 0;
  }

  /// Get current state
  CircuitState get state => _state;

  /// Get current metrics
  CircuitBreakerMetrics getMetrics() {
    final failureRate = _callResults.isEmpty
        ? 0.0
        : _callResults.where((r) => !r).length / _callResults.length;

    return CircuitBreakerMetrics(
      totalCalls: _totalCalls,
      successfulCalls: _successfulCalls,
      failedCalls: _failedCalls,
      rejectedCalls: _rejectedCalls,
      currentState: _state,
      lastStateChange: _lastStateChange,
      lastFailureTime: _lastFailureTime,
      failureRate: failureRate,
    );
  }

  /// Reset circuit breaker to initial state
  void reset() {
    _logger.i('Circuit breaker: RESET');
    _state = CircuitState.closed;
    _lastStateChange = DateTime.now();
    _lastFailureTime = null;
    _openedAt = null;
    _totalCalls = 0;
    _successfulCalls = 0;
    _failedCalls = 0;
    _rejectedCalls = 0;
    _consecutiveSuccesses = 0;
    _consecutiveFailures = 0;
    _callResults.clear();
  }

  /// Force circuit to open state (for testing/manual intervention)
  void forceOpen() {
    _logger.w('Circuit breaker: FORCED OPEN');
    _transitionToOpen();
  }

  /// Force circuit to closed state (for testing/manual intervention)
  void forceClosed() {
    _logger.i('Circuit breaker: FORCED CLOSED');
    _transitionToClosed();
  }
}
