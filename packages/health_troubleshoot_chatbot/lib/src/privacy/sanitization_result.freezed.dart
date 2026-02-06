// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sanitization_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SanitizationResult _$SanitizationResultFromJson(Map<String, dynamic> json) {
  return _SanitizationResult.fromJson(json);
}

/// @nodoc
mixin _$SanitizationResult {
  /// Original text before sanitization.
  String get originalText => throw _privateConstructorUsedError;

  /// Sanitized text safe for sending to LLM.
  String get sanitizedText => throw _privateConstructorUsedError;

  /// List of detected entities.
  List<DetectedEntity> get detectedEntities =>
      throw _privateConstructorUsedError;

  /// Whether the text is safe to send to LLM.
  ///
  /// Even after sanitization, some texts with critical PII
  /// should not be sent (defense in depth).
  bool get isSafe => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SanitizationResultCopyWith<SanitizationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SanitizationResultCopyWith<$Res> {
  factory $SanitizationResultCopyWith(
          SanitizationResult value, $Res Function(SanitizationResult) then) =
      _$SanitizationResultCopyWithImpl<$Res, SanitizationResult>;
  @useResult
  $Res call(
      {String originalText,
      String sanitizedText,
      List<DetectedEntity> detectedEntities,
      bool isSafe});
}

/// @nodoc
class _$SanitizationResultCopyWithImpl<$Res, $Val extends SanitizationResult>
    implements $SanitizationResultCopyWith<$Res> {
  _$SanitizationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalText = null,
    Object? sanitizedText = null,
    Object? detectedEntities = null,
    Object? isSafe = null,
  }) {
    return _then(_value.copyWith(
      originalText: null == originalText
          ? _value.originalText
          : originalText // ignore: cast_nullable_to_non_nullable
              as String,
      sanitizedText: null == sanitizedText
          ? _value.sanitizedText
          : sanitizedText // ignore: cast_nullable_to_non_nullable
              as String,
      detectedEntities: null == detectedEntities
          ? _value.detectedEntities
          : detectedEntities // ignore: cast_nullable_to_non_nullable
              as List<DetectedEntity>,
      isSafe: null == isSafe
          ? _value.isSafe
          : isSafe // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SanitizationResultImplCopyWith<$Res>
    implements $SanitizationResultCopyWith<$Res> {
  factory _$$SanitizationResultImplCopyWith(_$SanitizationResultImpl value,
          $Res Function(_$SanitizationResultImpl) then) =
      __$$SanitizationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String originalText,
      String sanitizedText,
      List<DetectedEntity> detectedEntities,
      bool isSafe});
}

/// @nodoc
class __$$SanitizationResultImplCopyWithImpl<$Res>
    extends _$SanitizationResultCopyWithImpl<$Res, _$SanitizationResultImpl>
    implements _$$SanitizationResultImplCopyWith<$Res> {
  __$$SanitizationResultImplCopyWithImpl(_$SanitizationResultImpl _value,
      $Res Function(_$SanitizationResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalText = null,
    Object? sanitizedText = null,
    Object? detectedEntities = null,
    Object? isSafe = null,
  }) {
    return _then(_$SanitizationResultImpl(
      originalText: null == originalText
          ? _value.originalText
          : originalText // ignore: cast_nullable_to_non_nullable
              as String,
      sanitizedText: null == sanitizedText
          ? _value.sanitizedText
          : sanitizedText // ignore: cast_nullable_to_non_nullable
              as String,
      detectedEntities: null == detectedEntities
          ? _value._detectedEntities
          : detectedEntities // ignore: cast_nullable_to_non_nullable
              as List<DetectedEntity>,
      isSafe: null == isSafe
          ? _value.isSafe
          : isSafe // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SanitizationResultImpl implements _SanitizationResult {
  const _$SanitizationResultImpl(
      {required this.originalText,
      required this.sanitizedText,
      final List<DetectedEntity> detectedEntities = const [],
      required this.isSafe})
      : _detectedEntities = detectedEntities;

  factory _$SanitizationResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SanitizationResultImplFromJson(json);

  /// Original text before sanitization.
  @override
  final String originalText;

  /// Sanitized text safe for sending to LLM.
  @override
  final String sanitizedText;

  /// List of detected entities.
  final List<DetectedEntity> _detectedEntities;

  /// List of detected entities.
  @override
  @JsonKey()
  List<DetectedEntity> get detectedEntities {
    if (_detectedEntities is EqualUnmodifiableListView)
      return _detectedEntities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_detectedEntities);
  }

  /// Whether the text is safe to send to LLM.
  ///
  /// Even after sanitization, some texts with critical PII
  /// should not be sent (defense in depth).
  @override
  final bool isSafe;

  @override
  String toString() {
    return 'SanitizationResult(originalText: $originalText, sanitizedText: $sanitizedText, detectedEntities: $detectedEntities, isSafe: $isSafe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SanitizationResultImpl &&
            (identical(other.originalText, originalText) ||
                other.originalText == originalText) &&
            (identical(other.sanitizedText, sanitizedText) ||
                other.sanitizedText == sanitizedText) &&
            const DeepCollectionEquality()
                .equals(other._detectedEntities, _detectedEntities) &&
            (identical(other.isSafe, isSafe) || other.isSafe == isSafe));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, originalText, sanitizedText,
      const DeepCollectionEquality().hash(_detectedEntities), isSafe);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SanitizationResultImplCopyWith<_$SanitizationResultImpl> get copyWith =>
      __$$SanitizationResultImplCopyWithImpl<_$SanitizationResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SanitizationResultImplToJson(
      this,
    );
  }
}

abstract class _SanitizationResult implements SanitizationResult {
  const factory _SanitizationResult(
      {required final String originalText,
      required final String sanitizedText,
      final List<DetectedEntity> detectedEntities,
      required final bool isSafe}) = _$SanitizationResultImpl;

  factory _SanitizationResult.fromJson(Map<String, dynamic> json) =
      _$SanitizationResultImpl.fromJson;

  @override

  /// Original text before sanitization.
  String get originalText;
  @override

  /// Sanitized text safe for sending to LLM.
  String get sanitizedText;
  @override

  /// List of detected entities.
  List<DetectedEntity> get detectedEntities;
  @override

  /// Whether the text is safe to send to LLM.
  ///
  /// Even after sanitization, some texts with critical PII
  /// should not be sent (defense in depth).
  bool get isSafe;
  @override
  @JsonKey(ignore: true)
  _$$SanitizationResultImplCopyWith<_$SanitizationResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DetectedEntity _$DetectedEntityFromJson(Map<String, dynamic> json) {
  return _DetectedEntity.fromJson(json);
}

/// @nodoc
mixin _$DetectedEntity {
  /// Type of entity detected.
  EntityType get type => throw _privateConstructorUsedError;

  /// Original value found in text.
  String get originalValue => throw _privateConstructorUsedError;

  /// Sanitized replacement value.
  String get sanitizedValue => throw _privateConstructorUsedError;

  /// Start index in original text.
  int get startIndex => throw _privateConstructorUsedError;

  /// End index in original text.
  int get endIndex => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DetectedEntityCopyWith<DetectedEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectedEntityCopyWith<$Res> {
  factory $DetectedEntityCopyWith(
          DetectedEntity value, $Res Function(DetectedEntity) then) =
      _$DetectedEntityCopyWithImpl<$Res, DetectedEntity>;
  @useResult
  $Res call(
      {EntityType type,
      String originalValue,
      String sanitizedValue,
      int startIndex,
      int endIndex});
}

/// @nodoc
class _$DetectedEntityCopyWithImpl<$Res, $Val extends DetectedEntity>
    implements $DetectedEntityCopyWith<$Res> {
  _$DetectedEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? originalValue = null,
    Object? sanitizedValue = null,
    Object? startIndex = null,
    Object? endIndex = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EntityType,
      originalValue: null == originalValue
          ? _value.originalValue
          : originalValue // ignore: cast_nullable_to_non_nullable
              as String,
      sanitizedValue: null == sanitizedValue
          ? _value.sanitizedValue
          : sanitizedValue // ignore: cast_nullable_to_non_nullable
              as String,
      startIndex: null == startIndex
          ? _value.startIndex
          : startIndex // ignore: cast_nullable_to_non_nullable
              as int,
      endIndex: null == endIndex
          ? _value.endIndex
          : endIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetectedEntityImplCopyWith<$Res>
    implements $DetectedEntityCopyWith<$Res> {
  factory _$$DetectedEntityImplCopyWith(_$DetectedEntityImpl value,
          $Res Function(_$DetectedEntityImpl) then) =
      __$$DetectedEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {EntityType type,
      String originalValue,
      String sanitizedValue,
      int startIndex,
      int endIndex});
}

/// @nodoc
class __$$DetectedEntityImplCopyWithImpl<$Res>
    extends _$DetectedEntityCopyWithImpl<$Res, _$DetectedEntityImpl>
    implements _$$DetectedEntityImplCopyWith<$Res> {
  __$$DetectedEntityImplCopyWithImpl(
      _$DetectedEntityImpl _value, $Res Function(_$DetectedEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? originalValue = null,
    Object? sanitizedValue = null,
    Object? startIndex = null,
    Object? endIndex = null,
  }) {
    return _then(_$DetectedEntityImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EntityType,
      originalValue: null == originalValue
          ? _value.originalValue
          : originalValue // ignore: cast_nullable_to_non_nullable
              as String,
      sanitizedValue: null == sanitizedValue
          ? _value.sanitizedValue
          : sanitizedValue // ignore: cast_nullable_to_non_nullable
              as String,
      startIndex: null == startIndex
          ? _value.startIndex
          : startIndex // ignore: cast_nullable_to_non_nullable
              as int,
      endIndex: null == endIndex
          ? _value.endIndex
          : endIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectedEntityImpl implements _DetectedEntity {
  const _$DetectedEntityImpl(
      {required this.type,
      required this.originalValue,
      required this.sanitizedValue,
      required this.startIndex,
      required this.endIndex});

  factory _$DetectedEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectedEntityImplFromJson(json);

  /// Type of entity detected.
  @override
  final EntityType type;

  /// Original value found in text.
  @override
  final String originalValue;

  /// Sanitized replacement value.
  @override
  final String sanitizedValue;

  /// Start index in original text.
  @override
  final int startIndex;

  /// End index in original text.
  @override
  final int endIndex;

  @override
  String toString() {
    return 'DetectedEntity(type: $type, originalValue: $originalValue, sanitizedValue: $sanitizedValue, startIndex: $startIndex, endIndex: $endIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectedEntityImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.originalValue, originalValue) ||
                other.originalValue == originalValue) &&
            (identical(other.sanitizedValue, sanitizedValue) ||
                other.sanitizedValue == sanitizedValue) &&
            (identical(other.startIndex, startIndex) ||
                other.startIndex == startIndex) &&
            (identical(other.endIndex, endIndex) ||
                other.endIndex == endIndex));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, originalValue, sanitizedValue, startIndex, endIndex);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectedEntityImplCopyWith<_$DetectedEntityImpl> get copyWith =>
      __$$DetectedEntityImplCopyWithImpl<_$DetectedEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectedEntityImplToJson(
      this,
    );
  }
}

abstract class _DetectedEntity implements DetectedEntity {
  const factory _DetectedEntity(
      {required final EntityType type,
      required final String originalValue,
      required final String sanitizedValue,
      required final int startIndex,
      required final int endIndex}) = _$DetectedEntityImpl;

  factory _DetectedEntity.fromJson(Map<String, dynamic> json) =
      _$DetectedEntityImpl.fromJson;

  @override

  /// Type of entity detected.
  EntityType get type;
  @override

  /// Original value found in text.
  String get originalValue;
  @override

  /// Sanitized replacement value.
  String get sanitizedValue;
  @override

  /// Start index in original text.
  int get startIndex;
  @override

  /// End index in original text.
  int get endIndex;
  @override
  @JsonKey(ignore: true)
  _$$DetectedEntityImplCopyWith<_$DetectedEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
