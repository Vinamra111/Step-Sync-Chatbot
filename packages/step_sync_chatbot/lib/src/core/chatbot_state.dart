import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/chat_message.dart';
import '../data/models/permission_state.dart';
import '../data/models/step_data.dart';

part 'chatbot_state.freezed.dart';

/// The complete state of the chatbot.
@freezed
class ChatBotState with _$ChatBotState {
  const factory ChatBotState({
    /// Current list of messages in the conversation.
    required List<ChatMessage> messages,

    /// Current conversation status.
    required ConversationStatus status,

    /// Current permission state.
    required PermissionState permissionState,

    /// Available data sources.
    @Default([]) List<DataSource> dataSources,

    /// Recent step data (for quick access).
    List<StepData>? recentStepData,

    /// Whether the bot is currently typing.
    @Default(false) bool isTyping,

    /// Whether the bot is currently streaming a response.
    @Default(false) bool isStreaming,

    /// Content of the message currently being streamed (partial text).
    String? streamingMessageContent,

    /// ID of the message being streamed (to update it progressively).
    String? streamingMessageId,

    /// Current error message, if any.
    String? errorMessage,

    /// User context for personalization.
    @Default({}) Map<String, dynamic> userContext,
  }) = _ChatBotState;

  /// Creates initial state.
  factory ChatBotState.initial() {
    return ChatBotState(
      messages: [],
      status: ConversationStatus.idle,
      permissionState: PermissionState.unknown(),
    );
  }
}

/// Status of the conversation.
enum ConversationStatus {
  /// Idle, waiting for user input.
  idle,

  /// Bot is processing user input.
  processing,

  /// Checking health data permissions.
  checkingPermissions,

  /// Waiting for user to grant permissions.
  waitingForPermission,

  /// Fetching health data.
  fetchingData,

  /// Running diagnostics.
  diagnosing,

  /// Streaming response (ChatGPT-like).
  streaming,

  /// An error occurred.
  error,
}
