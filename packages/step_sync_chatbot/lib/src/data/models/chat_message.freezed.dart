// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  /// Unique identifier for this message.
  String get id => throw _privateConstructorUsedError;

  /// The text content of the message.
  String get text => throw _privateConstructorUsedError;

  /// Who sent this message.
  MessageSender get sender => throw _privateConstructorUsedError;

  /// When this message was sent.
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Type of message (text, chart, permission request, etc.).
  MessageType get type => throw _privateConstructorUsedError;

  /// Additional data for special message types (e.g., chart data, buttons).
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;

  /// Whether this message represents an error.
  bool get isError => throw _privateConstructorUsedError;

  /// Quick reply options to show with this message.
  List<QuickReply>? get quickReplies => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {String id,
      String text,
      MessageSender sender,
      DateTime timestamp,
      MessageType type,
      Map<String, dynamic>? data,
      bool isError,
      List<QuickReply>? quickReplies});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? sender = null,
    Object? timestamp = null,
    Object? type = null,
    Object? data = freezed,
    Object? isError = null,
    Object? quickReplies = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      sender: null == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as MessageSender,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MessageType,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      isError: null == isError
          ? _value.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      quickReplies: freezed == quickReplies
          ? _value.quickReplies
          : quickReplies // ignore: cast_nullable_to_non_nullable
              as List<QuickReply>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String text,
      MessageSender sender,
      DateTime timestamp,
      MessageType type,
      Map<String, dynamic>? data,
      bool isError,
      List<QuickReply>? quickReplies});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? sender = null,
    Object? timestamp = null,
    Object? type = null,
    Object? data = freezed,
    Object? isError = null,
    Object? quickReplies = freezed,
  }) {
    return _then(_$ChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      sender: null == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as MessageSender,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MessageType,
      data: freezed == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      isError: null == isError
          ? _value.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      quickReplies: freezed == quickReplies
          ? _value._quickReplies
          : quickReplies // ignore: cast_nullable_to_non_nullable
              as List<QuickReply>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl(
      {required this.id,
      required this.text,
      required this.sender,
      required this.timestamp,
      this.type = MessageType.text,
      final Map<String, dynamic>? data,
      this.isError = false,
      final List<QuickReply>? quickReplies})
      : _data = data,
        _quickReplies = quickReplies;

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  /// Unique identifier for this message.
  @override
  final String id;

  /// The text content of the message.
  @override
  final String text;

  /// Who sent this message.
  @override
  final MessageSender sender;

  /// When this message was sent.
  @override
  final DateTime timestamp;

  /// Type of message (text, chart, permission request, etc.).
  @override
  @JsonKey()
  final MessageType type;

  /// Additional data for special message types (e.g., chart data, buttons).
  final Map<String, dynamic>? _data;

  /// Additional data for special message types (e.g., chart data, buttons).
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Whether this message represents an error.
  @override
  @JsonKey()
  final bool isError;

  /// Quick reply options to show with this message.
  final List<QuickReply>? _quickReplies;

  /// Quick reply options to show with this message.
  @override
  List<QuickReply>? get quickReplies {
    final value = _quickReplies;
    if (value == null) return null;
    if (_quickReplies is EqualUnmodifiableListView) return _quickReplies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, text: $text, sender: $sender, timestamp: $timestamp, type: $type, data: $data, isError: $isError, quickReplies: $quickReplies)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.sender, sender) || other.sender == sender) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.isError, isError) || other.isError == isError) &&
            const DeepCollectionEquality()
                .equals(other._quickReplies, _quickReplies));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      text,
      sender,
      timestamp,
      type,
      const DeepCollectionEquality().hash(_data),
      isError,
      const DeepCollectionEquality().hash(_quickReplies));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage(
      {required final String id,
      required final String text,
      required final MessageSender sender,
      required final DateTime timestamp,
      final MessageType type,
      final Map<String, dynamic>? data,
      final bool isError,
      final List<QuickReply>? quickReplies}) = _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override

  /// Unique identifier for this message.
  String get id;
  @override

  /// The text content of the message.
  String get text;
  @override

  /// Who sent this message.
  MessageSender get sender;
  @override

  /// When this message was sent.
  DateTime get timestamp;
  @override

  /// Type of message (text, chart, permission request, etc.).
  MessageType get type;
  @override

  /// Additional data for special message types (e.g., chart data, buttons).
  Map<String, dynamic>? get data;
  @override

  /// Whether this message represents an error.
  bool get isError;
  @override

  /// Quick reply options to show with this message.
  List<QuickReply>? get quickReplies;
  @override
  @JsonKey(ignore: true)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QuickReply _$QuickReplyFromJson(Map<String, dynamic> json) {
  return _QuickReply.fromJson(json);
}

/// @nodoc
mixin _$QuickReply {
  String get label => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  String? get icon => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuickReplyCopyWith<QuickReply> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuickReplyCopyWith<$Res> {
  factory $QuickReplyCopyWith(
          QuickReply value, $Res Function(QuickReply) then) =
      _$QuickReplyCopyWithImpl<$Res, QuickReply>;
  @useResult
  $Res call({String label, String value, String? icon});
}

/// @nodoc
class _$QuickReplyCopyWithImpl<$Res, $Val extends QuickReply>
    implements $QuickReplyCopyWith<$Res> {
  _$QuickReplyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? icon = freezed,
  }) {
    return _then(_value.copyWith(
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuickReplyImplCopyWith<$Res>
    implements $QuickReplyCopyWith<$Res> {
  factory _$$QuickReplyImplCopyWith(
          _$QuickReplyImpl value, $Res Function(_$QuickReplyImpl) then) =
      __$$QuickReplyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String label, String value, String? icon});
}

/// @nodoc
class __$$QuickReplyImplCopyWithImpl<$Res>
    extends _$QuickReplyCopyWithImpl<$Res, _$QuickReplyImpl>
    implements _$$QuickReplyImplCopyWith<$Res> {
  __$$QuickReplyImplCopyWithImpl(
      _$QuickReplyImpl _value, $Res Function(_$QuickReplyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? icon = freezed,
  }) {
    return _then(_$QuickReplyImpl(
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuickReplyImpl implements _QuickReply {
  const _$QuickReplyImpl({required this.label, required this.value, this.icon});

  factory _$QuickReplyImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuickReplyImplFromJson(json);

  @override
  final String label;
  @override
  final String value;
  @override
  final String? icon;

  @override
  String toString() {
    return 'QuickReply(label: $label, value: $value, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuickReplyImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, label, value, icon);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuickReplyImplCopyWith<_$QuickReplyImpl> get copyWith =>
      __$$QuickReplyImplCopyWithImpl<_$QuickReplyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuickReplyImplToJson(
      this,
    );
  }
}

abstract class _QuickReply implements QuickReply {
  const factory _QuickReply(
      {required final String label,
      required final String value,
      final String? icon}) = _$QuickReplyImpl;

  factory _QuickReply.fromJson(Map<String, dynamic> json) =
      _$QuickReplyImpl.fromJson;

  @override
  String get label;
  @override
  String get value;
  @override
  String? get icon;
  @override
  @JsonKey(ignore: true)
  _$$QuickReplyImplCopyWith<_$QuickReplyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
