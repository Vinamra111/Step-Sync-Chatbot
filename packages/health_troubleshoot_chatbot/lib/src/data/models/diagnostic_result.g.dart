// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DiagnosticResultImpl _$$DiagnosticResultImplFromJson(
        Map<String, dynamic> json) =>
    _$DiagnosticResultImpl(
      permissionState: PermissionState.fromJson(
          json['permissionState'] as Map<String, dynamic>),
      platformAvailability: PlatformAvailability.fromJson(
          json['platformAvailability'] as Map<String, dynamic>),
      batteryOptimization: json['batteryOptimization'] == null
          ? null
          : BatteryOptimizationStatus.fromJson(
              json['batteryOptimization'] as Map<String, dynamic>),
      dataSources: (json['dataSources'] as List<dynamic>?)
              ?.map((e) => DataSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentStepData: (json['recentStepData'] as List<dynamic>?)
          ?.map((e) => StepData.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallStatus:
          $enumDecode(_$SystemHealthStatusEnumMap, json['overallStatus']),
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => DiagnosticIssue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$DiagnosticResultImplToJson(
        _$DiagnosticResultImpl instance) =>
    <String, dynamic>{
      'permissionState': instance.permissionState,
      'platformAvailability': instance.platformAvailability,
      'batteryOptimization': instance.batteryOptimization,
      'dataSources': instance.dataSources,
      'recentStepData': instance.recentStepData,
      'overallStatus': _$SystemHealthStatusEnumMap[instance.overallStatus]!,
      'issues': instance.issues,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$SystemHealthStatusEnumMap = {
  SystemHealthStatus.healthy: 'healthy',
  SystemHealthStatus.warning: 'warning',
  SystemHealthStatus.error: 'error',
  SystemHealthStatus.unknown: 'unknown',
};

_$PlatformAvailabilityImpl _$$PlatformAvailabilityImplFromJson(
        Map<String, dynamic> json) =>
    _$PlatformAvailabilityImpl(
      isAvailable: json['isAvailable'] as bool,
      platformName: json['platformName'] as String,
      requiresInstallation: json['requiresInstallation'] as bool? ?? false,
      isSupported: json['isSupported'] as bool? ?? true,
      details: json['details'] as String?,
    );

Map<String, dynamic> _$$PlatformAvailabilityImplToJson(
        _$PlatformAvailabilityImpl instance) =>
    <String, dynamic>{
      'isAvailable': instance.isAvailable,
      'platformName': instance.platformName,
      'requiresInstallation': instance.requiresInstallation,
      'isSupported': instance.isSupported,
      'details': instance.details,
    };

_$BatteryOptimizationStatusImpl _$$BatteryOptimizationStatusImplFromJson(
        Map<String, dynamic> json) =>
    _$BatteryOptimizationStatusImpl(
      isOptimized: json['isOptimized'] as bool,
      isBlockingSync: json['isBlockingSync'] as bool,
      explanation: json['explanation'] as String,
      recommendedAction: json['recommendedAction'] as String?,
    );

Map<String, dynamic> _$$BatteryOptimizationStatusImplToJson(
        _$BatteryOptimizationStatusImpl instance) =>
    <String, dynamic>{
      'isOptimized': instance.isOptimized,
      'isBlockingSync': instance.isBlockingSync,
      'explanation': instance.explanation,
      'recommendedAction': instance.recommendedAction,
    };

_$DiagnosticIssueImpl _$$DiagnosticIssueImplFromJson(
        Map<String, dynamic> json) =>
    _$DiagnosticIssueImpl(
      severity: $enumDecode(_$IssueSeverityEnumMap, json['severity']),
      category: $enumDecode(_$IssueCategoryEnumMap, json['category']),
      title: json['title'] as String,
      description: json['description'] as String,
      suggestedFix: json['suggestedFix'] as String?,
      action: $enumDecodeNullable(_$IssueActionEnumMap, json['action']),
    );

Map<String, dynamic> _$$DiagnosticIssueImplToJson(
        _$DiagnosticIssueImpl instance) =>
    <String, dynamic>{
      'severity': _$IssueSeverityEnumMap[instance.severity]!,
      'category': _$IssueCategoryEnumMap[instance.category]!,
      'title': instance.title,
      'description': instance.description,
      'suggestedFix': instance.suggestedFix,
      'action': _$IssueActionEnumMap[instance.action],
    };

const _$IssueSeverityEnumMap = {
  IssueSeverity.info: 'info',
  IssueSeverity.warning: 'warning',
  IssueSeverity.error: 'error',
  IssueSeverity.critical: 'critical',
};

const _$IssueCategoryEnumMap = {
  IssueCategory.permissions: 'permissions',
  IssueCategory.platform: 'platform',
  IssueCategory.system: 'system',
  IssueCategory.dataSources: 'dataSources',
  IssueCategory.sync: 'sync',
  IssueCategory.unknown: 'unknown',
};

const _$IssueActionEnumMap = {
  IssueAction.grantPermissions: 'grantPermissions',
  IssueAction.installHealthConnect: 'installHealthConnect',
  IssueAction.openBatterySettings: 'openBatterySettings',
  IssueAction.openAppSettings: 'openAppSettings',
  IssueAction.selectPrimarySource: 'selectPrimarySource',
  IssueAction.contactSupport: 'contactSupport',
};
