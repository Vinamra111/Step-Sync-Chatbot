// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LLMResponseImpl _$$LLMResponseImplFromJson(Map<String, dynamic> json) =>
    _$LLMResponseImpl(
      text: json['text'] as String,
      provider: json['provider'] as String,
      model: json['model'] as String,
      promptTokens: (json['promptTokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completionTokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      responseTimeMs: (json['responseTimeMs'] as num?)?.toInt() ?? 0,
      success: json['success'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$LLMResponseImplToJson(_$LLMResponseImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'provider': instance.provider,
      'model': instance.model,
      'promptTokens': instance.promptTokens,
      'completionTokens': instance.completionTokens,
      'totalTokens': instance.totalTokens,
      'estimatedCost': instance.estimatedCost,
      'responseTimeMs': instance.responseTimeMs,
      'success': instance.success,
      'errorMessage': instance.errorMessage,
      'timestamp': instance.timestamp?.toIso8601String(),
      'metadata': instance.metadata,
    };
