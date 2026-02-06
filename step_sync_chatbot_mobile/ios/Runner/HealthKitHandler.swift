import Foundation
import HealthKit
import Flutter

/// Handler for HealthKit operations
/// Manages HealthKit availability checking and authorization requests
class HealthKitHandler: NSObject {
    private let healthStore = HKHealthStore()

    /// Check if HealthKit is available on this device
    ///
    /// Returns dictionary with:
    /// - "available": Bool - true if HealthKit is supported
    /// - "status": String - Authorization status ("AUTHORIZED", "DENIED", "NOT_DETERMINED", "UNKNOWN")
    /// - "error": String? - Error message if something went wrong
    ///
    /// Note: HealthKit is not available on iPad (most models) and iPod touch
    func checkHealthKitAvailability(result: @escaping FlutterResult) {
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            result([
                "available": false,
                "status": "NOT_AVAILABLE",
                "error": "HealthKit is not available on this device (iPad/iPod touch)"
            ])
            return
        }

        // Get step count type
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            result([
                "available": false,
                "status": "UNKNOWN",
                "error": "Step count type not found"
            ])
            return
        }

        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: stepType)
        let statusString = authStatusToString(authStatus)

        NSLog("HealthKit availability check: available=true, status=\(statusString)")

        result([
            "available": true,
            "status": statusString,
            "error": nil
        ])
    }

    /// Request HealthKit authorization for step count
    ///
    /// Shows the HealthKit permission sheet
    /// Returns true if authorization request completed (regardless of user choice)
    func requestHealthKitAuthorization(result: @escaping FlutterResult) {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            NSLog("HealthKit not available on this device")
            result(false)
            return
        }

        // Get step count type
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            NSLog("Step count type not found")
            result(false)
            return
        }

        // Define the types to read
        let typesToRead: Set<HKObjectType> = [stepType]

        // Request authorization
        NSLog("Requesting HealthKit authorization for step count...")
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            DispatchQueue.main.async {
                if let error = error {
                    NSLog("HealthKit authorization error: \(error.localizedDescription)")
                    result(false)
                    return
                }

                NSLog("HealthKit authorization request completed: \(success)")

                // Check the actual authorization status after request
                let authStatus = self.healthStore.authorizationStatus(for: stepType)
                NSLog("HealthKit authorization status: \(self.authStatusToString(authStatus))")

                // Return true if the request completed, regardless of user choice
                // The actual status can be checked by calling checkHealthKitAvailability again
                result(true)
            }
        }
    }

    /// Convert HKAuthorizationStatus to string
    private func authStatusToString(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .sharingAuthorized:
            return "AUTHORIZED"
        case .sharingDenied:
            return "DENIED"
        case .notDetermined:
            return "NOT_DETERMINED"
        @unknown default:
            return "UNKNOWN"
        }
    }

    /// Open iOS Settings app
    ///
    /// Opens the Settings app to the main screen
    /// User can navigate to Privacy & Security → Health to modify permissions
    func openIOSSettings(result: @escaping FlutterResult) {
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
}
