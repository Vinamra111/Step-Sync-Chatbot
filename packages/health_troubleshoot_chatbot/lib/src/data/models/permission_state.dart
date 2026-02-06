import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_state.freezed.dart';
part 'permission_state.g.dart';

/// Represents the current state of health data permissions.
@freezed
class PermissionState with _$PermissionState {
  const factory PermissionState({
    /// Whether step reading permission is granted.
    required bool stepsGranted,

    /// Whether activity reading permission is granted.
    required bool activityGranted,

    /// Overall permission status.
    required PermissionStatus status,

    /// When permissions were last checked.
    DateTime? lastCheckedAt,

    /// Error message if permission check failed.
    String? errorMessage,
  }) = _PermissionState;

  factory PermissionState.fromJson(Map<String, dynamic> json) =>
      _$PermissionStateFromJson(json);

  /// Creates initial unknown state.
  factory PermissionState.unknown() {
    return const PermissionState(
      stepsGranted: false,
      activityGranted: false,
      status: PermissionStatus.unknown,
    );
  }

  /// Creates granted state.
  factory PermissionState.granted() {
    return PermissionState(
      stepsGranted: true,
      activityGranted: true,
      status: PermissionStatus.granted,
      lastCheckedAt: DateTime.now(),
    );
  }

  /// Creates denied state.
  factory PermissionState.denied() {
    return PermissionState(
      stepsGranted: false,
      activityGranted: false,
      status: PermissionStatus.denied,
      lastCheckedAt: DateTime.now(),
    );
  }
}

/// Overall permission status.
enum PermissionStatus {
  /// Permissions have not been checked yet.
  unknown,

  /// All required permissions are granted.
  granted,

  /// Some or all permissions are denied.
  denied,

  /// Currently requesting permissions from user.
  requesting,

  /// Permission check or request failed.
  error,
}
