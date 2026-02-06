/// YAML-based domain configuration
///
/// Allows defining custom domains via YAML files without writing Dart code.
/// Perfect for simple domains that don't need custom logic.

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';
import 'dart:io';

import 'domain_config.dart';
import 'intent_classifier.dart';
import 'template_provider.dart';
import 'diagnostic_provider.dart';
import 'health_metric_adapter.dart';
import '../data/models/chat_message.dart';
import '../data/models/tracking_status.dart';
import '../data/models/data_source.dart';

/// YAML-based domain configuration
///
/// Loads domain configuration from a YAML file.
///
/// Example YAML:
/// ```yaml
/// domain:
///   id: "water_tracking"
///   name: "Water Intake Tracking"
///   metric_name: "water intake"
///   metric_unit: "oz"
///
/// branding:
///   assistant_name: "Hydration Helper"
///   app_name: "My Hydration App"
///
/// intents:
///   - id: "metric_not_syncing"
///     patterns: ["water not tracking", "{{metric_name}} not updating"]
///     confidence: 0.92
///
/// templates:
///   greeting: "Hi! I'm {{assistant_name}}."
/// ```
class YamlDomainConfig extends DomainConfig {
  final Map<String, dynamic> _config;
  late final YamlIntentClassifier _intentClassifier;
  late final YamlTemplateProvider _templateProvider;
  late final YamlDiagnosticProvider _diagnosticProvider;
  late final YamlHealthMetricAdapter _healthAdapter;

  YamlDomainConfig._(this._config) {
    _intentClassifier = YamlIntentClassifier(
      config: _config,
      placeholders: getPlaceholders(),
    );
    _templateProvider = YamlTemplateProvider(
      config: _config,
      placeholders: getPlaceholders(),
    );
    _diagnosticProvider = YamlDiagnosticProvider(
      config: _config,
      placeholders: getPlaceholders(),
    );
    _healthAdapter = YamlHealthMetricAdapter(
      config: _config,
    );
  }

  /// Load from a file path
  static Future<YamlDomainConfig> fromFile(String filePath) async {
    final file = File(filePath);
    final contents = await file.readAsString();
    final yaml = loadYaml(contents);

    return YamlDomainConfig._(_yamlToMap(yaml));
  }

  /// Load from Flutter asset
  static Future<YamlDomainConfig> fromAsset(String assetPath) async {
    final contents = await rootBundle.loadString(assetPath);
    final yaml = loadYaml(contents);

    return YamlDomainConfig._(_yamlToMap(yaml));
  }

  /// Load from YAML string
  static YamlDomainConfig fromString(String yamlString) {
    final yaml = loadYaml(yamlString);
    return YamlDomainConfig._(_yamlToMap(yaml));
  }

  /// Convert YamlMap to regular Map
  static Map<String, dynamic> _yamlToMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return Map<String, dynamic>.from(yaml.map(
        (key, value) => MapEntry(key.toString(), _yamlToMap(value)),
      ));
    } else if (yaml is YamlList) {
      return yaml.map((item) => _yamlToMap(item)).toList();
    } else {
      return yaml;
    }
  }

  @override
  String get domainId => _config['domain']?['id'] ?? 'custom_domain';

  @override
  String get domainName => _config['domain']?['name'] ?? 'Custom Domain';

  @override
  String get metricName => _config['domain']?['metric_name'] ?? 'metric';

  @override
  String get metricUnit => _config['domain']?['metric_unit'] ?? 'units';

  @override
  String get assistantName =>
      _config['branding']?['assistant_name'] ?? 'Health Assistant';

  @override
  String get appName => _config['branding']?['app_name'] ?? 'Health App';

  @override
  IntentClassifier get intentClassifier => _intentClassifier;

  @override
  TemplateProvider get templateProvider => _templateProvider;

  @override
  DiagnosticProvider get diagnosticProvider => _diagnosticProvider;

  @override
  HealthMetricAdapter get healthAdapter => _healthAdapter;

  @override
  String? modifySystemPrompt(String basePrompt) {
    final customPrompt = _config['llm']?['system_prompt_addition'];
    if (customPrompt != null) {
      return '$basePrompt\n\n$customPrompt';
    }
    return null;
  }
}

