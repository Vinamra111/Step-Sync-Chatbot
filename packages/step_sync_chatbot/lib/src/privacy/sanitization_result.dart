import 'package:freezed_annotation/freezed_annotation.dart';

part 'sanitization_result.freezed.dart';
part 'sanitization_result.g.dart';

/// Result of PHI/PII sanitization operation.
@freezed
class SanitizationResult with _$SanitizationResult {
  const factory SanitizationResult({
    /// Original text before sanitization.
    required String originalText,

    /// Sanitized text safe for sending to LLM.
    required String sanitizedText,

    /// List of detected entities.
    @Default([]) List<DetectedEntity> detectedEntities,

    /// Whether the text is safe to send to LLM.
    ///
    /// Even after sanitization, some texts with critical PII
    /// should not be sent (defense in depth).
    required bool isSafe,
  }) = _SanitizationResult;

  factory SanitizationResult.fromJson(Map<String, dynamic> json) =>
      _$SanitizationResultFromJson(json);
}

/// A detected PHI/PII entity in text.
@freezed
class DetectedEntity with _$DetectedEntity {
  const factory DetectedEntity({
    /// Type of entity detected.
    required EntityType type,

    /// Original value found in text.
    required String originalValue,

    /// Sanitized replacement value.
    required String sanitizedValue,

    /// Start index in original text.
    required int startIndex,

    /// End index in original text.
    required int endIndex,
  }) = _DetectedEntity;

  factory DetectedEntity.fromJson(Map<String, dynamic> json) =>
      _$DetectedEntityFromJson(json);
}

/// Types of PHI/PII entities that can be detected.
enum EntityType {
  /// Numeric values (step counts, ages, etc.)
  number,

  /// Dates (absolute or relative)
  date,

  /// Fitness app names (Google Fit, Fitbit, etc.)
  appName,

  /// Device names (iPhone 15, Galaxy S24, etc.)
  deviceName,

  /// Person names
  name,

  /// Email addresses
  email,

  /// Phone numbers
  phoneNumber,

  /// Locations (addresses, GPS coordinates)
  location,

  /// Other sensitive data
  other,
}

extension EntityTypeExtension on EntityType {
  /// User-friendly label for the entity type.
  String get label {
    switch (this) {
      case EntityType.number:
        return 'Number';
      case EntityType.date:
        return 'Date';
      case EntityType.appName:
        return 'App Name';
      case EntityType.deviceName:
        return 'Device Name';
      case EntityType.name:
        return 'Name';
      case EntityType.email:
        return 'Email';
      case EntityType.phoneNumber:
        return 'Phone Number';
      case EntityType.location:
        return 'Location';
      case EntityType.other:
        return 'Other';
    }
  }

  /// Whether this entity type is considered critical (blocks sending).
  bool get isCritical {
    switch (this) {
      case EntityType.email:
      case EntityType.phoneNumber:
      case EntityType.name:
      case EntityType.location:
        return true;
      default:
        return false;
    }
  }

  /// Emoji icon for the entity type.
  String get emoji {
    switch (this) {
      case EntityType.number:
        return '🔢';
      case EntityType.date:
        return '📅';
      case EntityType.appName:
        return '📱';
      case EntityType.deviceName:
        return '⌚';
      case EntityType.name:
        return '👤';
      case EntityType.email:
        return '📧';
      case EntityType.phoneNumber:
        return '📞';
      case EntityType.location:
        return '📍';
      case EntityType.other:
        return '🔒';
    }
  }
}
