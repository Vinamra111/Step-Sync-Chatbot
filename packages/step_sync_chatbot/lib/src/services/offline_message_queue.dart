/// Offline Message Queue
///
/// Manages messages that couldn't be sent due to offline status.
/// Features:
/// - Persistent storage using SQLite
/// - Auto-retry when connection restored
/// - Priority-based queuing
/// - Duplicate detection
/// - Queue size limits

import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart';
import '../data/models/chat_message.dart';

/// Message priority for queue ordering
enum MessagePriority {
  /// Low priority (background sync)
  low,

  /// Normal priority (user messages)
  normal,

  /// High priority (urgent messages)
  high,
}

/// Queued message with metadata
class QueuedMessage {
  final String id;
  final String userId;
  final String messageText;
  final MessagePriority priority;
  final DateTime queuedAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  final Map<String, dynamic> metadata;

  const QueuedMessage({
    required this.id,
    required this.userId,
    required this.messageText,
    this.priority = MessagePriority.normal,
    required this.queuedAt,
    this.retryCount = 0,
    this.lastRetryAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'message_text': messageText,
      'priority': priority.index,
      'queued_at': queuedAt.toIso8601String(),
      'retry_count': retryCount,
      'last_retry_at': lastRetryAt?.toIso8601String(),
      'metadata': jsonEncode(metadata),
    };
  }

  factory QueuedMessage.fromMap(Map<String, dynamic> map) {
    return QueuedMessage(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      messageText: map['message_text'] as String,
      priority: MessagePriority.values[map['priority'] as int],
      queuedAt: DateTime.parse(map['queued_at'] as String),
      retryCount: map['retry_count'] as int,
      lastRetryAt: map['last_retry_at'] != null
          ? DateTime.parse(map['last_retry_at'] as String)
          : null,
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : {},
    );
  }

  QueuedMessage copyWith({
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return QueuedMessage(
      id: id,
      userId: userId,
      messageText: messageText,
      priority: priority,
      queuedAt: queuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      metadata: metadata,
    );
  }

  @override
  String toString() =>
      'QueuedMessage(id: $id, text: "${messageText.substring(0, messageText.length > 50 ? 50 : messageText.length)}...", priority: $priority, retries: $retryCount)';
}

/// Offline Message Queue Service
class OfflineMessageQueue {
  final String _userId;
  final Logger _logger;
  final Lock _lock = Lock();

  Database? _database;

  /// Maximum queue size (prevent unbounded growth)
  final int maxQueueSize;

  /// Maximum retry attempts before giving up
  final int maxRetryAttempts;

  /// Stream of queue size changes
  final StreamController<int> _queueSizeController =
      StreamController<int>.broadcast();
  Stream<int> get queueSizeStream => _queueSizeController.stream;

  /// Stream of messages being processed
  final StreamController<QueuedMessage> _processingController =
      StreamController<QueuedMessage>.broadcast();
  Stream<QueuedMessage> get processingStream => _processingController.stream;

  OfflineMessageQueue({
    required String userId,
    Logger? logger,
    this.maxQueueSize = 100,
    this.maxRetryAttempts = 3,
  })  : _userId = userId,
        _logger = logger ?? Logger();

  /// Initialize the queue database
  Future<void> initialize(String databasePath) async {
    return _lock.synchronized(() async {
      _logger.d('Initializing offline message queue for user: $_userId');

      final dbPath = path.join(databasePath, 'offline_queue_$_userId.db');
      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _createDatabase,
      );

      // Clean up old messages on startup
      await _cleanupOldMessages();

      final size = await getQueueSize();
      _logger.i('Offline message queue initialized. Current size: $size');
      _queueSizeController.add(size);
    });
  }

  /// Create database schema
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE queued_messages (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        message_text TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 1,
        queued_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_retry_at TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for efficient querying
    await db.execute('''
      CREATE INDEX idx_user_priority ON queued_messages(user_id, priority DESC, queued_at ASC)
    ''');

    await db.execute('''
      CREATE INDEX idx_retry_count ON queued_messages(retry_count)
    ''');
  }

