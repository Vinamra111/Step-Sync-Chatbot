// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'llm_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LLMResponse _$LLMResponseFromJson(Map<String, dynamic> json) {
  return _LLMResponse.fromJson(json);
}

/// @nodoc
mixin _$LLMResponse {
  /// Generated response text.
  String get text => throw _privateConstructorUsedError;

  /// Provider that generated the response.
  String get provider => throw _privateConstructorUsedError;

  /// Model used for generation.
  String get model => throw _privateConstructorUsedError;

  /// Number of tokens in the prompt.
  int get promptTokens => throw _privateConstructorUsedError;

  /// Number of tokens in the completion.
  int get completionTokens => throw _privateConstructorUsedError;

  /// Total tokens used.
  int get totalTokens => throw _privateConstructorUsedError;

  /// Estimated cost in USD.
  double get estimatedCost => throw _privateConstructorUsedError;

  /// Response time in milliseconds.
  int get responseTimeMs => throw _privateConstructorUsedError;

  /// Whether the response was successful.
  bool get success => throw _privateConstructorUsedError;

  /// Error message if failed.
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Timestamp when response was generated.
  DateTime? get timestamp => throw _privateConstructorUsedError;

  /// Additional metadata from provider.
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LLMResponseCopyWith<LLMResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LLMResponseCopyWith<$Res> {
  factory $LLMResponseCopyWith(
          LLMResponse value, $Res Function(LLMResponse) then) =
      _$LLMResponseCopyWithImpl<$Res, LLMResponse>;
  @useResult
  $Res call(
      {String text,
      String provider,
      String model,
      int promptTokens,
      int completionTokens,
      int totalTokens,
      double estimatedCost,
      int responseTimeMs,
      bool success,
      String? errorMessage,
      DateTime? timestamp,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$LLMResponseCopyWithImpl<$Res, $Val extends LLMResponse>
    implements $LLMResponseCopyWith<$Res> {
  _$LLMResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? provider = null,
    Object? model = null,
    Object? promptTokens = null,
    Object? completionTokens = null,
    Object? totalTokens = null,
    Object? estimatedCost = null,
    Object? responseTimeMs = null,
    Object? success = null,
    Object? errorMessage = freezed,
    Object? timestamp = freezed,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      promptTokens: null == promptTokens
          ? _value.promptTokens
          : promptTokens // ignore: cast_nullable_to_non_nullable
              as int,
      completionTokens: null == completionTokens
          ? _value.completionTokens
          : completionTokens // ignore: cast_nullable_to_non_nullable
              as int,
      totalTokens: null == totalTokens
          ? _value.totalTokens
          : totalTokens // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedCost: null == estimatedCost
          ? _value.estimatedCost
          : estimatedCost // ignore: cast_nullable_to_non_nullable
              as double,
      responseTimeMs: null == responseTimeMs
          ? _value.responseTimeMs
          : responseTimeMs // ignore: cast_nullable_to_non_nullable
              as int,
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LLMResponseImplCopyWith<$Res>
    implements $LLMResponseCopyWith<$Res> {
  factory _$$LLMResponseImplCopyWith(
          _$LLMResponseImpl value, $Res Function(_$LLMResponseImpl) then) =
      __$$LLMResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String text,
      String provider,
      String model,
      int promptTokens,
      int completionTokens,
      int totalTokens,
      double estimatedCost,
      int responseTimeMs,
      bool success,
      String? errorMessage,
      DateTime? timestamp,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$$LLMResponseImplCopyWithImpl<$Res>
    extends _$LLMResponseCopyWithImpl<$Res, _$LLMResponseImpl>
    implements _$$LLMResponseImplCopyWith<$Res> {
  __$$LLMResponseImplCopyWithImpl(
      _$LLMResponseImpl _value, $Res Function(_$LLMResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? provider = null,
    Object? model = null,
    Object? promptTokens = null,
    Object? completionTokens = null,
    Object? totalTokens = null,
    Object? estimatedCost = null,
    Object? responseTimeMs = null,
    Object? success = null,
    Object? errorMessage = freezed,
    Object? timestamp = freezed,
    Object? metadata = null,
  }) {
    return _then(_$LLMResponseImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
      model: null == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      promptTokens: null == promptTokens
          ? _value.promptTokens
          : promptTokens // ignore: cast_nullable_to_non_nullable
              as int,
      completionTokens: null == completionTokens
          ? _value.completionTokens
          : completionTokens // ignore: cast_nullable_to_non_nullable
              as int,
      totalTokens: null == totalTokens
          ? _value.totalTokens
          : totalTokens // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedCost: null == estimatedCost
          ? _value.estimatedCost
          : estimatedCost // ignore: cast_nullable_to_non_nullable
              as double,
      responseTimeMs: null == responseTimeMs
          ? _value.responseTimeMs
          : responseTimeMs // ignore: cast_nullable_to_non_nullable
              as int,
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LLMResponseImpl implements _LLMResponse {
  const _$LLMResponseImpl(
      {required this.text,
      required this.provider,
      required this.model,
      this.promptTokens = 0,
      this.completionTokens = 0,
      this.totalTokens = 0,
      this.estimatedCost = 0.0,
      this.responseTimeMs = 0,
      this.success = true,
      this.errorMessage,
      this.timestamp,
      final Map<String, dynamic> metadata = const {}})
      : _metadata = metadata;

  factory _$LLMResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LLMResponseImplFromJson(json);

  /// Generated response text.
  @override
  final String text;

  /// Provider that generated the response.
  @override
  final String provider;

  /// Model used for generation.
  @override
  final String model;

  /// Number of tokens in the prompt.
  @override
  @JsonKey()
  final int promptTokens;

  /// Number of tokens in the completion.
  @override
  @JsonKey()
  final int completionTokens;

  /// Total tokens used.
  @override
  @JsonKey()
  final int totalTokens;

  /// Estimated cost in USD.
  @override
  @JsonKey()
  final double estimatedCost;

  /// Response time in milliseconds.
  @override
  @JsonKey()
  final int responseTimeMs;

  /// Whether the response was successful.
  @override
  @JsonKey()
  final bool success;

  /// Error message if failed.
  @override
  final String? errorMessage;

  /// Timestamp when response was generated.
  @override
  final DateTime? timestamp;

  /// Additional metadata from provider.
  final Map<String, dynamic> _metadata;

  /// Additional metadata from provider.
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'LLMResponse(text: $text, provider: $provider, model: $model, promptTokens: $promptTokens, completionTokens: $completionTokens, totalTokens: $totalTokens, estimatedCost: $estimatedCost, responseTimeMs: $responseTimeMs, success: $success, errorMessage: $errorMessage, timestamp: $timestamp, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LLMResponseImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.promptTokens, promptTokens) ||
                other.promptTokens == promptTokens) &&
            (identical(other.completionTokens, completionTokens) ||
                other.completionTokens == completionTokens) &&
            (identical(other.totalTokens, totalTokens) ||
                other.totalTokens == totalTokens) &&
            (identical(other.estimatedCost, estimatedCost) ||
                other.estimatedCost == estimatedCost) &&
            (identical(other.responseTimeMs, responseTimeMs) ||
                other.responseTimeMs == responseTimeMs) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      text,
      provider,
      model,
      promptTokens,
      completionTokens,
      totalTokens,
      estimatedCost,
      responseTimeMs,
      success,
      errorMessage,
      timestamp,
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LLMResponseImplCopyWith<_$LLMResponseImpl> get copyWith =>
      __$$LLMResponseImplCopyWithImpl<_$LLMResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LLMResponseImplToJson(
      this,
    );
  }
}

abstract class _LLMResponse implements LLMResponse {
  const factory _LLMResponse(
      {required final String text,
      required final String provider,
      required final String model,
      final int promptTokens,
      final int completionTokens,
      final int totalTokens,
      final double estimatedCost,
      final int responseTimeMs,
      final bool success,
      final String? errorMessage,
      final DateTime? timestamp,
      final Map<String, dynamic> metadata}) = _$LLMResponseImpl;

  factory _LLMResponse.fromJson(Map<String, dynamic> json) =
      _$LLMResponseImpl.fromJson;

  @override

  /// Generated response text.
  String get text;
  @override

  /// Provider that generated the response.
  String get provider;
  @override

  /// Model used for generation.
  String get model;
  @override

  /// Number of tokens in the prompt.
  int get promptTokens;
  @override

  /// Number of tokens in the completion.
  int get completionTokens;
  @override

  /// Total tokens used.
  int get totalTokens;
  @override

  /// Estimated cost in USD.
  double get estimatedCost;
  @override

  /// Response time in milliseconds.
  int get responseTimeMs;
  @override

  /// Whether the response was successful.
  bool get success;
  @override

  /// Error message if failed.
  String? get errorMessage;
  @override

  /// Timestamp when response was generated.
  DateTime? get timestamp;
  @override

  /// Additional metadata from provider.
  Map<String, dynamic> get metadata;
  @override
  @JsonKey(ignore: true)
  _$$LLMResponseImplCopyWith<_$LLMResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
