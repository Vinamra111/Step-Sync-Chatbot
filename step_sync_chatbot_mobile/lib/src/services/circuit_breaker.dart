/// Circuit Breaker Pattern - Prevents Cascade Failures
///
/// Automatically fails fast when external API (Groq) is down/slow,
/// preventing app hangs and providing graceful degradation.

import 'dart:async';

/// Circuit breaker state
enum CircuitState {
  /// Circuit is closed, calls are allowed
  closed,

  /// Circuit is open, calls are blocked
  open,

  /// Circuit is half-open, testing if service recovered
  halfOpen,
}

/// Circuit breaker for API calls
class CircuitBreaker {
  /// Current state
  CircuitState _state = CircuitState.closed;
  CircuitState get state => _state;

  /// Failure count in current window
  int _failureCount = 0;

  /// Success count in half-open state
  int _successCount = 0;

  /// Timestamp when circuit was opened
  DateTime? _openedAt;

  /// Configuration
  final int failureThreshold;
  final Duration timeout;
  final int successThreshold;

  CircuitBreaker({
    this.failureThreshold = 5, // Open after 5 failures
    this.timeout = const Duration(seconds: 60), // Stay open for 60s
    this.successThreshold = 2, // Close after 2 successes
  });

  /// Execute a function with circuit breaker protection
  Future<T> execute<T>(
    Future<T> Function() operation, {
    required T Function() fallback,
  }) async {
    // Check if circuit should transition from OPEN to HALF_OPEN
    if (_state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitState.halfOpen;
        _successCount = 0;
      } else {
        // Circuit still open, use fallback immediately
        return fallback();
      }
    }

    // If circuit is OPEN, fail fast
    if (_state == CircuitState.open) {
      return fallback();
    }

    try {
      // Execute the operation
      final result = await operation();

      // Record success
      _onSuccess();

      return result;
    } catch (error) {
      // Record failure
      _onFailure();

      // Use fallback
      return fallback();
    }
  }

  /// Record a successful call
  void _onSuccess() {
    if (_state == CircuitState.halfOpen) {
      _successCount++;

      // Close circuit after enough successes
      if (_successCount >= successThreshold) {
        _state = CircuitState.closed;
        _failureCount = 0;
        _openedAt = null;
      }
    } else if (_state == CircuitState.closed) {
      // Reset failure count on success
      _failureCount = 0;
    }
  }

  /// Record a failed call
  void _onFailure() {
    if (_state == CircuitState.halfOpen) {
      // If test call failed, reopen circuit
      _state = CircuitState.open;
      _openedAt = DateTime.now();
    } else if (_state == CircuitState.closed) {
      _failureCount++;

      // Open circuit if threshold exceeded
      if (_failureCount >= failureThreshold) {
        _state = CircuitState.open;
        _openedAt = DateTime.now();
      }
    }
  }

  /// Check if enough time has passed to attempt reset
  bool _shouldAttemptReset() {
    if (_openedAt == null) return false;

    final elapsed = DateTime.now().difference(_openedAt!);
    return elapsed >= timeout;
  }

  /// Reset circuit breaker to closed state
  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _openedAt = null;
  }

  /// Get current status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'state': _state.name,
      'failureCount': _failureCount,
      'successCount': _successCount,
      'openedAt': _openedAt?.toIso8601String(),
      'timeUntilReset': _openedAt != null
          ? timeout.inSeconds - DateTime.now().difference(_openedAt!).inSeconds
          : 0,
    };
  }
}
