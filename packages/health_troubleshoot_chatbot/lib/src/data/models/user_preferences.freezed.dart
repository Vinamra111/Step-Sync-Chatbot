// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) {
  return _UserPreferences.fromJson(json);
}

/// @nodoc
mixin _$UserPreferences {
  /// User ID these preferences belong to.
  String get userId => throw _privateConstructorUsedError;

  /// Preferred primary data source (e.g., "com.samsung.android.app.health").
  String? get preferredDataSource => throw _privateConstructorUsedError;

  /// Whether to enable notifications.
  bool get notificationsEnabled => throw _privateConstructorUsedError;

  /// Conversation style preference.
  ConversationStyle get conversationStyle => throw _privateConstructorUsedError;

  /// Topics the user has already learned about (don't re-explain).
  List<String> get learnedTopics => throw _privateConstructorUsedError;

  /// When preferences were last updated.
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserPreferencesCopyWith<UserPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserPreferencesCopyWith<$Res> {
  factory $UserPreferencesCopyWith(
          UserPreferences value, $Res Function(UserPreferences) then) =
      _$UserPreferencesCopyWithImpl<$Res, UserPreferences>;
  @useResult
  $Res call(
      {String userId,
      String? preferredDataSource,
      bool notificationsEnabled,
      ConversationStyle conversationStyle,
      List<String> learnedTopics,
      DateTime? lastUpdated});
}

/// @nodoc
class _$UserPreferencesCopyWithImpl<$Res, $Val extends UserPreferences>
    implements $UserPreferencesCopyWith<$Res> {
  _$UserPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? preferredDataSource = freezed,
    Object? notificationsEnabled = null,
    Object? conversationStyle = null,
    Object? learnedTopics = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      preferredDataSource: freezed == preferredDataSource
          ? _value.preferredDataSource
          : preferredDataSource // ignore: cast_nullable_to_non_nullable
              as String?,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      conversationStyle: null == conversationStyle
          ? _value.conversationStyle
          : conversationStyle // ignore: cast_nullable_to_non_nullable
              as ConversationStyle,
      learnedTopics: null == learnedTopics
          ? _value.learnedTopics
          : learnedTopics // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserPreferencesImplCopyWith<$Res>
    implements $UserPreferencesCopyWith<$Res> {
  factory _$$UserPreferencesImplCopyWith(_$UserPreferencesImpl value,
          $Res Function(_$UserPreferencesImpl) then) =
      __$$UserPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String? preferredDataSource,
      bool notificationsEnabled,
      ConversationStyle conversationStyle,
      List<String> learnedTopics,
      DateTime? lastUpdated});
}

/// @nodoc
class __$$UserPreferencesImplCopyWithImpl<$Res>
    extends _$UserPreferencesCopyWithImpl<$Res, _$UserPreferencesImpl>
    implements _$$UserPreferencesImplCopyWith<$Res> {
  __$$UserPreferencesImplCopyWithImpl(
      _$UserPreferencesImpl _value, $Res Function(_$UserPreferencesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? preferredDataSource = freezed,
    Object? notificationsEnabled = null,
    Object? conversationStyle = null,
    Object? learnedTopics = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_$UserPreferencesImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      preferredDataSource: freezed == preferredDataSource
          ? _value.preferredDataSource
          : preferredDataSource // ignore: cast_nullable_to_non_nullable
              as String?,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      conversationStyle: null == conversationStyle
          ? _value.conversationStyle
          : conversationStyle // ignore: cast_nullable_to_non_nullable
              as ConversationStyle,
      learnedTopics: null == learnedTopics
          ? _value._learnedTopics
          : learnedTopics // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserPreferencesImpl implements _UserPreferences {
  const _$UserPreferencesImpl(
      {required this.userId,
      this.preferredDataSource,
      this.notificationsEnabled = true,
      this.conversationStyle = ConversationStyle.balanced,
      final List<String> learnedTopics = const [],
      this.lastUpdated})
      : _learnedTopics = learnedTopics;

  factory _$UserPreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserPreferencesImplFromJson(json);

  /// User ID these preferences belong to.
  @override
  final String userId;

  /// Preferred primary data source (e.g., "com.samsung.android.app.health").
  @override
  final String? preferredDataSource;

  /// Whether to enable notifications.
  @override
  @JsonKey()
  final bool notificationsEnabled;

  /// Conversation style preference.
  @override
  @JsonKey()
  final ConversationStyle conversationStyle;

  /// Topics the user has already learned about (don't re-explain).
  final List<String> _learnedTopics;

  /// Topics the user has already learned about (don't re-explain).
  @override
  @JsonKey()
  List<String> get learnedTopics {
    if (_learnedTopics is EqualUnmodifiableListView) return _learnedTopics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_learnedTopics);
  }

  /// When preferences were last updated.
  @override
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'UserPreferences(userId: $userId, preferredDataSource: $preferredDataSource, notificationsEnabled: $notificationsEnabled, conversationStyle: $conversationStyle, learnedTopics: $learnedTopics, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserPreferencesImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.preferredDataSource, preferredDataSource) ||
                other.preferredDataSource == preferredDataSource) &&
            (identical(other.notificationsEnabled, notificationsEnabled) ||
                other.notificationsEnabled == notificationsEnabled) &&
            (identical(other.conversationStyle, conversationStyle) ||
                other.conversationStyle == conversationStyle) &&
            const DeepCollectionEquality()
                .equals(other._learnedTopics, _learnedTopics) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      preferredDataSource,
      notificationsEnabled,
      conversationStyle,
      const DeepCollectionEquality().hash(_learnedTopics),
      lastUpdated);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      __$$UserPreferencesImplCopyWithImpl<_$UserPreferencesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserPreferencesImplToJson(
      this,
    );
  }
}

abstract class _UserPreferences implements UserPreferences {
  const factory _UserPreferences(
      {required final String userId,
      final String? preferredDataSource,
      final bool notificationsEnabled,
      final ConversationStyle conversationStyle,
      final List<String> learnedTopics,
      final DateTime? lastUpdated}) = _$UserPreferencesImpl;

  factory _UserPreferences.fromJson(Map<String, dynamic> json) =
      _$UserPreferencesImpl.fromJson;

  @override

  /// User ID these preferences belong to.
  String get userId;
  @override

  /// Preferred primary data source (e.g., "com.samsung.android.app.health").
  String? get preferredDataSource;
  @override

  /// Whether to enable notifications.
  bool get notificationsEnabled;
  @override

  /// Conversation style preference.
  ConversationStyle get conversationStyle;
  @override

  /// Topics the user has already learned about (don't re-explain).
  List<String> get learnedTopics;
  @override

  /// When preferences were last updated.
  DateTime? get lastUpdated;
  @override
  @JsonKey(ignore: true)
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
