// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ConversationMessage {
  String get text => throw _privateConstructorUsedError;
  bool get isUser => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get detectedIntent => throw _privateConstructorUsedError;
  SentimentLevel? get sentiment => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ConversationMessageCopyWith<ConversationMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationMessageCopyWith<$Res> {
  factory $ConversationMessageCopyWith(
          ConversationMessage value, $Res Function(ConversationMessage) then) =
      _$ConversationMessageCopyWithImpl<$Res, ConversationMessage>;
  @useResult
  $Res call(
      {String text,
      bool isUser,
      DateTime timestamp,
      String? detectedIntent,
      SentimentLevel? sentiment});
}

/// @nodoc
class _$ConversationMessageCopyWithImpl<$Res, $Val extends ConversationMessage>
    implements $ConversationMessageCopyWith<$Res> {
  _$ConversationMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? isUser = null,
    Object? timestamp = null,
    Object? detectedIntent = freezed,
    Object? sentiment = freezed,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      isUser: null == isUser
          ? _value.isUser
          : isUser // ignore: cast_nullable_to_non_nullable
              as bool,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      detectedIntent: freezed == detectedIntent
          ? _value.detectedIntent
          : detectedIntent // ignore: cast_nullable_to_non_nullable
              as String?,
      sentiment: freezed == sentiment
          ? _value.sentiment
          : sentiment // ignore: cast_nullable_to_non_nullable
              as SentimentLevel?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConversationMessageImplCopyWith<$Res>
    implements $ConversationMessageCopyWith<$Res> {
  factory _$$ConversationMessageImplCopyWith(_$ConversationMessageImpl value,
          $Res Function(_$ConversationMessageImpl) then) =
      __$$ConversationMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String text,
      bool isUser,
      DateTime timestamp,
      String? detectedIntent,
      SentimentLevel? sentiment});
}

/// @nodoc
class __$$ConversationMessageImplCopyWithImpl<$Res>
    extends _$ConversationMessageCopyWithImpl<$Res, _$ConversationMessageImpl>
    implements _$$ConversationMessageImplCopyWith<$Res> {
  __$$ConversationMessageImplCopyWithImpl(_$ConversationMessageImpl _value,
      $Res Function(_$ConversationMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? isUser = null,
    Object? timestamp = null,
    Object? detectedIntent = freezed,
    Object? sentiment = freezed,
  }) {
    return _then(_$ConversationMessageImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      isUser: null == isUser
          ? _value.isUser
          : isUser // ignore: cast_nullable_to_non_nullable
              as bool,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      detectedIntent: freezed == detectedIntent
          ? _value.detectedIntent
          : detectedIntent // ignore: cast_nullable_to_non_nullable
              as String?,
      sentiment: freezed == sentiment
          ? _value.sentiment
          : sentiment // ignore: cast_nullable_to_non_nullable
              as SentimentLevel?,
    ));
  }
}

/// @nodoc

class _$ConversationMessageImpl implements _ConversationMessage {
  const _$ConversationMessageImpl(
      {required this.text,
      required this.isUser,
      required this.timestamp,
      this.detectedIntent,
      this.sentiment});

  @override
  final String text;
  @override
  final bool isUser;
  @override
  final DateTime timestamp;
  @override
  final String? detectedIntent;
  @override
  final SentimentLevel? sentiment;

  @override
  String toString() {
    return 'ConversationMessage(text: $text, isUser: $isUser, timestamp: $timestamp, detectedIntent: $detectedIntent, sentiment: $sentiment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationMessageImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.isUser, isUser) || other.isUser == isUser) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.detectedIntent, detectedIntent) ||
                other.detectedIntent == detectedIntent) &&
            (identical(other.sentiment, sentiment) ||
                other.sentiment == sentiment));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, text, isUser, timestamp, detectedIntent, sentiment);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationMessageImplCopyWith<_$ConversationMessageImpl> get copyWith =>
      __$$ConversationMessageImplCopyWithImpl<_$ConversationMessageImpl>(
          this, _$identity);
}

abstract class _ConversationMessage implements ConversationMessage {
  const factory _ConversationMessage(
      {required final String text,
      required final bool isUser,
      required final DateTime timestamp,
      final String? detectedIntent,
      final SentimentLevel? sentiment}) = _$ConversationMessageImpl;

  @override
  String get text;
  @override
  bool get isUser;
  @override
  DateTime get timestamp;
  @override
  String? get detectedIntent;
  @override
  SentimentLevel? get sentiment;
  @override
  @JsonKey(ignore: true)
  _$$ConversationMessageImplCopyWith<_$ConversationMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
