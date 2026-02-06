// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chatbot_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChatBotState {
  /// Current list of messages in the conversation.
  List<ChatMessage> get messages => throw _privateConstructorUsedError;

  /// Current conversation status.
  ConversationStatus get status => throw _privateConstructorUsedError;

  /// Current permission state.
  PermissionState get permissionState => throw _privateConstructorUsedError;

  /// Available data sources.
  List<DataSource> get dataSources => throw _privateConstructorUsedError;

  /// Recent step data (for quick access).
  List<StepData>? get recentStepData => throw _privateConstructorUsedError;

  /// Whether the bot is currently typing.
  bool get isTyping => throw _privateConstructorUsedError;

  /// Current error message, if any.
  String? get errorMessage => throw _privateConstructorUsedError;

  /// User context for personalization.
  Map<String, dynamic> get userContext => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChatBotStateCopyWith<ChatBotState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatBotStateCopyWith<$Res> {
  factory $ChatBotStateCopyWith(
          ChatBotState value, $Res Function(ChatBotState) then) =
      _$ChatBotStateCopyWithImpl<$Res, ChatBotState>;
  @useResult
  $Res call(
      {List<ChatMessage> messages,
      ConversationStatus status,
      PermissionState permissionState,
      List<DataSource> dataSources,
      List<StepData>? recentStepData,
      bool isTyping,
      String? errorMessage,
      Map<String, dynamic> userContext});

  $PermissionStateCopyWith<$Res> get permissionState;
}

