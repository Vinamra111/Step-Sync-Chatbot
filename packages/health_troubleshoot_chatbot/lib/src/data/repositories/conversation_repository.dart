import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/user_preferences.dart';

/// Repository for managing conversation history and user preferences.
///
/// This interface defines methods for persisting and retrieving chatbot data.
/// Implementations can use SQLite, shared preferences, or remote storage.
abstract class ConversationRepository {
  /// Initialize the repository (e.g., create database tables).
  Future<void> initialize();

  /// Save a conversation to storage.
  ///
  /// If a conversation with the same ID exists, it will be updated.
  Future<void> saveConversation(Conversation conversation);

  /// Load all conversations for a user.
  ///
  /// Returns conversations sorted by last updated date (most recent first).
  /// If [limit] is provided, returns only the most recent N conversations.
  Future<List<Conversation>> loadConversations({
    required String userId,
    int? limit,
  });

  /// Load a specific conversation by ID.
  ///
  /// Returns null if conversation not found.
  Future<Conversation?> loadConversation(String conversationId);

  /// Load the most recent conversation for a user.
  ///
  /// Returns null if no conversations exist.
  Future<Conversation?> loadMostRecentConversation(String userId);

  /// Delete a conversation.
  Future<void> deleteConversation(String conversationId);

  /// Delete all conversations for a user.
  Future<void> deleteAllConversations(String userId);

  /// Save user preferences.
  Future<void> saveUserPreferences(UserPreferences preferences);

  /// Load user preferences.
  ///
  /// Returns null if no preferences found for user.
  Future<UserPreferences?> loadUserPreferences(String userId);

  /// Add a message to an existing conversation.
  ///
  /// This is a convenience method that loads the conversation,
  /// adds the message, and saves it back.
  Future<void> addMessageToConversation({
    required String conversationId,
    required ChatMessage message,
  });

  /// Get conversation statistics for a user.
  Future<ConversationStats> getStats(String userId);

  /// Clean up old conversations.
  ///
  /// Deletes conversations older than [retentionDays] days.
  Future<int> cleanupOldConversations({
    required String userId,
    required int retentionDays,
  });

  /// Close the repository and release resources.
  Future<void> close();
}

/// Statistics about a user's conversation history.
class ConversationStats {
  /// Total number of conversations.
  final int totalConversations;

  /// Total number of messages across all conversations.
  final int totalMessages;

  /// Date of first conversation.
  final DateTime? firstConversationDate;

  /// Date of most recent conversation.
  final DateTime? lastConversationDate;

  /// Average messages per conversation.
  double get averageMessagesPerConversation {
    if (totalConversations == 0) return 0;
    return totalMessages / totalConversations;
  }

  const ConversationStats({
    required this.totalConversations,
    required this.totalMessages,
    this.firstConversationDate,
    this.lastConversationDate,
  });

  factory ConversationStats.empty() {
    return const ConversationStats(
      totalConversations: 0,
      totalMessages: 0,
    );
  }
}
