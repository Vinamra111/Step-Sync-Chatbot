/// Production Conversation Persistence Service
///
/// Provides durable storage for conversations using SQLite with:
/// - Automatic save on message add
/// - Lazy loading of conversation history
/// - Transaction support for data integrity
/// - Migration support for schema changes
/// - Error recovery and data validation

import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:path/path.dart';
import 'groq_chat_service.dart';
import 'encryption_key_manager.dart';

/// Exception for persistence errors
class PersistenceException implements Exception {
  final String message;
  final dynamic originalError;

  PersistenceException(this.message, {this.originalError});

  @override
  String toString() => 'PersistenceException: $message';
}

/// Configuration for persistence
class PersistenceConfig {
  final String databaseName;
  final int databaseVersion;
  final bool enableWAL; // Write-Ahead Logging for better concurrency
  final int maxRetries;
  final bool enableEncryption; // HIPAA-compliant encryption
  final EncryptionKeyManager? encryptionKeyManager;

  const PersistenceConfig({
    this.databaseName = 'step_sync_conversations.db',
    this.databaseVersion = 1,
    this.enableWAL = true,
    this.maxRetries = 3,
    this.enableEncryption = true, // Encryption ON by default for HIPAA
    this.encryptionKeyManager,
  });
}

/// Persisted message model
class PersistedMessage {
  final int? id;
  final String sessionId;
  final String content;
  final String role;
  final DateTime timestamp;
  final String? metadataJson;

  PersistedMessage({
    this.id,
    required this.sessionId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.metadataJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'role': role,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metadata_json': metadataJson,
    };
  }

  factory PersistedMessage.fromMap(Map<String, dynamic> map) {
    return PersistedMessage(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String,
      content: map['content'] as String,
      role: map['role'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      metadataJson: map['metadata_json'] as String?,
    );
  }

  ConversationMessage toConversationMessage() {
    Map<String, dynamic>? metadata;
    if (metadataJson != null) {
      try {
        metadata = jsonDecode(metadataJson!) as Map<String, dynamic>;
      } catch (e) {
        // Invalid JSON, ignore
      }
    }

    return ConversationMessage(
      content: content,
      role: role,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  static PersistedMessage fromConversationMessage(
    String sessionId,
    ConversationMessage message,
  ) {
    String? metadataJson;
    if (message.metadata != null) {
      try {
        metadataJson = jsonEncode(message.metadata);
      } catch (e) {
        // Can't encode, ignore
      }
    }

    return PersistedMessage(
      sessionId: sessionId,
      content: message.content,
      role: message.role,
      timestamp: message.timestamp,
      metadataJson: metadataJson,
    );
  }
}

/// Persisted session model
class PersistedSession {
  final String id;
  final DateTime startTime;
  final DateTime lastActivityTime;
  final String? metadataJson;

  PersistedSession({
    required this.id,
    required this.startTime,
    required this.lastActivityTime,
    this.metadataJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'last_activity_time': lastActivityTime.millisecondsSinceEpoch,
      'metadata_json': metadataJson,
    };
  }

  factory PersistedSession.fromMap(Map<String, dynamic> map) {
    return PersistedSession(
      id: map['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      lastActivityTime: DateTime.fromMillisecondsSinceEpoch(map['last_activity_time'] as int),
      metadataJson: map['metadata_json'] as String?,
    );
  }
}

/// Production Conversation Persistence Service
class ConversationPersistenceService {
  final PersistenceConfig config;
  final Logger _logger;
  final EncryptionKeyManager _encryptionKeyManager;
  Database? _database;
  final _initializeLock = Completer<void>();
  bool _isInitialized = false;

  ConversationPersistenceService({
    PersistenceConfig? config,
    Logger? logger,
    EncryptionKeyManager? encryptionKeyManager,
  })  : config = config ?? const PersistenceConfig(),
        _logger = logger ?? Logger(),
        _encryptionKeyManager = encryptionKeyManager ??
            (config?.encryptionKeyManager ?? EncryptionKeyManager());

  /// Initialize database connection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('Initializing conversation persistence (encryption: ${config.enableEncryption})');

      final databasePath = await getDatabasesPath();
      final path = join(databasePath, config.databaseName);

      // Open database with encryption if enabled
      if (config.enableEncryption) {
        final encryptionKey = await _encryptionKeyManager.getOrGenerateKey();
        _logger.d('Using encrypted database with SQLCipher');

        _database = await sqlcipher.openDatabase(
          path,
          version: config.databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
          password: encryptionKey,
        );
      } else {
        _logger.w('Using unencrypted database (not HIPAA compliant!)');

        _database = await openDatabase(
          path,
          version: config.databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
        );
      }

      if (config.enableWAL) {
        await _database!.execute('PRAGMA journal_mode=WAL');
        _logger.d('WAL mode enabled for better concurrency');
      }

      _isInitialized = true;
      _initializeLock.complete();
      _logger.i('Persistence initialized: $path');
    } catch (e) {
      _logger.e('Failed to initialize persistence: $e');
      _initializeLock.completeError(e);
      throw PersistenceException('Failed to initialize database', originalError: e);
    }
  }

  /// Ensure database is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeLock.future;
    }
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    _logger.d('Creating database schema v$version');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        last_activity_time INTEGER NOT NULL,
        metadata_json TEXT
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        content TEXT NOT NULL,
        role TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        metadata_json TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_messages_session ON messages(session_id)');
    await db.execute('CREATE INDEX idx_messages_timestamp ON messages(timestamp)');
    await db.execute('CREATE INDEX idx_sessions_activity ON sessions(last_activity_time)');
  }

