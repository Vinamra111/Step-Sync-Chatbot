# Step Verification Feature - Integration Plan
## Comprehensive Implementation Strategy

**Date:** January 22, 2026
**Status:** Research Complete - Ready for Review
**Goal:** Add step count verification without breaking existing chatbot functionality

---

## 📋 Executive Summary

### What We're Adding
A new diagnostic capability that:
1. Reads actual step count from Health Connect
2. Compares it with what the app displays
3. Identifies data source discrepancies
4. Provides troubleshooting guidance

### Risk Level: **LOW** ✅
- Non-breaking addition
- Optional feature (only runs when user requests it)
- Graceful error handling
- No changes to existing working features

---

## 🔬 Research Findings

### Health Connect SDK Capabilities

**API Methods Available:**
1. **`aggregate()`** - Recommended for step totals (avoids double-counting)
2. **`readRecords()`** - Get individual step entries with sources
3. **`aggregateGroupByDuration()`** - Break down by time periods

**Key Data Type:**
- `StepsRecord` - Stores step count data with metadata:
  - `count` - Number of steps
  - `startTime` - When counting started
  - `endTime` - When counting ended
  - `metadata.dataOrigin` - Which app wrote this data

### Permissions Required

**New Permissions Needed:**
```xml
<!-- Read step count data -->
<uses-permission android:name="android.permission.health.READ_STEPS" />

<!-- Optional: Read data older than 30 days -->
<uses-permission android:name="android.permission.health.READ_HEALTH_DATA_HISTORY" />
```

**Runtime Permission:**
- Must request via Health Connect permission dialog
- User can grant/revoke anytime
- Must check before every read operation

---

## 🏗️ Architecture Design

### Integration Points (Non-Breaking)

**1. New Kotlin Method in MainActivity.kt**
```kotlin
Location: Line ~720 (after checkHealthConnectAvailability)
Name: readHealthConnectSteps()
Purpose: Read step data from Health Connect
Returns: Map with step count, data sources, and status
```

**2. New Dart Service Class**
```dart
File: lib/src/services/step_verifier.dart (NEW FILE)
Purpose: Handle step verification logic
Dependencies: Uses existing DiagnosticChannels
```

**3. New Diagnostic Command**
```dart
Location: main.dart _handleUserMessage()
Trigger: "verify steps", "check my steps", "are my steps correct"
Action: Calls _verifyStepCount()
```

**4. New UI Display**
```dart
Location: main.dart _verifyStepCount() (NEW METHOD)
Purpose: Show step verification results with sources
Format: Uses existing _add() message system
```

### Data Flow
```
User: "verify my steps"
  ↓
_handleUserMessage() detects command
  ↓
_verifyStepCount() called
  ↓
StepVerifier.checkSteps()
  ↓
Platform Channel → MainActivity.readHealthConnectSteps()
  ↓
Health Connect SDK → aggregate() + readRecords()
  ↓
Return: {total, sources, lastSync, status}
  ↓
Format results → Display to user
```

---

## 💻 Implementation Plan

### Phase 1: Foundation (No Breaking Changes)

**Step 1.1: Add Permissions**
- File: `android/app/src/main/AndroidManifest.xml`
- Add READ_STEPS permission
- Add to privacy policy note in comments

**Step 1.2: Add Gradle Dependency**
- Already added: `androidx.health.connect:connect-client:1.1.0-alpha01`
- No additional dependencies needed

**Step 1.3: Create Platform Channel**
- Add to `DiagnosticChannels.dart`:
```dart
static const steps = MethodChannel('com.stepsync.chatbot/steps');
```

### Phase 2: Native Implementation

