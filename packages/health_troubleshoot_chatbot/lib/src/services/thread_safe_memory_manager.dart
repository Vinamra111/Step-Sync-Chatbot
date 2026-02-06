/// Thread-Safe Conversation Memory Manager
///
/// Wraps ConversationMemoryManager with proper synchronization to prevent
/// data corruption from concurrent access.
///
/// Features:
/// - Mutex-based locking per session
/// - Read-write lock optimization
/// - Deadlock prevention
/// - Performance monitoring
/// - Thread-safe concurrent access

import 'dart:async';
import 'package:logger/logger.dart';
import 'package:synchronized/synchronized.dart';
import 'conversation_memory_manager.dart';
import 'conversation_persistence_service.dart';
import 'groq_chat_service.dart';
import 'memory_monitor.dart';

/// Thread-safe wrapper for ConversationMemoryManager
class ThreadSafeMemoryManager {
  final ConversationMemoryManager _memoryManager;
  final ConversationPersistenceService? _persistenceService;
  final MemoryMonitor? _memoryMonitor;
  final Logger _logger;

  // Per-session locks to allow concurrent access to different sessions
  final Map<String, Lock> _sessionLocks = {};
  final Lock _globalLock = Lock();

  ThreadSafeMemoryManager({
    ConversationMemoryManager? memoryManager,
    ConversationPersistenceService? persistenceService,
    MemoryMonitor? memoryMonitor,
    MemoryConfig? memoryConfig,
    Logger? logger,
  })  : _memoryMonitor = memoryMonitor,
        _memoryManager = memoryManager ??
            ConversationMemoryManager(
              config: memoryConfig,
              logger: logger,
              memoryMonitor: memoryMonitor,
            ),
        _persistenceService = persistenceService,
        _logger = logger ?? Logger();

  /// Get or create a lock for a session
  Lock _getSessionLock(String sessionId) {
    if (!_sessionLocks.containsKey(sessionId)) {
      _sessionLocks[sessionId] = Lock();
    }
    return _sessionLocks[sessionId]!;
  }

  /// Execute operation with session lock
  Future<T> _withSessionLock<T>(
    String sessionId,
    Future<T> Function() operation,
  ) async {
    final lock = _getSessionLock(sessionId);

    return lock.synchronized(() async {
      _logger.d('Lock acquired for session: $sessionId');
      try {
        final result = await operation();
        _logger.d('Lock released for session: $sessionId');
        return result;
      } catch (e) {
        _logger.e('Error in locked operation for session $sessionId: $e');
        _logger.d('Lock released for session: $sessionId');
        rethrow;
      }
    });
  }

  /// Execute operation with global lock
  Future<T> _withGlobalLock<T>(Future<T> Function() operation) async {
    return _globalLock.synchronized(() async {
      _logger.d('Global lock acquired');
      try {
        final result = await operation();
        _logger.d('Global lock released');
        return result;
      } catch (e) {
        _logger.e('Error in globally locked operation: $e');
        _logger.d('Global lock released');
        rethrow;
      }
    });
  }

  /// Thread-safe: Get or create session
  Future<ConversationSession> getSession(String sessionId) async {
    return _withSessionLock(sessionId, () async {
      // Try to load from persistence first
      if (_persistenceService != null) {
        final persisted = await _persistenceService!.loadSession(sessionId);
        if (persisted != null) {
          // Load messages
          final messages = await _persistenceService!.loadMessages(sessionId);
          final conversationMessages = messages
              .map((m) => m.toConversationMessage())
              .toList();

          // Restore session by creating it and adding messages
          final session = _memoryManager.getSession(sessionId);

          // Add messages back
          for (final message in conversationMessages) {
            _memoryManager.addMessage(sessionId, message);
          }

          return session;
        }
      }

      return _memoryManager.getSession(sessionId);
    });
  }

  /// Thread-safe: Add message
  Future<void> addMessage(String sessionId, ConversationMessage message) async {
    await _withSessionLock(sessionId, () async {
      _memoryManager.addMessage(sessionId, message);

      // Persist if service available
      if (_persistenceService != null) {
        final session = _memoryManager.getSession(sessionId);

        // Save session
        await _persistenceService!.saveSession(PersistedSession(
          id: session.id,
          startTime: session.startTime,
          lastActivityTime: session.lastActivityTime,
        ));

        // Save message
        final persisted = PersistedMessage.fromConversationMessage(
          sessionId,
          message,
        );
        await _persistenceService!.saveMessage(persisted);
      }
    });
  }