  /// Add message to queue
  Future<void> enqueue(
    String messageId,
    String messageText, {
    MessagePriority priority = MessagePriority.normal,
    Map<String, dynamic> metadata = const {},
  }) async {
    return _lock.synchronized(() async {
      _ensureInitialized();

      // Check queue size limit
      final currentSize = await getQueueSize();
      if (currentSize >= maxQueueSize) {
        _logger.w('Queue size limit reached ($maxQueueSize). Removing oldest low-priority message.');
        await _removeOldestLowPriorityMessage();
      }

      final queuedMessage = QueuedMessage(
        id: messageId,
        userId: _userId,
        messageText: messageText,
        priority: priority,
        queuedAt: DateTime.now(),
        metadata: metadata,
      );

      await _database!.insert(
        'queued_messages',
        queuedMessage.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.d('Message enqueued: $messageId (priority: $priority)');
      _queueSizeController.add(await getQueueSize());
    });
  }

  /// Get next message to process (highest priority first)
  Future<QueuedMessage?> dequeue() async {
    return _lock.synchronized(() async {
      _ensureInitialized();

      final results = await _database!.query(
        'queued_messages',
        where: 'user_id = ? AND retry_count < ?',
        whereArgs: [_userId, maxRetryAttempts],
        orderBy: 'priority DESC, queued_at ASC',
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      final message = QueuedMessage.fromMap(results.first);
      _processingController.add(message);
      return message;
    });
  }

  /// Mark message as successfully sent and remove from queue
  Future<void> markSent(String messageId) async {
    return _lock.synchronized(() async {
      _ensureInitialized();

      await _database!.delete(
        'queued_messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );

      _logger.d('Message removed from queue: $messageId');
      _queueSizeController.add(await getQueueSize());
    });
  }

  /// Mark message as failed and increment retry count
  Future<void> markFailed(String messageId) async {
    return _lock.synchronized(() async {
      _ensureInitialized();

      final results = await _database!.query(
        'queued_messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );

      if (results.isEmpty) {
        return;
      }

      final message = QueuedMessage.fromMap(results.first);
      final updatedMessage = message.copyWith(
        retryCount: message.retryCount + 1,
        lastRetryAt: DateTime.now(),
      );

      if (updatedMessage.retryCount >= maxRetryAttempts) {
        _logger.w('Message exceeded max retry attempts: $messageId (${updatedMessage.retryCount} attempts)');
        // Keep in database but won't be retried (retry_count >= maxRetryAttempts)
      }

      await _database!.update(
        'queued_messages',
        updatedMessage.toMap(),
        where: 'id = ?',
        whereArgs: [messageId],
      );

      _logger.d('Message retry count updated: $messageId (${updatedMessage.retryCount}/$maxRetryAttempts)');
    });
  }

  /// Get all queued messages for user
  Future<List<QueuedMessage>> getAllQueued() async {
    return _lock.synchronized(() async {
      _ensureInitialized();

      final results = await _database!.query(
        'queued_messages',
        where: 'user_id = ?',
        whereArgs: [_userId],
        orderBy: 'priority DESC, queued_at ASC',
      );

      return results.map((map) => QueuedMessage.fromMap(map)).toList();
    });
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    _ensureInitialized();

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM queued_messages WHERE user_id = ? AND retry_count < ?',
      [_userId, maxRetryAttempts],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if queue is empty
  Future<bool> isEmpty() async {
    final size = await getQueueSize();
    return size == 0;
  }

  /// Clear all messages from queue
  Future<void> clear() async {
    return _lock.synchronized(() async {
      _ensureInitialized();

      await _database!.delete(
        'queued_messages',
        where: 'user_id = ?',
        whereArgs: [_userId],
      );

      _logger.i('Queue cleared for user: $_userId');
      _queueSizeController.add(0);
    });
  }

  /// Remove oldest low-priority message
  Future<void> _removeOldestLowPriorityMessage() async {
    final results = await _database!.query(
      'queued_messages',
      where: 'user_id = ? AND priority = ?',
      whereArgs: [_userId, MessagePriority.low.index],
      orderBy: 'queued_at ASC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      final messageId = results.first['id'] as String;
      await _database!.delete(
        'queued_messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );
      _logger.d('Removed oldest low-priority message: $messageId');
    }
  }

  /// Clean up messages older than 7 days
  Future<void> _cleanupOldMessages() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

    final deleted = await _database!.delete(
      'queued_messages',
      where: 'queued_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    if (deleted > 0) {
      _logger.i('Cleaned up $deleted old messages from queue');
    }
  }

  /// Get failed messages (exceeded retry limit)
  Future<List<QueuedMessage>> getFailedMessages() async {
    return _lock.synchronized(() async {
      _ensureInitialized();

      final results = await _database!.query(
        'queued_messages',
        where: 'user_id = ? AND retry_count >= ?',
        whereArgs: [_userId, maxRetryAttempts],
        orderBy: 'queued_at DESC',
      );

      return results.map((map) => QueuedMessage.fromMap(map)).toList();
    });
  }

  /// Remove failed messages
  Future<void> clearFailedMessages() async {
    return _lock.synchronized(() async {
      _ensureInitialized();

      final deleted = await _database!.delete(
        'queued_messages',
        where: 'user_id = ? AND retry_count >= ?',
        whereArgs: [_userId, maxRetryAttempts],
      );

      if (deleted > 0) {
        _logger.i('Cleared $deleted failed messages from queue');
        _queueSizeController.add(await getQueueSize());
      }
    });
  }

  /// Ensure database is initialized
  void _ensureInitialized() {
    if (_database == null) {
      throw StateError('OfflineMessageQueue not initialized. Call initialize() first.');
    }
  }

  /// Dispose resources
  void dispose() {
    _logger.d('Disposing offline message queue');
    _queueSizeController.close();
    _processingController.close();
    _database?.close();
  }
}