**Step 2.1: Create Step Reader Method**
```kotlin
// Location: MainActivity.kt, line ~720
private suspend fun readHealthConnectSteps(): Map<String, Any?> {
    return withContext(Dispatchers.IO) {
        try {
            // Check if Health Connect is available
            val availability = getSdkStatus()
            if (availability != 1) {
                return@withContext mapOf(
                    "status" to "unavailable",
                    "error" to "Health Connect not available"
                )
            }

            // Check permission
            val healthConnectClient = HealthConnectClient.getOrCreate(this@MainActivity)
            val granted = healthConnectClient.permissionController
                .getGrantedPermissions()
                .contains(StepsRecord.READ)

            if (!granted) {
                return@withContext mapOf(
                    "status" to "permission_denied",
                    "error" to "READ_STEPS permission not granted"
                )
            }

            // Read today's steps (aggregate)
            val now = Instant.now()
            val startOfDay = now.truncatedTo(ChronoUnit.DAYS)

            val aggregateResponse = healthConnectClient.aggregate(
                AggregateRequest(
                    metrics = setOf(StepsRecord.COUNT_TOTAL),
                    timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                )
            )

            val totalSteps = aggregateResponse[StepsRecord.COUNT_TOTAL] ?: 0L

            // Read individual records to get sources
            val recordsResponse = healthConnectClient.readRecords(
                ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startOfDay, now)
                )
            )

            // Group by data source
            val sourceMap = mutableMapOf<String, Long>()
            for (record in recordsResponse.records) {
                val source = record.metadata.dataOrigin.packageName
                sourceMap[source] = (sourceMap[source] ?: 0) + record.count
            }

            return@withContext mapOf(
                "status" to "success",
                "totalSteps" to totalSteps,
                "sources" to sourceMap,
                "recordCount" to recordsResponse.records.size,
                "lastSync" to now.toString()
            )

        } catch (e: SecurityException) {
            mapOf(
                "status" to "permission_denied",
                "error" to "Permission denied: ${e.message}"
            )
        } catch (e: Exception) {
            mapOf(
                "status" to "error",
                "error" to "Failed to read steps: ${e.message}"
            )
        }
    }
}
```

**Step 2.2: Register Method Channel Handler**
```kotlin
// Location: MainActivity.kt configureFlutterEngine()
// Add after existing channel setup

MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.stepsync.chatbot/steps")
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "readSteps" -> {
                lifecycleScope.launch {
                    try {
                        val steps = readHealthConnectSteps()
                        result.success(steps)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }
            "requestStepsPermission" -> {
                requestHealthConnectStepsPermission(result)
            }
            else -> result.notImplemented()
        }
    }
```

### Phase 3: Dart Implementation

**Step 3.1: Create StepVerifier Service**
```dart
// File: lib/src/services/step_verifier.dart (NEW)

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../diagnostics/diagnostic_channels.dart';

enum StepVerificationStatus {
  success,
  unavailable,
  permissionDenied,
  error,
  unknown,
}

class StepVerificationResult {
  final StepVerificationStatus status;
  final int? totalSteps;
  final Map<String, int>? sources;
  final int? recordCount;
  final String? lastSync;
  final String? error;

  const StepVerificationResult({
    required this.status,
    this.totalSteps,
    this.sources,
    this.recordCount,
    this.lastSync,
    this.error,
  });

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

  static StepVerificationStatus _parseStatus(String status) {
    switch (status) {
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

class StepVerifier {
  static final _log = Logger();

  /// Read step count from Health Connect
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
      _log.e('PlatformException reading steps: ${e.message}');
      return StepVerificationResult(
        status: StepVerificationStatus.error,
        error: 'Platform error: ${e.message}',
      );
    } catch (e) {
      _log.e('Error reading steps: $e');
      return StepVerificationResult(
        status: StepVerificationStatus.error,
        error: 'Unexpected error: $e',
      );
    }
  }

  /// Request permission to read steps
  static Future<bool> requestPermission() async {
    try {
      _log.d('Requesting steps permission...');
      final result = await DiagnosticChannels.steps.invokeMethod('requestStepsPermission');
      return result as bool? ?? false;
    } catch (e) {
      _log.e('Error requesting permission: $e');
      return false;
    }
  }
}
```

