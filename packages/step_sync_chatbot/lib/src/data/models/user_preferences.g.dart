// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserPreferencesImpl _$$UserPreferencesImplFromJson(
        Map<String, dynamic> json) =>
    _$UserPreferencesImpl(
      userId: json['userId'] as String,
      preferredDataSource: json['preferredDataSource'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      conversationStyle: $enumDecodeNullable(
              _$ConversationStyleEnumMap, json['conversationStyle']) ??
          ConversationStyle.balanced,
      learnedTopics: (json['learnedTopics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$UserPreferencesImplToJson(
        _$UserPreferencesImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'preferredDataSource': instance.preferredDataSource,
      'notificationsEnabled': instance.notificationsEnabled,
      'conversationStyle':
          _$ConversationStyleEnumMap[instance.conversationStyle]!,
      'learnedTopics': instance.learnedTopics,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };

const _$ConversationStyleEnumMap = {
  ConversationStyle.concise: 'concise',
  ConversationStyle.balanced: 'balanced',
  ConversationStyle.detailed: 'detailed',
};