/// YAML-based intent classifier
class YamlIntentClassifier implements IntentClassifier {
  final Map<String, dynamic> config;
  final Map<String, String> placeholders;
  late final List<_YamlIntentPattern> _patterns;

  YamlIntentClassifier({
    required this.config,
    required this.placeholders,
  }) {
    _patterns = _buildPatterns();
  }

  List<_YamlIntentPattern> _buildPatterns() {
    final patterns = <_YamlIntentPattern>[];
    final intents = config['intents'] as List? ?? [];

    for (final intentData in intents) {
      if (intentData is! Map) continue;

      final id = intentData['id'] as String?;
      final patternStrings = intentData['patterns'] as List? ?? [];
      final confidence = (intentData['confidence'] as num?)?.toDouble() ?? 0.8;

      if (id == null) continue;

      for (final patternString in patternStrings) {
        if (patternString is! String) continue;

        // Replace placeholders in pattern
        String pattern = patternString;
        for (final entry in placeholders.entries) {
          pattern = pattern.replaceAll('{{${entry.key}}}', entry.value);
        }

        patterns.add(_YamlIntentPattern(
          pattern: pattern,
          intentId: id,
          confidence: confidence,
        ));
      }
    }

    return patterns;
  }

  @override
  IntentClassificationResult classify(String input) {
    final lowercaseInput = input.toLowerCase();

    for (final pattern in _patterns) {
      if (lowercaseInput.contains(pattern.pattern.toLowerCase())) {
        return IntentClassificationResult(
          intent: UserIntent.custom(
            id: pattern.intentId,
            displayName: pattern.intentId.replaceAll('_', ' ').toUpperCase(),
          ),
          confidence: pattern.confidence,
        );
      }
    }

    // Fallback to common intents
    if (lowercaseInput.contains('hello') ||
        lowercaseInput.contains('hi') ||
        lowercaseInput.contains('hey')) {
      return IntentClassificationResult(
        intent: UserIntent.greeting,
        confidence: 0.95,
      );
    }

    if (lowercaseInput.contains('thank')) {
      return IntentClassificationResult(
        intent: UserIntent.thanks,
        confidence: 0.9,
      );
    }

    return IntentClassificationResult(
      intent: UserIntent.unknown,
      confidence: 0.5,
    );
  }

  @override
  List<UserIntent> getSupportedIntents() {
    final intents = config['intents'] as List? ?? [];

    return intents
        .where((i) => i is Map && i['id'] != null)
        .map((i) => UserIntent.custom(
              id: i['id'] as String,
              displayName: (i['display_name'] as String?) ??
                  (i['id'] as String).replaceAll('_', ' ').toUpperCase(),
            ))
        .toList();
  }
}

class _YamlIntentPattern {
  final String pattern;
  final String intentId;
  final double confidence;

  _YamlIntentPattern({
    required this.pattern,
    required this.intentId,
    required this.confidence,
  });
}

/// YAML-based template provider
class YamlTemplateProvider extends BaseTemplateProvider {
  final Map<String, dynamic> config;

  YamlTemplateProvider({
    required this.config,
    required Map<String, String> placeholders,
  }) : super(placeholders: placeholders);

  @override
  ChatMessage getResponse(UserIntent intent, {Map<String, dynamic>? context}) {
    final templates = config['templates'] as Map? ?? {};
    final template = templates[intent.id] as String?;

    if (template != null) {
      return createBotMessage(template, context: context);
    }

    // Fallback responses
    if (intent == UserIntent.greeting) {
      return getGreeting();
    } else if (intent == UserIntent.thanks) {
      return createBotMessage("You're welcome! Let me know if you need more help.");
    } else if (intent == UserIntent.help) {
      return getHelp();
    }

    return getUnknownResponse();
  }