**Step 3.2: Add DiagnosticChannels Entry**
```dart
// File: lib/src/diagnostics/diagnostic_channels.dart
// Add to existing class:

static const steps = MethodChannel('com.stepsync.chatbot/steps');
```

**Step 3.3: Add Command Handler in main.dart**
```dart
// Location: main.dart _handleUserMessage(), add to keyword detection:

if (lower.contains('verify') && lower.contains('step') ||
    lower.contains('check') && lower.contains('step') && lower.contains('count') ||
    lower.contains('are my steps correct') ||
    lower.contains('step verification')) {
  _verifyStepCount();
  return;
}
```

**Step 3.4: Add Verification Method**
```dart
// Location: main.dart, add new method:

Future<void> _verifyStepCount() async {
  try {
    _add(true, '🔍 **Verifying Your Step Count**\n\nChecking Health Connect data...');

    // Check Health Connect availability first
    final availability = await _healthPlatformChecker.checkHealthConnectAvailability();

    if (availability.status != HealthPlatformStatus.available &&
        availability.status != HealthPlatformStatus.builtIn) {
      _add(true,
        '⚠️ **Health Connect Not Available**\n\n'
        'I need Health Connect to verify your steps.\n\n'
        'Current status: ${availability.status.description}\n\n'
        'Please install or activate Health Connect first.',
        actions: [
          ActionButton(
            label: 'Check Health Connect',
            icon: Icons.health_and_safety,
            onPressed: () => _checkHealthConnect(),
          ),
        ],
      );
      return;
    }

    // Read steps from Health Connect
    final result = await StepVerifier.readSteps();

    // Handle different statuses
    switch (result.status) {
      case StepVerificationStatus.success:
        _displayStepVerificationResults(result);
        break;

      case StepVerificationStatus.permissionDenied:
        _add(true,
          '🔒 **Permission Required**\n\n'
          'I need permission to read your steps from Health Connect.\n\n'
          'This allows me to:\n'
          '• Verify your step count\n'
          '• Check data sources\n'
          '• Identify sync issues\n\n'
          'Tap below to grant permission.',
          actions: [
            ActionButton(
              label: 'Grant Permission',
              icon: Icons.security,
              onPressed: () async {
                final granted = await StepVerifier.requestPermission();
                if (granted && mounted) {
                  _add(true, '✅ Permission granted! Let me check your steps again...');
                  await Future.delayed(Duration(milliseconds: 500));
                  if (mounted) _verifyStepCount();
                } else if (mounted) {
                  _add(true, '❌ Permission was not granted. I cannot verify steps without this permission.');
                }
              },
            ),
          ],
        );
        break;

      case StepVerificationStatus.unavailable:
        _add(true,
          '⚠️ **Health Connect Unavailable**\n\n'
          '${result.error ?? "Health Connect is not available on this device."}\n\n'
          'Please check your Health Connect installation.',
        );
        break;

      case StepVerificationStatus.error:
      case StepVerificationStatus.unknown:
        _add(true,
          '❌ **Verification Failed**\n\n'
          'Error: ${result.error ?? "Unknown error occurred"}\n\n'
          'Please try again or check your Health Connect settings.',
        );
        break;
    }
  } catch (e) {
    _log.e('Error in step verification: $e');
    _add(true, '❌ **Error**\n\nFailed to verify steps: $e');
  }
}

void _displayStepVerificationResults(StepVerificationResult result) {
  final steps = result.totalSteps ?? 0;
  final sources = result.sources ?? {};

  // Build sources list
  final sourcesText = sources.isEmpty
      ? '• No data sources found'
      : sources.entries.map((e) {
          final appName = _getAppName(e.key);
          return '• **$appName**: ${e.value} steps';
        }).join('\n');

  // Determine if there are issues
  final hasMultipleSources = sources.length > 1;
  final hasNoSources = sources.isEmpty;

  String statusIcon = '✅';
  String statusText = 'Everything looks good!';
  String recommendation = '';

  if (hasNoSources) {
    statusIcon = '⚠️';
    statusText = 'No step data found';
    recommendation = '\n\n**Recommendation:**\n'
        'No apps are writing step data to Health Connect. '
        'Make sure your fitness apps have permission to write steps.';
  } else if (hasMultipleSources) {
    statusIcon = 'ℹ️';
    statusText = 'Multiple data sources detected';
    recommendation = '\n\n**Note:**\n'
        'You have multiple apps writing steps. Health Connect merges this data '
        'based on your app priority settings. If you see duplicate counts, '
        'you can adjust priority in Health Connect settings.';
  }

  _add(true,
    '$statusIcon **Step Verification Complete**\n\n'
    '**Total Steps Today:** $steps\n\n'
    '**Data Sources:**\n'
    '$sourcesText\n\n'
    '**Status:** $statusText'
    '$recommendation\n\n'
    '**Last Checked:** ${_formatTime(result.lastSync)}',
    actions: [
      ActionButton(
        label: 'Check Again',
        icon: Icons.refresh,
        onPressed: () => _verifyStepCount(),
      ),
      if (hasMultipleSources)
        ActionButton(
          label: 'Manage Data Sources',
          icon: Icons.settings,
          onPressed: () => _openHealthConnectSettings(),
        ),
    ],
  );
}

String _getAppName(String packageName) {
  // Map common package names to friendly names
  final knownApps = {
    'com.google.android.apps.fitness': 'Google Fit',
    'com.samsung.health': 'Samsung Health',
    'com.mi.health': 'Mi Fitness',
    'com.android.healthconnect.controller': 'Health Connect (System)',
    'com.example.step_sync_chatbot_mobile': 'Step Sync (This App)',
  };

  return knownApps[packageName] ?? packageName.split('.').last;
}

String _formatTime(String? isoTime) {
  if (isoTime == null) return 'Unknown';
  try {
    final time = DateTime.parse(isoTime);
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  } catch (e) {
    return 'Unknown';
  }
}

Future<void> _openHealthConnectSettings() async {
  try {
    _add(true, '📱 Opening Health Connect settings...');
    final success = await _healthPlatformChecker.openHealthConnectPlayStore();
    if (!success && mounted) {
      _add(true, '❌ Could not open Health Connect settings. Please open it manually from your Settings app.');
    }
  } catch (e) {
    _log.e('Error opening settings: $e');
    _add(true, '❌ Error opening settings: $e');
  }
}
```