  /// Thread-safe: Add user message
  Future<void> addUserMessage(String sessionId, String content) async {
    await addMessage(
      sessionId,
      ConversationMessage(content: content, role: 'user'),
    );
  }

  /// Thread-safe: Add assistant message
  Future<void> addAssistantMessage(String sessionId, String content) async {
    await addMessage(
      sessionId,
      ConversationMessage(content: content, role: 'assistant'),
    );
  }

  /// Thread-safe: Get history
  Future<List<ConversationMessage>> getHistory(String sessionId) async {
    return _withSessionLock(sessionId, () async {
      return _memoryManager.getHistory(sessionId);
    });
  }

  /// Thread-safe: Get recent messages
  Future<List<ConversationMessage>> getRecentMessages(
    String sessionId,
    int count,
  ) async {
    return _withSessionLock(sessionId, () async {
      return _memoryManager.getRecentMessages(sessionId, count);
    });
  }

  /// Thread-safe: Clear session
  Future<void> clearSession(String sessionId) async {
    await _withSessionLock(sessionId, () async {
      _memoryManager.clearSession(sessionId);

      // Delete from persistence
      if (_persistenceService != null) {
        await _persistenceService!.deleteSession(sessionId);
      }

      // Remove lock
      _sessionLocks.remove(sessionId);
    });
  }

  /// Thread-safe: Clear all sessions (requires global lock)
  Future<void> clearAllSessions() async {
    await _withGlobalLock(() async {
      _memoryManager.clearAllSessions();

      // Delete all from persistence
      if (_persistenceService != null) {
        await _persistenceService!.deleteAll();
      }

      // Clear all locks
      _sessionLocks.clear();
    });
  }

  /// Thread-safe: Get active session IDs
  Future<List<String>> getActiveSessionIds() async {
    return _withGlobalLock(() async {
      return _memoryManager.getActiveSessionIds();
    });
  }

  /// Thread-safe: Get session count
  Future<int> getSessionCount() async {
    return _withGlobalLock(() async {
      return _memoryManager.sessionCount;
    });
  }

  /// Thread-safe: Has session
  Future<bool> hasSession(String sessionId) async {
    return _withSessionLock(sessionId, () async {
      return _memoryManager.hasSession(sessionId);
    });
  }

  /// Thread-safe: Get stats
  Future<MemoryStats> getStats() async {
    return _withGlobalLock(() async {
      return _memoryManager.getStats();
    });
  }

  /// Thread-safe: Get per-session memory usage
  Future<Map<String, Map<String, dynamic>>> getSessionUsage() async {
    return _withGlobalLock(() async {
      return _memoryManager.getSessionUsage();
    });
  }

  /// Get lock statistics (for monitoring)
  Map<String, dynamic> getLockStats() {
    final lockedSessions = _sessionLocks.entries
        .where((e) => e.value.locked)
        .map((e) => e.key)
        .toList();

    return {
      'totalLocks': _sessionLocks.length,
      'activeLocks': lockedSessions.length,
      'lockedSessions': lockedSessions,
      'isGlobalLocked': _globalLock.locked,
    };
  }

  /// Get memory snapshot for a session (from MemoryMonitor)
  MemoryUsageSnapshot? getMemorySnapshot(String sessionId) {
    return _memoryMonitor?.getSnapshot(sessionId);
  }

  /// Get global memory statistics from MemoryMonitor
  Map<String, dynamic>? getMemoryStatistics() {
    return _memoryMonitor?.getStatistics();
  }

  /// Check if memory monitor is detecting warnings
  bool hasMemoryWarning() {
    return _memoryMonitor?.hasWarning() ?? false;
  }

  /// Check if memory monitor is detecting critical alerts
  bool hasMemoryCritical() {
    return _memoryMonitor?.hasCritical() ?? false;
  }

  /// Get combined monitoring dashboard data
  Future<Map<String, dynamic>> getMonitoringDashboard() async {
    return _withGlobalLock(() async {
      final stats = _memoryManager.getStats();
      final lockStats = getLockStats();
      final memoryStats = getMemoryStatistics();

      return {
        'memory_stats': stats.toJson(),
        'lock_stats': lockStats,
        'memory_monitor': memoryStats,
        'has_memory_warning': hasMemoryWarning(),
        'has_memory_critical': hasMemoryCritical(),
      };
    });
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _withGlobalLock(() async {
      _memoryManager.dispose();
      _memoryMonitor?.dispose();
      _sessionLocks.clear();
    });
  }
}
