import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/user_preferences.dart';
import 'conversation_repository.dart';

/// SQLite implementation of ConversationRepository.
///
/// Stores conversation history and user preferences in a local SQLite database.
class SQLiteConversationRepository implements ConversationRepository {
  static const String _databaseName = 'step_sync_chatbot.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _conversationsTable = 'conversations';
  static const String _messagesTable = 'messages';
  static const String _preferencesTable = 'user_preferences';

  Database? _database;

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Conversations table
    await db.execute('''
      CREATE TABLE $_conversationsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE $_messagesTable (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        text TEXT NOT NULL,
        sender TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        type TEXT NOT NULL,
        data TEXT,
        is_error INTEGER NOT NULL DEFAULT 0,
        quick_replies TEXT,
        FOREIGN KEY (conversation_id) REFERENCES $_conversationsTable (id) ON DELETE CASCADE
      )
    ''');

    // User preferences table
    await db.execute('''
      CREATE TABLE $_preferencesTable (
        user_id TEXT PRIMARY KEY,
        primary_data_source_id TEXT,
        notification_enabled INTEGER NOT NULL DEFAULT 1,
        theme_mode TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for performance
    await db.execute(
      'CREATE INDEX idx_conversations_user_id ON $_conversationsTable (user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_conversations_updated_at ON $_conversationsTable (updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_conversation_id ON $_messagesTable (conversation_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_timestamp ON $_messagesTable (timestamp)',
    );
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
  }

  Database get _db {
    if (_database == null) {
      throw StateError(
        'Repository not initialized. Call initialize() first.',
      );
    }
    return _database!;
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final db = _db;

    await db.transaction((txn) async {
      // Save conversation metadata
      await txn.insert(
        _conversationsTable,
        {
          'id': conversation.id,
          'user_id': conversation.userId,
          'title': conversation.title,
          'status': conversation.status.name,
          'created_at': conversation.createdAt.millisecondsSinceEpoch,
          'updated_at': conversation.updatedAt.millisecondsSinceEpoch,
          'metadata': conversation.metadata != null
              ? jsonEncode(conversation.metadata)
              : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Delete existing messages for this conversation
      await txn.delete(
        _messagesTable,
        where: 'conversation_id = ?',
        whereArgs: [conversation.id],
      );

      // Save all messages
      for (final message in conversation.messages) {
        await txn.insert(
          _messagesTable,
          {
            'id': message.id,
            'conversation_id': conversation.id,
            'text': message.text,
            'sender': message.sender.name,
            'timestamp': message.timestamp.millisecondsSinceEpoch,
            'type': message.type.name,
            'data': message.data != null ? jsonEncode(message.data) : null,
            'is_error': message.isError ? 1 : 0,
            'quick_replies': message.quickReplies != null
                ? jsonEncode(
                    message.quickReplies!
                        .map((qr) => {
                              'label': qr.label,
                              'value': qr.value,
                              'icon': qr.icon,
                            })
                        .toList(),
                  )
                : null,
          },
        );
      }
    });
  }

  @override
  Future<List<Conversation>> loadConversations({
    required String userId,
    int? limit,
  }) async {
    final db = _db;

    final conversationMaps = await db.query(
      _conversationsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    final conversations = <Conversation>[];

    for (final convMap in conversationMaps) {
      final messages = await _loadMessagesForConversation(
        convMap['id'] as String,
      );

      conversations.add(
        Conversation(
          id: convMap['id'] as String,
          userId: convMap['user_id'] as String,
          title: convMap['title'] as String?,
          messages: messages,
          status: ConversationLifecycleStatus.values.firstWhere(
            (s) => s.name == convMap['status'],
            orElse: () => ConversationLifecycleStatus.active,
          ),
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            convMap['created_at'] as int,
          ),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            convMap['updated_at'] as int,
          ),
          metadata: convMap['metadata'] != null
              ? jsonDecode(convMap['metadata'] as String)
              : null,
        ),
      );
    }

    return conversations;
  }

  @override
  Future<Conversation?> loadConversation(String conversationId) async {
    final db = _db;

    final conversationMaps = await db.query(
      _conversationsTable,
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (conversationMaps.isEmpty) return null;

    final convMap = conversationMaps.first;
    final messages = await _loadMessagesForConversation(conversationId);

    return Conversation(
      id: convMap['id'] as String,
      userId: convMap['user_id'] as String,
      title: convMap['title'] as String?,
      messages: messages,
      status: ConversationStatus.values.firstWhere(
        (s) => s.name == convMap['status'],
        orElse: () => ConversationStatus.idle,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        convMap['created_at'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        convMap['updated_at'] as int,
      ),
      metadata: convMap['metadata'] != null
          ? jsonDecode(convMap['metadata'] as String)
          : null,
    );
  }

  @override
  Future<Conversation?> loadMostRecentConversation(String userId) async {
    final conversations = await loadConversations(
      userId: userId,
      limit: 1,
    );

    return conversations.isNotEmpty ? conversations.first : null;
  }

  /// Load messages for a specific conversation
  Future<List<ChatMessage>> _loadMessagesForConversation(
    String conversationId,
  ) async {
    final db = _db;

    final messageMaps = await db.query(
      _messagesTable,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    return messageMaps.map((msgMap) {
      return ChatMessage(
        id: msgMap['id'] as String,
        text: msgMap['text'] as String,
        sender: MessageSender.values.firstWhere(
          (s) => s.name == msgMap['sender'],
          orElse: () => MessageSender.user,
        ),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          msgMap['timestamp'] as int,
        ),
        type: MessageType.values.firstWhere(
          (t) => t.name == msgMap['type'],
          orElse: () => MessageType.text,
        ),
        data: msgMap['data'] != null
            ? jsonDecode(msgMap['data'] as String)
            : null,
        isError: (msgMap['is_error'] as int) == 1,
        quickReplies: msgMap['quick_replies'] != null
            ? (jsonDecode(msgMap['quick_replies'] as String) as List)
                .map((qr) => QuickReply(
                      label: qr['label'] as String,
                      value: qr['value'] as String,
                      icon: qr['icon'] as String?,
                    ))
                .toList()
            : null,
      );
    }).toList();
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final db = _db;

    await db.delete(
      _conversationsTable,
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    // Messages will be deleted automatically due to CASCADE
  }

  @override
  Future<void> deleteAllConversations(String userId) async {
    final db = _db;

    // Get all conversation IDs for this user
    final conversations = await db.query(
      _conversationsTable,
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final conversationIds = conversations.map((c) => c['id'] as String).toList();

    await db.transaction((txn) async {
      // Delete all messages for these conversations
      if (conversationIds.isNotEmpty) {
        await txn.delete(
          _messagesTable,
          where: 'conversation_id IN (${conversationIds.map((_) => '?').join(', ')})',
          whereArgs: conversationIds,
        );
      }

      // Delete all conversations for this user
      await txn.delete(
        _conversationsTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });
  }

  @override
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    final db = _db;

    await db.insert(
      _preferencesTable,
      {
        'user_id': preferences.userId,
        'primary_data_source_id': preferences.preferredDataSource,
        'notification_enabled': preferences.notificationsEnabled ? 1 : 0,
        'theme_mode': preferences.conversationStyle.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<UserPreferences?> loadUserPreferences(String userId) async {
    final db = _db;

    final prefMaps = await db.query(
      _preferencesTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (prefMaps.isEmpty) return null;

    final prefMap = prefMaps.first;

    final themeModeStr = prefMap['theme_mode'] as String?;
    ConversationStyle style = ConversationStyle.balanced;
    if (themeModeStr != null) {
      style = ConversationStyle.values.firstWhere(
        (e) => e.name == themeModeStr,
        orElse: () => ConversationStyle.balanced,
      );
    }

    return UserPreferences(
      userId: prefMap['user_id'] as String,
      preferredDataSource: prefMap['primary_data_source_id'] as String?,
      notificationsEnabled: (prefMap['notification_enabled'] as int) == 1,
      conversationStyle: style,
    );
  }

  @override
  Future<void> addMessageToConversation({
    required String conversationId,
    required ChatMessage message,
  }) async {
    final conversation = await loadConversation(conversationId);

    if (conversation == null) {
      throw StateError('Conversation $conversationId not found');
    }

    final updatedConversation = conversation.copyWith(
      messages: [...conversation.messages, message],
      updatedAt: DateTime.now(),
    );

    await saveConversation(updatedConversation);
  }

  @override
  Future<ConversationStats> getStats(String userId) async {
    final db = _db;

    // Get conversation count
    final convCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_conversationsTable WHERE user_id = ?',
      [userId],
    );
    final totalConversations = convCountResult.first['count'] as int;

    if (totalConversations == 0) {
      return ConversationStats.empty();
    }

    // Get message count
    final msgCountResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM $_messagesTable
      WHERE conversation_id IN (
        SELECT id FROM $_conversationsTable WHERE user_id = ?
      )
    ''', [userId]);
    final totalMessages = msgCountResult.first['count'] as int;

