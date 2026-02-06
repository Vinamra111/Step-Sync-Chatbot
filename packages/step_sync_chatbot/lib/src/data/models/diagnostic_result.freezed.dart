// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diagnostic_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DiagnosticResult _$DiagnosticResultFromJson(Map<String, dynamic> json) {
  return _DiagnosticResult.fromJson(json);
}

/// @nodoc
mixin _$DiagnosticResult {
  /// Permission check results.
  PermissionState get permissionState => throw _privateConstructorUsedError;

  /// Health Connect/HealthKit availability.
  PlatformAvailability get platformAvailability =>
      throw _privateConstructorUsedError;

  /// Battery optimization status (Android only).
  BatteryOptimizationStatus? get batteryOptimization =>
      throw _privateConstructorUsedError;

  /// Data sources detected.
  List<DataSource> get dataSources => throw _privateConstructorUsedError;

  /// Recent step data (if available).
  List<StepData>? get recentStepData => throw _privateConstructorUsedError;

  /// Overall system health status.
  SystemHealthStatus get overallStatus => throw _privateConstructorUsedError;

  /// List of detected issues.
  List<DiagnosticIssue> get issues => throw _privateConstructorUsedError;

  /// Timestamp when diagnostic was run.
  DateTime get timestamp => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DiagnosticResultCopyWith<DiagnosticResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagnosticResultCopyWith<$Res> {
  factory $DiagnosticResultCopyWith(
          DiagnosticResult value, $Res Function(DiagnosticResult) then) =
      _$DiagnosticResultCopyWithImpl<$Res, DiagnosticResult>;
  @useResult
  $Res call(
      {PermissionState permissionState,
      PlatformAvailability platformAvailability,
      BatteryOptimizationStatus? batteryOptimization,
      List<DataSource> dataSources,
      List<StepData>? recentStepData,
      SystemHealthStatus overallStatus,
      List<DiagnosticIssue> issues,
      DateTime timestamp});

  $PermissionStateCopyWith<$Res> get permissionState;
  $PlatformAvailabilityCopyWith<$Res> get platformAvailability;
  $BatteryOptimizationStatusCopyWith<$Res>? get batteryOptimization;
}

/// @nodoc
class _$DiagnosticResultCopyWithImpl<$Res, $Val extends DiagnosticResult>
    implements $DiagnosticResultCopyWith<$Res> {
  _$DiagnosticResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? permissionState = null,
    Object? platformAvailability = null,
    Object? batteryOptimization = freezed,
    Object? dataSources = null,
    Object? recentStepData = freezed,
    Object? overallStatus = null,
    Object? issues = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      permissionState: null == permissionState
          ? _value.permissionState
          : permissionState // ignore: cast_nullable_to_non_nullable
              as PermissionState,
      platformAvailability: null == platformAvailability
          ? _value.platformAvailability
          : platformAvailability // ignore: cast_nullable_to_non_nullable
              as PlatformAvailability,
      batteryOptimization: freezed == batteryOptimization
          ? _value.batteryOptimization
          : batteryOptimization // ignore: cast_nullable_to_non_nullable
              as BatteryOptimizationStatus?,
      dataSources: null == dataSources
          ? _value.dataSources
          : dataSources // ignore: cast_nullable_to_non_nullable
              as List<DataSource>,
      recentStepData: freezed == recentStepData
          ? _value.recentStepData
          : recentStepData // ignore: cast_nullable_to_non_nullable
              as List<StepData>?,
      overallStatus: null == overallStatus
          ? _value.overallStatus
          : overallStatus // ignore: cast_nullable_to_non_nullable
              as SystemHealthStatus,
      issues: null == issues
          ? _value.issues
          : issues // ignore: cast_nullable_to_non_nullable
              as List<DiagnosticIssue>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PermissionStateCopyWith<$Res> get permissionState {
    return $PermissionStateCopyWith<$Res>(_value.permissionState, (value) {
      return _then(_value.copyWith(permissionState: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PlatformAvailabilityCopyWith<$Res> get platformAvailability {
    return $PlatformAvailabilityCopyWith<$Res>(_value.platformAvailability,
        (value) {
      return _then(_value.copyWith(platformAvailability: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $BatteryOptimizationStatusCopyWith<$Res>? get batteryOptimization {
    if (_value.batteryOptimization == null) {
      return null;
    }

    return $BatteryOptimizationStatusCopyWith<$Res>(_value.batteryOptimization!,
        (value) {
      return _then(_value.copyWith(batteryOptimization: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DiagnosticResultImplCopyWith<$Res>
    implements $DiagnosticResultCopyWith<$Res> {
  factory _$$DiagnosticResultImplCopyWith(_$DiagnosticResultImpl value,
          $Res Function(_$DiagnosticResultImpl) then) =
      __$$DiagnosticResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PermissionState permissionState,
      PlatformAvailability platformAvailability,
      BatteryOptimizationStatus? batteryOptimization,
      List<DataSource> dataSources,
      List<StepData>? recentStepData,
      SystemHealthStatus overallStatus,
      List<DiagnosticIssue> issues,
      DateTime timestamp});

  @override
  $PermissionStateCopyWith<$Res> get permissionState;
  @override
  $PlatformAvailabilityCopyWith<$Res> get platformAvailability;
  @override
  $BatteryOptimizationStatusCopyWith<$Res>? get batteryOptimization;
}

/// @nodoc
class __$$DiagnosticResultImplCopyWithImpl<$Res>
    extends _$DiagnosticResultCopyWithImpl<$Res, _$DiagnosticResultImpl>
    implements _$$DiagnosticResultImplCopyWith<$Res> {
  __$$DiagnosticResultImplCopyWithImpl(_$DiagnosticResultImpl _value,
      $Res Function(_$DiagnosticResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? permissionState = null,
    Object? platformAvailability = null,
    Object? batteryOptimization = freezed,
    Object? dataSources = null,
    Object? recentStepData = freezed,
    Object? overallStatus = null,
    Object? issues = null,
    Object? timestamp = null,
  }) {
    return _then(_$DiagnosticResultImpl(
      permissionState: null == permissionState
          ? _value.permissionState
          : permissionState // ignore: cast_nullable_to_non_nullable
              as PermissionState,
      platformAvailability: null == platformAvailability
          ? _value.platformAvailability
          : platformAvailability // ignore: cast_nullable_to_non_nullable
              as PlatformAvailability,
      batteryOptimization: freezed == batteryOptimization
          ? _value.batteryOptimization
          : batteryOptimization // ignore: cast_nullable_to_non_nullable
              as BatteryOptimizationStatus?,
      dataSources: null == dataSources
          ? _value._dataSources
          : dataSources // ignore: cast_nullable_to_non_nullable
              as List<DataSource>,
      recentStepData: freezed == recentStepData
          ? _value._recentStepData
          : recentStepData // ignore: cast_nullable_to_non_nullable
              as List<StepData>?,
      overallStatus: null == overallStatus
          ? _value.overallStatus
          : overallStatus // ignore: cast_nullable_to_non_nullable
              as SystemHealthStatus,
      issues: null == issues
          ? _value._issues
          : issues // ignore: cast_nullable_to_non_nullable
              as List<DiagnosticIssue>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiagnosticResultImpl implements _DiagnosticResult {
  const _$DiagnosticResultImpl(
      {required this.permissionState,
      required this.platformAvailability,
      this.batteryOptimization,
      final List<DataSource> dataSources = const [],
      final List<StepData>? recentStepData,
      required this.overallStatus,
      final List<DiagnosticIssue> issues = const [],
      required this.timestamp})
      : _dataSources = dataSources,
        _recentStepData = recentStepData,
        _issues = issues;

  factory _$DiagnosticResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiagnosticResultImplFromJson(json);

  /// Permission check results.
  @override
  final PermissionState permissionState;

  /// Health Connect/HealthKit availability.
  @override
  final PlatformAvailability platformAvailability;

  /// Battery optimization status (Android only).
  @override
  final BatteryOptimizationStatus? batteryOptimization;

  /// Data sources detected.
  final List<DataSource> _dataSources;

  /// Data sources detected.
  @override
  @JsonKey()
  List<DataSource> get dataSources {
    if (_dataSources is EqualUnmodifiableListView) return _dataSources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dataSources);
  }

  /// Recent step data (if available).
  final List<StepData>? _recentStepData;

  /// Recent step data (if available).
  @override
  List<StepData>? get recentStepData {
    final value = _recentStepData;
    if (value == null) return null;
    if (_recentStepData is EqualUnmodifiableListView) return _recentStepData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Overall system health status.
  @override
  final SystemHealthStatus overallStatus;

  /// List of detected issues.
  final List<DiagnosticIssue> _issues;

  /// List of detected issues.
  @override
  @JsonKey()
  List<DiagnosticIssue> get issues {
    if (_issues is EqualUnmodifiableListView) return _issues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_issues);
  }

  /// Timestamp when diagnostic was run.
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'DiagnosticResult(permissionState: $permissionState, platformAvailability: $platformAvailability, batteryOptimization: $batteryOptimization, dataSources: $dataSources, recentStepData: $recentStepData, overallStatus: $overallStatus, issues: $issues, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagnosticResultImpl &&
            (identical(other.permissionState, permissionState) ||
                other.permissionState == permissionState) &&
            (identical(other.platformAvailability, platformAvailability) ||
                other.platformAvailability == platformAvailability) &&
            (identical(other.batteryOptimization, batteryOptimization) ||
                other.batteryOptimization == batteryOptimization) &&
            const DeepCollectionEquality()
                .equals(other._dataSources, _dataSources) &&
            const DeepCollectionEquality()
                .equals(other._recentStepData, _recentStepData) &&
            (identical(other.overallStatus, overallStatus) ||
                other.overallStatus == overallStatus) &&
            const DeepCollectionEquality().equals(other._issues, _issues) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      permissionState,
      platformAvailability,
      batteryOptimization,
      const DeepCollectionEquality().hash(_dataSources),
      const DeepCollectionEquality().hash(_recentStepData),
      overallStatus,
      const DeepCollectionEquality().hash(_issues),
      timestamp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagnosticResultImplCopyWith<_$DiagnosticResultImpl> get copyWith =>
      __$$DiagnosticResultImplCopyWithImpl<_$DiagnosticResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiagnosticResultImplToJson(
      this,
    );
  }
}

abstract class _DiagnosticResult implements DiagnosticResult {
  const factory _DiagnosticResult(
      {required final PermissionState permissionState,
      required final PlatformAvailability platformAvailability,
      final BatteryOptimizationStatus? batteryOptimization,
      final List<DataSource> dataSources,
      final List<StepData>? recentStepData,
      required final SystemHealthStatus overallStatus,
      final List<DiagnosticIssue> issues,
      required final DateTime timestamp}) = _$DiagnosticResultImpl;

  factory _DiagnosticResult.fromJson(Map<String, dynamic> json) =
      _$DiagnosticResultImpl.fromJson;

  @override

  /// Permission check results.
  PermissionState get permissionState;
  @override

  /// Health Connect/HealthKit availability.
  PlatformAvailability get platformAvailability;
  @override

  /// Battery optimization status (Android only).
  BatteryOptimizationStatus? get batteryOptimization;
  @override

  /// Data sources detected.
  List<DataSource> get dataSources;
  @override

  /// Recent step data (if available).
  List<StepData>? get recentStepData;
  @override

  /// Overall system health status.
  SystemHealthStatus get overallStatus;
  @override

  /// List of detected issues.
  List<DiagnosticIssue> get issues;
  @override

  /// Timestamp when diagnostic was run.
  DateTime get timestamp;
  @override
  @JsonKey(ignore: true)
  _$$DiagnosticResultImplCopyWith<_$DiagnosticResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlatformAvailability _$PlatformAvailabilityFromJson(Map<String, dynamic> json) {
  return _PlatformAvailability.fromJson(json);
}

/// @nodoc
mixin _$PlatformAvailability {
  /// Whether the platform (Health Connect/HealthKit) is available.
  bool get isAvailable => throw _privateConstructorUsedError;

  /// Platform name (e.g., "Health Connect", "HealthKit").
  String get platformName => throw _privateConstructorUsedError;

  /// Whether installation is required (Android 9-13 only).
  bool get requiresInstallation => throw _privateConstructorUsedError;

  /// Whether the platform is supported on this device.
  bool get isSupported => throw _privateConstructorUsedError;

  /// Additional details about availability.
  String? get details => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlatformAvailabilityCopyWith<PlatformAvailability> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlatformAvailabilityCopyWith<$Res> {
  factory $PlatformAvailabilityCopyWith(PlatformAvailability value,
          $Res Function(PlatformAvailability) then) =
      _$PlatformAvailabilityCopyWithImpl<$Res, PlatformAvailability>;
  @useResult
  $Res call(
      {bool isAvailable,
      String platformName,
      bool requiresInstallation,
      bool isSupported,
      String? details});
}

/// @nodoc
class _$PlatformAvailabilityCopyWithImpl<$Res,
        $Val extends PlatformAvailability>
    implements $PlatformAvailabilityCopyWith<$Res> {
  _$PlatformAvailabilityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAvailable = null,
    Object? platformName = null,
    Object? requiresInstallation = null,
    Object? isSupported = null,
    Object? details = freezed,
  }) {
    return _then(_value.copyWith(
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      platformName: null == platformName
          ? _value.platformName
          : platformName // ignore: cast_nullable_to_non_nullable
              as String,
      requiresInstallation: null == requiresInstallation
          ? _value.requiresInstallation
          : requiresInstallation // ignore: cast_nullable_to_non_nullable
              as bool,
      isSupported: null == isSupported
          ? _value.isSupported
          : isSupported // ignore: cast_nullable_to_non_nullable
              as bool,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlatformAvailabilityImplCopyWith<$Res>
    implements $PlatformAvailabilityCopyWith<$Res> {
  factory _$$PlatformAvailabilityImplCopyWith(_$PlatformAvailabilityImpl value,
          $Res Function(_$PlatformAvailabilityImpl) then) =
      __$$PlatformAvailabilityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isAvailable,
      String platformName,
      bool requiresInstallation,
      bool isSupported,
      String? details});
}

/// @nodoc
class __$$PlatformAvailabilityImplCopyWithImpl<$Res>
    extends _$PlatformAvailabilityCopyWithImpl<$Res, _$PlatformAvailabilityImpl>
    implements _$$PlatformAvailabilityImplCopyWith<$Res> {
  __$$PlatformAvailabilityImplCopyWithImpl(_$PlatformAvailabilityImpl _value,
      $Res Function(_$PlatformAvailabilityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAvailable = null,
    Object? platformName = null,
    Object? requiresInstallation = null,
    Object? isSupported = null,
    Object? details = freezed,
  }) {
    return _then(_$PlatformAvailabilityImpl(
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      platformName: null == platformName
          ? _value.platformName
          : platformName // ignore: cast_nullable_to_non_nullable
              as String,
      requiresInstallation: null == requiresInstallation
          ? _value.requiresInstallation
          : requiresInstallation // ignore: cast_nullable_to_non_nullable
              as bool,
      isSupported: null == isSupported
          ? _value.isSupported
          : isSupported // ignore: cast_nullable_to_non_nullable
              as bool,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlatformAvailabilityImpl implements _PlatformAvailability {
  const _$PlatformAvailabilityImpl(
      {required this.isAvailable,
      required this.platformName,
      this.requiresInstallation = false,
      this.isSupported = true,
      this.details});

  factory _$PlatformAvailabilityImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlatformAvailabilityImplFromJson(json);

  /// Whether the platform (Health Connect/HealthKit) is available.
  @override
  final bool isAvailable;

  /// Platform name (e.g., "Health Connect", "HealthKit").
  @override
  final String platformName;

  /// Whether installation is required (Android 9-13 only).
  @override
  @JsonKey()
  final bool requiresInstallation;

  /// Whether the platform is supported on this device.
  @override
  @JsonKey()
  final bool isSupported;

  /// Additional details about availability.
  @override
  final String? details;

  @override
  String toString() {
    return 'PlatformAvailability(isAvailable: $isAvailable, platformName: $platformName, requiresInstallation: $requiresInstallation, isSupported: $isSupported, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlatformAvailabilityImpl &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.platformName, platformName) ||
                other.platformName == platformName) &&
            (identical(other.requiresInstallation, requiresInstallation) ||
                other.requiresInstallation == requiresInstallation) &&
            (identical(other.isSupported, isSupported) ||
                other.isSupported == isSupported) &&
            (identical(other.details, details) || other.details == details));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, isAvailable, platformName,
      requiresInstallation, isSupported, details);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlatformAvailabilityImplCopyWith<_$PlatformAvailabilityImpl>
      get copyWith =>
          __$$PlatformAvailabilityImplCopyWithImpl<_$PlatformAvailabilityImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlatformAvailabilityImplToJson(
      this,
    );
  }
}

abstract class _PlatformAvailability implements PlatformAvailability {
  const factory _PlatformAvailability(
      {required final bool isAvailable,
      required final String platformName,
      final bool requiresInstallation,
      final bool isSupported,
      final String? details}) = _$PlatformAvailabilityImpl;

  factory _PlatformAvailability.fromJson(Map<String, dynamic> json) =
      _$PlatformAvailabilityImpl.fromJson;

  @override

  /// Whether the platform (Health Connect/HealthKit) is available.
  bool get isAvailable;
  @override

  /// Platform name (e.g., "Health Connect", "HealthKit").
  String get platformName;
  @override

  /// Whether installation is required (Android 9-13 only).
  bool get requiresInstallation;
  @override

  /// Whether the platform is supported on this device.
  bool get isSupported;
  @override

  /// Additional details about availability.
  String? get details;
  @override
  @JsonKey(ignore: true)
  _$$PlatformAvailabilityImplCopyWith<_$PlatformAvailabilityImpl>
      get copyWith => throw _privateConstructorUsedError;
}

BatteryOptimizationStatus _$BatteryOptimizationStatusFromJson(
    Map<String, dynamic> json) {
  return _BatteryOptimizationStatus.fromJson(json);
}

/// @nodoc
mixin _$BatteryOptimizationStatus {
  /// Whether battery optimization is enabled for the app.
  bool get isOptimized => throw _privateConstructorUsedError;

  /// Whether this is blocking background sync.
  bool get isBlockingSync => throw _privateConstructorUsedError;

  /// User-friendly explanation.
  String get explanation => throw _privateConstructorUsedError;

  /// Recommended action.
  String? get recommendedAction => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BatteryOptimizationStatusCopyWith<BatteryOptimizationStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BatteryOptimizationStatusCopyWith<$Res> {
  factory $BatteryOptimizationStatusCopyWith(BatteryOptimizationStatus value,
          $Res Function(BatteryOptimizationStatus) then) =
      _$BatteryOptimizationStatusCopyWithImpl<$Res, BatteryOptimizationStatus>;
  @useResult
  $Res call(
      {bool isOptimized,
      bool isBlockingSync,
      String explanation,
      String? recommendedAction});
}

/// @nodoc
class _$BatteryOptimizationStatusCopyWithImpl<$Res,
        $Val extends BatteryOptimizationStatus>
    implements $BatteryOptimizationStatusCopyWith<$Res> {
  _$BatteryOptimizationStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOptimized = null,
    Object? isBlockingSync = null,
    Object? explanation = null,
    Object? recommendedAction = freezed,
  }) {
    return _then(_value.copyWith(
      isOptimized: null == isOptimized
          ? _value.isOptimized
          : isOptimized // ignore: cast_nullable_to_non_nullable
              as bool,
      isBlockingSync: null == isBlockingSync
          ? _value.isBlockingSync
          : isBlockingSync // ignore: cast_nullable_to_non_nullable
              as bool,
      explanation: null == explanation
          ? _value.explanation
          : explanation // ignore: cast_nullable_to_non_nullable
              as String,
      recommendedAction: freezed == recommendedAction
          ? _value.recommendedAction
          : recommendedAction // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BatteryOptimizationStatusImplCopyWith<$Res>
    implements $BatteryOptimizationStatusCopyWith<$Res> {
  factory _$$BatteryOptimizationStatusImplCopyWith(
          _$BatteryOptimizationStatusImpl value,
          $Res Function(_$BatteryOptimizationStatusImpl) then) =
      __$$BatteryOptimizationStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isOptimized,
      bool isBlockingSync,
      String explanation,
      String? recommendedAction});
}

/// @nodoc
class __$$BatteryOptimizationStatusImplCopyWithImpl<$Res>
    extends _$BatteryOptimizationStatusCopyWithImpl<$Res,
        _$BatteryOptimizationStatusImpl>
    implements _$$BatteryOptimizationStatusImplCopyWith<$Res> {
  __$$BatteryOptimizationStatusImplCopyWithImpl(
      _$BatteryOptimizationStatusImpl _value,
      $Res Function(_$BatteryOptimizationStatusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isOptimized = null,
    Object? isBlockingSync = null,
    Object? explanation = null,
    Object? recommendedAction = freezed,
  }) {
    return _then(_$BatteryOptimizationStatusImpl(
      isOptimized: null == isOptimized
          ? _value.isOptimized
          : isOptimized // ignore: cast_nullable_to_non_nullable
              as bool,
      isBlockingSync: null == isBlockingSync
          ? _value.isBlockingSync
          : isBlockingSync // ignore: cast_nullable_to_non_nullable
              as bool,
      explanation: null == explanation
          ? _value.explanation
          : explanation // ignore: cast_nullable_to_non_nullable
              as String,
      recommendedAction: freezed == recommendedAction
          ? _value.recommendedAction
          : recommendedAction // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BatteryOptimizationStatusImpl implements _BatteryOptimizationStatus {
  const _$BatteryOptimizationStatusImpl(
      {required this.isOptimized,
      required this.isBlockingSync,
      required this.explanation,
      this.recommendedAction});

  factory _$BatteryOptimizationStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$BatteryOptimizationStatusImplFromJson(json);

  /// Whether battery optimization is enabled for the app.
  @override
  final bool isOptimized;

  /// Whether this is blocking background sync.
  @override
  final bool isBlockingSync;

  /// User-friendly explanation.
  @override
  final String explanation;

  /// Recommended action.
  @override
  final String? recommendedAction;

  @override
  String toString() {
    return 'BatteryOptimizationStatus(isOptimized: $isOptimized, isBlockingSync: $isBlockingSync, explanation: $explanation, recommendedAction: $recommendedAction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BatteryOptimizationStatusImpl &&
            (identical(other.isOptimized, isOptimized) ||
                other.isOptimized == isOptimized) &&
            (identical(other.isBlockingSync, isBlockingSync) ||
                other.isBlockingSync == isBlockingSync) &&
            (identical(other.explanation, explanation) ||
                other.explanation == explanation) &&
            (identical(other.recommendedAction, recommendedAction) ||
                other.recommendedAction == recommendedAction));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, isOptimized, isBlockingSync, explanation, recommendedAction);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BatteryOptimizationStatusImplCopyWith<_$BatteryOptimizationStatusImpl>
      get copyWith => __$$BatteryOptimizationStatusImplCopyWithImpl<
          _$BatteryOptimizationStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BatteryOptimizationStatusImplToJson(
      this,
    );
  }
}

abstract class _BatteryOptimizationStatus implements BatteryOptimizationStatus {
  const factory _BatteryOptimizationStatus(
      {required final bool isOptimized,
      required final bool isBlockingSync,
      required final String explanation,
      final String? recommendedAction}) = _$BatteryOptimizationStatusImpl;

  factory _BatteryOptimizationStatus.fromJson(Map<String, dynamic> json) =
      _$BatteryOptimizationStatusImpl.fromJson;

  @override

  /// Whether battery optimization is enabled for the app.
  bool get isOptimized;
  @override

  /// Whether this is blocking background sync.
  bool get isBlockingSync;
  @override

  /// User-friendly explanation.
  String get explanation;
  @override

  /// Recommended action.
  String? get recommendedAction;
  @override
  @JsonKey(ignore: true)
  _$$BatteryOptimizationStatusImplCopyWith<_$BatteryOptimizationStatusImpl>
      get copyWith => throw _privateConstructorUsedError;
}

DiagnosticIssue _$DiagnosticIssueFromJson(Map<String, dynamic> json) {
  return _DiagnosticIssue.fromJson(json);
}

/// @nodoc
mixin _$DiagnosticIssue {
  /// Severity of the issue.
  IssueSeverity get severity => throw _privateConstructorUsedError;

  /// Category of the issue.
  IssueCategory get category => throw _privateConstructorUsedError;

  /// Short title of the issue.
  String get title => throw _privateConstructorUsedError;

  /// Detailed description.
  String get description => throw _privateConstructorUsedError;

  /// Suggested fix/resolution.
  String? get suggestedFix => throw _privateConstructorUsedError;

  /// Action that can be taken to fix.
  IssueAction? get action => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DiagnosticIssueCopyWith<DiagnosticIssue> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiagnosticIssueCopyWith<$Res> {
  factory $DiagnosticIssueCopyWith(
          DiagnosticIssue value, $Res Function(DiagnosticIssue) then) =
      _$DiagnosticIssueCopyWithImpl<$Res, DiagnosticIssue>;
  @useResult
  $Res call(
      {IssueSeverity severity,
      IssueCategory category,
      String title,
      String description,
      String? suggestedFix,
      IssueAction? action});
}

/// @nodoc
class _$DiagnosticIssueCopyWithImpl<$Res, $Val extends DiagnosticIssue>
    implements $DiagnosticIssueCopyWith<$Res> {
  _$DiagnosticIssueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? severity = null,
    Object? category = null,
    Object? title = null,
    Object? description = null,
    Object? suggestedFix = freezed,
    Object? action = freezed,
  }) {
    return _then(_value.copyWith(
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as IssueSeverity,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as IssueCategory,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      suggestedFix: freezed == suggestedFix
          ? _value.suggestedFix
          : suggestedFix // ignore: cast_nullable_to_non_nullable
              as String?,
      action: freezed == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as IssueAction?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiagnosticIssueImplCopyWith<$Res>
    implements $DiagnosticIssueCopyWith<$Res> {
  factory _$$DiagnosticIssueImplCopyWith(_$DiagnosticIssueImpl value,
          $Res Function(_$DiagnosticIssueImpl) then) =
      __$$DiagnosticIssueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {IssueSeverity severity,
      IssueCategory category,
      String title,
      String description,
      String? suggestedFix,
      IssueAction? action});
}

/// @nodoc
class __$$DiagnosticIssueImplCopyWithImpl<$Res>
    extends _$DiagnosticIssueCopyWithImpl<$Res, _$DiagnosticIssueImpl>
    implements _$$DiagnosticIssueImplCopyWith<$Res> {
  __$$DiagnosticIssueImplCopyWithImpl(
      _$DiagnosticIssueImpl _value, $Res Function(_$DiagnosticIssueImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? severity = null,
    Object? category = null,
    Object? title = null,
    Object? description = null,
    Object? suggestedFix = freezed,
    Object? action = freezed,
  }) {
    return _then(_$DiagnosticIssueImpl(
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as IssueSeverity,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as IssueCategory,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      suggestedFix: freezed == suggestedFix
          ? _value.suggestedFix
          : suggestedFix // ignore: cast_nullable_to_non_nullable
              as String?,
      action: freezed == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as IssueAction?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiagnosticIssueImpl implements _DiagnosticIssue {
  const _$DiagnosticIssueImpl(
      {required this.severity,
      required this.category,
      required this.title,
      required this.description,
      this.suggestedFix,
      this.action});

  factory _$DiagnosticIssueImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiagnosticIssueImplFromJson(json);

  /// Severity of the issue.
  @override
  final IssueSeverity severity;

  /// Category of the issue.
  @override
  final IssueCategory category;

  /// Short title of the issue.
  @override
  final String title;

  /// Detailed description.
  @override
  final String description;

  /// Suggested fix/resolution.
  @override
  final String? suggestedFix;

  /// Action that can be taken to fix.
  @override
  final IssueAction? action;

  @override
  String toString() {
    return 'DiagnosticIssue(severity: $severity, category: $category, title: $title, description: $description, suggestedFix: $suggestedFix, action: $action)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiagnosticIssueImpl &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.suggestedFix, suggestedFix) ||
                other.suggestedFix == suggestedFix) &&
            (identical(other.action, action) || other.action == action));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, severity, category, title,
      description, suggestedFix, action);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiagnosticIssueImplCopyWith<_$DiagnosticIssueImpl> get copyWith =>
      __$$DiagnosticIssueImplCopyWithImpl<_$DiagnosticIssueImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiagnosticIssueImplToJson(
      this,
    );
  }
}

abstract class _DiagnosticIssue implements DiagnosticIssue {
  const factory _DiagnosticIssue(
      {required final IssueSeverity severity,
      required final IssueCategory category,
      required final String title,
      required final String description,
      final String? suggestedFix,
      final IssueAction? action}) = _$DiagnosticIssueImpl;

  factory _DiagnosticIssue.fromJson(Map<String, dynamic> json) =
      _$DiagnosticIssueImpl.fromJson;

  @override

  /// Severity of the issue.
  IssueSeverity get severity;
  @override

  /// Category of the issue.
  IssueCategory get category;
  @override

  /// Short title of the issue.
  String get title;
  @override

  /// Detailed description.
  String get description;
  @override

  /// Suggested fix/resolution.
  String? get suggestedFix;
  @override

  /// Action that can be taken to fix.
  IssueAction? get action;
  @override
  @JsonKey(ignore: true)
  _$$DiagnosticIssueImplCopyWith<_$DiagnosticIssueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
