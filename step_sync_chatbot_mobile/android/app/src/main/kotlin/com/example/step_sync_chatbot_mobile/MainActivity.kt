package com.example.step_sync_chatbot_mobile

import android.Manifest
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val BATTERY_CHANNEL = "com.stepsync.chatbot/battery"
    private val PERMISSIONS_CHANNEL = "com.stepsync.chatbot/permissions"
    private val HEALTH_CONNECT_CHANNEL = "com.stepsync.chatbot/healthconnect"
    private val STEPS_CHANNEL = "com.stepsync.chatbot/steps"
    private val POWER_CHANNEL = "com.stepsync.chatbot/power"
    private val NETWORK_CHANNEL = "com.stepsync.chatbot/network"
    private val MANUFACTURER_CHANNEL = "com.stepsync.chatbot/manufacturer"
    private val SENSORS_CHANNEL = "com.stepsync.chatbot/sensors"

    // Permission request codes
    private val REQUEST_CODE_ACTIVITY_RECOGNITION = 1001
    private val REQUEST_CODE_NOTIFICATIONS = 1002
    private val REQUEST_CODE_HEALTH_CONNECT_STEPS = 1003

    // Pending results for permission requests
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Battery channel (existing - DO NOT MODIFY)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBatteryOptimizationEnabled" -> {
                    try {
                        val isOptimized = checkBatteryOptimization()
                        result.success(isOptimized)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check battery optimization: ${e.message}", null)
                    }
                }
                "requestBatteryOptimizationExemption" -> {
                    try {
                        val success = requestBatteryExemption()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to request exemption: ${e.message}", null)
                    }
                }
                "isBatteryOptimizationSupported" -> {
                    val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                    result.success(supported)
                }
                "getDeviceInfo" -> {
                    val deviceInfo = mapOf(
                        "manufacturer" to Build.MANUFACTURER,
                        "brand" to Build.BRAND,
                        "model" to Build.MODEL,
                        "device" to Build.DEVICE,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "displayName" to "${Build.MANUFACTURER} ${Build.MODEL}"
                    )
                    result.success(deviceInfo)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Permissions channel (NEW)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPhysicalActivityPermission" -> {
                    try {
                        val status = checkPhysicalActivityPermission()
                        result.success(status)
                    } catch (e: Exception) {
                        if (e.message == "NOT_AVAILABLE") {
                            result.success("NOT_APPLICABLE")
                        } else {
                            result.error("ERROR", "Failed to check physical activity permission: ${e.message}", null)
                        }
                    }
                }
                "requestPhysicalActivityPermission" -> {
                    pendingPermissionResult = result
                    requestPhysicalActivityPermission()
                }
                "checkNotificationPermission" -> {
                    try {
                        val status = checkNotificationPermission()
                        result.success(status)
                    } catch (e: Exception) {
                        if (e.message == "NOT_AVAILABLE") {
                            result.success("NOT_APPLICABLE")
                        } else {
                            result.error("ERROR", "Failed to check notification permission: ${e.message}", null)
                        }
                    }
                }
                "requestNotificationPermission" -> {
                    pendingPermissionResult = result
                    requestNotificationPermission()
                }
                "checkLocationPermission" -> {
                    try {
                        val status = checkLocationPermission()
                        result.success(status)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check location permission: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Health Connect channel (NEW - Week 2)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HEALTH_CONNECT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkHealthConnectAvailability" -> {
                    try {
                        val availability = checkHealthConnectAvailability()
                        result.success(availability)
                    } catch (e: Exception) {
                        if (e.message == "NOT_SUPPORTED") {
                            result.error("NOT_SUPPORTED", "Health Connect not supported on this Android version", null)
                        } else {
                            result.error("ERROR", "Failed to check Health Connect: ${e.message}", null)
                        }
                    }
                }
                "openHealthConnectPlayStore" -> {
                    try {
                        val success = openHealthConnectPlayStore()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open Play Store: ${e.message}", null)
                    }
                }
                "requestHealthConnectPermissions" -> {
                    try {
                        val success = requestHealthConnectPermissions()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to request permissions: ${e.message}", null)
                    }
                }
                "checkHealthConnectPermissions" -> {
                    lifecycleScope.launch {
                        try {
                            val hasPermissions = checkHealthConnectPermissions()
                            result.success(hasPermissions)
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", "Exception in checkHealthConnectPermissions: ${e.message}", e)
                            result.error("ERROR", "Failed to check permissions: ${e.message}", null)
                        }
                    }
                }
                "debugHealthConnect" -> {
                    lifecycleScope.launch {
                        try {
                            val debug = debugHealthConnect()
                            result.success(debug)
                        } catch (e: Exception) {
                            result.error("ERROR", "Debug failed: ${e.message}", null)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Power channel (NEW - Week 3)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, POWER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPowerSavingMode" -> {
                    try {
                        val isEnabled = checkPowerSavingMode()
                        result.success(isEnabled)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check Power Saving Mode: ${e.message}", null)
                    }
                }
                "checkDozeModeStatus" -> {
                    try {
                        val status = checkDozeModeStatus()
                        result.success(status)
                    } catch (e: Exception) {
                        if (e.message == "NOT_AVAILABLE") {
                            result.error("NOT_AVAILABLE", "Doze Mode not available on this Android version", null)
                        } else {
                            result.error("ERROR", "Failed to check Doze Mode: ${e.message}", null)
                        }
                    }
                }
                "requestDozeModeWhitelist" -> {
                    try {
                        val success = requestDozeModeWhitelist()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to request Doze whitelist: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Network channel (NEW - Week 4)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkDataSaverMode" -> {
                    try {
                        val status = checkDataSaverMode()
                        result.success(status)
                    } catch (e: Exception) {
                        if (e.message == "NOT_AVAILABLE") {
                            result.success("NOT_APPLICABLE")
                        } else {
                            result.error("ERROR", "Failed to check Data Saver Mode: ${e.message}", null)
                        }
                    }
                }
                "requestDataSaverWhitelist" -> {
                    try {
                        val success = requestDataSaverWhitelist()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to request Data Saver whitelist: ${e.message}", null)
                    }
                }
                "checkBackgroundDataRestriction" -> {
                    try {
                        val status = checkBackgroundDataRestriction()
                        result.success(status)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check background data restriction: ${e.message}", null)
                    }
                }
                "openAppDataSettings" -> {
                    try {
                        val success = openAppDataSettings()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open app data settings: ${e.message}", null)
                    }
                }
                "checkConnectivity" -> {
                    try {
                        val info = checkConnectivity()
                        result.success(info)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check connectivity: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Manufacturer channel (NEW - Week 5)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MANUFACTURER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    val deviceInfo = mapOf(
                        "manufacturer" to Build.MANUFACTURER,
                        "brand" to Build.BRAND,
                        "model" to Build.MODEL,
                        "device" to Build.DEVICE,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "displayName" to "${Build.MANUFACTURER} ${Build.MODEL}"
                    )
                    result.success(deviceInfo)
                }
                "openXiaomiAutostartSettings" -> {
                    try {
                        val success = openXiaomiAutostartSettings()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open Xiaomi settings: ${e.message}", null)
                    }
                }
                "openSamsungBatterySettings" -> {
                    try {
                        val success = openSamsungBatterySettings()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open Samsung settings: ${e.message}", null)
                    }
                }
                "openOppoAutostartSettings" -> {
                    try {
                        val success = openOppoAutostartSettings()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open Oppo settings: ${e.message}", null)
                    }
                }
                "openVivoAutostartSettings" -> {
                    try {
                        val success = openVivoAutostartSettings()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open Vivo settings: ${e.message}", null)
                    }
                }
                "openHuaweiAutostartSettings" -> {
                    try {
                        val success = openHuaweiAutostartSettings()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open Huawei settings: ${e.message}", null)
                    }
                }
                "openAppSettings" -> {
                    try {
                        val success = openAppSettings()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open app settings: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Sensors channel (NEW - Week 6)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SENSORS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkStepCounterSensor" -> {
                    try {
                        val isAvailable = checkStepCounterSensor()
                        result.success(isAvailable)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check step counter sensor: ${e.message}", null)
                    }
                }
                "getSensorInfo" -> {
                    try {
                        val sensorInfo = getSensorInfo()
                        result.success(sensorInfo)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get sensor info: ${e.message}", null)
                    }
                }
                "checkPlayServices" -> {
                    try {
                        val status = checkPlayServices()
                        result.success(status)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to check Play Services: ${e.message}", null)
                    }
                }
                "openPlayServicesInStore" -> {
                    try {
                        val success = openPlayServicesInStore()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open Play Services in store: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Step Verification channel (NEW - Step Count Verification)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STEPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "readSteps" -> {
                    lifecycleScope.launch {
                        try {
                            val steps = readHealthConnectSteps()
                            result.success(steps)
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", "Error in readSteps handler: ${e.message}", e)
                            result.error("ERROR", "Failed to read steps: ${e.message}", null)
                        }
                    }
                }
                "requestStepsPermission" -> {
                    requestHealthConnectStepsPermission(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Check if battery optimization is enabled for this app
     *
     * Returns true if optimization is enabled (bad for background work)
     * Returns false if app is whitelisted (good for background work)
     */
    private fun checkBatteryOptimization(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            // Battery optimization not available before Android 6.0
            throw Exception("NOT_AVAILABLE")
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val packageName = applicationContext.packageName

        // Returns true if the app is ignoring battery optimizations (good)
        // We invert it to return true if optimization IS enabled (bad)
        return !powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    /**
     * Open the system settings screen to disable battery optimization
     *
     * Returns true if the intent was successfully launched
     */
    private fun requestBatteryExemption(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }

        return try {
            // Try app-specific intent first
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${applicationContext.packageName}")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.i("MainActivity", "Opened battery settings successfully")
            true
        } catch (e: Exception) {
            // Fallback to general battery optimization settings if app-specific fails
            android.util.Log.w("MainActivity", "App-specific settings failed, trying general settings: ${e.message}")
            try {
                val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
                android.util.Log.i("MainActivity", "Opened general battery settings")
                true
            } catch (e2: Exception) {
                // Last resort: open app settings page
                android.util.Log.e("MainActivity", "All battery settings failed, trying app info: ${e2.message}")
                try {
                    val appSettingsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:${applicationContext.packageName}")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(appSettingsIntent)
                    true
                } catch (e3: Exception) {
                    android.util.Log.e("MainActivity", "All settings intents failed: ${e3.message}")
                    false
                }
            }
        }
    }

    // ========================================================================
    // PERMISSIONS CHECKING AND REQUESTING
    // ========================================================================

    /**
     * Check if Physical Activity Recognition permission is granted (Android 10+)
     *
     * Returns:
     * - "GRANTED" if permission is granted
     * - "DENIED" if permission is denied but can be requested
     * - "PERMANENTLY_DENIED" if user selected "Don't ask again"
     *
     * Throws exception with message "NOT_AVAILABLE" if Android < 10
     */
    private fun checkPhysicalActivityPermission(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw Exception("NOT_AVAILABLE")
        }

        val permission = Manifest.permission.ACTIVITY_RECOGNITION
        val status = ContextCompat.checkSelfPermission(this, permission)

        return if (status == PackageManager.PERMISSION_GRANTED) {
            "GRANTED"
        } else {
            // Check if we should show rationale (means user denied but can ask again)
            if (ActivityCompat.shouldShowRequestPermissionRationale(this, permission)) {
                "DENIED"
            } else {
                // User denied and selected "Don't ask again", or never asked
                // We can't distinguish between these two states reliably
                "DENIED"
            }
        }
    }

    /**
     * Request Physical Activity Recognition permission
     *
     * Result will be delivered to onRequestPermissionsResult
     */
    private fun requestPhysicalActivityPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            pendingPermissionResult?.success(false)
            pendingPermissionResult = null
            return
        }

        val permission = Manifest.permission.ACTIVITY_RECOGNITION
        ActivityCompat.requestPermissions(
            this,
            arrayOf(permission),
            REQUEST_CODE_ACTIVITY_RECOGNITION
        )
    }

    /**
     * Check if Notification permission is granted (Android 13+)
     *
     * Returns:
     * - "GRANTED" if permission is granted
     * - "DENIED" if permission is denied
     *
     * Throws exception with message "NOT_AVAILABLE" if Android < 13
     */
    private fun checkNotificationPermission(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            throw Exception("NOT_AVAILABLE")
        }

        val permission = Manifest.permission.POST_NOTIFICATIONS
        val status = ContextCompat.checkSelfPermission(this, permission)

        return if (status == PackageManager.PERMISSION_GRANTED) {
            "GRANTED"
        } else {
            "DENIED"
        }
    }

    /**
     * Request Notification permission (Android 13+)
     *
     * Result will be delivered to onRequestPermissionsResult
     */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            pendingPermissionResult?.success(false)
            pendingPermissionResult = null
            return
        }

        val permission = Manifest.permission.POST_NOTIFICATIONS
        ActivityCompat.requestPermissions(
            this,
            arrayOf(permission),
            REQUEST_CODE_NOTIFICATIONS
        )
    }

    /**
     * Check Location permission status
     *
     * Returns map with:
     * - "fine": Boolean - Fine location (GPS) granted
     * - "coarse": Boolean - Coarse location (Network) granted
     * - "background": Boolean - Background location granted (Android 10+)
     */
    private fun checkLocationPermission(): Map<String, Boolean> {
        val fineLocation = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val coarseLocation = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val backgroundLocation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true // Not applicable on Android < 10
        }

        return mapOf(
            "fine" to fineLocation,
            "coarse" to coarseLocation,
            "background" to backgroundLocation
        )
    }

    /**
     * Handle permission request results
     * Implements PluginRegistry.RequestPermissionsResultListener
     */
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        // Call parent implementation first
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        // Handle our custom permission requests
        when (requestCode) {
            REQUEST_CODE_ACTIVITY_RECOGNITION, REQUEST_CODE_NOTIFICATIONS -> {
                val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED

                android.util.Log.i("MainActivity", "Permission result: $granted for request code $requestCode")

                pendingPermissionResult?.success(granted)
                pendingPermissionResult = null
            }
        }
    }

    /**
     * Handle activity results (used for Health Connect permissions)
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            REQUEST_CODE_HEALTH_CONNECT_STEPS -> {
                // Health Connect permission result
                // Note: We can't reliably determine if permission was granted from resultCode
                // The app needs to check permission status after the dialog closes
                android.util.Log.i("MainActivity", "Health Connect permission dialog closed (resultCode=$resultCode)")

                // Return true to indicate dialog was shown (not that permission was granted)
                // The Dart side will need to re-check permission status
                pendingPermissionResult?.success(true)
                pendingPermissionResult = null
            }
        }
    }

    // ========================================================================
    // HEALTH CONNECT (ANDROID 9+ / 14+)
    // ========================================================================

    /**
     * Get the correct Health Connect package name for this device
     *
     * Returns the package name that actually has SDK_AVAILABLE status
     * This handles devices that may have multiple HC packages installed
     */
    private fun getHealthConnectPackageName(): String {
        val apiLevel = Build.VERSION.SDK_INT

        // List of possible package names to check
        val possiblePackages = if (apiLevel >= 34) {
            // Android 14+: Check framework packages first, then fallback to APK
            listOf(
                "com.google.android.healthconnect.controller",
                "com.android.healthconnect.controller",
                "com.google.android.apps.healthdata"  // Some devices may have both
            )
        } else {
            // Android 9-13: APK package only
            listOf("com.google.android.apps.healthdata")
        }

        // Check each package and return the first one that's actually available
        for (packageName in possiblePackages) {
            try {
                val sdkStatus = HealthConnectClient.getSdkStatus(this, packageName)
                android.util.Log.d("MainActivity", "Package $packageName has SDK status: $sdkStatus")

                if (sdkStatus == 1) { // SDK_AVAILABLE
                    android.util.Log.i("MainActivity", "Using Health Connect package: $packageName")
                    return packageName
                }
            } catch (e: Exception) {
                android.util.Log.d("MainActivity", "Package $packageName check failed: ${e.message}")
            }
        }

        // No package returned SDK_AVAILABLE, return default based on API level
        val defaultPackage = if (apiLevel >= 34) {
            "com.google.android.healthconnect.controller"
        } else {
            "com.google.android.apps.healthdata"
        }

        android.util.Log.w("MainActivity", "No available Health Connect package found, using default: $defaultPackage")
        return defaultPackage
    }

    /**
     * Check Health Connect availability using official SDK
     *
     * Returns map with:
     * - "status": String - SDK_AVAILABLE, SDK_UNAVAILABLE, SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED, NOT_SUPPORTED
     * - "apiLevel": Int - Android API level
     * - "packageName": String - Health Connect package name
     * - "version": String? - Installed version (if available)
     * - "sdkStatus": Int - Raw SDK status code
     *
     * Status meanings:
     * - SDK_AVAILABLE (1): Health Connect is fully functional
     * - SDK_UNAVAILABLE (2): Not available on this device/version
     * - SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED (3): Stub exists but needs update/download
     * - NOT_SUPPORTED: Android version too old
     *
     * Android 14+ (API 34+): Health Connect is built into the OS as framework module
     * Android 9-13 (API 28-33): Health Connect is a separate app from Play Store
     * Android 8 and below (API < 28): Not supported
     */
    private fun checkHealthConnectAvailability(): Map<String, Any?> {
        val apiLevel = Build.VERSION.SDK_INT
        val packageName = getHealthConnectPackageName()

        android.util.Log.i("MainActivity", "=== HEALTH CONNECT CHECK START ===")
        android.util.Log.i("MainActivity", "Android API Level: $apiLevel")
        android.util.Log.i("MainActivity", "Package name to check: $packageName")

        return when {
            // Android 9+ - Use SDK status check
            apiLevel >= 28 -> {
                try {
                    // Get official SDK status
                    val sdkStatus = HealthConnectClient.getSdkStatus(this, packageName)
                    android.util.Log.i("MainActivity", "SDK Status returned: $sdkStatus")
                    android.util.Log.i("MainActivity", "Status interpretation: ${when(sdkStatus) {
                        1 -> "SDK_AVAILABLE (fully functional)"
                        2 -> "SDK_UNAVAILABLE (not available)"
                        3 -> "SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED (needs update)"
                        else -> "UNKNOWN ($sdkStatus)"
                    }}")

                    // CRITICAL FIX: Use explicit integer values instead of SDK constants
                    // Testing revealed that status codes are: 1=available, 2=unavailable, 3=needs update
                    when (sdkStatus) {
                        1 -> {  // SDK_AVAILABLE
                            android.util.Log.i("MainActivity", "Health Connect: Fully available and functional")

                            // Check if it's the full version or just the stub (Android 14+)
                            var isStubOnly = false
                            var versionName: String? = null

                            try {
                                val packageInfo = packageManager.getPackageInfo(packageName, 0)
                                versionName = packageInfo.versionName

                                // For Android 14+, check if it's user-installed or just system module
                                if (apiLevel >= 34) {
                                    val appInfo = packageInfo.applicationInfo
                                    // If it's a system app but NOT updated (meaning no user-installed version on top)
                                    // then it's just the stub
                                    val isSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                                    val isUpdatedSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0

                                    // Stub = system app that hasn't been updated/installed from Play Store
                                    isStubOnly = isSystemApp && !isUpdatedSystemApp

                                    android.util.Log.i("MainActivity", "isSystemApp=$isSystemApp, isUpdatedSystemApp=$isUpdatedSystemApp, isStubOnly=$isStubOnly")
                                }
                            } catch (e: Exception) {
                                android.util.Log.w("MainActivity", "Could not check if stub: ${e.message}")
                            }

                            mapOf(
                                "status" to "SDK_AVAILABLE",
                                "apiLevel" to apiLevel,
                                "packageName" to packageName,
                                "version" to versionName,
                                "sdkStatus" to sdkStatus,
                                "isStubOnly" to isStubOnly
                            )
                        }
                        2 -> {  // SDK_UNAVAILABLE
                            android.util.Log.w("MainActivity", "Health Connect: SDK unavailable")
                            mapOf(
                                "status" to "SDK_UNAVAILABLE",
                                "apiLevel" to apiLevel,
                                "packageName" to packageName,
                                "version" to null,
                                "sdkStatus" to sdkStatus
                            )
                        }
                        3 -> {  // SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED - STUB/SHELL EXISTS BUT NEEDS DOWNLOAD
                            android.util.Log.w("MainActivity", "Health Connect: Stub/shell present - needs download from Play Store")
                            mapOf(
                                "status" to "SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED",
                                "apiLevel" to apiLevel,
                                "packageName" to packageName,
                                "version" to null,
                                "sdkStatus" to sdkStatus
                            )
                        }
                        else -> {
                            android.util.Log.w("MainActivity", "Health Connect: Unknown SDK status $sdkStatus")
                            mapOf(
                                "status" to "SDK_UNAVAILABLE",
                                "apiLevel" to apiLevel,
                                "packageName" to packageName,
                                "version" to null,
                                "sdkStatus" to sdkStatus
                            )
                        }
                    }
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "Error checking Health Connect SDK status: ${e.message}")
                    // Fallback to basic package check
                    val isInstalled = try {
                        packageManager.getPackageInfo(packageName, 0)
                        true
                    } catch (ex: PackageManager.NameNotFoundException) {
                        false
                    }

                    mapOf(
                        "status" to if (isInstalled) "SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED" else "SDK_UNAVAILABLE",
                        "apiLevel" to apiLevel,
                        "packageName" to packageName,
                        "version" to null,
                        "sdkStatus" to HealthConnectClient.SDK_UNAVAILABLE
                    )
                }
            }
            // Android 8 and below - Not supported
            else -> {
                android.util.Log.w("MainActivity", "Health Connect: Not supported (Android < 9)")
                throw Exception("NOT_SUPPORTED")
            }
        }
    }

    /**
     * Open Play Store to install Health Connect app (Android 9-13)
     *
     * Returns true if Play Store was opened successfully
     */
    private fun openHealthConnectPlayStore(): Boolean {
        val packageName = "com.google.android.apps.healthdata"

        return try {
            // Try to open Play Store app first
            val marketIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("market://details?id=$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(marketIntent)
            android.util.Log.i("MainActivity", "Opened Play Store app for Health Connect")
            true
        } catch (e: android.content.ActivityNotFoundException) {
            // Fallback to web browser if Play Store app not available
            android.util.Log.w("MainActivity", "Play Store app not found, trying browser: ${e.message}")
            try {
                val webIntent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(webIntent)
                android.util.Log.i("MainActivity", "Opened browser for Health Connect")
                true
            } catch (e2: Exception) {
                android.util.Log.e("MainActivity", "Failed to open Play Store: ${e2.message}")
                false
            }
        }
    }

    /**
     * Request Health Connect permissions
     *
     * Opens Health Connect permission request dialog or settings
     * Returns true if permission request was initiated successfully
     */
    private fun requestHealthConnectPermissions(): Boolean {
        val apiLevel = Build.VERSION.SDK_INT

        return try {
            when {
                // Android 14+ - Try multiple approaches to open permissions
                apiLevel >= 34 -> {
                    // Method 1: Try direct PermissionsActivity
                    try {
                        val intent = Intent().apply {
                            setClassName(
                                "com.google.android.healthconnect.controller",
                                "com.android.healthconnect.controller.permissions.request.PermissionsActivity"
                            )
                            putExtra("android.intent.extra.PACKAGE_NAME", this@MainActivity.packageName)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        android.util.Log.i("MainActivity", "Opened PermissionsActivity directly")
                        return true
                    } catch (e: Exception) {
                        android.util.Log.w("MainActivity", "Direct PermissionsActivity failed: ${e.message}")
                    }

                    // Method 2: Fall back to home settings
                    val intent = Intent("android.health.connect.action.HEALTH_HOME_SETTINGS").apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(intent)
                    android.util.Log.i("MainActivity", "Opened Health Connect home screen")
                    true
                }
                // Android 9-13 - Health Connect app settings
                apiLevel >= 28 -> {
                    // First check if Health Connect is installed
                    try {
                        packageManager.getPackageInfo("com.google.android.apps.healthdata", 0)
                    } catch (e: PackageManager.NameNotFoundException) {
                        android.util.Log.e("MainActivity", "Health Connect not installed, cannot open permissions")
                        return false
                    }

                    // Try to open Health Connect app with permission management
                    val intent = Intent().apply {
                        action = Intent.ACTION_VIEW
                        setPackage("com.google.android.apps.healthdata")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(intent)
                    android.util.Log.i("MainActivity", "Opened Health Connect app")
                    true
                }
                else -> {
                    android.util.Log.w("MainActivity", "Health Connect not supported (Android < 9)")
                    false
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to open Health Connect permissions: ${e.message}")

            // Fallback: Try to open app settings
            try {
                val packageToOpen = if (apiLevel >= 34) {
                    // Android 14+: Open system Health Connect settings
                    "com.android.healthconnect.controller"
                } else {
                    // Android 9-13: Open Health Connect app settings
                    "com.google.android.apps.healthdata"
                }

                val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageToOpen")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
                android.util.Log.i("MainActivity", "Opened app settings as fallback")
                true
            } catch (e2: Exception) {
                android.util.Log.e("MainActivity", "All Health Connect intents failed: ${e2.message}")
                false
            }
        }
    }

    /**
     * DEBUG: Comprehensive Health Connect diagnostics
     */
    private suspend fun debugHealthConnect(): Map<String, Any?> {
        return withContext(Dispatchers.IO) {
            val results = mutableMapOf<String, Any?>()

            try {
                val apiLevel = Build.VERSION.SDK_INT
                results["apiLevel"] = apiLevel

                // Check which packages are installed
                val googlePackage = "com.google.android.healthconnect.controller"
                val aospPackage = "com.android.healthconnect.controller"
                val oldPackage = "com.google.android.apps.healthdata"

                results["googlePackageInstalled"] = try {
                    packageManager.getPackageInfo(googlePackage, 0)
                    true
                } catch (e: Exception) { false }

                results["aospPackageInstalled"] = try {
                    packageManager.getPackageInfo(aospPackage, 0)
                    true
                } catch (e: Exception) { false }

                results["oldPackageInstalled"] = try {
                    packageManager.getPackageInfo(oldPackage, 0)
                    true
                } catch (e: Exception) { false }

                // Get detected package name
                val detectedPackage = getHealthConnectPackageName()
                results["detectedPackageName"] = detectedPackage

                // Check SDK status for each package
                results["googlePackageSdkStatus"] = try {
                    HealthConnectClient.getSdkStatus(this@MainActivity, googlePackage)
                } catch (e: Exception) { "ERROR: ${e.message}" }

                results["aospPackageSdkStatus"] = try {
                    HealthConnectClient.getSdkStatus(this@MainActivity, aospPackage)
                } catch (e: Exception) { "ERROR: ${e.message}" }

                results["oldPackageSdkStatus"] = try {
                    HealthConnectClient.getSdkStatus(this@MainActivity, oldPackage)
                } catch (e: Exception) { "ERROR: ${e.message}" }

                results["detectedPackageSdkStatus"] = try {
                    HealthConnectClient.getSdkStatus(this@MainActivity, detectedPackage)
                } catch (e: Exception) { "ERROR: ${e.message}" }

                // Check permissions
                results["hasPermissions"] = try {
                    checkHealthConnectPermissions()
                } catch (e: Exception) { "ERROR: ${e.message}" }

                android.util.Log.i("MainActivity", "=== HEALTH CONNECT DEBUG ===")
                android.util.Log.i("MainActivity", results.toString())

            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Debug error: ${e.message}", e)
                results["error"] = e.message
            }

            return@withContext results
        }
    }

    /**
     * Check if Health Connect permissions are granted
     *
     * Returns true if READ_STEPS permission is granted
     * Returns false if not granted or Health Connect not available
     */
    private suspend fun checkHealthConnectPermissions(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                android.util.Log.i("MainActivity", "=== PERMISSION CHECK START ===")

                // Try to actually use Health Connect - if this works, HC is functional
                // Don't trust SDK status as it can be misleading (status 3 even when working)
                val healthConnectClient = HealthConnectClient.getOrCreate(this@MainActivity)

                // Check if READ_STEPS permission is granted
                val granted = healthConnectClient.permissionController
                    .getGrantedPermissions()
                    .contains(
                        androidx.health.connect.client.permission.HealthPermission.getReadPermission(
                            androidx.health.connect.client.records.StepsRecord::class
                        )
                    )

                android.util.Log.i("MainActivity", "READ_STEPS permission granted: $granted")
                return@withContext granted

            } catch (e: Exception) {
                // If we can't get the client or check permissions, HC is not available
                android.util.Log.e("MainActivity", "Health Connect not available: ${e.message}", e)
                throw e  // Re-throw to signal HC is not available
            }
        }
    }

    /**
     * Read step count data from Health Connect
     *
     * Returns a map with:
     * - status: success|unavailable|permission_denied|error
     * - totalSteps: Total step count for today
     * - sources: Map of package names to step counts
     * - recordCount: Number of step records found
     * - lastSync: ISO8601 timestamp
     * - error: Error message if failed
     */
    private suspend fun readHealthConnectSteps(): Map<String, Any?> {
        return withContext(Dispatchers.IO) {
            try {
                android.util.Log.i("MainActivity", "=== READING STEPS FROM HEALTH CONNECT ===")

                // Try to get Health Connect client directly
                // Don't check SDK status - just try to use it
                // If it's not available, exception will be caught below
                val healthConnectClient = HealthConnectClient.getOrCreate(this@MainActivity)
                android.util.Log.i("MainActivity", "Health Connect client created successfully")

                // Check permission
                val granted = healthConnectClient.permissionController
                    .getGrantedPermissions()
                    .contains(
                        androidx.health.connect.client.permission.HealthPermission.getReadPermission(
                            androidx.health.connect.client.records.StepsRecord::class
                        )
                    )

                if (!granted) {
                    android.util.Log.w("MainActivity", "READ_STEPS permission not granted")
                    return@withContext mapOf(
                        "status" to "permission_denied",
                        "error" to "READ_STEPS permission not granted"
                    )
                }

                // Read today's steps (from midnight to now in LOCAL timezone)
                val now = java.time.Instant.now()
                val localZone = java.time.ZoneId.systemDefault()
                val localDate = java.time.LocalDate.now(localZone)
                val startOfDay = localDate.atStartOfDay(localZone).toInstant()

                android.util.Log.i("MainActivity", "Reading steps from $startOfDay to $now (timezone: $localZone)")

                // Aggregate total steps for today
                val aggregateResponse = healthConnectClient.aggregate(
                    androidx.health.connect.client.request.AggregateRequest(
                        metrics = setOf(androidx.health.connect.client.records.StepsRecord.COUNT_TOTAL),
                        timeRangeFilter = androidx.health.connect.client.time.TimeRangeFilter.between(startOfDay, now)
                    )
                )

                val totalSteps = aggregateResponse[androidx.health.connect.client.records.StepsRecord.COUNT_TOTAL] ?: 0L

                // Read individual records to get data sources
                val recordsResponse = healthConnectClient.readRecords(
                    androidx.health.connect.client.request.ReadRecordsRequest(
                        recordType = androidx.health.connect.client.records.StepsRecord::class,
                        timeRangeFilter = androidx.health.connect.client.time.TimeRangeFilter.between(startOfDay, now)
                    )
                )

                // Group steps by data source
                val sourceMap = mutableMapOf<String, Long>()
                for (record in recordsResponse.records) {
                    val source = record.metadata.dataOrigin.packageName
                    sourceMap[source] = (sourceMap[source] ?: 0) + record.count
                }

                android.util.Log.i("MainActivity", "Read complete: $totalSteps steps from ${sourceMap.size} sources")

                return@withContext mapOf(
                    "status" to "success",
                    "totalSteps" to totalSteps.toInt(),
                    "sources" to sourceMap.mapValues { it.value.toInt() },
                    "recordCount" to recordsResponse.records.size,
                    "lastSync" to now.toString()
                )

            } catch (e: SecurityException) {
                android.util.Log.e("MainActivity", "SecurityException reading steps: ${e.message}")
                mapOf(
                    "status" to "permission_denied",
                    "error" to "Permission denied: ${e.message}"
                )
            } catch (e: IllegalStateException) {
                // Health Connect not available
                android.util.Log.e("MainActivity", "Health Connect not available: ${e.message}", e)
                mapOf(
                    "status" to "unavailable",
                    "error" to "Health Connect not available: ${e.message}"
                )
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Error reading steps: ${e.message}", e)

                // Check if error message indicates Health Connect unavailability
                val errorMsg = e.message?.toLowerCase() ?: ""
                if (errorMsg.contains("health connect") || errorMsg.contains("unavailable")) {
                    mapOf(
                        "status" to "unavailable",
                        "error" to "Health Connect not available: ${e.message}"
                    )
                } else {
                    mapOf(
                        "status" to "error",
                        "error" to "Failed to read steps: ${e.message}"
                    )
                }
            }
        }
    }

    /**
     * Request permission to read steps from Health Connect
     *
     * Opens Health Connect permission dialog
     * Returns true if permission was granted
     */
    private fun requestHealthConnectStepsPermission(result: MethodChannel.Result) {
        try {
            val permissionContract = androidx.health.connect.client.PermissionController
                .createRequestPermissionResultContract()

            val permissions = setOf(
                androidx.health.connect.client.permission.HealthPermission.getReadPermission(
                    androidx.health.connect.client.records.StepsRecord::class
                )
            )

            val intent = permissionContract.createIntent(this, permissions)

            // Store result for callback
            pendingPermissionResult = result

            startActivityForResult(intent, REQUEST_CODE_HEALTH_CONNECT_STEPS)
            android.util.Log.i("MainActivity", "Opened Health Connect permission dialog for steps")

        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error requesting steps permission: ${e.message}", e)
            result.error("ERROR", "Failed to request permission: ${e.message}", null)
        }
    }

    // ========================================================================
    // POWER MANAGEMENT (ANDROID)
    // ========================================================================

    /**
     * Check if Power Saving Mode is enabled
     *
     * Returns true if Power Saving Mode is on (bad for background work)
     * Returns false if Power Saving Mode is off (good for background work)
     */
    private fun checkPowerSavingMode(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isPowerSaveMode
    }

    /**
     * Check Doze Mode and App Standby status
     *
     * Returns map with:
     * - "isDeviceInDozeMode": Boolean - Device is in deep sleep
     * - "appStandbyBucket": String - App usage frequency (ACTIVE, WORKING_SET, FREQUENT, RARE, RESTRICTED)
     * - "isAppWhitelisted": Boolean - App is exempt from Doze restrictions
     *
     * Android 6+ (API 23+): Doze Mode
     * Android 9+ (API 28+): App Standby Buckets
     */
    private fun checkDozeModeStatus(): Map<String, Any?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            throw Exception("NOT_AVAILABLE")
        }

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        // Check if device is in Doze Mode
        val isDeviceInDozeMode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isDeviceIdleMode
        } else {
            false
        }

        // Check App Standby Bucket (Android 9+)
        val appStandbyBucket: Int
        val appStandbyBucketName: String

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            appStandbyBucket = usageStatsManager.appStandbyBucket

            appStandbyBucketName = when (appStandbyBucket) {
                UsageStatsManager.STANDBY_BUCKET_ACTIVE -> "ACTIVE"
                UsageStatsManager.STANDBY_BUCKET_WORKING_SET -> "WORKING_SET"
                UsageStatsManager.STANDBY_BUCKET_FREQUENT -> "FREQUENT"
                UsageStatsManager.STANDBY_BUCKET_RARE -> "RARE"
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    UsageStatsManager.STANDBY_BUCKET_RESTRICTED
                } else {
                    50 // RESTRICTED value
                } -> "RESTRICTED"
                else -> "UNKNOWN"
            }
        } else {
            appStandbyBucket = -1
            appStandbyBucketName = "UNKNOWN"
        }

        // Check if app is whitelisted from battery optimizations
        val isAppWhitelisted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            false
        }

        android.util.Log.i("MainActivity", "Doze Mode: device=$isDeviceInDozeMode, bucket=$appStandbyBucketName, whitelisted=$isAppWhitelisted")

        return mapOf(
            "isDeviceInDozeMode" to isDeviceInDozeMode,
            "appStandbyBucket" to appStandbyBucketName,
            "isAppWhitelisted" to isAppWhitelisted
        )
    }

    /**
     * Request Doze Mode whitelist
     *
     * Opens settings where user can exempt the app from Doze restrictions
     * Returns true if settings was opened successfully
     *
     * Note: Same as battery optimization exemption
     */
    private fun requestDozeModeWhitelist(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }

        return try {
            // Try REQUEST_IGNORE_BATTERY_OPTIMIZATIONS first
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.i("MainActivity", "Opened Doze whitelist settings")
            true
        } catch (e: Exception) {
            // Fallback to general battery optimization settings
            android.util.Log.w("MainActivity", "Specific whitelist failed, trying general: ${e.message}")
            try {
                val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
                android.util.Log.i("MainActivity", "Opened general battery optimization settings")
                true
            } catch (e2: Exception) {
                android.util.Log.e("MainActivity", "All Doze whitelist intents failed: ${e2.message}")
                false
            }
        }
    }

    // ========================================================================
    // NETWORK & DATA (ANDROID 7+)
    // ========================================================================

    /**
     * Check Data Saver Mode status (Android 7+)
     *
     * Returns:
     * - "ENABLED": Data Saver is on, background data blocked for most apps
     * - "DISABLED": Data Saver is off, background data allowed
     * - "WHITELISTED": Data Saver is on, but this app is whitelisted
     *
     * Throws exception with message "NOT_AVAILABLE" if Android < 7
     */
    private fun checkDataSaverMode(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            throw Exception("NOT_AVAILABLE")
        }

        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        return when (connectivityManager.restrictBackgroundStatus) {
            ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED -> {
                android.util.Log.i("MainActivity", "Data Saver: ENABLED (background data blocked)")
                "ENABLED"
            }
            ConnectivityManager.RESTRICT_BACKGROUND_STATUS_WHITELISTED -> {
                android.util.Log.i("MainActivity", "Data Saver: WHITELISTED (background data allowed)")
                "WHITELISTED"
            }
            ConnectivityManager.RESTRICT_BACKGROUND_STATUS_DISABLED -> {
                android.util.Log.i("MainActivity", "Data Saver: DISABLED (background data allowed)")
                "DISABLED"
            }
            else -> {
                android.util.Log.w("MainActivity", "Data Saver: UNKNOWN")
                "UNKNOWN"
            }
        }
    }

    /**
     * Request Data Saver whitelist
     *
     * Opens settings where user can whitelist the app to allow
     * background data even when Data Saver is enabled.
     *
     * Returns true if settings was opened successfully.
     */
    private fun requestDataSaverWhitelist(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return false
        }

        return try {
            val intent = Intent(Settings.ACTION_IGNORE_BACKGROUND_DATA_RESTRICTIONS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.i("MainActivity", "Opened Data Saver whitelist settings")
            true
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to open Data Saver settings: ${e.message}")

            // Fallback to app settings
            try {
                val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
                android.util.Log.i("MainActivity", "Opened app settings as fallback")
                true
            } catch (e2: Exception) {
                android.util.Log.e("MainActivity", "All Data Saver intents failed: ${e2.message}")
                false
            }
        }
    }

    /**
     * Check if background data is restricted for this app
     *
     * Returns:
     * - "ALLOWED": App can use background data
     * - "RESTRICTED": App cannot use background data
     *
     * This is different from Data Saver Mode:
     * - Data Saver: System-wide setting affecting all apps
     * - Background Data Restriction: Per-app setting set by user
     *
     * Found in: Settings → Apps → [App] → Mobile data & WiFi → Background data
     */
    private fun checkBackgroundDataRestriction(): String {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // Check if background data is restricted for this specific app
            val restrictBackgroundStatus = connectivityManager.restrictBackgroundStatus

            when (restrictBackgroundStatus) {
                ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED -> {
                    // Data Saver is on and app is not whitelisted
                    android.util.Log.i("MainActivity", "Background data: RESTRICTED (via Data Saver)")
                    "RESTRICTED"
                }
                ConnectivityManager.RESTRICT_BACKGROUND_STATUS_DISABLED,
                ConnectivityManager.RESTRICT_BACKGROUND_STATUS_WHITELISTED -> {
                    // Data Saver is off or app is whitelisted
                    android.util.Log.i("MainActivity", "Background data: ALLOWED")
                    "ALLOWED"
                }
                else -> {
                    android.util.Log.w("MainActivity", "Background data: UNKNOWN")
                    "UNKNOWN"
                }
            }
        } else {
            // Android < 7: No background data restriction
            android.util.Log.i("MainActivity", "Background data: ALLOWED (Android < 7)")
            "ALLOWED"
        }
    }

    /**
     * Open app data settings
     *
     * Opens the settings screen where user can enable background data
     * for this app.
     *
     * Returns true if settings was opened successfully.
     */
    private fun openAppDataSettings(): Boolean {
        return try {
            // Try to open app network settings (Android 7+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val intent = Intent(Settings.ACTION_IGNORE_BACKGROUND_DATA_RESTRICTIONS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
                android.util.Log.i("MainActivity", "Opened app data settings")
                true
            } else {
                // Fallback to general app settings for Android < 7
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
                android.util.Log.i("MainActivity", "Opened general app settings")
                true
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to open app data settings: ${e.message}")
            false
        }
    }

    /**
     * Check current network connectivity
     *
     * Returns map with:
     * - "type": String - "WIFI", "CELLULAR", "NONE", "UNKNOWN"
     * - "isConnected": Boolean - true if connected to network
     * - "networkType": String? - Detailed type (e.g., "LTE", "5G", "WiFi")
     * - "isMetered": Boolean - true if cellular or metered WiFi
     */
    private fun checkConnectivity(): Map<String, Any?> {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6+: Use NetworkCapabilities API
            val activeNetwork = connectivityManager.activeNetwork
            android.util.Log.i("MainActivity", "Connectivity: activeNetwork=$activeNetwork")

            // CRITICAL FIX: If activeNetwork is null, fall back to legacy API immediately
            if (activeNetwork == null) {
                android.util.Log.w("MainActivity", "Connectivity: activeNetwork is null, using fallback")
                val networkInfo = connectivityManager.activeNetworkInfo
                android.util.Log.i("MainActivity", "Connectivity: Fallback networkInfo=$networkInfo")

                if (networkInfo != null && networkInfo.isConnected) {
                    val type = when (networkInfo.type) {
                        ConnectivityManager.TYPE_WIFI -> "WIFI"
                        ConnectivityManager.TYPE_MOBILE -> "CELLULAR"
                        ConnectivityManager.TYPE_ETHERNET -> "WIFI"
                        else -> "UNKNOWN"
                    }
                    android.util.Log.i("MainActivity", "Connectivity: activeNetwork null but networkInfo shows $type connected")
                    return mapOf(
                        "type" to type,
                        "isConnected" to true,
                        "networkType" to type,
                        "isMetered" to (networkInfo.type == ConnectivityManager.TYPE_MOBILE)
                    )
                } else {
                    android.util.Log.w("MainActivity", "Connectivity: No network detected")
                    return mapOf(
                        "type" to "NONE",
                        "isConnected" to false,
                        "networkType" to null,
                        "isMetered" to false
                    )
                }
            }

            val networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
            android.util.Log.i("MainActivity", "Connectivity: networkCapabilities=$networkCapabilities")

            if (networkCapabilities == null) {
                android.util.Log.w("MainActivity", "Connectivity: No network capabilities but activeNetwork exists")

                // CRITICAL FIX: If we have an active network but can't get capabilities,
                // the network likely still works. This can happen on some devices/Android versions.
                // Use the legacy API as fallback to determine connectivity.
                val networkInfo = connectivityManager.activeNetworkInfo
                android.util.Log.i("MainActivity", "Connectivity: Fallback to networkInfo=$networkInfo")

                if (networkInfo != null && networkInfo.isConnected) {
                    // Network exists and is connected according to legacy API
                    val type = when (networkInfo.type) {
                        ConnectivityManager.TYPE_WIFI -> "WIFI"
                        ConnectivityManager.TYPE_MOBILE -> "CELLULAR"
                        ConnectivityManager.TYPE_ETHERNET -> "WIFI"
                        else -> "UNKNOWN"
                    }
                    android.util.Log.i("MainActivity", "Connectivity: Using fallback - type=$type, connected=true")
                    return mapOf(
                        "type" to type,
                        "isConnected" to true,
                        "networkType" to type,
                        "isMetered" to (networkInfo.type == ConnectivityManager.TYPE_MOBILE)
                    )
                }

                // No network at all
                android.util.Log.w("MainActivity", "Connectivity: No network capabilities and networkInfo also failed")
                return mapOf(
                    "type" to "NONE",
                    "isConnected" to false,
                    "networkType" to null,
                    "isMetered" to false
                )
            }

            // Determine network type
            val type = when {
                networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "WIFI"
                networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "CELLULAR"
                networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "WIFI" // Treat as WiFi
                else -> "UNKNOWN"
            }

            // CRITICAL FIX: Check for connectivity with multiple fallbacks
            // 1. Prefer NET_CAPABILITY_INTERNET if available
            // 2. If that's false but we have CELLULAR or WIFI transport, assume connected
            //    (Some carriers/networks don't set NET_CAPABILITY_INTERNET properly)
            val hasInternetCapability = networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            val hasKnownTransport = networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                                   networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ||
                                   networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)

            // Consider connected if either:
            // - Has internet capability, OR
            // - Has a known working transport (WiFi/Cellular/Ethernet)
            val isConnected = hasInternetCapability || hasKnownTransport

            val isMetered = !networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)

            android.util.Log.i("MainActivity", "Connectivity: type=$type, hasInternet=$hasInternetCapability, hasTransport=$hasKnownTransport, connected=$isConnected, metered=$isMetered")

            return mapOf(
                "type" to type,
                "isConnected" to isConnected,
                "networkType" to type, // Simplified - could be enhanced with TelephonyManager
                "isMetered" to isMetered
            )
        } else {
            // Android 5 and below: Use deprecated NetworkInfo API
            @Suppress("DEPRECATION")
            val activeNetworkInfo = connectivityManager.activeNetworkInfo

            if (activeNetworkInfo == null || !activeNetworkInfo.isConnected) {
                android.util.Log.i("MainActivity", "Connectivity: No connection (legacy API)")
                return mapOf(
                    "type" to "NONE",
                    "isConnected" to false,
                    "networkType" to null,
                    "isMetered" to false
                )
            }

            @Suppress("DEPRECATION")
            val type = when (activeNetworkInfo.type) {
                ConnectivityManager.TYPE_WIFI -> "WIFI"
                ConnectivityManager.TYPE_MOBILE -> "CELLULAR"
                else -> "UNKNOWN"
            }

            @Suppress("DEPRECATION")
            val isMetered = connectivityManager.isActiveNetworkMetered

            android.util.Log.i("MainActivity", "Connectivity (legacy): type=$type, metered=$isMetered")

            return mapOf(
                "type" to type,
                "isConnected" to true,
                "networkType" to type,
                "isMetered" to isMetered
            )
        }
    }

    // ============================================================================
    // MANUFACTURER-SPECIFIC METHODS (Week 5)
    // ============================================================================

    /**
     * Open Xiaomi/MIUI autostart settings
     *
     * Attempts to open MIUI's autostart management activity.
     * Falls back to app settings if the MIUI activity is not found.
     *
     * Returns true if settings was opened successfully.
     */
    private fun openXiaomiAutostartSettings(): Boolean {
        return try {
            // Try MIUI autostart manager
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity"
                )
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.i("MainActivity", "Opened Xiaomi autostart settings")
            true
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "MIUI autostart settings not found, trying fallback: ${e.message}")
            // Fallback to general app settings
            openAppSettings()
        }
    }

    /**
     * Open Samsung battery settings
     *
     * Opens Samsung One UI battery settings where user can add app to
     * "Never sleeping apps" list.
     *
     * Returns true if settings was opened successfully.
     */
    private fun openSamsungBatterySettings(): Boolean {
        return try {
            // Try Samsung battery settings
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity"
                )
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.i("MainActivity", "Opened Samsung battery settings")
            true
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Samsung battery settings not found, trying fallback: ${e.message}")
            // Fallback to app-specific battery settings
            try {
                val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
                android.util.Log.i("MainActivity", "Opened general app settings")
                true
            } catch (e2: Exception) {
                android.util.Log.e("MainActivity", "Failed to open any settings: ${e2.message}")
                false
            }
        }
    }

    /**
     * Open Oppo/Realme autostart settings
     *
     * Attempts to open ColorOS/Realme UI startup manager.
     * Falls back to app settings if not found.
     *
     * Returns true if settings was opened successfully.
     */
    private fun openOppoAutostartSettings(): Boolean {
        return try {
            // Try ColorOS/Realme startup manager (primary)
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity"
                )
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.i("MainActivity", "Opened Oppo/Realme autostart settings")
            true
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Primary Oppo settings not found, trying alternative: ${e.message}")
            try {
                // Alternative ColorOS startup manager
                val altIntent = Intent().apply {
                    component = android.content.ComponentName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.startupapp.StartupAppListActivity"
                    )
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(altIntent)
                android.util.Log.i("MainActivity", "Opened alternative Oppo autostart settings")
                true
            } catch (e2: Exception) {
                android.util.Log.w("MainActivity", "Alternative Oppo settings not found, using fallback: ${e2.message}")
                // Fallback to general app settings
                openAppSettings()
            }
        }
    }

    /**
     * Open Vivo autostart settings
     *
     * Attempts to open Funtouch OS autostart manager.
     * Falls back to app settings if not found.
     *
     * Returns true if settings was opened successfully.
     */
    private fun openVivoAutostartSettings(): Boolean {
        return try {
            // Try Vivo autostart manager
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
                )
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.i("MainActivity", "Opened Vivo autostart settings")
            true
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Vivo autostart settings not found, using fallback: ${e.message}")
            // Fallback to general app settings
            openAppSettings()
        }
    }

    /**
     * Open Huawei autostart settings
     *
     * Attempts to open EMUI startup manager.
     * Falls back to app settings if not found.
     *
     * Returns true if settings was opened successfully.
     */
    private fun openHuaweiAutostartSettings(): Boolean {
        return try {
            // Try Huawei/EMUI startup manager
            val intent = Intent().apply {
                component = android.content.ComponentName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                )
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.i("MainActivity", "Opened Huawei autostart settings")
            true
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Huawei autostart settings not found, using fallback: ${e.message}")
            // Fallback to general app settings
            openAppSettings()
        }
    }

    /**
     * Open generic app settings (fallback for all manufacturers)
     *
     * Opens Android's app info page for this app.
     *
     * Returns true if settings was opened successfully.
     */
    private fun openAppSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            android.util.Log.i("MainActivity", "Opened app settings")
            true
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to open app settings: ${e.message}")
            false
        }
    }

    // ============================================================================
    // SENSORS & SYSTEM INFO (Week 6)
    // ============================================================================

    /**
     * Check if step counter sensor is available
     *
     * Returns true if device has TYPE_STEP_COUNTER sensor
     * Returns false if sensor is not available (rare on modern devices)
     */
    private fun checkStepCounterSensor(): Boolean {
        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val stepCounter = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        val isAvailable = stepCounter != null
        android.util.Log.i("MainActivity", "Step counter sensor: ${if (isAvailable) "AVAILABLE" else "NOT AVAILABLE"}")

        return isAvailable
    }

    /**
     * Get detailed sensor information
     *
     * Returns map with:
     * - "stepCounterAvailable": Boolean - Step counter sensor available
     * - "stepDetectorAvailable": Boolean - Step detector sensor available
     * - "stepCounterVendor": String? - Sensor vendor name
     * - "stepCounterName": String? - Sensor name
     * - "stepCounterPower": Float? - Power consumption in mA
     * - "playServicesAvailable": Boolean - Google Play Services status
     * - "playServicesVersion": String? - Play Services version
     */
    private fun getSensorInfo(): Map<String, Any?> {
        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager

        // Step counter sensor (total steps since last reboot)
        val stepCounter = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        // Step detector sensor (triggers on each step)
        val stepDetector = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)

        // Google Play Services status
        val playServicesStatus = checkPlayServices()
        val playServicesAvailable = playServicesStatus == "AVAILABLE"

        val playServicesVersion = if (playServicesAvailable) {
            try {
                val packageInfo = packageManager.getPackageInfo("com.google.android.gms", 0)
                packageInfo.versionName
            } catch (e: Exception) {
                null
            }
        } else {
            null
        }

        val info = mapOf(
            "stepCounterAvailable" to (stepCounter != null),
            "stepDetectorAvailable" to (stepDetector != null),
            "stepCounterVendor" to stepCounter?.vendor,
            "stepCounterName" to stepCounter?.name,
            "stepCounterPower" to stepCounter?.power,
            "playServicesAvailable" to playServicesAvailable,
            "playServicesVersion" to playServicesVersion
        )

        android.util.Log.i("MainActivity", "Sensor info: $info")
        return info
    }

    /**
     * Check Google Play Services availability
     *
     * Returns:
     * - "AVAILABLE": Play Services installed and up-to-date
     * - "UNAVAILABLE": Not installed or outdated
     * - "NOT_APPLICABLE": Android 14+ (Health Connect built-in)
     *
     * Google Play Services is required for Health Connect on Android 9-13.
     * On Android 14+, Health Connect is built into the OS.
     */
    private fun checkPlayServices(): String {
        val apiLevel = Build.VERSION.SDK_INT

        // Android 14+: Health Connect is built-in, Play Services not required
        if (apiLevel >= 34) {
            android.util.Log.i("MainActivity", "Play Services: NOT_APPLICABLE (Android 14+, Health Connect built-in)")
            return "NOT_APPLICABLE"
        }

        // Android 9-13: Check Play Services availability
        val googleApiAvailability = GoogleApiAvailability.getInstance()
        val resultCode = googleApiAvailability.isGooglePlayServicesAvailable(this)

        return when (resultCode) {
            ConnectionResult.SUCCESS -> {
                android.util.Log.i("MainActivity", "Play Services: AVAILABLE")
                "AVAILABLE"
            }
            else -> {
                val errorString = googleApiAvailability.getErrorString(resultCode)
                android.util.Log.w("MainActivity", "Play Services: UNAVAILABLE ($errorString)")
                "UNAVAILABLE"
            }
        }
    }

    /**
     * Open Google Play Services in Play Store for update
     *
     * Returns true if Play Store was opened successfully
     */
    private fun openPlayServicesInStore(): Boolean {
        val packageName = "com.google.android.gms"

        return try {
            // Try to open Play Store app first
            val marketIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("market://details?id=$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(marketIntent)
            android.util.Log.i("MainActivity", "Opened Play Store app for Google Play Services")
            true
        } catch (e: android.content.ActivityNotFoundException) {
            // Fallback to web browser if Play Store app not available
            android.util.Log.w("MainActivity", "Play Store app not found, trying browser: ${e.message}")
            try {
                val webIntent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(webIntent)
                android.util.Log.i("MainActivity", "Opened browser for Google Play Services")
                true
            } catch (e2: Exception) {
                android.util.Log.e("MainActivity", "Failed to open Play Store: ${e2.message}")
                false
            }
        }
    }
}