    // Get date range
    final dateRangeResult = await db.rawQuery('''
      SELECT
        MIN(created_at) as first_date,
        MAX(updated_at) as last_date
      FROM $_conversationsTable
      WHERE user_id = ?
    ''', [userId]);

    final firstDate = dateRangeResult.first['first_date'] as int?;
    final lastDate = dateRangeResult.first['last_date'] as int?;

    return ConversationStats(
      totalConversations: totalConversations,
      totalMessages: totalMessages,
      firstConversationDate: firstDate != null
          ? DateTime.fromMillisecondsSinceEpoch(firstDate)
          : null,
      lastConversationDate: lastDate != null
          ? DateTime.fromMillisecondsSinceEpoch(lastDate)
          : null,
    );
  }

  @override
  Future<int> cleanupOldConversations({
    required String userId,
    required int retentionDays,
  }) async {
    final db = _db;

    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

    // Get conversations to delete
    final conversations = await db.query(
      _conversationsTable,
      columns: ['id'],
      where: 'user_id = ? AND updated_at < ?',
      whereArgs: [userId, cutoffTimestamp],
    );

    if (conversations.isEmpty) return 0;

    final conversationIds = conversations.map((c) => c['id'] as String).toList();

    await db.transaction((txn) async {
      // Delete messages
      await txn.delete(
        _messagesTable,
        where: 'conversation_id IN (${conversationIds.map((_) => '?').join(', ')})',
        whereArgs: conversationIds,
      );

      // Delete conversations
      await txn.delete(
        _conversationsTable,
        where: 'user_id = ? AND updated_at < ?',
        whereArgs: [userId, cutoffTimestamp],
      );
    });

    return conversationIds.length;
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
