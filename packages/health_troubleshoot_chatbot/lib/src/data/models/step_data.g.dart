// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'step_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StepDataImpl _$$StepDataImplFromJson(Map<String, dynamic> json) =>
    _$StepDataImpl(
      date: DateTime.parse(json['date'] as String),
      steps: (json['steps'] as num).toInt(),
      source: DataSource.fromJson(json['source'] as Map<String, dynamic>),
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.parse(json['lastSyncedAt'] as String),
    );

Map<String, dynamic> _$$StepDataImplToJson(_$StepDataImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'steps': instance.steps,
      'source': instance.source,
      'lastSyncedAt': instance.lastSyncedAt?.toIso8601String(),
    };

_$DataSourceImpl _$$DataSourceImplFromJson(Map<String, dynamic> json) =>
    _$DataSourceImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecodeNullable(_$DataSourceTypeEnumMap, json['type']) ??
          DataSourceType.app,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Map<String, dynamic> _$$DataSourceImplToJson(_$DataSourceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$DataSourceTypeEnumMap[instance.type]!,
      'isPrimary': instance.isPrimary,
    };

const _$DataSourceTypeEnumMap = {
  DataSourceType.app: 'app',
  DataSourceType.phone: 'phone',
  DataSourceType.watch: 'watch',
  DataSourceType.unknown: 'unknown',
};
