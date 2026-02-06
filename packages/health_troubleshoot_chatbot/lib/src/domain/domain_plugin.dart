/// Domain plugin system
///
/// Allows advanced users to create custom domains via Dart plugins.
/// Plugins extend DomainConfig with optional lifecycle hooks and customization.

import 'domain_config.dart';

/// Abstract plugin interface for advanced domain customization
///
/// Extends DomainConfig with lifecycle hooks and custom behavior.
///
/// Example:
/// ```dart
/// class WaterTrackingPlugin extends DomainPlugin {
///   @override
///   String get domainId => 'water_tracking_advanced';
///
///   @override
///   Future<void> initialize() async {
///     print('Loading water tracking ML model...');
///   }
///
///   @override
///   String? modifySystemPrompt(String basePrompt) {
///     return '''
/// $basePrompt
///
/// HYDRATION TRACKING CONTEXT:
/// - Recommend 8 glasses (64oz) per day
/// - Consider activity level and weather
/// ''';
///   }
/// }
/// ```
abstract class DomainPlugin extends DomainConfig {
  /// Plugin version (for compatibility checking)
  String get version => '1.0.0';

  /// Required permissions for this plugin
  ///
  /// Example: ['ACTIVITY_RECOGNITION', 'BODY_SENSORS']
  List<String> get requiredPermissions => [];

  /// Initialize plugin resources
  ///
  /// Called once when the plugin is first loaded.
  /// Use this to:
  /// - Load ML models
  /// - Initialize databases
  /// - Set up background tasks
  Future<void> initialize() async {}

  /// Dispose plugin resources
  ///
  /// Called when the plugin is unloaded.
  /// Clean up:
  /// - Database connections
  /// - Background tasks
  /// - ML models
  void dispose() {}

  /// Validate plugin configuration
  ///
  /// Returns error message if invalid, null if valid.
  String? validate() => null;

  /// Get plugin metadata
  Map<String, dynamic> getMetadata() {
    return {
      'domain_id': domainId,
      'domain_name': domainName,
      'version': version,
      'metric_name': metricName,
      'metric_unit': metricUnit,
      'required_permissions': requiredPermissions,
    };
  }
}

/// Plugin registry for registering and retrieving domain plugins
///
/// Example:
/// ```dart
/// void main() {
///   // Register plugin
///   DomainPluginRegistry.register(
///     'water_tracking',
///     () => WaterTrackingPlugin(),
///   );
///
///   runApp(MyApp());
/// }
///
/// // Use plugin
/// final plugin = DomainPluginRegistry.get('water_tracking');
/// ```
class DomainPluginRegistry {
  static final Map<String, DomainPlugin Function()> _factories = {};
  static final Map<String, DomainPlugin> _instances = {};

  /// Register a plugin factory
  ///
  /// The factory function will be called when the plugin is first requested.
  static void register(String domainId, DomainPlugin Function() factory) {
    _factories[domainId] = factory;
  }

  /// Get a plugin instance (creates if needed)
  static DomainPlugin? get(String domainId) {
    // Return cached instance if available
    if (_instances.containsKey(domainId)) {
      return _instances[domainId];
    }

    // Create new instance from factory
    final factory = _factories[domainId];
    if (factory == null) return null;

    final plugin = factory();
    _instances[domainId] = plugin;

    return plugin;
  }

  /// Get plugin without initializing (just metadata)
  static Map<String, dynamic>? getMetadata(String domainId) {
    final factory = _factories[domainId];
    if (factory == null) return null;

    final plugin = factory();
    return plugin.getMetadata();
  }

  /// Check if plugin is registered
  static bool has(String domainId) {
    return _factories.containsKey(domainId);
  }

  /// Get all registered plugin IDs
  static List<String> getRegisteredPluginIds() {
    return List.unmodifiable(_factories.keys);
  }

  /// Unregister a plugin
  static void unregister(String domainId) {
    // Dispose instance if it exists
    final instance = _instances[domainId];
    if (instance != null) {
      instance.dispose();
      _instances.remove(domainId);
    }

    _factories.remove(domainId);
  }

  /// Clear all registered plugins
  static void clear() {
    // Dispose all instances
    for (final instance in _instances.values) {
      instance.dispose();
    }

    _instances.clear();
    _factories.clear();
  }

  /// Initialize a plugin (if not already initialized)
  static Future<void> initialize(String domainId) async {
    final plugin = get(domainId);
    if (plugin != null) {
      await plugin.initialize();
    }
  }

  /// Validate a plugin
  static String? validate(String domainId) {
    final plugin = get(domainId);
    if (plugin == null) {
      return 'Plugin not found: $domainId';
    }

    return plugin.validate();
  }
}

/// Base class for simple plugins
///
/// Provides sensible defaults for common use cases.
abstract class SimpleDomainPlugin extends DomainPlugin {
  @override
  String get domainName => domainId
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  @override
  Map<String, String> get branding => {
        'assistant_name': assistantName,
        'app_name': appName,
        'metric_name': metricName,
        'metric_unit': metricUnit,
      };
}
