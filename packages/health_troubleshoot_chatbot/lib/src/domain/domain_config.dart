/// Core domain configuration abstraction
///
/// This is the central abstraction that makes the chatbot domain-agnostic.
/// Every domain (steps, sleep, nutrition, etc.) must provide:
/// - Domain metadata (name, metric name, units)
/// - Intent classification logic
/// - Response templates
/// - Diagnostic capabilities
/// - Health data access

import 'intent_classifier.dart';
import 'template_provider.dart';
import 'diagnostic_provider.dart';
import 'health_metric_adapter.dart';

/// Abstract base class for all domain configurations
///
/// Implementations can be:
/// 1. Built-in domains (StepTrackingDomain, SleepTrackingDomain)
/// 2. YAML-loaded domains (YamlDomainConfig)
/// 3. Custom plugins (extending DomainPlugin)
abstract class DomainConfig {
  /// Unique identifier for this domain (e.g., "step_tracking", "sleep_tracking")
  String get domainId;

  /// Human-readable domain name (e.g., "Step Tracking", "Sleep Tracking")
  String get domainName;

  /// The metric being tracked (e.g., "steps", "sleep hours", "water intake")
  String get metricName;

  /// Unit of measurement (e.g., "steps", "hours", "oz", "kcal")
  String get metricUnit;

  /// Name of the assistant (e.g., "Step Sync Assistant", "Sleep Coach")
  String get assistantName;

  /// Name of the user's app (customizable)
  String get appName;

  /// Optional: Additional branding information
  Map<String, String> get branding => {
        'assistant_name': assistantName,
        'app_name': appName,
        'metric_name': metricName,
        'metric_unit': metricUnit,
      };

  /// Intent classifier for this domain
  ///
  /// Determines user intent from their messages
  /// Example: "my steps aren't syncing" → metricNotSyncing intent
  IntentClassifier get intentClassifier;

  /// Template provider for this domain
  ///
  /// Generates chatbot responses based on intents
  /// Uses placeholders like {{metric_name}}, {{app_name}}
  TemplateProvider get templateProvider;

  /// Diagnostic provider for this domain
  ///
  /// Checks for common tracking issues (permissions, data conflicts, etc.)
  DiagnosticProvider get diagnosticProvider;

  /// Health metric adapter for this domain
  ///
  /// Handles reading/writing health data for this specific metric
  HealthMetricAdapter get healthAdapter;

  /// Get all placeholders for template rendering
  ///
  /// Returns a map of placeholder names to values:
  /// {
  ///   'metric_name': 'steps',
  ///   'metric_unit': 'steps',
  ///   'assistant_name': 'Step Sync Assistant',
  ///   'app_name': 'My Fitness App'
  /// }
  Map<String, String> getPlaceholders() {
    return {
      'metric_name': metricName,
      'metric_unit': metricUnit,
      'assistant_name': assistantName,
      'app_name': appName,
      'domain_name': domainName,
    };
  }

  /// Render a template string with this domain's placeholders
  ///
  /// Example:
  /// renderTemplate("Hi! I'm {{assistant_name}}.")
  /// → "Hi! I'm Step Sync Assistant."
  String renderTemplate(String template) {
    String result = template;
    final placeholders = getPlaceholders();

    for (final entry in placeholders.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }

    return result;
  }

  /// Optional: Modify the system prompt for LLM
  ///
  /// Allows domains to customize the LLM behavior
  /// Returns null to use default prompt
  String? modifySystemPrompt(String basePrompt) => null;

  /// Optional: Run custom diagnostics
  ///
  /// For advanced domain-specific checks
  Future<Map<String, dynamic>?> runCustomDiagnostics() =>
      Future.value(null);

  /// Optional: Handle custom actions
  ///
  /// For domain-specific user actions
  Future<void> handleCustomAction(
    String actionId,
    Map<String, dynamic> context,
  ) async {}

  @override
  String toString() {
    return 'DomainConfig(id: $domainId, name: $domainName, metric: $metricName)';
  }
}
