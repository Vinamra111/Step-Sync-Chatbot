# Android Integration Guide for Step Sync ChatBot

This guide shows how to integrate the battery optimization checker and other Android-specific features into your Flutter app.

## Battery Optimization Detection

### Step 1: Add Permissions to AndroidManifest.xml

Add this permission to your `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- For battery optimization detection (Android 6.0+) -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

### Step 2: Create/Update MainActivity

Create or update your `MainActivity.kt` (or `MainActivity.java`) file:

#### Kotlin (MainActivity.kt)

**Location**: `android/app/src/main/kotlin/com/yourcompany/yourapp/MainActivity.kt`

```kotlin
package com.yourcompany.yourapp

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val BATTERY_CHANNEL = "com.stepsync.chatbot/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBatteryOptimizationEnabled" -> {
                        val isOptimized = isBatteryOptimizationEnabled()
                        result.success(isOptimized)
                    }
                    "requestBatteryOptimizationExemption" -> {
                        val success = requestBatteryOptimizationExemption()
                        result.success(success)
                    }
                    "isBatteryOptimizationSupported" -> {
                        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
                        result.success(supported)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    /**
     * Check if battery optimization is enabled for this app
     * @return true if optimization is enabled (blocking background work)
     */
    private fun isBatteryOptimizationEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            // Battery optimization not available on Android < 6.0
            return false
        }

        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        val packageName = applicationContext.packageName

        // Returns true if NOT ignoring battery optimizations (i.e., optimization is enabled)
        return !pm.isIgnoringBatteryOptimizations(packageName)
    }

    /**
     * Request battery optimization exemption from user
     * Opens system settings screen
     * @return true if intent was launched successfully
     */
    private fun requestBatteryOptimizationExemption(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }

        return try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${applicationContext.packageName}")
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
```

#### Java (MainActivity.java)

**Location**: `android/app/src/main/java/com/yourcompany/yourapp/MainActivity.java`

```java
package com.yourcompany.yourapp;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.PowerManager;
import android.provider.Settings;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String BATTERY_CHANNEL = "com.stepsync.chatbot/battery";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), BATTERY_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "isBatteryOptimizationEnabled":
                        boolean isOptimized = isBatteryOptimizationEnabled();
                        result.success(isOptimized);
                        break;
                    case "requestBatteryOptimizationExemption":
                        boolean success = requestBatteryOptimizationExemption();
                        result.success(success);
                        break;
                    case "isBatteryOptimizationSupported":
                        boolean supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M;
                        result.success(supported);
                        break;
                    default:
                        result.notImplemented();
                        break;
                }
            });
    }

    /**
     * Check if battery optimization is enabled for this app
     * @return true if optimization is enabled (blocking background work)
     */
    private boolean isBatteryOptimizationEnabled() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            // Battery optimization not available on Android < 6.0
            return false;
        }

        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        String packageName = getApplicationContext().getPackageName();

        // Returns true if NOT ignoring battery optimizations (i.e., optimization is enabled)
        return !pm.isIgnoringBatteryOptimizations(packageName);
    }

    /**
     * Request battery optimization exemption from user
     * Opens system settings screen
     * @return true if intent was launched successfully
     */
    private boolean requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false;
        }

        try {
            Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
            intent.setData(Uri.parse("package:" + getApplicationContext().getPackageName()));
            startActivity(intent);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}
```

### Step 3: Usage in Dart

```dart
import 'package:step_sync_chatbot/src/diagnostics/battery_checker.dart';

final batteryChecker = BatteryChecker();

// Check battery optimization status
final status = await batteryChecker.checkBatteryOptimization();

switch (status) {
  case BatteryOptimizationStatus.enabled:
    print('Battery optimization is BLOCKING background work');
    // Show "Fix Now" button to user
    break;
  case BatteryOptimizationStatus.disabled:
    print('Battery optimization is disabled - background work allowed');
    break;
  case BatteryOptimizationStatus.unknown:
    print('Could not determine battery optimization status');
    break;
  case BatteryOptimizationStatus.notApplicable:
    print('Not applicable (iOS or Android < 6.0)');
    break;
}

// Request exemption (opens system settings)
final success = await batteryChecker.requestBatteryOptimizationExemption();
if (success) {
  print('Settings screen opened - waiting for user action');
}
```

## Testing

### Test on Android Device/Emulator

1. **Check Current Status**:
   ```dart
   final status = await batteryChecker.checkBatteryOptimization();
   print('Current status: $status');
   ```

2. **Enable Battery Optimization** (to test detection):
   - Go to Settings → Apps → Your App → Battery → Battery optimization
   - Set to "Optimize"
   - Re-run check - should return `BatteryOptimizationStatus.enabled`

3. **Request Exemption**:
   ```dart
   await batteryChecker.requestBatteryOptimizationExemption();
   ```
   - User should see system settings screen
   - Select "Don't optimize"
   - Re-run check - should return `BatteryOptimizationStatus.disabled`

### Expected Behavior by Android Version

| Android Version | Battery Optimization | Expected Status |
|-----------------|----------------------|-----------------|
| 5.x and below | Not available | `notApplicable` |
| 6.0 - 13 | Available | `enabled` or `disabled` |
| 14+ | Available | `enabled` or `disabled` |

## Troubleshooting

### Method Channel Not Found
- **Error**: `MissingPluginException: No implementation found for method`
- **Fix**: Make sure MainActivity.kt/java is in the correct package and the channel name matches exactly: `com.stepsync.chatbot/battery`

### Permission Denied
- **Error**: Permission denial when opening settings
- **Fix**: Add `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission to AndroidManifest.xml

### Always Returns Unknown
- **Check**: Verify Android method channel implementation is correct
- **Check**: Test on real device (not emulator) for more accurate results
- **Check**: Ensure Android version is 6.0+ (API 23+)

## Next Features to Implement

After battery optimization, you can implement:

1. **Low Power Mode (iOS)** - Similar pattern using iOS method channel
2. **Background Location Permission** - For more accurate step tracking
3. **Motion & Fitness Permission** - Required on iOS 14+
4. **Notification Permission** - For step tracking reminders

---

**Note**: This is a development-only implementation. Before production:
- Test on multiple Android versions (6.0, 8.0, 10, 12, 13, 14)
- Test on different device manufacturers (Samsung, Google Pixel, OnePlus, etc.)
- Handle edge cases (app reinstall, permission revoked, etc.)
