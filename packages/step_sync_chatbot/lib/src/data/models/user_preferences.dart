import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

/// User preferences for the chatbot.
@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    /// User ID these preferences belong to.
    required String userId,

    /// Preferred primary data source (e.g., "com.samsung.android.app.health").
    String? preferredDataSource,

    /// Whether to enable notifications.
    @Default(true) bool notificationsEnabled,

    /// Conversation style preference.
    @Default(ConversationStyle.balanced) ConversationStyle conversationStyle,

    /// Topics the user has already learned about (don't re-explain).
    @Default([]) List<String> learnedTopics,

    /// When preferences were last updated.
    DateTime? lastUpdated,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);

  /// Creates default preferences for a user.
  factory UserPreferences.defaults(String userId) {
    return UserPreferences(
      userId: userId,
      notificationsEnabled: true,
      conversationStyle: ConversationStyle.balanced,
      learnedTopics: [],
      lastUpdated: DateTime.now(),
    );
  }
}

/// How verbose the chatbot should be.
enum ConversationStyle {
  /// Brief, to-the-point responses.
  concise,

  /// Standard level of detail.
  balanced,

  /// Detailed explanations with context.
  detailed,
}
