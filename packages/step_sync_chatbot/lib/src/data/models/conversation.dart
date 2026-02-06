import 'package:freezed_annotation/freezed_annotation.dart';
import 'chat_message.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// Conversation lifecycle status (for data persistence)
enum ConversationLifecycleStatus {
  active,
  completed,
  archived,
}

/// Represents a complete conversation session with the chatbot.
@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    /// Unique identifier for this conversation.
    required String id,

    /// User ID who owns this conversation.
    required String userId,

    /// When the conversation was created.
    required DateTime createdAt,

    /// When the conversation was last updated.
    required DateTime updatedAt,

    /// All messages in this conversation.
    required List<ChatMessage> messages,

    /// Optional title for the conversation.
    String? title,

    /// Current status of the conversation.
    @Default(ConversationLifecycleStatus.active) ConversationLifecycleStatus status,

    /// Optional metadata (user context, diagnostic info, etc.).
    Map<String, dynamic>? metadata,

    /// Whether this conversation is still active.
    @Default(true) bool isActive,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  /// Creates a new conversation for a user.
  factory Conversation.create({
    required String userId,
    String? id,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: id ?? 'conv_${now.millisecondsSinceEpoch}',
      userId: userId,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }
}
