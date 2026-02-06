# Health Troubleshoot ChatBot

An intelligent, **domain-agnostic** troubleshooting chatbot for **ANY** health/wellness app - steps, sleep, water, nutrition, heart rate, and more.

🔄 **Migrating from `step_sync_chatbot`?** See [Migration Guide](#migration-from-step_sync_chatbot) below.

---

## 🎯 What's This?

A production-ready Flutter package that provides conversational troubleshooting for health data syncing issues across iOS (HealthKit) and Android (Health Connect).

**Unlike traditional step-tracking-only chatbots**, this package is **completely configurable** to support any health metric:
- 🚶 **Steps & Activity** (walking, running, distance)
- 😴 **Sleep Tracking** (duration, quality, stages)
- 💧 **Water Intake** (hydration tracking)
- 🍎 **Nutrition** (calories, macros, meals)
- ❤️ **Heart Health** (heart rate, HRV, blood pressure)
- 🏃 **Workouts** (exercise sessions, calories burned)
- ⚖️ **Weight & Body Metrics** (BMI, body fat, muscle mass)
- ...and **any custom metric** you define!

---

## ✨ Features

### Core Capabilities
- ✅ **Multi-Domain Support** - Steps, sleep, nutrition, water, or custom metrics
- ✅ **Hybrid Configuration** - YAML configs for simple cases, Dart plugins for advanced customization
- ✅ **LLM-Powered Responses** - Groq, OpenAI, Gemini integration via LangChain
- ✅ **Rule-Based Intent Classification** - Fast, deterministic pattern matching for 15+ common intents
- ✅ **Automated Diagnostics** - Detects permissions, battery optimization, data conflicts, etc.
- ✅ **Conversation Memory** - Context-aware responses with encrypted persistence
- ✅ **Privacy-First** - PHI sanitization, HIPAA-compliant architecture
- ✅ **Material Design 3 UI** - Beautiful, accessible chat interface

### Architecture
- ✅ **Production-Ready** - 150+ tests, circuit breakers, rate limiting, memory management
- ✅ **Riverpod State Management** - Type-safe, testable reactive architecture
- ✅ **Clean Interfaces** - Easy to mock, test, and extend
- ✅ **Backward Compatible** - Seamless migration from `step_sync_chatbot`

---

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  health_troubleshoot_chatbot:
    path: ../packages/health_troubleshoot_chatbot
```

### Basic Usage (Steps Tracking)

```dart
import 'package:health_troubleshoot_chatbot/health_troubleshoot_chatbot.dart';

// Wrap your app with ProviderScope
void main() {
  runApp(const ProviderScope(child: MyApp()));
}

// Open chatbot for step tracking
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HealthTroubleshootChatbot.forSteps(
      config: ChatBotConfig.development(userId: 'user123'),
    ),
  ),
);
```

### Multi-Domain Support

```dart
// Sleep tracking
HealthTroubleshootChatbot.forSleep(
  config: ChatBotConfig.development(userId: 'user123'),
)

// Nutrition tracking
HealthTroubleshootChatbot.forNutrition(
  config: ChatBotConfig.development(userId: 'user123'),
)

// Custom domain from YAML file
HealthTroubleshootChatbot.fromYaml(
  yamlPath: 'assets/water_tracking.yaml',
  config: ChatBotConfig.development(userId: 'user123'),
)

// Custom domain plugin
HealthTroubleshootChatbot.fromPlugin(
  pluginId: 'my_custom_domain',
  config: ChatBotConfig.development(userId: 'user123'),
)
```

---

## 🎨 Supported Domains

### Built-in Domains

The package includes **3 production-ready domains**:

| Domain | Metric | Assistant Name | Example Issues |
|--------|--------|----------------|----------------|
| **Step Tracking** | Steps (int) | Step Sync Assistant | Steps not syncing, wrong count, duplicate data |
| **Sleep Tracking** | Hours (double) | Sleep Coach | Sleep data missing, poor quality tracking |
| **Nutrition Tracking** | Calories (int) | Nutrition Helper | Calorie count wrong, meal data not saving |

### Custom Domains

Create your own domain in **2 ways**:

#### Option 1: YAML Configuration (Simple)

Create `assets/water_tracking.yaml`:

```yaml
domain:
  id: "water_tracking"
  name: "Water Intake Tracking"
  metric_name: "water intake"
  metric_unit: "oz"

branding:
  assistant_name: "Hydration Helper"
  app_name: "My Hydration App"

intents:
  - id: "metric_not_syncing"
    patterns: ["water not tracking", "{{metric_name}} not updating"]
    confidence: 0.92

templates:
  greeting: |
    Hi! I'm {{assistant_name}}. I help fix {{metric_name}} tracking issues.

diagnostics:
  issues:
    - type: "permissions_not_granted"
      title: "Permissions Not Granted"
      description: "The app doesn't have permission to read your {{metric_name}}."
```

Load it:

```dart
HealthTroubleshootChatbot.fromYaml(
  yamlPath: 'assets/water_tracking.yaml',
  config: config,
)
```

#### Option 2: Dart Plugin (Advanced)

For complex custom logic:

```dart
class WaterTrackingPlugin extends DomainPlugin {
  @override
  String get domainId => 'water_tracking';

  @override
  String get metricName => 'water intake';

  @override
  String get metricUnit => 'oz';

  @override
  String get assistantName => 'Hydration Helper';

  @override
  IntentClassifier get intentClassifier => WaterIntentClassifier();

  @override
  TemplateProvider get templateProvider => WaterTemplateProvider(domain: this);

