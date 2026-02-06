import 'dart:io';
import '../data/models/diagnostic_result.dart';
import '../data/models/permission_state.dart';
import '../data/models/step_data.dart';
import '../health/health_service.dart';
import '../utils/platform_utils.dart';
import '../diagnostics/battery_checker.dart' show BatteryChecker, BatteryCheckResult;

/// Service for running comprehensive diagnostics on the step tracking system.
class DiagnosticService {
  final HealthService _healthService;
  final BatteryChecker _batteryChecker;

  DiagnosticService({
    required HealthService healthService,
    BatteryChecker? batteryChecker,
  })  : _healthService = healthService,
        _batteryChecker = batteryChecker ?? BatteryChecker();

  /// Run a comprehensive diagnostic check.
  ///
  /// This checks:
  /// - Health platform availability (Health Connect/HealthKit)
  /// - Permissions status
  /// - Data sources
  /// - Battery optimization (Android)
  /// - Recent data availability
  Future<DiagnosticResult> runDiagnostics() async {
    final timestamp = DateTime.now();
    final issues = <DiagnosticIssue>[];

    // Check platform availability
    final platformAvailability = await _checkPlatformAvailability();

    if (!platformAvailability.isAvailable) {
      if (platformAvailability.requiresInstallation) {
        issues.add(DiagnosticIssue.healthConnectNotInstalled());
      }
    }

    // Check permissions
    final permissionState = await _healthService.checkPermissions();

    if (permissionState.status != PermissionStatus.granted) {
      issues.add(DiagnosticIssue.permissionsDenied());
    }

    // Check battery optimization (Android only)
    BatteryOptimizationStatus? batteryStatus;
    if (Platform.isAndroid) {
      batteryStatus = await _checkBatteryOptimization();
      if (batteryStatus.isBlockingSync) {
        issues.add(DiagnosticIssue.batteryOptimization());
      }
    }

    // Check data sources
    final dataSources = await _getDataSources();

    if (dataSources.isEmpty) {
      issues.add(DiagnosticIssue.noDataSources());
    } else if (dataSources.length > 3) {
      issues.add(DiagnosticIssue.multipleDataSources(dataSources.length));
    }

    // Try to fetch recent data
    final recentStepData = await _getRecentStepData();

    // Determine overall status
    final overallStatus = _determineOverallStatus(issues);

    return DiagnosticResult(
      permissionState: permissionState,
      platformAvailability: platformAvailability,
      batteryOptimization: batteryStatus,
      dataSources: dataSources,
      recentStepData: recentStepData,
      overallStatus: overallStatus,
      issues: issues,
      timestamp: timestamp,
    );
  }

  /// Check platform availability (Health Connect/HealthKit).
  Future<PlatformAvailability> _checkPlatformAvailability() async {
    try {
      final isAvailable = await _healthService.isAvailable();
      final platformName = _healthService.getPlatformName();

      if (Platform.isAndroid) {
        // Check if Health Connect installation is required
        final requirement = await PlatformUtils.getHealthConnectRequirement();

        if (requirement == HealthConnectRequirement.separateApp && !isAvailable) {
          return PlatformAvailability.healthConnectNotInstalled();
        }

        if (requirement == HealthConnectRequirement.notSupported) {
          return PlatformAvailability.notSupported(
            'Your Android version does not support Health Connect',
          );
        }

        return PlatformAvailability.healthConnectInstalled();
      } else if (Platform.isIOS) {
        return PlatformAvailability.healthKit(available: isAvailable);
      }

      return PlatformAvailability.notSupported('Platform not supported');
    } catch (e) {
      return PlatformAvailability.notSupported('Failed to check availability: $e');
    }
  }

