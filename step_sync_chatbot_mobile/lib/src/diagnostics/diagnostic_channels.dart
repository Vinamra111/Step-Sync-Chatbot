/// Centralized Method Channel Definitions for Native Diagnostics
///
/// This file defines all method channels used for communication between
/// Flutter and native platforms (Android/iOS). Each channel handles a
/// specific category of diagnostics.
///
/// Architecture: Flutter (Dart) ↔ Method Channels ↔ Native (Kotlin/Swift)

import 'package:flutter/services.dart';

/// Central registry of all diagnostic method channels
class DiagnosticChannels {
  // ========================================================================
  // CROSS-PLATFORM CHANNELS (Android + iOS)
  // ========================================================================

  /// Permissions channel - handles all permission checks and requests
  ///
  /// Methods:
  /// - Android: checkPhysicalActivityPermission, requestPhysicalActivityPermission
  /// - iOS: checkMotionFitnessPermission, requestMotionFitnessPermission
  /// - Both: checkLocationPermission, checkNotificationPermission
  static const permissions = MethodChannel('com.stepsync.chatbot/permissions');

  /// Power management channel - battery modes, power states
  ///
  /// Methods:
  /// - Android: checkPowerSavingMode, checkDozeMode
  /// - iOS: checkLowPowerMode (with event channel for real-time updates)
  static const power = MethodChannel('com.stepsync.chatbot/power');

  /// Network channel - connectivity, data saver, background data
  ///
  /// Methods:
  /// - checkDataSaverMode, checkBackgroundDataRestriction, checkConnectivityStatus
  static const network = MethodChannel('com.stepsync.chatbot/network');

  // ========================================================================
  // ANDROID-SPECIFIC CHANNELS
  // ========================================================================

  /// Battery optimization channel (EXISTING - DO NOT MODIFY)
  ///
  /// Already working in v6. Handles:
  /// - isBatteryOptimizationEnabled
  /// - requestBatteryOptimizationExemption
  /// - getDeviceInfo
  static const battery = MethodChannel('com.stepsync.chatbot/battery');

  /// Health Connect channel - Android's health data platform
  ///
  /// Methods:
  /// - checkHealthConnectAvailability
  /// - checkHealthConnectPermissions
  /// - openHealthConnectPlayStore
  static const healthConnect = MethodChannel('com.stepsync.chatbot/healthconnect');

  /// Step Verification channel - Read and verify step count data
  ///
  /// Methods:
  /// - readSteps: Read today's step count from Health Connect
  /// - requestStepsPermission: Request READ_STEPS permission
  /// Returns: {status, totalSteps, sources, recordCount, lastSync, error}
  static const steps = MethodChannel('com.stepsync.chatbot/steps');

  /// Sensors channel - hardware sensor availability
  ///
  /// Methods:
  /// - checkStepCounterSensor
  /// - checkGooglePlayServices
  static const sensors = MethodChannel('com.stepsync.chatbot/sensors');

  /// Manufacturer-specific channel - OEM customizations
  ///
  /// Methods:
  /// - checkXiaomiAutostart, openXiaomiAutostartSettings
  /// - checkSamsungSleepingApps, openSamsungBatterySettings
  /// - checkOppoAutostart, openOppoAutostartSettings
  static const manufacturer = MethodChannel('com.stepsync.chatbot/manufacturer');

  // ========================================================================
  // iOS-SPECIFIC CHANNELS
  // ========================================================================

  /// HealthKit channel - iOS health data platform
  ///
  /// Methods:
  /// - checkHealthKitAvailability
  /// - requestHealthKitAuthorization
  static const healthKit = MethodChannel('com.stepsync.chatbot/healthkit');

  /// iOS Settings channel - system settings status
  ///
  /// Methods:
  /// - checkBackgroundAppRefresh
  /// - checkLowPowerMode
  /// - checkCellularDataStatus
  static const iosSettings = MethodChannel('com.stepsync.chatbot/ios_settings');

  // ========================================================================
  // EVENT CHANNELS (Real-time Updates)
  // ========================================================================

  /// Low Power Mode events - iOS real-time notifications
  ///
  /// Streams boolean values when Low Power Mode is toggled on/off
  static const lowPowerModeEvents = EventChannel('com.stepsync.chatbot/low_power_mode_events');

  /// Power Save Mode events - Android real-time notifications
  ///
  /// Streams boolean values when Power Saving Mode is toggled on/off
  static const powerSaveModeEvents = EventChannel('com.stepsync.chatbot/power_save_mode_events');
}