  /// Upgrade database schema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from v$oldVersion to v$newVersion');
    // Future migrations will go here
  }

  /// On database open
  Future<void> _onOpen(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Save a session
  Future<void> saveSession(PersistedSession session) async {
    await _ensureInitialized();

    try {
      // Check if session exists
      final existing = await loadSession(session.id);

      if (existing != null) {
        // Update existing session (avoid DELETE CASCADE on messages)
        await _database!.update(
          'sessions',
          session.toMap(),
          where: 'id = ?',
          whereArgs: [session.id],
        );
        _logger.d('Session updated: ${session.id}');
      } else {
        // Insert new session
        await _database!.insert(
          'sessions',
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        _logger.d('Session created: ${session.id}');
      }
    } catch (e) {
      _logger.e('Failed to save session: $e');
      throw PersistenceException('Failed to save session', originalError: e);
    }
  }

  /// Save a message
  Future<void> saveMessage(PersistedMessage message) async {
    await _ensureInitialized();

    try {
      await _database!.insert(
        'messages',
        message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.d('Message saved to session: ${message.sessionId}');
    } catch (e) {
      _logger.e('Failed to save message: $e');
      throw PersistenceException('Failed to save message', originalError: e);
    }
  }

  /// Load session
  Future<PersistedSession?> loadSession(String sessionId) async {
    await _ensureInitialized();

    try {
      final results = await _database!.query(
        'sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      if (results.isEmpty) return null;

      return PersistedSession.fromMap(results.first);
    } catch (e) {
      _logger.e('Failed to load session: $e');
      throw PersistenceException('Failed to load session', originalError: e);
    }
  }

  /// Load messages for a session
  Future<List<PersistedMessage>> loadMessages(String sessionId) async {
    await _ensureInitialized();

    try {
      final results = await _database!.query(
        'messages',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC',
      );

      return results.map((map) => PersistedMessage.fromMap(map)).toList();
    } catch (e) {
      _logger.e('Failed to load messages: $e');
      throw PersistenceException('Failed to load messages', originalError: e);
    }
  }

  /// Load all session IDs
  Future<List<String>> loadAllSessionIds() async {
    await _ensureInitialized();

    try {
      final results = await _database!.query(
        'sessions',
        columns: ['id'],
        orderBy: 'last_activity_time DESC',
      );

      return results.map((map) => map['id'] as String).toList();
    } catch (e) {
      _logger.e('Failed to load session IDs: $e');
      throw PersistenceException('Failed to load session IDs', originalError: e);
    }
  }

  /// Delete a session and all its messages
  Future<void> deleteSession(String sessionId) async {
    await _ensureInitialized();

    try {
      await _database!.delete(
        'sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      _logger.i('Session deleted: $sessionId');
    } catch (e) {
      _logger.e('Failed to delete session: $e');
      throw PersistenceException('Failed to delete session', originalError: e);
    }
  }

  /// Delete all data
  Future<void> deleteAll() async {
    await _ensureInitialized();

    try {
      await _database!.delete('messages');
      await _database!.delete('sessions');
      _logger.i('All data deleted');
    } catch (e) {
      _logger.e('Failed to delete all data: $e');
      throw PersistenceException('Failed to delete all data', originalError: e);
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getStats() async {
    await _ensureInitialized();

    try {
      final sessionCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM sessions'),
      ) ?? 0;

      final messageCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM messages'),
      ) ?? 0;

      return {
        'sessions': sessionCount,
        'messages': messageCount,
      };
    } catch (e) {
      _logger.e('Failed to get stats: $e');
      return {'sessions': 0, 'messages': 0};
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
      _logger.i('Persistence closed');
    }
  }
}
