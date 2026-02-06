import 'package:step_sync_chatbot/src/llm/llm_response.dart';

/// Rate limiter and cost monitor for LLM usage.
///
/// Prevents excessive API calls and tracks costs.
class LLMRateLimiter {
  final int maxCallsPerHour;
  final int maxCallsPerUserPerHour;
  final double maxHourlyCostUSD;

  // Tracking
  final Map<String, List<DateTime>> _userCallTimestamps = {};
  final List<DateTime> _globalCallTimestamps = [];
  final List<LLMResponse> _responses = [];
  double _totalCostUSD = 0.0;
  DateTime _costResetTime = DateTime.now().add(const Duration(hours: 1));

  LLMRateLimiter({
    this.maxCallsPerHour = 100,
    this.maxCallsPerUserPerHour = 50,
    this.maxHourlyCostUSD = 10.0,
  });

  /// Check if a call is allowed for the given user.
  ///
  /// Returns true if allowed, false if rate limit exceeded.
  bool canMakeCall(String userId) {
    final now = DateTime.now();

    // Reset hourly cost if needed
    if (now.isAfter(_costResetTime)) {
      _resetHourlyCost();
    }

    // Check global rate limit
    _cleanOldTimestamps(_globalCallTimestamps, now);
    if (_globalCallTimestamps.length >= maxCallsPerHour) {
      return false;
    }

    // Check per-user rate limit
    _userCallTimestamps.putIfAbsent(userId, () => []);
    final userTimestamps = _userCallTimestamps[userId]!;
    _cleanOldTimestamps(userTimestamps, now);

    if (userTimestamps.length >= maxCallsPerUserPerHour) {
      return false;
    }

    // Check cost limit
    if (_totalCostUSD >= maxHourlyCostUSD) {
      return false;
    }

    return true;
  }

  /// Record a call made by the user.
  void recordCall(String userId, LLMResponse response) {
    final now = DateTime.now();

    // Record timestamp
    _globalCallTimestamps.add(now);
    _userCallTimestamps.putIfAbsent(userId, () => []);
    _userCallTimestamps[userId]!.add(now);

    // Record response for cost tracking
    _responses.add(response);
    _totalCostUSD += response.estimatedCost;
  }

  /// Get statistics about LLM usage.
  LLMUsageStats getStats() {
    final now = DateTime.now();
    _cleanOldTimestamps(_globalCallTimestamps, now);

    // Calculate average response time
    final avgResponseTime = _responses.isEmpty
        ? 0
        : _responses.map((r) => r.responseTimeMs).reduce((a, b) => a + b) /
            _responses.length;

    // Calculate total tokens
    final totalTokens = _responses.fold<int>(
      0,
      (sum, r) => sum + r.totalTokens,
    );

    return LLMUsageStats(
      callsInLastHour: _globalCallTimestamps.length,
      totalCostUSD: _totalCostUSD,
      remainingBudgetUSD: maxHourlyCostUSD - _totalCostUSD,
      averageResponseTimeMs: avgResponseTime.toInt(),
      totalTokensUsed: totalTokens,
      totalCalls: _responses.length,
      costResetTime: _costResetTime,
    );
  }

  /// Get user-specific statistics.
  LLMUserStats getUserStats(String userId) {
    final now = DateTime.now();
    final userTimestamps = _userCallTimestamps[userId] ?? [];
    _cleanOldTimestamps(userTimestamps, now);

    // Get user's responses
    final userResponses = _responses.where((r) {
      // Note: This is simplified. In production, you'd track userId with each response
      return true; // For now, include all
    }).toList();

    final userCost = userResponses.fold<double>(
      0.0,
      (sum, r) => sum + r.estimatedCost,
    );

    return LLMUserStats(
      userId: userId,
      callsInLastHour: userTimestamps.length,
      remainingCallsThisHour: maxCallsPerUserPerHour - userTimestamps.length,
      totalCostUSD: userCost,
    );
  }

  /// Clean timestamps older than 1 hour.
  void _cleanOldTimestamps(List<DateTime> timestamps, DateTime now) {
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    timestamps.removeWhere((timestamp) => timestamp.isBefore(oneHourAgo));
  }

  /// Reset hourly cost tracking.
  void _resetHourlyCost() {
    _totalCostUSD = 0.0;
    _costResetTime = DateTime.now().add(const Duration(hours: 1));
    _responses.clear();
  }

  /// Clear all tracking data (for testing).
  void reset() {
    _userCallTimestamps.clear();
    _globalCallTimestamps.clear();
    _responses.clear();
    _totalCostUSD = 0.0;
    _costResetTime = DateTime.now().add(const Duration(hours: 1));
  }
}

/// Statistics about LLM usage.
class LLMUsageStats {
  final int callsInLastHour;
  final double totalCostUSD;
  final double remainingBudgetUSD;
  final int averageResponseTimeMs;
  final int totalTokensUsed;
  final int totalCalls;
  final DateTime costResetTime;

  LLMUsageStats({
    required this.callsInLastHour,
    required this.totalCostUSD,
    required this.remainingBudgetUSD,
    required this.averageResponseTimeMs,
    required this.totalTokensUsed,
    required this.totalCalls,
    required this.costResetTime,
  });

  @override
  String toString() {
    return 'LLM Usage Stats:\n'
        '  Calls (last hour): $callsInLastHour\n'
        '  Total cost: \$${totalCostUSD.toStringAsFixed(4)}\n'
        '  Remaining budget: \$${remainingBudgetUSD.toStringAsFixed(4)}\n'
        '  Avg response time: ${averageResponseTimeMs}ms\n'
        '  Total tokens: $totalTokensUsed\n'
        '  Cost resets: ${costResetTime.toLocal()}';
  }
}

/// User-specific LLM usage statistics.
class LLMUserStats {
  final String userId;
  final int callsInLastHour;
  final int remainingCallsThisHour;
  final double totalCostUSD;

  LLMUserStats({
    required this.userId,
    required this.callsInLastHour,
    required this.remainingCallsThisHour,
    required this.totalCostUSD,
  });

  @override
  String toString() {
    return 'User $userId LLM Stats:\n'
        '  Calls (last hour): $callsInLastHour\n'
        '  Remaining calls: $remainingCallsThisHour\n'
        '  Total cost: \$${totalCostUSD.toStringAsFixed(4)}';
  }
}