/// @nodoc
class _$ChatBotStateCopyWithImpl<$Res, $Val extends ChatBotState>
    implements $ChatBotStateCopyWith<$Res> {
  _$ChatBotStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? status = null,
    Object? permissionState = null,
    Object? dataSources = null,
    Object? recentStepData = freezed,
    Object? isTyping = null,
    Object? errorMessage = freezed,
    Object? userContext = null,
  }) {
    return _then(_value.copyWith(
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ConversationStatus,
      permissionState: null == permissionState
          ? _value.permissionState
          : permissionState // ignore: cast_nullable_to_non_nullable
              as PermissionState,
      dataSources: null == dataSources
          ? _value.dataSources
          : dataSources // ignore: cast_nullable_to_non_nullable
              as List<DataSource>,
      recentStepData: freezed == recentStepData
          ? _value.recentStepData
          : recentStepData // ignore: cast_nullable_to_non_nullable
              as List<StepData>?,
      isTyping: null == isTyping
          ? _value.isTyping
          : isTyping // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      userContext: null == userContext
          ? _value.userContext
          : userContext // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PermissionStateCopyWith<$Res> get permissionState {
    return $PermissionStateCopyWith<$Res>(_value.permissionState, (value) {
      return _then(_value.copyWith(permissionState: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ChatBotStateImplCopyWith<$Res>
    implements $ChatBotStateCopyWith<$Res> {
  factory _$$ChatBotStateImplCopyWith(
          _$ChatBotStateImpl value, $Res Function(_$ChatBotStateImpl) then) =
      __$$ChatBotStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ChatMessage> messages,
      ConversationStatus status,
      PermissionState permissionState,
      List<DataSource> dataSources,
      List<StepData>? recentStepData,
      bool isTyping,
      String? errorMessage,
      Map<String, dynamic> userContext});

  @override
  $PermissionStateCopyWith<$Res> get permissionState;
}

/// @nodoc
class __$$ChatBotStateImplCopyWithImpl<$Res>
    extends _$ChatBotStateCopyWithImpl<$Res, _$ChatBotStateImpl>
    implements _$$ChatBotStateImplCopyWith<$Res> {
  __$$ChatBotStateImplCopyWithImpl(
      _$ChatBotStateImpl _value, $Res Function(_$ChatBotStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? status = null,
    Object? permissionState = null,
    Object? dataSources = null,
    Object? recentStepData = freezed,
    Object? isTyping = null,
    Object? errorMessage = freezed,
    Object? userContext = null,
  }) {
    return _then(_$ChatBotStateImpl(
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ConversationStatus,
      permissionState: null == permissionState
          ? _value.permissionState
          : permissionState // ignore: cast_nullable_to_non_nullable
              as PermissionState,
      dataSources: null == dataSources
          ? _value._dataSources
          : dataSources // ignore: cast_nullable_to_non_nullable
              as List<DataSource>,
      recentStepData: freezed == recentStepData
          ? _value._recentStepData
          : recentStepData // ignore: cast_nullable_to_non_nullable
              as List<StepData>?,
      isTyping: null == isTyping
          ? _value.isTyping
          : isTyping // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      userContext: null == userContext
          ? _value._userContext
          : userContext // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

class _$ChatBotStateImpl implements _ChatBotState {
  const _$ChatBotStateImpl(
      {required final List<ChatMessage> messages,
      required this.status,
      required this.permissionState,
      final List<DataSource> dataSources = const [],
      final List<StepData>? recentStepData,
      this.isTyping = false,
      this.errorMessage,
      final Map<String, dynamic> userContext = const {}})
      : _messages = messages,
        _dataSources = dataSources,
        _recentStepData = recentStepData,
        _userContext = userContext;

  /// Current list of messages in the conversation.
  final List<ChatMessage> _messages;

  /// Current list of messages in the conversation.
  @override
  List<ChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  /// Current conversation status.
  @override
  final ConversationStatus status;

  /// Current permission state.
  @override
  final PermissionState permissionState;

  /// Available data sources.
  final List<DataSource> _dataSources;

  /// Available data sources.
  @override
  @JsonKey()
  List<DataSource> get dataSources {
    if (_dataSources is EqualUnmodifiableListView) return _dataSources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dataSources);
  }

  /// Recent step data (for quick access).
  final List<StepData>? _recentStepData;

  /// Recent step data (for quick access).
  @override
  List<StepData>? get recentStepData {
    final value = _recentStepData;
    if (value == null) return null;
    if (_recentStepData is EqualUnmodifiableListView) return _recentStepData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Whether the bot is currently typing.
  @override
  @JsonKey()
  final bool isTyping;

  /// Current error message, if any.
  @override
  final String? errorMessage;

  /// User context for personalization.
  final Map<String, dynamic> _userContext;

  /// User context for personalization.
  @override
  @JsonKey()
  Map<String, dynamic> get userContext {
    if (_userContext is EqualUnmodifiableMapView) return _userContext;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_userContext);
  }

  @override
  String toString() {
    return 'ChatBotState(messages: $messages, status: $status, permissionState: $permissionState, dataSources: $dataSources, recentStepData: $recentStepData, isTyping: $isTyping, errorMessage: $errorMessage, userContext: $userContext)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatBotStateImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.permissionState, permissionState) ||
                other.permissionState == permissionState) &&
            const DeepCollectionEquality()
                .equals(other._dataSources, _dataSources) &&
            const DeepCollectionEquality()
                .equals(other._recentStepData, _recentStepData) &&
            (identical(other.isTyping, isTyping) ||
                other.isTyping == isTyping) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality()
                .equals(other._userContext, _userContext));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_messages),
      status,
      permissionState,
      const DeepCollectionEquality().hash(_dataSources),
      const DeepCollectionEquality().hash(_recentStepData),
      isTyping,
      errorMessage,
      const DeepCollectionEquality().hash(_userContext));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatBotStateImplCopyWith<_$ChatBotStateImpl> get copyWith =>
      __$$ChatBotStateImplCopyWithImpl<_$ChatBotStateImpl>(this, _$identity);
}

abstract class _ChatBotState implements ChatBotState {
  const factory _ChatBotState(
      {required final List<ChatMessage> messages,
      required final ConversationStatus status,
      required final PermissionState permissionState,
      final List<DataSource> dataSources,
      final List<StepData>? recentStepData,
      final bool isTyping,
      final String? errorMessage,
      final Map<String, dynamic> userContext}) = _$ChatBotStateImpl;

  @override

  /// Current list of messages in the conversation.
  List<ChatMessage> get messages;
  @override

  /// Current conversation status.
  ConversationStatus get status;
  @override

  /// Current permission state.
  PermissionState get permissionState;
  @override

  /// Available data sources.
  List<DataSource> get dataSources;
  @override

  /// Recent step data (for quick access).
  List<StepData>? get recentStepData;
  @override

  /// Whether the bot is currently typing.
  bool get isTyping;
  @override

  /// Current error message, if any.
  String? get errorMessage;
  @override

  /// User context for personalization.
  Map<String, dynamic> get userContext;
  @override
  @JsonKey(ignore: true)
  _$$ChatBotStateImplCopyWith<_$ChatBotStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
