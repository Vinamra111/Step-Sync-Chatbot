// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'permission_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PermissionState _$PermissionStateFromJson(Map<String, dynamic> json) {
  return _PermissionState.fromJson(json);
}

/// @nodoc
mixin _$PermissionState {
  /// Whether step reading permission is granted.
  bool get stepsGranted => throw _privateConstructorUsedError;

  /// Whether activity reading permission is granted.
  bool get activityGranted => throw _privateConstructorUsedError;

  /// Overall permission status.
  PermissionStatus get status => throw _privateConstructorUsedError;

  /// When permissions were last checked.
  DateTime? get lastCheckedAt => throw _privateConstructorUsedError;

  /// Error message if permission check failed.
  String? get errorMessage => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PermissionStateCopyWith<PermissionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PermissionStateCopyWith<$Res> {
  factory $PermissionStateCopyWith(
          PermissionState value, $Res Function(PermissionState) then) =
      _$PermissionStateCopyWithImpl<$Res, PermissionState>;
  @useResult
  $Res call(
      {bool stepsGranted,
      bool activityGranted,
      PermissionStatus status,
      DateTime? lastCheckedAt,
      String? errorMessage});
}

/// @nodoc
class _$PermissionStateCopyWithImpl<$Res, $Val extends PermissionState>
    implements $PermissionStateCopyWith<$Res> {
  _$PermissionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepsGranted = null,
    Object? activityGranted = null,
    Object? status = null,
    Object? lastCheckedAt = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      stepsGranted: null == stepsGranted
          ? _value.stepsGranted
          : stepsGranted // ignore: cast_nullable_to_non_nullable
              as bool,
      activityGranted: null == activityGranted
          ? _value.activityGranted
          : activityGranted // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PermissionStatus,
      lastCheckedAt: freezed == lastCheckedAt
          ? _value.lastCheckedAt
          : lastCheckedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PermissionStateImplCopyWith<$Res>
    implements $PermissionStateCopyWith<$Res> {
  factory _$$PermissionStateImplCopyWith(_$PermissionStateImpl value,
          $Res Function(_$PermissionStateImpl) then) =
      __$$PermissionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool stepsGranted,
      bool activityGranted,
      PermissionStatus status,
      DateTime? lastCheckedAt,
      String? errorMessage});
}

/// @nodoc
class __$$PermissionStateImplCopyWithImpl<$Res>
    extends _$PermissionStateCopyWithImpl<$Res, _$PermissionStateImpl>
    implements _$$PermissionStateImplCopyWith<$Res> {
  __$$PermissionStateImplCopyWithImpl(
      _$PermissionStateImpl _value, $Res Function(_$PermissionStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepsGranted = null,
    Object? activityGranted = null,
    Object? status = null,
    Object? lastCheckedAt = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$PermissionStateImpl(
      stepsGranted: null == stepsGranted
          ? _value.stepsGranted
          : stepsGranted // ignore: cast_nullable_to_non_nullable
              as bool,
      activityGranted: null == activityGranted
          ? _value.activityGranted
          : activityGranted // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PermissionStatus,
      lastCheckedAt: freezed == lastCheckedAt
          ? _value.lastCheckedAt
          : lastCheckedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PermissionStateImpl implements _PermissionState {
  const _$PermissionStateImpl(
      {required this.stepsGranted,
      required this.activityGranted,
      required this.status,
      this.lastCheckedAt,
      this.errorMessage});

  factory _$PermissionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PermissionStateImplFromJson(json);

  /// Whether step reading permission is granted.
  @override
  final bool stepsGranted;

  /// Whether activity reading permission is granted.
  @override
  final bool activityGranted;

  /// Overall permission status.
  @override
  final PermissionStatus status;

  /// When permissions were last checked.
  @override
  final DateTime? lastCheckedAt;

  /// Error message if permission check failed.
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'PermissionState(stepsGranted: $stepsGranted, activityGranted: $activityGranted, status: $status, lastCheckedAt: $lastCheckedAt, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PermissionStateImpl &&
            (identical(other.stepsGranted, stepsGranted) ||
                other.stepsGranted == stepsGranted) &&
            (identical(other.activityGranted, activityGranted) ||
                other.activityGranted == activityGranted) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastCheckedAt, lastCheckedAt) ||
                other.lastCheckedAt == lastCheckedAt) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, stepsGranted, activityGranted,
      status, lastCheckedAt, errorMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PermissionStateImplCopyWith<_$PermissionStateImpl> get copyWith =>
      __$$PermissionStateImplCopyWithImpl<_$PermissionStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PermissionStateImplToJson(
      this,
    );
  }
}

abstract class _PermissionState implements PermissionState {
  const factory _PermissionState(
      {required final bool stepsGranted,
      required final bool activityGranted,
      required final PermissionStatus status,
      final DateTime? lastCheckedAt,
      final String? errorMessage}) = _$PermissionStateImpl;

  factory _PermissionState.fromJson(Map<String, dynamic> json) =
      _$PermissionStateImpl.fromJson;

  @override

  /// Whether step reading permission is granted.
  bool get stepsGranted;
  @override

  /// Whether activity reading permission is granted.
  bool get activityGranted;
  @override

  /// Overall permission status.
  PermissionStatus get status;
  @override

  /// When permissions were last checked.
  DateTime? get lastCheckedAt;
  @override

  /// Error message if permission check failed.
  String? get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$PermissionStateImplCopyWith<_$PermissionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
