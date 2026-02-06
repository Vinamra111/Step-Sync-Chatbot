/// Example: Custom Sleep Tracking Plugin
///
/// Shows how to create a custom domain plugin for sleep tracking
/// with advanced features like sleep quality analysis.

import 'package:health_troubleshoot_chatbot/health_troubleshoot_chatbot.dart';

/// Custom sleep tracking plugin with ML-powered sleep quality analysis
class CustomSleepTrackingPlugin extends DomainPlugin {
  @override
  String get domainId => 'sleep_tracking_advanced';

  @override
  String get domainName => 'Advanced Sleep Tracking';

  @override
  String get metricName => 'sleep hours';

  @override
  String get metricUnit => 'hours';

  @override
  String get assistantName => 'Sleep Coach Pro';

  @override
  String get appName => 'My Sleep App';

  @override
  String get version => '1.0.0';

  @override
  List<String> get requiredPermissions => [
        'ACTIVITY_RECOGNITION',
        'BODY_SENSORS',
      ];

  // Simulated ML model (in reality, you'd load a real model)
  bool _isModelLoaded = false;

  @override
  Future<void> initialize() async {
    print('🌙 Initializing Sleep Tracking Plugin v$version');
    print('   Loading sleep quality ML model...');

    // Simulate loading an ML model
    await Future.delayed(const Duration(milliseconds: 500));
    _isModelLoaded = true;

    print('   ✓ ML model loaded successfully');
  }

  @override
  void dispose() {
    print('🌙 Disposing Sleep Tracking Plugin');
    _isModelLoaded = false;
  }

  @override
  String? validate() {
    if (!_isModelLoaded) {
      return 'ML model not loaded. Call initialize() first.';
    }
    return null;
  }

  @override
  IntentClassifier get intentClassifier => SleepIntentClassifier();

  @override
  TemplateProvider get templateProvider =>
      SleepTemplateProvider(placeholders: getPlaceholders());

  @override
  DiagnosticProvider get diagnosticProvider =>
      SleepDiagnosticProvider(placeholders: getPlaceholders());

  @override
  HealthMetricAdapter get healthAdapter => SleepMetricAdapter();

  @override
  String? modifySystemPrompt(String basePrompt) {
    return '''
$basePrompt

SLEEP TRACKING CONTEXT:
- Recommended sleep: 7-9 hours for adults, 8-10 for teens
- Sleep quality matters more than just duration
- Consider sleep debt and patterns
- REM and deep sleep stages are important
- Consistent sleep schedule improves quality

SLEEP QUALITY INDICATORS:
- Good: 7-9 hours, minimal interruptions, feeling rested
- Fair: 6-7 hours, some interruptions
- Poor: < 6 hours, frequent wake-ups, feeling tired

When analyzing sleep issues:
1. Check duration first
2. Look for patterns (weekday vs weekend)
3. Consider sleep environment factors
4. Ask about caffeine, screen time, stress
''';
  }

