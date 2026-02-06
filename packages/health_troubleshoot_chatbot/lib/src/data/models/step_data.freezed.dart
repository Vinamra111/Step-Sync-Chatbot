// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'step_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StepData _$StepDataFromJson(Map<String, dynamic> json) {
  return _StepData.fromJson(json);
}

/// @nodoc
mixin _$StepData {
  /// The date this step count is for (date only, no time).
  DateTime get date => throw _privateConstructorUsedError;

  /// Total step count for this date.
  int get steps => throw _privateConstructorUsedError;

  /// Source app/device that provided this data.
  DataSource get source => throw _privateConstructorUsedError;

  /// When this data was last synced.
  DateTime? get lastSyncedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StepDataCopyWith<StepData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StepDataCopyWith<$Res> {
  factory $StepDataCopyWith(StepData value, $Res Function(StepData) then) =
      _$StepDataCopyWithImpl<$Res, StepData>;
  @useResult
  $Res call(
      {DateTime date, int steps, DataSource source, DateTime? lastSyncedAt});

  $DataSourceCopyWith<$Res> get source;
}

/// @nodoc
class _$StepDataCopyWithImpl<$Res, $Val extends StepData>
    implements $StepDataCopyWith<$Res> {
  _$StepDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? steps = null,
    Object? source = null,
    Object? lastSyncedAt = freezed,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as int,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as DataSource,
      lastSyncedAt: freezed == lastSyncedAt
          ? _value.lastSyncedAt
          : lastSyncedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $DataSourceCopyWith<$Res> get source {
    return $DataSourceCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StepDataImplCopyWith<$Res>
    implements $StepDataCopyWith<$Res> {
  factory _$$StepDataImplCopyWith(
          _$StepDataImpl value, $Res Function(_$StepDataImpl) then) =
      __$$StepDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime date, int steps, DataSource source, DateTime? lastSyncedAt});

  @override
  $DataSourceCopyWith<$Res> get source;
}

/// @nodoc
class __$$StepDataImplCopyWithImpl<$Res>
    extends _$StepDataCopyWithImpl<$Res, _$StepDataImpl>
    implements _$$StepDataImplCopyWith<$Res> {
  __$$StepDataImplCopyWithImpl(
      _$StepDataImpl _value, $Res Function(_$StepDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? steps = null,
    Object? source = null,
    Object? lastSyncedAt = freezed,
  }) {
    return _then(_$StepDataImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as int,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as DataSource,
      lastSyncedAt: freezed == lastSyncedAt
          ? _value.lastSyncedAt
          : lastSyncedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StepDataImpl implements _StepData {
  const _$StepDataImpl(
      {required this.date,
      required this.steps,
      required this.source,
      this.lastSyncedAt});

  factory _$StepDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$StepDataImplFromJson(json);

  /// The date this step count is for (date only, no time).
  @override
  final DateTime date;

  /// Total step count for this date.
  @override
  final int steps;

  /// Source app/device that provided this data.
  @override
  final DataSource source;

  /// When this data was last synced.
  @override
  final DateTime? lastSyncedAt;

  @override
  String toString() {
    return 'StepData(date: $date, steps: $steps, source: $source, lastSyncedAt: $lastSyncedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StepDataImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.steps, steps) || other.steps == steps) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.lastSyncedAt, lastSyncedAt) ||
                other.lastSyncedAt == lastSyncedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, date, steps, source, lastSyncedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StepDataImplCopyWith<_$StepDataImpl> get copyWith =>
      __$$StepDataImplCopyWithImpl<_$StepDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StepDataImplToJson(
      this,
    );
  }
}

abstract class _StepData implements StepData {
  const factory _StepData(
      {required final DateTime date,
      required final int steps,
      required final DataSource source,
      final DateTime? lastSyncedAt}) = _$StepDataImpl;

  factory _StepData.fromJson(Map<String, dynamic> json) =
      _$StepDataImpl.fromJson;

  @override

  /// The date this step count is for (date only, no time).
  DateTime get date;
  @override

  /// Total step count for this date.
  int get steps;
  @override

  /// Source app/device that provided this data.
  DataSource get source;
  @override

  /// When this data was last synced.
  DateTime? get lastSyncedAt;
  @override
  @JsonKey(ignore: true)
  _$$StepDataImplCopyWith<_$StepDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DataSource _$DataSourceFromJson(Map<String, dynamic> json) {
  return _DataSource.fromJson(json);
}

/// @nodoc
mixin _$DataSource {
  /// Package name (Android) or bundle ID (iOS).
  String get id => throw _privateConstructorUsedError;

  /// User-friendly name (e.g., "Samsung Health", "Google Fit").
  String get name => throw _privateConstructorUsedError;

  /// Type of source.
  DataSourceType get type => throw _privateConstructorUsedError;

  /// Whether this is the user's preferred primary source.
  bool get isPrimary => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DataSourceCopyWith<DataSource> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataSourceCopyWith<$Res> {
  factory $DataSourceCopyWith(
          DataSource value, $Res Function(DataSource) then) =
      _$DataSourceCopyWithImpl<$Res, DataSource>;
  @useResult
  $Res call({String id, String name, DataSourceType type, bool isPrimary});
}

/// @nodoc
class _$DataSourceCopyWithImpl<$Res, $Val extends DataSource>
    implements $DataSourceCopyWith<$Res> {
  _$DataSourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? isPrimary = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DataSourceType,
      isPrimary: null == isPrimary
          ? _value.isPrimary
          : isPrimary // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DataSourceImplCopyWith<$Res>
    implements $DataSourceCopyWith<$Res> {
  factory _$$DataSourceImplCopyWith(
          _$DataSourceImpl value, $Res Function(_$DataSourceImpl) then) =
      __$$DataSourceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, DataSourceType type, bool isPrimary});
}

/// @nodoc
class __$$DataSourceImplCopyWithImpl<$Res>
    extends _$DataSourceCopyWithImpl<$Res, _$DataSourceImpl>
    implements _$$DataSourceImplCopyWith<$Res> {
  __$$DataSourceImplCopyWithImpl(
      _$DataSourceImpl _value, $Res Function(_$DataSourceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? isPrimary = null,
  }) {
    return _then(_$DataSourceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DataSourceType,
      isPrimary: null == isPrimary
          ? _value.isPrimary
          : isPrimary // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DataSourceImpl implements _DataSource {
  const _$DataSourceImpl(
      {required this.id,
      required this.name,
      this.type = DataSourceType.app,
      this.isPrimary = false});

  factory _$DataSourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataSourceImplFromJson(json);

  /// Package name (Android) or bundle ID (iOS).
  @override
  final String id;

  /// User-friendly name (e.g., "Samsung Health", "Google Fit").
  @override
  final String name;

  /// Type of source.
  @override
  @JsonKey()
  final DataSourceType type;

  /// Whether this is the user's preferred primary source.
  @override
  @JsonKey()
  final bool isPrimary;

  @override
  String toString() {
    return 'DataSource(id: $id, name: $name, type: $type, isPrimary: $isPrimary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataSourceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isPrimary, isPrimary) ||
                other.isPrimary == isPrimary));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, type, isPrimary);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DataSourceImplCopyWith<_$DataSourceImpl> get copyWith =>
      __$$DataSourceImplCopyWithImpl<_$DataSourceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DataSourceImplToJson(
      this,
    );
  }
}

abstract class _DataSource implements DataSource {
  const factory _DataSource(
      {required final String id,
      required final String name,
      final DataSourceType type,
      final bool isPrimary}) = _$DataSourceImpl;

  factory _DataSource.fromJson(Map<String, dynamic> json) =
      _$DataSourceImpl.fromJson;

  @override

  /// Package name (Android) or bundle ID (iOS).
  String get id;
  @override

  /// User-friendly name (e.g., "Samsung Health", "Google Fit").
  String get name;
  @override

  /// Type of source.
  DataSourceType get type;
  @override

  /// Whether this is the user's preferred primary source.
  bool get isPrimary;
  @override
  @JsonKey(ignore: true)
  _$$DataSourceImplCopyWith<_$DataSourceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
