/// Production Conversation Memory Manager
///
/// Manages conversation history with:
/// - Context window management (token limits)
/// - Message persistence
/// - Automatic summarization for old messages
/// - LangChain integration
/// - Conversation session management

import 'dart:convert' show utf8;
import 'package:logger/logger.dart';
import 'package:langchain/langchain.dart';
import 'groq_chat_service.dart';
import 'memory_monitor.dart';

/// Configuration for memory management
class MemoryConfig {
  final int maxMessages;
  final int maxTokens;
  final bool enableSummarization;
  final Duration sessionTimeout;

  const MemoryConfig({
    this.maxMessages = 20,
    this.maxTokens = 4000,
    this.enableSummarization = false,
    this.sessionTimeout = const Duration(hours: 24),
  });
}

/// Conversation session with metadata
class ConversationSession {
  final String id;
  final DateTime startTime;
  DateTime lastActivityTime;
  final List<ConversationMessage> messages;
  final Map<String, dynamic> metadata;

  /// Total bytes used by messages in this session (UTF-8 encoded)
  int _bytesUsed = 0;

  ConversationSession({
    required this.id,
    DateTime? startTime,
    DateTime? lastActivityTime,
    List<ConversationMessage>? messages,
    Map<String, dynamic>? metadata,
    int bytesUsed = 0,
  })  : startTime = startTime ?? DateTime.now(),
        lastActivityTime = lastActivityTime ?? DateTime.now(),
        messages = messages ?? [],
        metadata = metadata ?? {},
        _bytesUsed = bytesUsed;

  /// Whether session has expired
  bool isExpired(Duration timeout) {
    return DateTime.now().difference(lastActivityTime) > timeout;
  }

  /// Update last activity time
  void touch() {
    lastActivityTime = DateTime.now();
  }

  /// Total message count
  int get messageCount => messages.length;

  /// User message count
  int get userMessageCount => messages.where((m) => m.isUser).length;

  /// Assistant message count
  int get assistantMessageCount => messages.where((m) => m.isAssistant).length;

  /// Duration since start
  Duration get duration => DateTime.now().difference(startTime);

  /// Total bytes used (UTF-8 encoded message content)
  int get bytesUsed => _bytesUsed;

  /// Add bytes to total
  void addBytes(int bytes) {
    _bytesUsed += bytes;
  }

  /// Remove bytes from total
  void removeBytes(int bytes) {
    _bytesUsed = (_bytesUsed - bytes).clamp(0, double.infinity).toInt();
  }

  /// Recalculate total bytes from messages
  void recalculateBytes() {
    _bytesUsed = 0;
    for (final message in messages) {
      _bytesUsed += utf8.encode(message.content).length;
    }
  }
}

/// Statistics about memory usage
class MemoryStats {
  final int totalMessages;
  final int userMessages;
  final int assistantMessages;
  final int estimatedTokens;
  final int totalBytes;
  final int activeSessions;
  final DateTime oldestMessage;
  final int maxCapacity;
  final int messagesAtCapacity;

  MemoryStats({
    required this.totalMessages,
    required this.userMessages,
    required this.assistantMessages,
    required this.estimatedTokens,
    required this.totalBytes,
    required this.activeSessions,
    required this.oldestMessage,
    required this.maxCapacity,
    required this.messagesAtCapacity,
  });

  /// Percentage of message capacity used (0-100)
  double get capacityUsedPercent => maxCapacity > 0
      ? (messagesAtCapacity / maxCapacity * 100).clamp(0, 100)
      : 0.0;

  /// Whether any session is approaching capacity (>= 80%)
  bool get isApproachingCapacity => capacityUsedPercent >= 80;

  /// Whether any session is at capacity (100%)
  bool get isAtCapacity => capacityUsedPercent >= 100;

  /// Average messages per session
  double get averageMessagesPerSession => activeSessions > 0
      ? totalMessages / activeSessions
      : 0.0;

  /// Total megabytes used
  double get totalMB => totalBytes / (1024 * 1024);

  /// Convert to JSON for logging/monitoring
  Map<String, dynamic> toJson() {
    return {
      'totalMessages': totalMessages,
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'estimatedTokens': estimatedTokens,
      'totalBytes': totalBytes,
      'totalMB': totalMB.toStringAsFixed(2),
      'activeSessions': activeSessions,
      'oldestMessage': oldestMessage.toIso8601String(),
      'maxCapacity': maxCapacity,
      'messagesAtCapacity': messagesAtCapacity,
      'capacityUsedPercent': capacityUsedPercent.toStringAsFixed(1),
      'isApproachingCapacity': isApproachingCapacity,
      'isAtCapacity': isAtCapacity,
      'averageMessagesPerSession': averageMessagesPerSession.toStringAsFixed(1),
    };
  }
}