  @override
  Future<Map<String, dynamic>?> runCustomDiagnostics() async {
    if (!_isModelLoaded) {
      return {
        'error': 'ML model not loaded',
      };
    }

    // Example: Run ML-based sleep quality prediction
    return {
      'model_status': 'active',
      'predictions_available': true,
      'last_analysis': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<void> handleCustomAction(
    String actionId,
    Map<String, dynamic> context,
  ) async {
    switch (actionId) {
      case 'analyze_sleep_quality':
        print('🌙 Analyzing sleep quality with ML model...');
        // Perform ML analysis
        break;

      case 'suggest_bedtime':
        print('🌙 Calculating optimal bedtime...');
        // Calculate bedtime recommendation
        break;

      default:
        print('Unknown action: $actionId');
    }
  }
}

/// Simple sleep intent classifier
class SleepIntentClassifier implements IntentClassifier {
  @override
  IntentClassificationResult classify(String input) {
    final lowercaseInput = input.toLowerCase();

    if (lowercaseInput.contains('sleep') && lowercaseInput.contains('not')) {
      return IntentClassificationResult(
        intent: UserIntent.metricNotSyncing,
        confidence: 0.9,
      );
    }

    if (lowercaseInput.contains('sleep quality') ||
        lowercaseInput.contains('poor sleep')) {
      return IntentClassificationResult(
        intent: UserIntent.custom(
          id: 'poor_sleep_quality',
          displayName: 'Poor Sleep Quality',
          category: IntentCategory.troubleshooting,
        ),
        confidence: 0.92,
      );
    }

    if (lowercaseInput.contains('hello') || lowercaseInput.contains('hi')) {
      return IntentClassificationResult(
        intent: UserIntent.greeting,
        confidence: 0.95,
      );
    }

    return IntentClassificationResult(
      intent: UserIntent.unknown,
      confidence: 0.5,
    );
  }

  @override
  List<UserIntent> getSupportedIntents() {
    return [
      UserIntent.greeting,
      UserIntent.metricNotSyncing,
      UserIntent.wrongCount,
      UserIntent.custom(
        id: 'poor_sleep_quality',
        displayName: 'Poor Sleep Quality',
      ),
    ];
  }
}

/// Sleep-specific template provider
class SleepTemplateProvider extends BaseTemplateProvider {
  SleepTemplateProvider({required Map<String, String> placeholders})
      : super(placeholders: placeholders);

  @override
  ChatMessage getResponse(UserIntent intent, {Map<String, dynamic>? context}) {
    if (intent.id == 'poor_sleep_quality') {
      return createBotMessage('''
I see you're having trouble with sleep quality. Let's look at some factors:

🛏️ **Sleep Environment**
- Is your room dark, quiet, and cool?
- Are you using screens before bed?

⏰ **Sleep Schedule**
- Do you go to bed at the same time each night?
- Are you getting 7-9 hours?

☕ **Lifestyle Factors**
- Caffeine intake (cut off 6+ hours before bed)
- Exercise (helps sleep but not too close to bedtime)
- Stress levels

Let me analyze your recent sleep patterns...
''');
    }

    return getUnknownResponse();
  }

  @override
  ChatMessage getGreeting({String? userName}) {
    return createBotMessage('''
Hi${userName != null ? " $userName" : ""}! I'm {{assistant_name}} 🌙

I help you track and improve your {{metric_name}}.

I can assist with:
• Sleep tracking issues
• Sleep quality analysis
• Personalized sleep recommendations
• Optimal bedtime suggestions

What can I help you with today?
''');
  }

  @override
  ChatMessage getHelp() {
    return createBotMessage('''
I can help you with {{metric_name}} tracking in {{app_name}}:

✓ Sleep data not syncing
✓ Sleep quality analysis
✓ Sleep schedule optimization
✓ Troubleshooting tracking issues

What do you need help with?
''');
  }

  @override
  ChatMessage getUnknownResponse() {
    return createBotMessage('''
I'm not quite sure what you mean. Are you having issues with:
• {{metric_name}} not syncing?
• Sleep quality concerns?
• Something else?
''');
  }
}

/// Sleep-specific diagnostic provider
class SleepDiagnosticProvider extends BaseDiagnosticProvider {
  SleepDiagnosticProvider({required Map<String, String> placeholders})
      : super(placeholders: placeholders);

  @override
  Future<TrackingStatusResult> checkTrackingStatus() async {
    // Implement sleep-specific diagnostics
    return TrackingStatusResult(
      isTracking: true,
      issues: [],
      lastChecked: DateTime.now(),
    );
  }

  @override
  List<TrackingIssueType> getSupportedIssues() {
    return [
      TrackingIssueType.permissionsNotGranted,
      TrackingIssueType.dataNotSyncing,
      TrackingIssueType.wrongDataSource,
    ];
  }

  @override
  Future<TrackingIssue?> checkSpecificIssue(TrackingIssueType type) async {
    // Implement specific checks
    return null;
  }
}

/// Sleep-specific metric adapter
class SleepMetricAdapter extends BaseHealthMetricAdapter<double> {
  @override
  String get metricName => 'sleep hours';

  @override
  String get metricUnit => 'hours';

  @override
  Future<List<HealthMetricData<double>>> getMetricData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Implement actual sleep data fetching
    return [];
  }

  @override
  Future<double?> getTodayValue() async => null;

  @override
  Future<double?> getValueForDate(DateTime date) async => null;

  @override
  Future<List<DataSource>> getDataSources() async => [];

  @override
  Future<DataSource?> getPrimaryDataSource() async => null;

  @override
  Future<void> setPrimaryDataSource(String dataSourceId) async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> hasPermissions() async => false;

  @override
  Future<void> syncData() async {}

  @override
  Future<DateTime?> getLastSyncTime() async => null;

  @override
  Future<void> deleteData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {}

  @override
  Future<void> writeData({
    required DateTime date,
    required double value,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  bool isValidValue(double value) {
    return value >= 0 && value <= 24; // 0-24 hours per day
  }

  @override
  double? getRecommendedDailyGoal() => 8.0; // 8 hours

  @override
  double? getMinValue() => 0.0;

  @override
  double? getMaxValue() => 24.0;
}
