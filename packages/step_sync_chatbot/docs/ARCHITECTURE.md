# Step Sync ChatBot - Architecture Documentation

**Version**: 0.1.0
**Last Updated**: January 2026

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture Principles](#2-architecture-principles)
3. [Layer Breakdown](#3-layer-breakdown)
4. [Data Flow](#4-data-flow)
5. [Key Components](#5-key-components)
6. [State Management](#6-state-management)
7. [Database Schema](#7-database-schema)
8. [Security Architecture](#8-security-architecture)
9. [Performance Optimizations](#9-performance-optimizations)
10. [Extension Points](#10-extension-points)

---

## 1. System Overview

The Step Sync ChatBot is a production-ready Flutter package that provides intelligent troubleshooting for step tracking issues across iOS (HealthKit) and Android (Health Connect).

###Key Features
- 🤖 LLM-powered conversational AI (Groq/OpenAI)
- 🎯 Rule-based intent classification (fast, deterministic)
- 🔍 Automated diagnostics (permissions, data conflicts, battery)
- 💾 Encrypted conversation persistence
- 🧠 Context-aware memory management
- 🔒 HIPAA-compliant data handling

### System Context

```
┌─────────────────────────────────────────────┐
│              User's Flutter App             │
└─────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│         Step Sync ChatBot Package           │
│  ┌───────────────────────────────────────┐  │
│  │     UI Layer (ChatScreen)             │  │
│  └───────────────────────────────────────┘  │
│                   │                          │
│  ┌───────────────────────────────────────┐  │
│  │  Business Logic (Controllers)         │  │
│  └───────────────────────────────────────┘  │
│                   │                          │
│  ┌───────────────────────────────────────┐  │
│  │  Services (Health, LLM, Memory)       │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
┌────────────────┐        ┌──────────────────┐
│  Health APIs   │        │   LLM APIs       │
│  (HealthKit/   │        │   (Groq/OpenAI)  │
│ Health Connect)│        │                  │
└────────────────┘        └──────────────────┘
```

---

## 2. Architecture Principles

### Clean Architecture (Uncle Bob)

The system follows a strict 3-tier architecture with dependency inversion:

```
Presentation → Orchestration → Service
   (UI)           (Logic)        (Data)
```

**Dependency Rule**: Dependencies point inward
- UI depends on Logic
- Logic depends on Services
- Services depend on nothing (or external APIs)

### SOLID Principles

- **S**ingle Responsibility: Each class has one reason to change
- **O**pen/Closed: Open for extension, closed for modification
- **L**iskov Substitution: Interfaces enable testability
- **I**nterface Segregation: Small, focused interfaces
- **D**ependency Inversion: Depend on abstractions, not concretions

### Design Patterns

| Pattern | Usage | Location |
|---------|-------|----------|
| **Repository** | Data access abstraction | `ConversationRepository` |
| **Strategy** | LLM/Intent routing | `ResponseStrategySelector` |
| **Factory** | Service creation | `ChatBotConfig` |
| **Observer** | State notifications | Riverpod |
| **Adapter** | Backend abstraction | `BackendAdapter` |
| **Circuit Breaker** | Fault tolerance | `LLMCircuitBreaker` |
| **Template Method** | Intent classification | `IntentClassifier` |

---

## 3. Layer Breakdown

### Layer 1: Presentation (UI)

**Responsibility**: User interface and user interaction

```dart
lib/src/ui/
├── screens/
│   └── chat_screen.dart         # Main chat UI
├── widgets/
│   ├── chat_message_widget.dart # Message bubbles
│   ├── chat_input.dart          # Input field
│   ├── diagnostic_card.dart     # Issue display
│   └── typing_indicator.dart    # Loading state
└── theme/
    └── chat_theme.dart          # Material Design 3
```

**Key Components:**
- `ChatScreen`: Main widget, coordinates UI
- `ChatMessage Widget`: User/bot message bubbles
- `DiagnosticCard`: Visual issue display
- `ChatInput`: Message input with validation

**State Management**: Riverpod `StateNotifier`

---

### Layer 2: Orchestration (Business Logic)

**Responsibility**: Application logic, use cases, coordination

```dart
lib/src/core/
├── chatbot_controller.dart      # Main controller
├── chatbot_state.dart           # State model
├── diagnostic_service.dart      # Issue detection
├── tracking_status_checker.dart # Health data checks
├── intelligent_diagnostic_engine.dart
├── conversation_templates.dart  # Response templates
└── rule_based_intent_classifier.dart
```

**Key Controllers:**

#### ChatBotController
```dart
class ChatBotController extends StateNotifier<ChatBotState> {
  // Dependencies (injected)
  final HealthService healthService;
  final LLMProvider llmProvider;
  final BackendAdapter backendAdapter;
  final ThreadSafeMemoryManager memoryManager;

  // Public API
  Future<void> sendMessage(String message);
  Future<void> runDiagnostic();
  Future<void> checkPermissions();
}
```

**Responsibilities:**
- Coordinate message flow
- Trigger diagnostics
- Manage conversation state
- Handle errors gracefully

---

### Layer 3: Service (Data & External APIs)

**Responsibility**: Data access, external API integration

```dart
lib/src/services/
├── groq_chat_service.dart       # Groq LLM integration
├── conversation_memory_manager.dart
├── thread_safe_memory_manager.dart
├── conversation_persistence_service.dart
├── memory_monitor.dart          # Memory tracking
└── phi_sanitizer.dart           # PII removal

lib/src/health/
├── health_service.dart          # Abstract interface
├── real_health_service.dart     # Production impl
└── mock_health_service.dart     # Testing impl

lib/src/llm/
├── llm_provider.dart            # Abstract interface
├── groq_llm_provider.dart       # Groq impl
├── azure_openai_provider.dart   # Azure impl
├── mock_llm_provider.dart       # Testing impl
├── llm_rate_limiter.dart        # Rate limiting
└── hybrid_intent_router.dart    # Route: rule vs LLM
```

---

## 4. Data Flow

### User Message Flow

```
1. User types message
   │
   ▼
2. ChatScreen captures input
   │
   ▼
3. ChatBotController.sendMessage()
   │
   ├──> 4a. Add to MemoryManager
   │    └──> ThreadSafeMemoryManager
   │         └──> ConversationPersistenceService (SQLite)
   │
   ├──> 4b. Sanitize PHI
   │    └──> PHISanitizer.sanitize()
   │
   ├──> 4c. Classify Intent
   │    └──> RuleBasedIntentClassifier.classify()
   │
   └──> 4d. Generate Response
        │
        ├──> Rule-based? → ConversationTemplates
        │
        └──> LLM-based? → HybridIntentRouter
             │
             ├──> Circuit Breaker Check
             │
             ├──> Rate Limiter Check
             │
             └──> LLMProvider.generateResponse()
                  └──> Groq API call
   │
   ▼
5. Response added to state
   │
   ▼
6. ChatScreen rebuilds (Riverpod)
   │
   ▼
7. User sees response
```

### Diagnostic Flow

```
1. User clicks "Run Diagnostic"
   │
   ▼
2. DiagnosticService.runFullDiagnostic()
   │
   ├──> Check Permissions
   │    └──> HealthService.checkPermissions()
   │         └──> HealthKit/Health Connect
   │
   ├──> Check Data Sources
   │    └──> HealthService.getDataSources()
   │
   ├──> Check Step Count
   │    └──> HealthService.getStepData()
   │
   ├──> Detect Conflicts
   │    └──> IntelligentDiagnosticEngine.analyze()
   │
   └──> Generate Report
        └──> TrackingStatusResult
   │
   ▼
3. Display issues in UI
```

---

## 5. Key Components

### 5.1 Health Service

**Purpose**: Abstract health data access across platforms

```dart
abstract class HealthService {
  Future<List<StepData>> getStepData({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<DataSource>> getDataSources();
  Future<bool> requestPermissions();
  Future<PermissionState> checkPermissions();
}
```

**Implementations:**
- `RealHealthService`: Production (HealthKit/Health Connect)
- `MockHealthService`: Testing/Development

**Platform Differences Handled:**
- iOS: HealthKit queries
- Android: Health Connect queries
- Abstracted via interface

---

### 5.2 LLM Provider

**Purpose**: Abstract LLM API calls

```dart
abstract class LLMProvider {
  Future<LLMResponse> generateResponse({
    required List<ConversationMessage> messages,
    required String systemPrompt,
  });
}
```

**Implementations:**
- `GroqLLMProvider`: Groq API (fast, cheap)
- `AzureOpenAIProvider`: Azure OpenAI
- `MockLLMProvider`: Testing

**Features:**
- Circuit breaker (5 failures → open)
- Rate limiting (10 req/min)
- Retry with exponential backoff
- Timeout handling (30s)

---

### 5.3 Memory Manager

**Purpose**: Manage conversation history with thread safety

```dart
class ThreadSafeMemoryManager {
  // Per-session locks (allow concurrent different sessions)
  final Map<String, Lock> _sessionLocks;

  // Global lock (for cross-session operations)
  final Lock _globalLock;

  Future<void> addMessage(String sessionId, ConversationMessage msg);
  Future<List<ConversationMessage>> getHistory(String sessionId);
  Future<void> clearSession(String sessionId);
}
```

**Features:**
- Per-session locking (fine-grained)
- Automatic trimming (maxMessages limit)
- Memory monitoring (alerts at 80%, 95%)
- Persistence integration (SQLite)

---

### 5.4 Intent Classifier

**Purpose**: Determine user intent from message

```dart
class RuleBasedIntentClassifier {
  IntentClassificationResult classify(String input) {
    // Pattern matching (regex)
    for (final pattern in _patterns) {
      if (pattern.regex.hasMatch(input)) {
        return IntentClassificationResult(
          intent: pattern.intent,
          confidence: pattern.confidence,
        );
      }
    }

    return IntentClassificationResult(
      intent: UserIntent.unclear,
      confidence: 0.5,
    );
  }
}
```

**Supported Intents:**
- `stepsNotSyncing`
- `wrongStepCount`
- `duplicateSteps`
- `permissionDenied`
- `multipleDataSources`
- `batteryOptimizationIssue`
- `greeting`, `thanks`, `needHelp`

---

## 6. State Management

### Riverpod Architecture

```dart
// State Provider
final chatBotControllerProvider =
    StateNotifierProvider.autoDispose<ChatBotController, ChatBotState>(
  (ref) => ChatBotController(
    healthService: ref.watch(healthServiceProvider),
    llmProvider: ref.watch(llmProviderProvider),
    memoryManager: ref.watch(memoryManagerProvider),
  ),
);

// State Model (Freezed)
@freezed
class ChatBotState with _$ChatBotState {
  const factory ChatBotState({
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isLoading,
    @Default(false) bool isProcessing,
    TrackingStatusResult? diagnosticResult,
    String? error,
  }) = _ChatBotState;
}
```

**State Lifecycle:**
1. User interaction → Controller method called
2. Controller updates state → `state = state.copyWith(...)`
3. Riverpod notifies listeners
4. UI rebuilds automatically

---

## 7. Database Schema

### SQLite Tables (Encrypted with SQLCipher)

#### `sessions` Table
```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  start_time INTEGER NOT NULL,
  last_activity_time INTEGER NOT NULL,
  created_at INTEGER DEFAULT CURRENT_TIMESTAMP
);
```

#### `messages` Table
```sql
CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  content TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  timestamp INTEGER NOT NULL,
  metadata TEXT,  -- JSON
  created_at INTEGER DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);

CREATE INDEX idx_messages_session ON messages(session_id);
CREATE INDEX idx_messages_timestamp ON messages(timestamp);
```

### Data Lifecycle

```
1. Message sent → In-memory (ConversationMemoryManager)
   │
   ▼
2. Persisted to SQLite (ConversationPersistenceService)
   │
   ▼
3. Encrypted at rest (SQLCipher)
   │
   ▼
4. Auto-trimmed when exceeds maxMessages (20 default)
   │
   ▼
5. Session expires after 24 hours of inactivity
```

---

## 8. Security Architecture

### 8.1 Data Encryption

**At-Rest Encryption:**
```dart
// SQLCipher encryption
final db = await openDatabase(
  path,
  password: await SecureStorage.getDBKey(),
  version: 1,
);
```

**Key Storage:**
```dart
// flutter_secure_storage (iOS Keychain, Android KeyStore)
final storage = FlutterSecureStorage();
await storage.write(key: 'db_encryption_key', value: key);
```

---

### 8.2 PHI Sanitization

**Before sending to LLM:**
```dart
final sanitized = PHISanitizer.sanitize(userMessage);
// Removes: emails, phones, SSN, credit cards, addresses
```

**Patterns Detected:**
- Email addresses
- Phone numbers (US/International)
- Social Security Numbers
- Credit card numbers
- Street addresses
- Names (via NER)

---

### 8.3 API Security

**Rate Limiting:**
```dart
final rateLimiter = LLMRateLimiter(
  maxRequestsPerMinute: 10,
  maxRequestsPerHour: 100,
);
```

**Circuit Breaker:**
```dart
final circuitBreaker = LLMCircuitBreaker(
  failureThreshold: 5,
  resetTimeout: Duration(seconds: 30),
);
```

**API Key Security:**
```dart
// ❌ NEVER hardcode
const apiKey = 'sk-...';

// ✅ Load securely
final apiKey = await SecureStorage.getGroqKey();
```

---

## 9. Performance Optimizations

### 9.1 Memory Management

**Automatic Trimming:**
- Per-session limit: 20 messages (configurable)
- Global limit: 50MB (configurable)
- Oldest messages removed first (FIFO)

**Memory Monitoring:**
```dart
MemoryMonitor(
  config: MemoryMonitorConfig(
    maxSessionBytes: 5 * 1024 * 1024,  // 5MB
    maxGlobalBytes: 50 * 1024 * 1024,   // 50MB
    warningThreshold: 0.8,              // 80%
    criticalThreshold: 0.95,            // 95%
  ),
)
```

---

### 9.2 Thread Safety

**Lock Granularity:**
- Per-session locks (allow concurrent access to different sessions)
- Global lock only for cross-session operations

**Benefits:**
- 50+ concurrent users without contention
- No deadlocks (deterministic lock ordering)

---

### 9.3 Database Optimizations

**Indexes:**
```sql
CREATE INDEX idx_messages_session ON messages(session_id);
CREATE INDEX idx_messages_timestamp ON messages(timestamp);
```

**Batch Operations:**
```dart
// Batch insert (single transaction)
await db.transaction((txn) async {
  for (final msg in messages) {
    await txn.insert('messages', msg.toJson());
  }
});
```

---

## 10. Extension Points

### 10.1 Custom Backend Adapter

```dart
abstract class BackendAdapter {
  Future<void> logConversation(ConversationSession session);
  Future<void> reportIssue(TrackingIssue issue);
  Future<UserPreferences?> getUserPreferences(String userId);
}

// Implement your own
class MyBackendAdapter implements BackendAdapter {
  @override
  Future<void> logConversation(ConversationSession session) async {
    await myApi.post('/conversations', session.toJson());
  }
}
```

---

### 10.2 Custom LLM Provider

```dart
class MyCustomLLMProvider implements LLMProvider {
  @override
  Future<LLMResponse> generateResponse({
    required List<ConversationMessage> messages,
    required String systemPrompt,
  }) async {
    final response = await myLLMApi.chat(messages);
    return LLMResponse(content: response.text);
  }
}
```

---

### 10.3 Custom Health Service

```dart
class MyHealthService implements HealthService {
  @override
  Future<List<StepData>> getStepData(...) async {
    // Custom logic for fetching step data
  }
}
```

---

## Summary

The Step Sync ChatBot follows a **clean, 3-tier architecture** with:

✅ **Clear separation of concerns** (UI → Logic → Data)
✅ **Dependency inversion** (interfaces, not implementations)
✅ **Production-grade resilience** (circuit breakers, retries, graceful degradation)
✅ **HIPAA-compliant security** (encryption, PHI sanitization)
✅ **Comprehensive testing** (unit, integration, load, chaos)
✅ **Extensibility** (adapters, providers, plugins)

The architecture is designed for **scalability**, **maintainability**, and **production deployment**.

---

**Document Version**: 1.0
**Last Updated**: January 20, 2026
**Next Review**: As needed for major architecture changes