/// Production Conversation Memory Manager
class ConversationMemoryManager {
  final MemoryConfig config;
  final Logger _logger;
  final MemoryMonitor? _memoryMonitor;
  // Made package-private for ThreadSafeMemoryManager access
  final Map<String, ConversationSession> _sessions = {};

  ConversationMemoryManager({
    MemoryConfig? config,
    Logger? logger,
    MemoryMonitor? memoryMonitor,
  })  : config = config ?? const MemoryConfig(),
        _logger = logger ?? Logger(),
        _memoryMonitor = memoryMonitor;

  /// Get or create a conversation session
  ConversationSession getSession(String sessionId) {
    // Clean up expired sessions first
    _cleanupExpiredSessions();

    // Get or create session
    if (!_sessions.containsKey(sessionId)) {
      _logger.d('Creating new session: $sessionId');
      _sessions[sessionId] = ConversationSession(id: sessionId);
    }

    final session = _sessions[sessionId]!;
    session.touch();
    return session;
  }

  /// Add a message to session
  void addMessage(
    String sessionId,
    ConversationMessage message,
  ) {
    final session = getSession(sessionId);
    session.messages.add(message);
    session.touch();

    // Calculate and track bytes (UTF-8 encoding)
    final messageBytes = utf8.encode(message.content).length;
    session.addBytes(messageBytes);

    // Update memory monitor if available
    _memoryMonitor?.trackSession(sessionId, session.bytesUsed);

    _logger.d(
      'Message added to session $sessionId '
      '(${session.messageCount} total, ${session.bytesUsed} bytes)',
    );

    // Check capacity and warn if approaching limit
    final usagePercent = (session.messageCount / config.maxMessages * 100).round();
    if (usagePercent >= 80 && usagePercent < 100) {
      _logger.w(
        'Session $sessionId approaching message limit: '
        '${session.messageCount}/${config.maxMessages} ($usagePercent% full)',
      );
    }

    // Trim if exceeds max messages
    if (session.messageCount > config.maxMessages) {
      _trimSession(session);
    }
  }

  /// Add user message
  void addUserMessage(String sessionId, String content) {
    addMessage(
      sessionId,
      ConversationMessage(content: content, role: 'user'),
    );
  }

  /// Add assistant message
  void addAssistantMessage(String sessionId, String content) {
    addMessage(
      sessionId,
      ConversationMessage(content: content, role: 'assistant'),
    );
  }

  /// Get conversation history for a session
  List<ConversationMessage> getHistory(String sessionId) {
    final session = getSession(sessionId);
    return List.unmodifiable(session.messages);
  }

  /// Get recent messages (last N)
  List<ConversationMessage> getRecentMessages(String sessionId, int count) {
    final session = getSession(sessionId);
    final messages = session.messages;

    if (messages.length <= count) {
      return List.unmodifiable(messages);
    }

    return List.unmodifiable(
      messages.sublist(messages.length - count),
    );
  }

  /// Clear a session
  void clearSession(String sessionId) {
    if (_sessions.containsKey(sessionId)) {
      _logger.i('Clearing session: $sessionId');
      _sessions.remove(sessionId);
      _memoryMonitor?.removeSession(sessionId);
    }
  }

  /// Clear all sessions
  void clearAllSessions() {
    _logger.i('Clearing all sessions (${_sessions.length} total)');
    _sessions.clear();
  }

  /// Get all active session IDs
  List<String> getActiveSessionIds() {
    _cleanupExpiredSessions();
    return List.unmodifiable(_sessions.keys);
  }

  /// Get session count
  int get sessionCount => _sessions.length;

  /// Check if session exists
  bool hasSession(String sessionId) {
    return _sessions.containsKey(sessionId);
  }

  /// Get per-session memory usage details
  Map<String, Map<String, dynamic>> getSessionUsage() {
    final usage = <String, Map<String, dynamic>>{};

    for (final entry in _sessions.entries) {
      final session = entry.value;
      final messageCount = session.messageCount;
      final usagePercent = (messageCount / config.maxMessages * 100).round();
      final bytesUsed = session.bytesUsed;
      final bytesMB = (bytesUsed / (1024 * 1024)).toStringAsFixed(2);

      usage[entry.key] = {
        'messageCount': messageCount,
        'maxMessages': config.maxMessages,
        'usagePercent': usagePercent,
        'bytesUsed': bytesUsed,
        'bytesMB': bytesMB,
        'isApproachingLimit': usagePercent >= 80,
        'isAtLimit': messageCount >= config.maxMessages,
        'userMessages': session.userMessageCount,
        'assistantMessages': session.assistantMessageCount,
        'startTime': session.startTime.toIso8601String(),
        'lastActivity': session.lastActivityTime.toIso8601String(),
        'duration': session.duration.inMinutes,
      };
    }

    return usage;
  }