---

## 🛡️ Risk Mitigation

### Potential Risks & Solutions

**Risk 1: Breaking Existing Features**
- ✅ **Mitigation:** All new code is additive, no modifications to existing methods
- ✅ **Testing:** Existing features work identically if new feature never called

**Risk 2: Permission Denial Crashes**
- ✅ **Mitigation:** All permission checks wrapped in try-catch
- ✅ **Fallback:** Graceful error messages, no crashes

**Risk 3: Health Connect Unavailable**
- ✅ **Mitigation:** Check availability before every operation
- ✅ **Fallback:** Clear user-friendly error messages

**Risk 4: No Step Data Available**
- ✅ **Mitigation:** Handle empty/null results explicitly
- ✅ **Fallback:** Show "No data found" message with guidance

**Risk 5: Multiple Data Sources Confusion**
- ✅ **Mitigation:** Clearly display all sources and their counts
- ✅ **Guidance:** Explain Health Connect's merge behavior

**Risk 6: Performance Impact**
- ✅ **Mitigation:** Async operations with proper coroutine scoping
- ✅ **Monitoring:** Only reads when user explicitly requests

---

## 🧪 Testing Strategy

### Unit Tests
```
1. Test step reading with mock data
2. Test permission denial handling
3. Test empty result handling
4. Test multiple sources parsing
5. Test error scenarios
```

### Integration Tests
```
1. Test with Health Connect unavailable
2. Test with permission denied
3. Test with no data
4. Test with single data source
5. Test with multiple sources
6. Test permission request flow
```

