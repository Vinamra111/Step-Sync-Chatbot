// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sanitization_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SanitizationResultImpl _$$SanitizationResultImplFromJson(
        Map<String, dynamic> json) =>
    _$SanitizationResultImpl(
      originalText: json['originalText'] as String,
      sanitizedText: json['sanitizedText'] as String,
      detectedEntities: (json['detectedEntities'] as List<dynamic>?)
              ?.map((e) => DetectedEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isSafe: json['isSafe'] as bool,
    );

Map<String, dynamic> _$$SanitizationResultImplToJson(
        _$SanitizationResultImpl instance) =>
    <String, dynamic>{
      'originalText': instance.originalText,
      'sanitizedText': instance.sanitizedText,
      'detectedEntities': instance.detectedEntities,
      'isSafe': instance.isSafe,
    };

_$DetectedEntityImpl _$$DetectedEntityImplFromJson(Map<String, dynamic> json) =>
    _$DetectedEntityImpl(
      type: $enumDecode(_$EntityTypeEnumMap, json['type']),
      originalValue: json['originalValue'] as String,
      sanitizedValue: json['sanitizedValue'] as String,
      startIndex: (json['startIndex'] as num).toInt(),
      endIndex: (json['endIndex'] as num).toInt(),
    );

Map<String, dynamic> _$$DetectedEntityImplToJson(
        _$DetectedEntityImpl instance) =>
    <String, dynamic>{
      'type': _$EntityTypeEnumMap[instance.type]!,
      'originalValue': instance.originalValue,
      'sanitizedValue': instance.sanitizedValue,
      'startIndex': instance.startIndex,
      'endIndex': instance.endIndex,
    };

const _$EntityTypeEnumMap = {
  EntityType.number: 'number',
  EntityType.date: 'date',
  EntityType.appName: 'appName',
  EntityType.deviceName: 'deviceName',
  EntityType.name: 'name',
  EntityType.email: 'email',
  EntityType.phoneNumber: 'phoneNumber',
  EntityType.location: 'location',
  EntityType.other: 'other',
};
