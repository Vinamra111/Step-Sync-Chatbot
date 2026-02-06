// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: $enumDecode(_$MessageSenderEnumMap, json['sender']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: $enumDecodeNullable(_$MessageTypeEnumMap, json['type']) ??
          MessageType.text,
      data: json['data'] as Map<String, dynamic>?,
      isError: json['isError'] as bool? ?? false,
      quickReplies: (json['quickReplies'] as List<dynamic>?)
          ?.map((e) => QuickReply.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'sender': _$MessageSenderEnumMap[instance.sender]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$MessageTypeEnumMap[instance.type]!,
      'data': instance.data,
      'isError': instance.isError,
      'quickReplies': instance.quickReplies,
    };

const _$MessageSenderEnumMap = {
  MessageSender.user: 'user',
  MessageSender.bot: 'bot',
  MessageSender.system: 'system',
};

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.stepChart: 'stepChart',
  MessageType.permissionRequest: 'permissionRequest',
  MessageType.error: 'error',
};

_$QuickReplyImpl _$$QuickReplyImplFromJson(Map<String, dynamic> json) =>
    _$QuickReplyImpl(
      label: json['label'] as String,
      value: json['value'] as String,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$$QuickReplyImplToJson(_$QuickReplyImpl instance) =>
    <String, dynamic>{
      'label': instance.label,
      'value': instance.value,
      'icon': instance.icon,
    };