  @override
  ChatMessage getGreeting({String? userName}) {
    final templates = config['templates'] as Map? ?? {};
    final template = templates['greeting'] as String?;

    if (template != null) {
      return createBotMessage(
        template,
        context: userName != null ? {'user_name': userName} : null,
      );
    }

    return createBotMessage(
      "Hi! I'm {{assistant_name}}. I help fix {{metric_name}} tracking issues.",
    );
  }

  @override
  ChatMessage getHelp() {
    final templates = config['templates'] as Map? ?? {};
    final template = templates['help'] as String?;

    if (template != null) {
      return createBotMessage(template);
    }

    return createBotMessage(
      "I can help you troubleshoot {{metric_name}} tracking issues. Just describe what's happening!",
    );
  }

  @override
  ChatMessage getUnknownResponse() {
    final templates = config['templates'] as Map? ?? {};
    final template = templates['unknown'] as String?;

    if (template != null) {
      return createBotMessage(template);
    }

    return createBotMessage(
      "I'm not sure I understand. Can you describe your {{metric_name}} tracking issue?",
    );
  }
}

/// YAML-based diagnostic provider
class YamlDiagnosticProvider extends BaseDiagnosticProvider {
  final Map<String, dynamic> config;

  YamlDiagnosticProvider({
    required this.config,
    required Map<String, String> placeholders,
  }) : super(placeholders: placeholders);

  @override
  Future<TrackingStatusResult> checkTrackingStatus() async {
    // YAML configs provide static diagnostic info
    // Actual diagnostics would be run by the healthAdapter
    final issues = <TrackingIssue>[];

    final diagnosticConfig = config['diagnostics'] as Map? ?? {};
    final issuesList = diagnosticConfig['issues'] as List? ?? [];

    // This is just a template - actual diagnostics happen in the adapter
    return TrackingStatusResult(
      isTracking: true,
      issues: issues,
      lastChecked: DateTime.now(),
    );
  }

  @override
  List<TrackingIssueType> getSupportedIssues() {
    final diagnosticConfig = config['diagnostics'] as Map? ?? {};
    final issuesList = diagnosticConfig['issues'] as List? ?? [];

    return issuesList
        .where((i) => i is Map && i['type'] != null)
        .map((i) => _parseIssueType(i['type'] as String))
        .where((type) => type != null)
        .cast<TrackingIssueType>()
        .toList();
  }

  @override
  Future<TrackingIssue?> checkSpecificIssue(TrackingIssueType type) async {
    // Would be implemented by the health adapter
    return null;
  }

  TrackingIssueType? _parseIssueType(String typeString) {
    switch (typeString) {
      case 'permissions_not_granted':
        return TrackingIssueType.permissionsNotGranted;
      case 'data_not_syncing':
        return TrackingIssueType.dataNotSyncing;
      case 'wrong_data_source':
        return TrackingIssueType.wrongDataSource;
      case 'conflicting_data_sources':
        return TrackingIssueType.conflictingDataSources;
      case 'battery_optimization_enabled':
        return TrackingIssueType.batteryOptimizationEnabled;
      case 'wrong_count':
        return TrackingIssueType.wrongCount;
      case 'duplicate_data':
        return TrackingIssueType.duplicateData;
      case 'app_not_installed':
        return TrackingIssueType.appNotInstalled;
      case 'device_not_supported':
        return TrackingIssueType.deviceNotSupported;
      default:
        return null;
    }
  }
}

/// YAML-based health metric adapter
///
/// This is a minimal implementation - real health data access
/// would need to be implemented separately.
class YamlHealthMetricAdapter extends BaseHealthMetricAdapter<dynamic> {
  final Map<String, dynamic> config;

  YamlHealthMetricAdapter({required this.config});

  @override
  String get metricName => config['domain']?['metric_name'] ?? 'metric';

  @override
  String get metricUnit => config['domain']?['metric_unit'] ?? 'units';

  @override
  Future<List<HealthMetricData>> getMetricData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // YAML configs don't implement actual data access
    // This would need to be overridden or use a real adapter
    return [];
  }

  @override
  Future<dynamic> getTodayValue() async => null;

  @override
  Future<dynamic> getValueForDate(DateTime date) async => null;

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
    required dynamic value,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  bool isValidValue(dynamic value) => true;
}
