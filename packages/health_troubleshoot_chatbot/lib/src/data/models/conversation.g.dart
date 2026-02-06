// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationImpl _$$ConversationImplFromJson(Map<String, dynamic> json) =>
    _$ConversationImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      title: json['title'] as String?,
      status: $enumDecodeNullable(
              _$ConversationLifecycleStatusEnumMap, json['status']) ??
          ConversationLifecycleStatus.active,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$ConversationImplToJson(_$ConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'messages': instance.messages,
      'title': instance.title,
      'status': _$ConversationLifecycleStatusEnumMap[instance.status]!,
      'metadata': instance.metadata,
      'isActive': instance.isActive,
    };

const _$ConversationLifecycleStatusEnumMap = {
  ConversationLifecycleStatus.active: 'active',
  ConversationLifecycleStatus.completed: 'completed',
  ConversationLifecycleStatus.archived: 'archived',
};
