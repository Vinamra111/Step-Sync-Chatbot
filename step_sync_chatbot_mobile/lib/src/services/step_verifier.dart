/// Step Verification Service
///
/// Reads and verifies step count data from Health Connect.
/// Provides step count verification, source identification,
/// and discrepancy detection.

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../diagnostics/diagnostic_channels.dart';

/// Status of step verification request
enum StepVerificationStatus {
  /// Successfully read step data
  success,

  /// Health Connect unavailable
  unavailable,

  /// Permission denied by user
  permissionDenied,

  /// Error occurred during read
  error,

  /// Unknown status
  unknown,
}

/// Result of step verification
class StepVerificationResult {
  /// Status of the verification
  final StepVerificationStatus status;

  /// Total step count for today
  final int? totalSteps;

  /// Map of app package names to their step contributions
  /// Example: {"com.google.android.apps.fitness": 5234}
  final Map<String, int>? sources;

  /// Number of individual step records found
  final int? recordCount;

  /// ISO8601 timestamp of when data was last synced
  final String? lastSync;

  /// Error message if status is error
  final String? error;

  const StepVerificationResult({
    required this.status,
    this.totalSteps,
    this.sources,
    this.recordCount,
    this.lastSync,
    this.error,
  });

  /// Parse result from platform channel response
  factory StepVerificationResult.fromMap(Map<dynamic, dynamic> map) {
    final statusStr = map['status'] as String;
    final status = _parseStatus(statusStr);

    return StepVerificationResult(
      status: status,
      totalSteps: map['totalSteps'] as int?,
      sources: (map['sources'] as Map<dynamic, dynamic>?)
          ?.map((k, v) => MapEntry(k.toString(), v as int)),
      recordCount: map['recordCount'] as int?,
      lastSync: map['lastSync'] as String?,
      error: map['error'] as String?,
    );
  }

  /// Parse status string to enum
  static StepVerificationStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return StepVerificationStatus.success;
      case 'unavailable':
        return StepVerificationStatus.unavailable;
      case 'permission_denied':
        return StepVerificationStatus.permissionDenied;
      case 'error':
        return StepVerificationStatus.error;
      default:
        return StepVerificationStatus.unknown;
    }
  }
}

/// Service for verifying step count data
class StepVerifier {
  static final _log = Logger();

  /// Read step count from Health Connect
  ///
  /// Returns [StepVerificationResult] with step count and data sources.
  /// Requires Health Connect to be available and READ_STEPS permission.
  static Future<StepVerificationResult> readSteps() async {
    try {
      _log.d('Reading steps from Health Connect...');

      final result = await DiagnosticChannels.steps.invokeMethod('readSteps');

      if (result == null) {
        _log.w('Step read returned null');
        return const StepVerificationResult(
          status: StepVerificationStatus.error,
          error: 'No data returned from Health Connect',
        );
      }

      final verification = StepVerificationResult.fromMap(result as Map<dynamic, dynamic>);
      _log.i('Steps read: ${verification.totalSteps}, sources: ${verification.sources?.keys}');

      return verification;
    } on PlatformException catch (e) {
      _log.e('PlatformException reading steps: ${e.code} - ${e.message}');
      return StepVerificationResult(
        status: StepVerificationStatus.error,
        error: 'Platform error: ${e.message}',
      );
    } catch (e, stackTrace) {
      _log.e('Error reading steps: $e\n$stackTrace');
      return StepVerificationResult(
        status: StepVerificationStatus.error,
        error: 'Unexpected error: $e',
      );
    }
  }

  /// Request permission to read steps from Health Connect
  ///
  /// Opens Health Connect permission dialog.
  /// Returns true if permission was granted.
  static Future<bool> requestPermission() async {
    try {
      _log.d('Requesting steps permission...');
      final result = await DiagnosticChannels.steps.invokeMethod('requestStepsPermission');
      final granted = result as bool? ?? false;
      _log.i('Steps permission ${granted ? "granted" : "denied"}');
      return granted;
    } on PlatformException catch (e) {
      _log.e('PlatformException requesting permission: ${e.code} - ${e.message}');
      return false;
    } catch (e, stackTrace) {
      _log.e('Error requesting permission: $e\n$stackTrace');
      return false;
    }
  }
}
