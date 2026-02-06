// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Conversation _$ConversationFromJson(Map<String, dynamic> json) {
  return _Conversation.fromJson(json);
}

/// @nodoc
mixin _$Conversation {
  /// Unique identifier for this conversation.
  String get id => throw _privateConstructorUsedError;

  /// User ID who owns this conversation.
  String get userId => throw _privateConstructorUsedError;

  /// When the conversation was created.
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// When the conversation was last updated.
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// All messages in this conversation.
  List<ChatMessage> get messages => throw _privateConstructorUsedError;

  /// Optional title for the conversation.
  String? get title => throw _privateConstructorUsedError;

  /// Current status of the conversation.
  ConversationLifecycleStatus get status => throw _privateConstructorUsedError;

  /// Optional metadata (user context, diagnostic info, etc.).
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Whether this conversation is still active.
  bool get isActive => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ConversationCopyWith<Conversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationCopyWith<$Res> {
  factory $ConversationCopyWith(
          Conversation value, $Res Function(Conversation) then) =
      _$ConversationCopyWithImpl<$Res, Conversation>;
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime createdAt,
      DateTime updatedAt,
      List<ChatMessage> messages,
      String? title,
      ConversationLifecycleStatus status,
      Map<String, dynamic>? metadata,
      bool isActive});
}

/// @nodoc
class _$ConversationCopyWithImpl<$Res, $Val extends Conversation>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? messages = null,
    Object? title = freezed,
    Object? status = null,
    Object? metadata = freezed,
    Object? isActive = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ConversationLifecycleStatus,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConversationImplCopyWith<$Res>
    implements $ConversationCopyWith<$Res> {
  factory _$$ConversationImplCopyWith(
          _$ConversationImpl value, $Res Function(_$ConversationImpl) then) =
      __$$ConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime createdAt,
      DateTime updatedAt,
      List<ChatMessage> messages,
      String? title,
      ConversationLifecycleStatus status,
      Map<String, dynamic>? metadata,
      bool isActive});
}

/// @nodoc
class __$$ConversationImplCopyWithImpl<$Res>
    extends _$ConversationCopyWithImpl<$Res, _$ConversationImpl>
    implements _$$ConversationImplCopyWith<$Res> {
  __$$ConversationImplCopyWithImpl(
      _$ConversationImpl _value, $Res Function(_$ConversationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? messages = null,
    Object? title = freezed,
    Object? status = null,
    Object? metadata = freezed,
    Object? isActive = null,
  }) {
    return _then(_$ConversationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ConversationLifecycleStatus,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationImpl implements _Conversation {
  const _$ConversationImpl(
      {required this.id,
      required this.userId,
      required this.createdAt,
      required this.updatedAt,
      required final List<ChatMessage> messages,
      this.title,
      this.status = ConversationLifecycleStatus.active,
      final Map<String, dynamic>? metadata,
      this.isActive = true})
      : _messages = messages,
        _metadata = metadata;

  factory _$ConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationImplFromJson(json);

  /// Unique identifier for this conversation.
  @override
  final String id;

  /// User ID who owns this conversation.
  @override
  final String userId;

  /// When the conversation was created.
  @override
  final DateTime createdAt;

  /// When the conversation was last updated.
  @override
  final DateTime updatedAt;

  /// All messages in this conversation.
  final List<ChatMessage> _messages;

  /// All messages in this conversation.
  @override
  List<ChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  /// Optional title for the conversation.
  @override
  final String? title;

  /// Current status of the conversation.
  @override
  @JsonKey()
  final ConversationLifecycleStatus status;

  /// Optional metadata (user context, diagnostic info, etc.).
  final Map<String, dynamic>? _metadata;

  /// Optional metadata (user context, diagnostic info, etc.).
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Whether this conversation is still active.
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'Conversation(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, messages: $messages, title: $title, status: $status, metadata: $metadata, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(_messages),
      title,
      status,
      const DeepCollectionEquality().hash(_metadata),
      isActive);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      __$$ConversationImplCopyWithImpl<_$ConversationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationImplToJson(
      this,
    );
  }
}

abstract class _Conversation implements Conversation {
  const factory _Conversation(
      {required final String id,
      required final String userId,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      required final List<ChatMessage> messages,
      final String? title,
      final ConversationLifecycleStatus status,
      final Map<String, dynamic>? metadata,
      final bool isActive}) = _$ConversationImpl;

  factory _Conversation.fromJson(Map<String, dynamic> json) =
      _$ConversationImpl.fromJson;

  @override

  /// Unique identifier for this conversation.
  String get id;
  @override

  /// User ID who owns this conversation.
  String get userId;
  @override

  /// When the conversation was created.
  DateTime get createdAt;
  @override

  /// When the conversation was last updated.
  DateTime get updatedAt;
  @override

  /// All messages in this conversation.
  List<ChatMessage> get messages;
  @override

  /// Optional title for the conversation.
  String? get title;
  @override

  /// Current status of the conversation.
  ConversationLifecycleStatus get status;
  @override

  /// Optional metadata (user context, diagnostic info, etc.).
  Map<String, dynamic>? get metadata;
  @override

  /// Whether this conversation is still active.
  bool get isActive;
  @override
  @JsonKey(ignore: true)
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
