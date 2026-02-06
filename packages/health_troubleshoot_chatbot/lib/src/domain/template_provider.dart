/// Response template abstraction
///
/// Provides chatbot responses for different intents.
/// Supports placeholders like {{metric_name}}, {{app_name}}.

import '../data/models/chat_message.dart';
import 'intent_classifier.dart';

/// Abstract template provider
///
/// Each domain implements this to provide domain-specific responses.
abstract class TemplateProvider {
  /// Get response for a given intent
  ///
  /// context can include:
  /// - user_name: User's name
  /// - metric_value: Current metric value
  /// - data_sources: Available data sources
  /// - diagnostic_results: Results from diagnostics
  ChatMessage getResponse(
    UserIntent intent, {
    Map<String, dynamic>? context,
  });

  /// Get greeting message
  ChatMessage getGreeting({String? userName});

  /// Get help message
  ChatMessage getHelp();

  /// Get unknown intent fallback message
  ChatMessage getUnknownResponse();

  /// Get all placeholder names used in templates
  ///
  /// Returns placeholders like:
  /// ['metric_name', 'metric_unit', 'assistant_name', 'app_name']
  List<String> getPlaceholderNames();
}

/// Template renderer utility
///
/// Handles placeholder substitution in template strings.
class TemplateRenderer {
  /// Render a template with placeholders
  ///
  /// Example:
  /// render("Hi! I'm {{assistant_name}}.", {'assistant_name': 'Step Sync Assistant'})
  /// → "Hi! I'm Step Sync Assistant."
  static String render(
    String template,
    Map<String, String> placeholders,
  ) {
    String result = template;

    for (final entry in placeholders.entries) {
      // Handle both {{key}} and {key} formats
      result = result.replaceAll('{{${entry.key}}}', entry.value);
      result = result.replaceAll('{${entry.key}}', entry.value);
    }

    return result;
  }

  /// Render a template with dynamic placeholders
  ///
  /// Converts all values to strings automatically
  static String renderDynamic(
    String template,
    Map<String, dynamic> placeholders,
  ) {
    final stringPlaceholders = placeholders.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return render(template, stringPlaceholders);
  }

  /// Extract placeholders from a template string
  ///
  /// Example:
  /// extractPlaceholders("Hi {{name}}, you have {{count}} {{metric_name}}.")
  /// → ['name', 'count', 'metric_name']
  static List<String> extractPlaceholders(String template) {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    final matches = regex.allMatches(template);

    return matches.map((m) => m.group(1)!).toList();
  }

  /// Check if template has all required placeholders filled
  static bool hasUnfilledPlaceholders(String rendered) {
    return rendered.contains(RegExp(r'\{\{.*?\}\}'));
  }

  /// Get list of unfilled placeholders in rendered text
  static List<String> getUnfilledPlaceholders(String rendered) {
    return extractPlaceholders(rendered);
  }
}

/// Base class for template providers
///
/// Provides common functionality for domain-specific template providers.
abstract class BaseTemplateProvider implements TemplateProvider {
  final Map<String, String> placeholders;

  const BaseTemplateProvider({required this.placeholders});

  /// Render a template with this provider's placeholders
  String renderTemplate(String template, {Map<String, dynamic>? context}) {
    final allPlaceholders = Map<String, String>.from(placeholders);

    // Add context values
    if (context != null) {
      allPlaceholders.addAll(
        context.map((key, value) => MapEntry(key, value.toString())),
      );
    }

    return TemplateRenderer.render(template, allPlaceholders);
  }

  /// Create a bot message from template
  ChatMessage createBotMessage(
    String template, {
    Map<String, dynamic>? context,
  }) {
    return ChatMessage.bot(
      text: renderTemplate(template, context: context),
    );
  }

  @override
  List<String> getPlaceholderNames() {
    return placeholders.keys.toList();
  }
}