  @override
  DiagnosticProvider get diagnosticProvider => WaterDiagnosticProvider(domain: this);

  @override
  HealthMetricAdapter get healthAdapter => WaterMetricAdapter();

  // Optional: Customize LLM prompts
  @override
  String? modifySystemPrompt(String basePrompt) {
    return '''
$basePrompt

HYDRATION TRACKING CONTEXT:
- Recommend 8 glasses (64oz) per day
- Consider activity level and weather
''';
  }
}

// Register plugin
void main() {
  DomainPluginRegistry.register('water_tracking', () => WaterTrackingPlugin());
  runApp(MyApp());
}

// Use plugin
HealthTroubleshootChatbot.fromPlugin(
  pluginId: 'water_tracking',
  config: config,
)
```

---

## 🔧 Configuration

### Development Mode

```dart
final config = ChatBotConfig.development(
  userId: 'user123',
  groqApiKey: 'your-groq-api-key', // Optional: enables LLM
);

HealthTroubleshootChatbot.forSteps(config: config)
```

### Production Mode

```dart
final config = ChatBotConfig.production(
  userId: currentUser.id,
  groqApiKey: await getGroqApiKey(),
  backendAdapter: MyBackendAdapter(), // Custom backend integration
  healthConfig: HealthDataConfig.defaults(),
);

HealthTroubleshootChatbot.forSteps(config: config)
```

---

## 📚 Examples

See `/example` directory for:
- **Multi-Domain Example**: Switch between steps, sleep, nutrition
- **YAML Config Example**: Load custom domains from config files
- **Plugin Example**: Build advanced custom domains

---

## 🔄 Migration from `step_sync_chatbot`

### Quick Migration (5 minutes)

**Step 1**: Update `pubspec.yaml`

```yaml
dependencies:
  health_troubleshoot_chatbot:  # NEW
    path: ../packages/health_troubleshoot_chatbot
```

**Step 2**: Update imports

```dart
// OLD
import 'package:step_sync_chatbot/step_sync_chatbot.dart';

// NEW
import 'package:health_troubleshoot_chatbot/health_troubleshoot_chatbot.dart';
```

**Step 3**: Use backward-compatible API (optional)

```dart
// OLD (still works!)
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ChatScreen(config: config),
));

// NEW (recommended)
Navigator.push(context, MaterialPageRoute(
  builder: (context) => HealthTroubleshootChatbot.forSteps(config: config),
));
```

**That's it!** All existing APIs remain unchanged. Zero code changes required if you use the compatibility layer.

See detailed migration guide: [`packages/step_sync_chatbot/MIGRATION.md`](../step_sync_chatbot/MIGRATION.md)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         DomainConfig (Abstract)         │
├─────────────────────────────────────────┤
│ - domainId, metricName, metricUnit      │
│ - IntentClassifier                      │
│ - TemplateProvider                      │
│ - DiagnosticProvider                    │
│ - HealthMetricAdapter                   │
└─────────────────────────────────────────┘
                    ▲
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────────────────┐   ┌──────────────────┐
│ StepTrackingDomain│   │ SleepTrackingDomain│
├───────────────────┤   ├──────────────────┤
│ Built-in domain   │   │ Built-in domain  │
│ for step tracking │   │ for sleep        │
└───────────────────┘   └──────────────────┘
        │                       │
        └───────────┬───────────┘
                    ▼
        ┌───────────────────────┐
        │ ChatBotController      │
        ├───────────────────────┤
        │ Uses domain for:      │
        │ - Intent classification│
        │ - Response generation │
        │ - Diagnostics         │
        └───────────────────────┘
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/domain/domain_config_test.dart

# Run load tests
flutter test test/load/load_test.dart

# Run chaos tests
flutter test test/chaos/chaos_test.dart
```

**Test Coverage**: 150+ tests covering:
- Unit tests for all services
- Integration tests for multi-domain scenarios
- Load tests (100+ concurrent users)
- Chaos tests (network failures, API errors, encryption recovery)

---

## 📖 Documentation

- **[API Documentation](API_DOCUMENTATION.md)** - Complete API reference
- **[Migration Guide](../step_sync_chatbot/MIGRATION.md)** - Migrating from step_sync_chatbot
- **[YAML Config Reference](API_DOCUMENTATION.md#yaml-configuration)** - YAML config format
- **[Plugin Development Guide](API_DOCUMENTATION.md#plugin-development)** - Build custom plugins

---

## 🤝 Contributing

This is a production package for wellness apps. Contributions welcome!

### Project Structure

```
lib/
├── src/
│   ├── domain/              # Domain abstraction layer (NEW)
│   │   ├── domain_config.dart
│   │   ├── intent_classifier.dart
│   │   ├── template_provider.dart
│   │   └── domain_plugin.dart
│   ├── domains/
│   │   └── built_in/        # Built-in domains (NEW)
│   │       ├── step_tracking_domain.dart
│   │       ├── sleep_tracking_domain.dart
│   │       └── nutrition_tracking_domain.dart
│   ├── core/                # Business logic
│   ├── services/            # LLM, memory, encryption
│   ├── ui/                  # Chat UI components
│   └── data/                # Models, repositories
└── health_troubleshoot_chatbot.dart  # Public API
```

---

## 📄 License

See LICENSE file.

---

## 🙏 Acknowledgments

Built with:
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) - State management
- [LangChain](https://pub.dev/packages/langchain) - LLM integration
- [Freezed](https://pub.dev/packages/freezed) - Immutable models
- [SQLCipher](https://pub.dev/packages/sqflite_sqlcipher) - Encrypted storage

---

**Made with ❤️ for the wellness community**
