/// Diagnostic capabilities abstraction
///
/// Handles automated troubleshooting and issue detection.

import '../data/models/tracking_status.dart';

/// Abstract diagnostic provider
///
/// Each domain implements this to provide domain-specific diagnostics.
abstract class DiagnosticProvider {
  /// Run full diagnostic check
  ///
  /// Checks for common issues:
  /// - Permissions not granted
  /// - Data not syncing
  /// - Conflicting data sources
  /// - Battery optimization blocking sync
  /// - Wrong metric values
  Future<TrackingStatusResult> checkTrackingStatus();

  /// Get list of supported issue types for this domain
  List<TrackingIssueType> getSupportedIssues();

  /// Create a tracking issue with domain-specific details
  TrackingIssue createIssue(
    TrackingIssueType type, {
    Map<String, dynamic>? params,
  });

  /// Check specific issue type
  Future<TrackingIssue?> checkSpecificIssue(TrackingIssueType type);

  /// Get human-readable description of an issue type
  String getIssueDescription(TrackingIssueType type);

  /// Get recommended fix for an issue
  String getIssueFix(TrackingIssueType type);
}

/// Base class for diagnostic providers
///
/// Provides common functionality for domain-specific diagnostic providers.
abstract class BaseDiagnosticProvider implements DiagnosticProvider {
  final Map<String, String> placeholders;

  const BaseDiagnosticProvider({required this.placeholders});

  /// Render a template with placeholders
  String renderTemplate(String template) {
    String result = template;

    for (final entry in placeholders.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }

    return result;
  }

  @override
  String getIssueDescription(TrackingIssueType type) {
    switch (type) {
      case TrackingIssueType.permissionsNotGranted:
        return renderTemplate(
          'The app doesn\'t have permission to read your {{metric_name}}.',
        );
      case TrackingIssueType.dataNotSyncing:
        return renderTemplate(
          'Your {{metric_name}} data isn\'t syncing properly.',
        );
      case TrackingIssueType.wrongDataSource:
        return renderTemplate(
          'The wrong data source is selected for {{metric_name}}.',
        );
      case TrackingIssueType.conflictingDataSources:
        return renderTemplate(
          'Multiple apps are writing conflicting {{metric_name}} data.',
        );
      case TrackingIssueType.batteryOptimizationEnabled:
        return renderTemplate(
          'Battery optimization is preventing {{metric_name}} tracking.',
        );
      case TrackingIssueType.wrongCount:
        return renderTemplate(
          'The {{metric_name}} count appears to be incorrect.',
        );
      case TrackingIssueType.duplicateData:
        return renderTemplate(
          'Duplicate {{metric_name}} entries are being recorded.',
        );
      case TrackingIssueType.appNotInstalled:
        return renderTemplate(
          'Required tracking app is not installed.',
        );
      case TrackingIssueType.deviceNotSupported:
        return renderTemplate(
          'Your device doesn\'t support {{metric_name}} tracking.',
        );
      default:
        return 'Unknown issue detected.';
    }
  }

  @override
  String getIssueFix(TrackingIssueType type) {
    switch (type) {
      case TrackingIssueType.permissionsNotGranted:
        return renderTemplate(
          'Go to Settings → {{app_name}} → Health/Fitness and enable all permissions.',
        );
      case TrackingIssueType.dataNotSyncing:
        return renderTemplate(
          'Try force-closing {{app_name}} and reopening it. If that doesn\'t work, check your internet connection.',
        );
      case TrackingIssueType.wrongDataSource:
        return renderTemplate(
          'Go to Settings → Data Sources and select your preferred {{metric_name}} tracker.',
        );
      case TrackingIssueType.conflictingDataSources:
        return renderTemplate(
          'Disable {{metric_name}} tracking in one of your fitness apps to avoid conflicts.',
        );
      case TrackingIssueType.batteryOptimizationEnabled:
        return renderTemplate(
          'Go to Settings → Battery → {{app_name}} and disable battery optimization.',
        );
      case TrackingIssueType.wrongCount:
        return renderTemplate(
          'Check which app is your primary {{metric_name}} source. You may have duplicate entries.',
        );
      case TrackingIssueType.duplicateData:
        return renderTemplate(
          'Remove duplicate data sources in your Health/Fitness app settings.',
        );
      case TrackingIssueType.appNotInstalled:
        return 'Install a compatible fitness tracking app from the App Store/Play Store.';
      case TrackingIssueType.deviceNotSupported:
        return 'Unfortunately, your device hardware doesn\'t support automatic tracking. Consider using a wearable device.';
      default:
        return 'Please contact support for assistance.';
    }
  }

  @override
  TrackingIssue createIssue(
    TrackingIssueType type, {
    Map<String, dynamic>? params,
  }) {
    return TrackingIssue(
      type: type,
      title: type.toString().split('.').last,
      description: getIssueDescription(type),
      suggestedFix: getIssueFix(type),
      severity: _getIssueSeverity(type),
    );
  }

  /// Determine severity of an issue
  TrackingIssueSeverity _getIssueSeverity(TrackingIssueType type) {
    switch (type) {
      case TrackingIssueType.permissionsNotGranted:
      case TrackingIssueType.appNotInstalled:
      case TrackingIssueType.deviceNotSupported:
        return TrackingIssueSeverity.critical;

      case TrackingIssueType.dataNotSyncing:
      case TrackingIssueType.wrongDataSource:
      case TrackingIssueType.batteryOptimizationEnabled:
        return TrackingIssueSeverity.high;

      case TrackingIssueType.conflictingDataSources:
      case TrackingIssueType.wrongCount:
      case TrackingIssueType.duplicateData:
        return TrackingIssueSeverity.medium;

      default:
        return TrackingIssueSeverity.low;
    }
  }
}
