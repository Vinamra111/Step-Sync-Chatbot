import '../data/models/conversation.dart';
import '../data/models/user_preferences.dart';

/// Interface that host applications must implement to integrate with the chatbot.
///
/// This adapter provides the connection between the chatbot and the host app's
/// backend services for data persistence and synchronization.
abstract class ChatBotBackendAdapter {
  /// Save a conversation to the backend.
  ///
  /// Called whenever the conversation state changes (new messages, etc.).
  /// Returns a Future that completes when the save is successful.
  Future<void> saveConversation(Conversation conversation);

  /// Load all conversations for a specific user.
  ///
  /// Returns a list of conversations, ordered by most recent first.
  Future<List<Conversation>> loadConversations(String userId);

  /// Save user preferences to the backend.
  ///
  /// Preferences include data source selection, notification settings, etc.
  Future<void> saveUserPreferences(UserPreferences preferences);

  /// Load user preferences from the backend.
  ///
  /// Returns preferences if they exist, or default preferences if not found.
  Future<UserPreferences> loadUserPreferences(String userId);

  /// Log an analytics event.
  ///
  /// Used for tracking chatbot usage, resolution rates, etc.
  /// Properties are arbitrary key-value pairs specific to each event.
  Future<void> logEvent(String eventName, Map<String, dynamic> properties);
}

/// Default implementation that keeps all data local (no backend sync).
///
/// Useful for development, testing, or apps that don't need multi-device sync.
class LocalOnlyBackendAdapter implements ChatBotBackendAdapter {
  @override
  Future<void> saveConversation(Conversation conversation) async {
    // No-op: data stays local only
  }

  @override
  Future<List<Conversation>> loadConversations(String userId) async {
    return [];
  }

  @override
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    // No-op: preferences stored locally via repository
  }

  @override
  Future<UserPreferences> loadUserPreferences(String userId) async {
    return UserPreferences.defaults(userId);
  }

  @override
  Future<void> logEvent(String eventName, Map<String, dynamic> properties) async {
    // No-op: no analytics in local mode
  }
}