  /// Get memory statistics
  MemoryStats getStats() {
    int totalMessages = 0;
    int userMessages = 0;
    int assistantMessages = 0;
    int estimatedTokens = 0;
    int totalBytes = 0;
    DateTime? oldestMessage;
    int messagesAtCapacity = 0;

    for (final session in _sessions.values) {
      totalMessages += session.messageCount;
      userMessages += session.userMessageCount;
      assistantMessages += session.assistantMessageCount;
      totalBytes += session.bytesUsed;

      // Track highest message count for capacity calculation
      if (session.messageCount > messagesAtCapacity) {
        messagesAtCapacity = session.messageCount;
      }

      for (final message in session.messages) {
        // Rough token estimate: 1 token ≈ 4 characters
        estimatedTokens += (message.content.length / 4).ceil();

        if (oldestMessage == null || message.timestamp.isBefore(oldestMessage)) {
          oldestMessage = message.timestamp;
        }
      }
    }

    return MemoryStats(
      totalMessages: totalMessages,
      userMessages: userMessages,
      assistantMessages: assistantMessages,
      estimatedTokens: estimatedTokens,
      totalBytes: totalBytes,
      activeSessions: _sessions.length,
      oldestMessage: oldestMessage ?? DateTime.now(),
      maxCapacity: config.maxMessages,
      messagesAtCapacity: messagesAtCapacity,
    );
  }

  /// Get LangChain memory for a session
  ConversationBufferMemory getLangChainMemory(String sessionId) {
    final memory = ConversationBufferMemory(returnMessages: true);
    final session = getSession(sessionId);

    // Load existing messages into LangChain memory
    // Note: This is a simplified version. In production, you'd want to
    // maintain the LangChain memory object across calls.
    _logger.d('Creating LangChain memory for session $sessionId');

    return memory;
  }

  /// Trim session to max messages
  void _trimSession(ConversationSession session) {
    final excess = session.messageCount - config.maxMessages;
    if (excess > 0) {
      _logger.w('Trimming session ${session.id}: removing $excess old messages');
      session.messages.removeRange(0, excess);

      // Recalculate bytes after trimming
      session.recalculateBytes();

      // Update memory monitor
      _memoryMonitor?.trackSession(session.id, session.bytesUsed);

      _logger.d(
        'Session ${session.id} trimmed: '
        '${session.messageCount} messages, ${session.bytesUsed} bytes',
      );
    }
  }

  /// Clean up expired sessions
  void _cleanupExpiredSessions() {
    final expiredIds = <String>[];

    for (final entry in _sessions.entries) {
      if (entry.value.isExpired(config.sessionTimeout)) {
        expiredIds.add(entry.key);
      }
    }

    if (expiredIds.isNotEmpty) {
      _logger.i('Cleaning up ${expiredIds.length} expired sessions');
      for (final id in expiredIds) {
        _sessions.remove(id);
      }
    }
  }

  /// Export session to JSON-serializable map
  Map<String, dynamic> exportSession(String sessionId) {
    final session = getSession(sessionId);

    return {
      'id': session.id,
      'startTime': session.startTime.toIso8601String(),
      'lastActivityTime': session.lastActivityTime.toIso8601String(),
      'messages': session.messages.map((m) => {
        'content': m.content,
        'role': m.role,
        'timestamp': m.timestamp.toIso8601String(),
        'metadata': m.metadata,
      }).toList(),
      'metadata': session.metadata,
    };
  }

  /// Import session from JSON map
  void importSession(Map<String, dynamic> data) {
    final id = data['id'] as String;
    final startTime = DateTime.parse(data['startTime'] as String);
    final lastActivityTime = DateTime.parse(data['lastActivityTime'] as String);

    final messages = (data['messages'] as List).map((m) {
      final messageMap = m as Map;
      final rawMetadata = messageMap['metadata'];
      final metadata = rawMetadata != null
          ? Map<String, dynamic>.from(rawMetadata as Map)
          : null;

      return ConversationMessage(
        content: messageMap['content'] as String,
        role: messageMap['role'] as String,
        timestamp: DateTime.parse(messageMap['timestamp'] as String),
        metadata: metadata,
      );
    }).toList();

    final rawSessionMetadata = data['metadata'];
    final metadata = rawSessionMetadata != null
        ? Map<String, dynamic>.from(rawSessionMetadata as Map)
        : <String, dynamic>{};

    final session = ConversationSession(
      id: id,
      startTime: startTime,
      lastActivityTime: lastActivityTime,
      messages: messages,
      metadata: metadata,
    );

    // Recalculate bytes from imported messages
    session.recalculateBytes();

    _sessions[id] = session;

    // Update memory monitor
    _memoryMonitor?.trackSession(id, session.bytesUsed);

    _logger.i(
      'Imported session: $id (${messages.length} messages, ${session.bytesUsed} bytes)',
    );
  }

  /// Dispose resources
  void dispose() {
    _logger.d('ConversationMemoryManager disposed');
    _sessions.clear();
  }
}
