import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Represents a single message in a chat conversation.
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    /// Unique identifier for this message.
    required String id,

    /// The text content of the message.
    required String text,

    /// Who sent this message.
    required MessageSender sender,

    /// When this message was sent.
    required DateTime timestamp,

    /// Type of message (text, chart, permission request, etc.).
    @Default(MessageType.text) MessageType type,

    /// Additional data for special message types (e.g., chart data, buttons).
    Map<String, dynamic>? data,

    /// Whether this message represents an error.
    @Default(false) bool isError,

    /// Quick reply options to show with this message.
    List<QuickReply>? quickReplies,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// Creates a user message.
  factory ChatMessage.user({
    required String text,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a bot message.
  factory ChatMessage.bot({
    required String text,
    MessageType type = MessageType.text,
    Map<String, dynamic>? data,
    List<QuickReply>? quickReplies,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
      type: type,
      data: data,
      quickReplies: quickReplies,
    );
  }

  /// Creates an error message.
  factory ChatMessage.error({
    required String text,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
      isError: true,
    );
  }
}

/// Who sent a message.
enum MessageSender {
  user,
  bot,
  system,
}

/// Type of message content.
enum MessageType {
  text,
  stepChart,
  permissionRequest,
  error,
}

/// Quick reply button option.
@freezed
class QuickReply with _$QuickReply {
  const factory QuickReply({
    required String label,
    required String value,
    String? icon,
  }) = _QuickReply;

  factory QuickReply.fromJson(Map<String, dynamic> json) =>
      _$QuickReplyFromJson(json);
}
