import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/core/diagnostic_service.dart';
import 'package:step_sync_chatbot/src/data/models/diagnostic_result.dart';
import 'package:step_sync_chatbot/src/data/models/permission_state.dart';
import 'package:step_sync_chatbot/src/data/models/step_data.dart';
import 'package:step_sync_chatbot/src/health/mock_health_service.dart';

void main() {
  group('DiagnosticService', () {
    late MockHealthService mockHealthService;
    late DiagnosticService diagnosticService;

    setUp(() {
      mockHealthService = MockHealthService();
      diagnosticService = DiagnosticService(healthService: mockHealthService);
    });

    group('runDiagnostics', () {
      test('returns healthy status when everything is working', () async {
        // Arrange - Set up healthy defaults
        mockHealthService.mockPermissionState = PermissionState.granted();
        mockHealthService.mockIsAvailable = true;
        await mockHealthService.initialize();
        // Set data sources after initialize to override defaults
        mockHealthService.mockDataSources = [
          DataSource(id: 'com.google.fit', name: 'Google Fit'),
        ];

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        expect(result.overallStatus, SystemHealthStatus.healthy);
        expect(result.issues, isEmpty);
        expect(result.permissionState.status, PermissionStatus.granted);
        // Platform availability check depends on actual platform (Android/iOS),
        // so in test environment (Windows) it won't match mobile platforms
        expect(result.platformAvailability, isNotNull);
      });

      test('detects permission denied issue', () async {
        // Arrange
        await mockHealthService.initialize();
        // MockHealthService has a way to set permission state
        mockHealthService.mockPermissionState = PermissionState.denied();

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        expect(result.overallStatus, SystemHealthStatus.error);
        expect(result.issues.length, greaterThan(0));

        final permissionIssue = result.issues.firstWhere(
          (issue) => issue.category == IssueCategory.permissions,
        );
        expect(permissionIssue.severity, IssueSeverity.critical);
        expect(permissionIssue.action, IssueAction.grantPermissions);
      });

      test('detects no data sources issue', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockDataSources = []; // No data sources

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        expect(result.dataSources, isEmpty);

        final dataSourceIssue = result.issues.firstWhere(
          (issue) => issue.category == IssueCategory.dataSources,
          orElse: () => throw Exception('No data source issue found'),
        );
        expect(dataSourceIssue.severity, IssueSeverity.warning);
      });

      test('detects multiple data sources issue', () async {
        // Arrange
        await mockHealthService.initialize();
        // Add 5 data sources to trigger multiple sources issue
        mockHealthService.mockDataSources = List.generate(
          5,
          (i) => DataSource(
            id: 'com.example.source$i',
            name: 'Source $i',
          ),
        );

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        expect(result.dataSources.length, 5);

        final multipleSourcesIssue = result.issues.firstWhere(
          (issue) => issue.category == IssueCategory.dataSources &&
                     issue.title.contains('Multiple'),
          orElse: () => throw Exception('Multiple data sources issue not found'),
        );
        expect(multipleSourcesIssue.severity, IssueSeverity.info);
        expect(multipleSourcesIssue.action, IssueAction.selectPrimarySource);
      });

      test('includes recent step data when available', () async {
        // Arrange
        await mockHealthService.initialize();
        final mockSource = const DataSource(id: 'mock', name: 'Mock Source');
        final mockStepData = [
          StepData(
            date: DateTime.now().subtract(const Duration(days: 1)),
            steps: 8000,
            source: mockSource,
          ),
          StepData(
            date: DateTime.now(),
            steps: 5000,
            source: mockSource,
          ),
        ];
        mockHealthService.mockStepData = mockStepData;

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        expect(result.recentStepData, isNotNull);
        expect(result.recentStepData!.length, 2);
        expect(result.recentStepData!.last.steps, 5000);
      });

      test('handles null recent step data gracefully', () async {
        // Arrange
        mockHealthService.mockPermissionState = PermissionState.granted();
        mockHealthService.mockIsAvailable = true;
        await mockHealthService.initialize();
        // Set data sources after initialize
        mockHealthService.mockDataSources = [
          DataSource(id: 'com.google.fit', name: 'Google Fit'),
        ];
        // Set empty list to simulate no data available (will be treated as null by diagnostic service)
        mockHealthService.mockStepData = [];

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        // Empty step data should be returned as empty list, not null
        expect(result.recentStepData, isNotNull);
        expect(result.recentStepData, isEmpty);
        // Should not crash and should still complete diagnostic
        expect(result.timestamp, isNotNull);
      });

      test('includes timestamp in result', () async {
        // Arrange
        mockHealthService.mockPermissionState = PermissionState.granted();
        mockHealthService.mockIsAvailable = true;
        await mockHealthService.initialize();
        mockHealthService.mockDataSources = [
          DataSource(id: 'com.google.fit', name: 'Google Fit'),
        ];
        final beforeTime = DateTime.now();

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        final afterTime = DateTime.now();
        expect(result.timestamp.isAfter(beforeTime.subtract(const Duration(seconds: 1))), isTrue);
        expect(result.timestamp.isBefore(afterTime.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('formatDiagnosticReport', () {
      test('formats healthy report correctly', () async {
        // Arrange
        mockHealthService.mockPermissionState = PermissionState.granted();
        mockHealthService.mockIsAvailable = true;
        await mockHealthService.initialize();
        mockHealthService.mockDataSources = [
          DataSource(id: 'com.google.fit', name: 'Google Fit'),
        ];
        final result = await diagnosticService.runDiagnostics();

        // Act
        final report = diagnosticService.formatDiagnosticReport(result);

        // Assert
        expect(report, contains('Diagnostic Report'));
        expect(report, contains('Healthy'));
        expect(report, contains('Platform:'));
        expect(report, contains('Permissions:'));
        expect(report, contains('✓ Granted'));
        expect(report, contains('Data Sources:'));
      });

      test('formats report with issues correctly', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockPermissionState = PermissionState.denied();
        final result = await diagnosticService.runDiagnostics();

        // Act
        final report = diagnosticService.formatDiagnosticReport(result);

        // Assert
        expect(report, contains('Issues Found:'));
        expect(report, contains('Permissions Not Granted'));
        expect(report, contains('💡')); // Should contain suggested fix emoji
      });

      test('formats report with today\'s steps when available', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockStepData = [
          StepData(
            date: DateTime.now(),
            steps: 12345,
            source: const DataSource(id: 'mock', name: 'Mock Source'),
          ),
        ];
        final result = await diagnosticService.runDiagnostics();

        // Act
        final report = diagnosticService.formatDiagnosticReport(result);

        // Assert
        expect(report, contains('12345 steps'));
      });

      test('formats report with multiple data sources', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockDataSources = [
          const DataSource(id: 'com.google.fit', name: 'Google Fit'),
          const DataSource(id: 'com.samsung.health', name: 'Samsung Health'),
          const DataSource(id: 'com.fitbit.app', name: 'Fitbit', isPrimary: true),
          const DataSource(id: 'com.strava.app', name: 'Strava'),
        ];
        final result = await diagnosticService.runDiagnostics();

        // Act
        final report = diagnosticService.formatDiagnosticReport(result);

        // Assert
        expect(report, contains('Data Sources: 4'));
        expect(report, contains('Google Fit'));
        expect(report, contains('Samsung Health'));
        expect(report, contains('Fitbit'));
        expect(report, contains('★')); // Primary source indicator
        expect(report, contains('and 1 more')); // Should truncate at 3
      });

      test('includes platform details when not available', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockIsAvailable = false;
        final result = await diagnosticService.runDiagnostics();

        // Act
        final report = diagnosticService.formatDiagnosticReport(result);

        // Assert
        expect(report, contains('✗ Not available'));
      });

      test('shows no issues message when healthy', () async {
        // Arrange
        mockHealthService.mockPermissionState = PermissionState.granted();
        mockHealthService.mockIsAvailable = true;
        await mockHealthService.initialize();
        mockHealthService.mockDataSources = [
          DataSource(id: 'com.google.fit', name: 'Google Fit'),
        ];
        final result = await diagnosticService.runDiagnostics();

        // Act
        final report = diagnosticService.formatDiagnosticReport(result);

        // Assert
        expect(report.toLowerCase(), contains('no issues'));
      });
    });

    group('_determineOverallStatus', () {
      test('returns healthy when no issues', () async {
        // Arrange
        mockHealthService.mockPermissionState = PermissionState.granted();
        mockHealthService.mockIsAvailable = true;
        await mockHealthService.initialize();
        mockHealthService.mockDataSources = [
          DataSource(id: 'com.google.fit', name: 'Google Fit'),
        ];

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        expect(result.overallStatus, SystemHealthStatus.healthy);
      });

      test('returns error when critical issues exist', () async {
        // Arrange
        await mockHealthService.initialize();
        mockHealthService.mockPermissionState = PermissionState.denied();

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        expect(result.overallStatus, SystemHealthStatus.error);
      });

      test('returns warning when only warning issues exist', () async {
        // Arrange
        mockHealthService.mockPermissionState = PermissionState.granted();
        mockHealthService.mockIsAvailable = true;
        await mockHealthService.initialize();
        mockHealthService.mockDataSources = []; // Causes warning issue

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        expect(result.overallStatus, SystemHealthStatus.warning);
      });

      test('returns healthy when only info issues exist', () async {
        // Arrange
        mockHealthService.mockPermissionState = PermissionState.granted();
        mockHealthService.mockIsAvailable = true;
        await mockHealthService.initialize();
        mockHealthService.mockDataSources = List.generate(
          4,
          (i) => DataSource(
            id: 'com.example.source$i',
            name: 'Source $i',
          ),
        );

        // Act
        final result = await diagnosticService.runDiagnostics();

        // Assert
        // Multiple data sources is info level, should still be healthy
        expect(result.overallStatus, SystemHealthStatus.healthy);
      });
    });

    group('DiagnosticIssue factory methods', () {
      test('permissionsDenied creates correct issue', () {
        // Act
        final issue = DiagnosticIssue.permissionsDenied();

        // Assert
        expect(issue.severity, IssueSeverity.critical);
        expect(issue.category, IssueCategory.permissions);
        expect(issue.action, IssueAction.grantPermissions);
        expect(issue.suggestedFix, isNotNull);
      });

      test('healthConnectNotInstalled creates correct issue', () {
        // Act
        final issue = DiagnosticIssue.healthConnectNotInstalled();

        // Assert
        expect(issue.severity, IssueSeverity.critical);
        expect(issue.category, IssueCategory.platform);
        expect(issue.action, IssueAction.installHealthConnect);
      });

      test('batteryOptimization creates correct issue', () {
        // Act
        final issue = DiagnosticIssue.batteryOptimization();

        // Assert
        expect(issue.severity, IssueSeverity.warning);
        expect(issue.category, IssueCategory.system);
        expect(issue.action, IssueAction.openBatterySettings);
      });

      test('noDataSources creates correct issue', () {
        // Act
        final issue = DiagnosticIssue.noDataSources();

        // Assert
        expect(issue.severity, IssueSeverity.warning);
        expect(issue.category, IssueCategory.dataSources);
        expect(issue.action, isNull);
      });

      test('multipleDataSources creates correct issue with count', () {
        // Act
        final issue = DiagnosticIssue.multipleDataSources(5);

        // Assert
        expect(issue.severity, IssueSeverity.info);
        expect(issue.category, IssueCategory.dataSources);
        expect(issue.action, IssueAction.selectPrimarySource);
        expect(issue.description, contains('5 apps'));
      });
    });

    group('SystemHealthStatus extension', () {
      test('emoji returns correct values', () {
        expect(SystemHealthStatus.healthy.emoji, '✅');
        expect(SystemHealthStatus.warning.emoji, '⚠️');
        expect(SystemHealthStatus.error.emoji, '❌');
        expect(SystemHealthStatus.unknown.emoji, '❓');
      });

      test('label returns correct values', () {
        expect(SystemHealthStatus.healthy.label, 'Healthy');
        expect(SystemHealthStatus.warning.label, 'Needs Attention');
        expect(SystemHealthStatus.error.label, 'Critical Issue');
        expect(SystemHealthStatus.unknown.label, 'Unknown');
      });
    });

    group('IssueSeverity extension', () {
      test('emoji returns correct values', () {
        expect(IssueSeverity.info.emoji, 'ℹ️');
        expect(IssueSeverity.warning.emoji, '⚠️');
        expect(IssueSeverity.error.emoji, '❌');
        expect(IssueSeverity.critical.emoji, '🚨');
      });
    });
  });
}
