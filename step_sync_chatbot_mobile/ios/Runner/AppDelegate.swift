import UIKit
import Flutter
import CoreMotion
import CoreTelephony
import Network

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let healthKitHandler = HealthKitHandler()
    private let pedometer = CMPedometer()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Get the Flutter view controller
        guard let controller = window?.rootViewController as? FlutterViewController else {
            NSLog("Could not get Flutter view controller")
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        setupMethodChannels(controller: controller)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// Setup all method channels for native communication
    private func setupMethodChannels(controller: FlutterViewController) {
        // HealthKit channel
        let healthKitChannel = FlutterMethodChannel(
            name: "com.stepsync.chatbot/healthkit",
            binaryMessenger: controller.binaryMessenger
        )

        healthKitChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "checkHealthKitAvailability":
                self.healthKitHandler.checkHealthKitAvailability(result: result)

            case "requestHealthKitAuthorization":
                self.healthKitHandler.requestHealthKitAuthorization(result: result)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Permissions channel (for Motion & Fitness)
        let permissionsChannel = FlutterMethodChannel(
            name: "com.stepsync.chatbot/permissions",
            binaryMessenger: controller.binaryMessenger
        )

        permissionsChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "checkMotionFitnessPermission":
                self.checkMotionFitnessPermission(result: result)

            case "requestMotionFitnessPermission":
                self.requestMotionFitnessPermission(result: result)

            case "openIOSSettings":
                self.healthKitHandler.openIOSSettings(result: result)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Power channel (for Low Power Mode and Background App Refresh)
        let powerChannel = FlutterMethodChannel(
            name: "com.stepsync.chatbot/power",
            binaryMessenger: controller.binaryMessenger
        )

        powerChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "checkLowPowerMode":
                self.checkLowPowerMode(result: result)

            case "checkBackgroundAppRefresh":
                self.checkBackgroundAppRefresh(result: result)

            case "openBackgroundAppRefreshSettings":
                self.openIOSSettings(result: result)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // iOS Settings channel (Week 6 - Cellular Data, etc.)
        let iosSettingsChannel = FlutterMethodChannel(
            name: "com.stepsync.chatbot/ios_settings",
            binaryMessenger: controller.binaryMessenger
        )

        iosSettingsChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "checkCellularDataStatus":
                self.checkCellularDataStatus(result: result)

            case "openCellularDataSettings":
                self.openIOSSettings(result: result)

            case "checkBackgroundAppRefresh":
                self.checkBackgroundAppRefresh(result: result)

            case "openBackgroundAppRefreshSettings":
                self.openIOSSettings(result: result)

            case "checkLowPowerMode":
                self.checkLowPowerMode(result: result)

            case "openLowPowerModeSettings":
                self.openIOSSettings(result: result)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        NSLog("iOS method channels registered successfully")
    }

    // ========================================================================
    // POWER MANAGEMENT (iOS)
    // ========================================================================

    /// Check if Low Power Mode is enabled
    ///
    /// Returns true if Low Power Mode is on, false if off
    private func checkLowPowerMode(result: @escaping FlutterResult) {
        let isEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        NSLog("Low Power Mode: \(isEnabled ? "enabled" : "disabled")")
        result(isEnabled)
    }

    /// Check Background App Refresh status
    ///
    /// Returns: "AVAILABLE", "DENIED", "RESTRICTED", or "UNKNOWN"
    private func checkBackgroundAppRefresh(result: @escaping FlutterResult) {
        let status = UIApplication.shared.backgroundRefreshStatus

        let statusString: String
        switch status {
        case .available:
            statusString = "AVAILABLE"
        case .denied:
            statusString = "DENIED"
        case .restricted:
            statusString = "RESTRICTED"
        @unknown default:
            statusString = "UNKNOWN"
        }

        NSLog("Background App Refresh: \(statusString)")
        result(statusString)
    }

    /// Open iOS Settings app
    ///
    /// Opens Settings where user can enable Background App Refresh
    private func openIOSSettings(result: @escaping FlutterResult) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            NSLog("Failed to create settings URL")
            result(false)
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            NSLog("Opening iOS Settings...")
            UIApplication.shared.open(settingsUrl, options: [:]) { success in
                NSLog("Settings opened: \(success)")
                result(success)
            }
        } else {
            NSLog("Cannot open iOS Settings")
            result(false)
        }
    }

    // ========================================================================
    // MOTION & FITNESS PERMISSION (CoreMotion)
    // ========================================================================

    /// Check Motion & Fitness permission status
    ///
    /// Returns: "GRANTED", "DENIED", "NOT_DETERMINED", "RESTRICTED", or "UNKNOWN"
    private func checkMotionFitnessPermission(result: @escaping FlutterResult) {
        let status = CMPedometer.authorizationStatus()

        let statusString: String
        switch status {
        case .authorized:
            statusString = "GRANTED"
        case .denied:
            statusString = "DENIED"
        case .notDetermined:
            statusString = "NOT_DETERMINED"
        case .restricted:
            statusString = "RESTRICTED"
        @unknown default:
            statusString = "UNKNOWN"
        }

        NSLog("Motion & Fitness permission status: \(statusString)")
        result(statusString)
    }

    /// Request Motion & Fitness permission
    ///
    /// Triggers permission dialog by querying pedometer data
    /// Returns true if permission was granted, false otherwise
    private func requestMotionFitnessPermission(result: @escaping FlutterResult) {
        // CoreMotion doesn't have a direct permission request API
        // We need to trigger the permission dialog by querying data
        let now = Date()

        NSLog("Requesting Motion & Fitness permission by querying pedometer data...")

        pedometer.queryPedometerData(from: now, to: now) { (data, error) in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError

                    // Check error code to determine status
                    if nsError.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                        NSLog("Motion & Fitness permission denied")
                        result(false)
                    } else {
                        NSLog("Motion & Fitness permission error: \(error.localizedDescription)")
                        result(false)
                    }
                } else {
                    NSLog("Motion & Fitness permission granted")
                    result(true)
                }
            }
        }
    }

    // ========================================================================
    // CELLULAR DATA (iOS) - Week 6
    // ========================================================================

    /// Check if cellular data is enabled for this app
    ///
    /// Note: iOS does not provide a direct API to check per-app cellular data status.
    /// This method uses indirect detection via network connectivity and cellular status.
    ///
    /// Returns: "ENABLED", "DISABLED", or "UNKNOWN"
    private func checkCellularDataStatus(result: @escaping FlutterResult) {
        // iOS limitation: No official API to check per-app cellular data status
        // We can only detect:
        // 1. If device has cellular capability
        // 2. Current network connectivity type
        // 3. System-wide cellular data settings (limited)

        NSLog("Checking cellular data status...")

        // Check if device has cellular capability
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider

        if carrier == nil {
            // No cellular carrier (e.g., iPad WiFi-only, iPod Touch)
            NSLog("Cellular data: No cellular carrier detected (WiFi-only device)")
            result("UNKNOWN")
            return
        }

        // Check current network connectivity
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)

        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    // Network is available
                    if path.usesInterfaceType(.cellular) {
                        // Currently using cellular data
                        NSLog("Cellular data: ENABLED (currently using cellular)")
                        result("ENABLED")
                    } else if path.usesInterfaceType(.wifi) {
                        // Currently using WiFi, can't determine cellular data status
                        NSLog("Cellular data: UNKNOWN (currently on WiFi)")
                        result("UNKNOWN")
                    } else {
                        NSLog("Cellular data: UNKNOWN (unknown network type)")
                        result("UNKNOWN")
                    }
                } else {
                    // No network connectivity
                    NSLog("Cellular data: UNKNOWN (no network connection)")
                    result("UNKNOWN")
                }

                monitor.cancel()
            }
        }

        monitor.start(queue: queue)

        // Set a timeout in case monitor doesn't respond quickly
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            monitor.cancel()
            NSLog("Cellular data check timed out, returning UNKNOWN")
            result("UNKNOWN")
        }
    }
}
