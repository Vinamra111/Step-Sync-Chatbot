// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PermissionStateImpl _$$PermissionStateImplFromJson(
        Map<String, dynamic> json) =>
    _$PermissionStateImpl(
      stepsGranted: json['stepsGranted'] as bool,
      activityGranted: json['activityGranted'] as bool,
      status: $enumDecode(_$PermissionStatusEnumMap, json['status']),
      lastCheckedAt: json['lastCheckedAt'] == null
          ? null
          : DateTime.parse(json['lastCheckedAt'] as String),
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$PermissionStateImplToJson(
        _$PermissionStateImpl instance) =>
    <String, dynamic>{
      'stepsGranted': instance.stepsGranted,
      'activityGranted': instance.activityGranted,
      'status': _$PermissionStatusEnumMap[instance.status]!,
      'lastCheckedAt': instance.lastCheckedAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
    };

const _$PermissionStatusEnumMap = {
  PermissionStatus.unknown: 'unknown',
  PermissionStatus.granted: 'granted',
  PermissionStatus.denied: 'denied',
  PermissionStatus.requesting: 'requesting',
  PermissionStatus.error: 'error',
};