### Manual Testing Checklist
```
□ Verify on device WITH Health Connect installed
□ Verify on device WITHOUT Health Connect
□ Test permission grant flow
□ Test permission denial flow
□ Test with 0 steps
□ Test with steps from single app
□ Test with steps from multiple apps
□ Test existing features still work
□ Test chat clear still works
□ Test all Quick Action buttons
□ Test diagnostics still work
```

---

## 📱 User Experience Flow

### Scenario 1: First Time Use
```
User: "verify my steps"
Bot: "🔍 Verifying Your Step Count
     Checking Health Connect data..."

Bot: "🔒 Permission Required
     I need permission to read your steps...
     [Grant Permission button]"

User: Taps button → Health Connect permission dialog
User: Grants permission

Bot: "✅ Permission granted! Let me check..."
Bot: "✅ Step Verification Complete
     Total Steps Today: 5,234

     Data Sources:
     • Google Fit: 5,234 steps

     Status: Everything looks good!"
```

### Scenario 2: Multiple Sources Detected
```
User: "check my steps"
Bot: "ℹ️ Step Verification Complete
     Total Steps Today: 7,891

     Data Sources:
     • Google Fit: 4,523 steps
     • Samsung Health: 3,368 steps

     Status: Multiple data sources detected

     Note: You have multiple apps writing steps.
     Health Connect merges this data based on
     your app priority settings..."
```

### Scenario 3: No Data Available
```
User: "verify steps"
Bot: "⚠️ Step Verification Complete
     Total Steps Today: 0

     Data Sources:
     • No data sources found

     Status: No step data found

     Recommendation: No apps are writing
     step data to Health Connect..."
```

---

## 🚀 Deployment Plan

### Phase 1: Development (1-2 hours)
1. Add permissions to AndroidManifest
2. Implement native Kotlin code
3. Create Dart service
4. Add UI integration
5. Add command handler

### Phase 2: Testing (30 minutes)
1. Run unit tests
2. Manual testing on device
3. Verify existing features work
4. Test all edge cases

### Phase 3: Documentation (15 minutes)
1. Update README with new feature
2. Document new commands
3. Add to user guide

### Total Estimated Time: 2-3 hours

---

## 📊 Success Criteria

✅ Feature works correctly when called
✅ Existing features unchanged and working
✅ Graceful error handling for all edge cases
✅ Clear, helpful user messages
✅ No crashes under any scenario
✅ Minimal performance impact
✅ Easy to understand and use

---

## 🎯 Conclusion

**Recommendation: PROCEED WITH IMPLEMENTATION**

**Rationale:**
1. **Non-Breaking:** Purely additive feature
2. **Well-Researched:** Comprehensive API understanding
3. **Risk-Mitigated:** All edge cases handled
4. **User Value:** Solves real troubleshooting need
5. **Clean Architecture:** Fits existing patterns
6. **Thoroughly Planned:** Clear implementation path

**This integration will enhance the chatbot without compromising its current excellent functionality.**

---

## 📚 Sources

- [Read raw data | Android Developers](https://developer.android.com/health-and-fitness/health-connect/read-data)
- [Track steps | Android Developers](https://developer.android.com/health-and-fitness/health-connect/features/steps)
- [Read aggregated data | Android Developers](https://developer.android.com/health-and-fitness/health-connect/aggregate-data)
- [Get started with Health Connect | Android Developers](https://developer.android.com/health-and-fitness/health-connect/get-started)
- [Synchronize data | Android Developers](https://developer.android.com/health-and-fitness/health-connect/sync-data)
- [Health Connect data types | Android Developers](https://developer.android.com/health-and-fitness/health-connect/data-types)
- [Exploring Health Connect Permissions | droidcon](https://www.droidcon.com/2024/01/17/exploring-health-connect-pt-1-setting-up-permissions/)

---

**End of Integration Plan**
**Ready for User Review and Approval**