  /// Check battery optimization status via method channel.
  ///
  /// IMPORTANT: This requires Android native code implementation.
  /// See android_integration.md for setup instructions.
  ///
  /// Possible issues:
  /// - Method channel not implemented in MainActivity → returns unknown
  /// - Android version < 6.0 → returns notApplicable
  /// - Permission not in manifest → may fail
  Future<BatteryOptimizationStatus> _checkBatteryOptimization() async {
    try {
      final result = await _batteryChecker.checkBatteryOptimization();

      // Map from BatteryCheckResult enum to BatteryOptimizationStatus model
      switch (result) {
        case BatteryCheckResult.enabled:
          return BatteryOptimizationStatus.enabled();
        case BatteryCheckResult.disabled:
          return BatteryOptimizationStatus.disabled();
        case BatteryCheckResult.notApplicable:
          // Return null for notApplicable (diagnostic model expects nullable)
          return BatteryOptimizationStatus.unknown();
        case BatteryCheckResult.unknown:
        default:
          return BatteryOptimizationStatus.unknown();
      }
    } catch (e) {
      // If method channel fails, return unknown rather than crashing
      return BatteryOptimizationStatus.unknown();
    }
  }

  /// Get available data sources.
  Future<List<DataSource>> _getDataSources() async {
    try {
      return await _healthService.getDataSources();
    } catch (e) {
      return [];
    }
  }

  /// Get recent step data (last 7 days).
  Future<List<StepData>?> _getRecentStepData() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      return await _healthService.getStepData(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      return null;
    }
  }

  /// Determine overall system health status based on issues.
  SystemHealthStatus _determineOverallStatus(List<DiagnosticIssue> issues) {
    if (issues.isEmpty) {
      return SystemHealthStatus.healthy;
    }

    // Check for critical issues
    final hasCritical = issues.any(
      (issue) => issue.severity == IssueSeverity.critical,
    );

    if (hasCritical) {
      return SystemHealthStatus.error;
    }

    // Check for errors
    final hasError = issues.any(
      (issue) => issue.severity == IssueSeverity.error,
    );

    if (hasError) {
      return SystemHealthStatus.error;
    }

    // Check for warnings
    final hasWarning = issues.any(
      (issue) => issue.severity == IssueSeverity.warning,
    );

    if (hasWarning) {
      return SystemHealthStatus.warning;
    }

    // Only info issues
    return SystemHealthStatus.healthy;
  }

  /// Format diagnostic result as user-friendly text.
  String formatDiagnosticReport(DiagnosticResult result) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('${result.overallStatus.emoji} Diagnostic Report');
    buffer.writeln('Status: ${result.overallStatus.label}');
    buffer.writeln();

    // Platform availability
    buffer.writeln('📱 Platform: ${result.platformAvailability.platformName}');
    if (result.platformAvailability.isAvailable) {
      buffer.writeln('   ✓ Available');
    } else {
      buffer.writeln('   ✗ Not available');
      if (result.platformAvailability.details != null) {
        buffer.writeln('   ${result.platformAvailability.details}');
      }
    }
    buffer.writeln();

    // Permissions
    buffer.writeln('🔐 Permissions:');
    if (result.permissionState.status == PermissionStatus.granted) {
      buffer.writeln('   ✓ Granted');
    } else {
      buffer.writeln('   ✗ Not granted');
    }
    buffer.writeln();

    // Data sources
    buffer.writeln('📊 Data Sources: ${result.dataSources.length}');
    for (final source in result.dataSources.take(3)) {
      final marker = source.isPrimary ? '★' : '•';
      buffer.writeln('   $marker ${source.name}');
    }
    if (result.dataSources.length > 3) {
      buffer.writeln('   ... and ${result.dataSources.length - 3} more');
    }
    buffer.writeln();

    // Recent data
    if (result.recentStepData != null && result.recentStepData!.isNotEmpty) {
      final todaySteps = result.recentStepData!.last.steps;
      buffer.writeln('👟 Today: $todaySteps steps');
      buffer.writeln();
    }

    // Issues
    if (result.issues.isNotEmpty) {
      buffer.writeln('Issues Found:');
      for (final issue in result.issues) {
        buffer.writeln('${issue.severity.emoji} ${issue.title}');
        buffer.writeln('   ${issue.description}');
        if (issue.suggestedFix != null) {
          buffer.writeln('   💡 ${issue.suggestedFix}');
        }
        buffer.writeln();
      }
    } else {
      buffer.writeln('✅ No issues found!');
    }

    return buffer.toString();
  }
}
