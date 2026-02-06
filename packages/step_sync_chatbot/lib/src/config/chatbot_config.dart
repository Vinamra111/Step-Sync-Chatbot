import 'package:flutter/material.dart';
import 'backend_adapter.dart';
import 'health_config.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/repositories/sqlite_conversation_repository.dart';
import '../health/health_service.dart';
import '../health/mock_health_service.dart';
import '../health/real_health_service.dart';

/// Configuration for the Step Sync ChatBot.
///
/// This class defines all the configuration needed to integrate the chatbot
/// into a host application, including backend integration, authentication,
/// and customization options.
class ChatBotConfig {
  /// Adapter for backend communication (conversation history, preferences, etc.)
  final ChatBotBackendAdapter backendAdapter;

  /// Provider function that returns the current user's authentication token.
  /// Called whenever the chatbot needs to make authenticated requests.
  final Future<String?> Function() authProvider;

  /// Configuration for health data integration.
  final HealthDataConfig healthConfig;

  /// Health service implementation to use.
  /// If null, uses RealHealthService by default in production.
  final HealthService? healthService;

  /// Conversation repository for persisting chat history.
  /// If null, conversations are not persisted.
  final ConversationRepository? conversationRepository;

  /// Whether to load previous conversation on initialization.
  final bool loadPreviousConversation;

  /// Optional custom theme for the chatbot UI.
  /// If null, uses default Material Design theme.
  final ThemeData? theme;

  /// Whether to enable debug logging.
  final bool debugMode;

  /// User ID for the current user.
  /// Used for conversation history and preferences.
  final String userId;

  /// Groq API key for LLM-powered conversation generation.
  /// Required for intelligent, context-aware responses.
  /// Get your API key from: https://console.groq.com
  final String? groqApiKey;

  /// Whether to enable LLM-powered responses (requires groqApiKey).
  /// If false, chatbot uses template-based responses only.
  final bool enableLLM;

  const ChatBotConfig({
    required this.backendAdapter,
    required this.authProvider,
    required this.healthConfig,
    required this.userId,
    this.healthService,
    this.conversationRepository,
    this.loadPreviousConversation = false,
    this.theme,
    this.debugMode = false,
    this.groqApiKey,
    this.enableLLM = true,
  });

  /// Creates a minimal configuration for testing/development.
  ///
  /// Uses local-only backend adapter, mock health service, and no persistence.
  factory ChatBotConfig.development({
    required String userId,
    HealthDataConfig? healthConfig,
    bool useMockService = true,
    bool enablePersistence = false,
    String? groqApiKey,
    bool enableLLM = false,
  }) {
    return ChatBotConfig(
      backendAdapter: LocalOnlyBackendAdapter(),
      authProvider: () async => null,
      healthConfig: healthConfig ?? HealthDataConfig.defaults(),
      healthService: useMockService ? MockHealthService() : null,
      conversationRepository:
          enablePersistence ? SQLiteConversationRepository() : null,
      loadPreviousConversation: enablePersistence,
      userId: userId,
      debugMode: true,
      groqApiKey: groqApiKey,
      enableLLM: enableLLM,
    );
  }

  /// Creates a production configuration with real health service and persistence.
  ///
  /// Uses provided backend adapter, real HealthSync SDK integration, and SQLite persistence.
  factory ChatBotConfig.production({
    required ChatBotBackendAdapter backendAdapter,
    required Future<String?> Function() authProvider,
    required String userId,
    HealthDataConfig? healthConfig,
    ThemeData? theme,
    bool enablePersistence = true,
    bool loadPreviousConversation = true,
    String? groqApiKey,
    bool enableLLM = true,
  }) {
    return ChatBotConfig(
      backendAdapter: backendAdapter,
      authProvider: authProvider,
      healthConfig: healthConfig ?? HealthDataConfig.defaults(),
      healthService: RealHealthService(),
      conversationRepository:
          enablePersistence ? SQLiteConversationRepository() : null,
      loadPreviousConversation: loadPreviousConversation && enablePersistence,
      userId: userId,
      theme: theme,
      debugMode: false,
      groqApiKey: groqApiKey,
      enableLLM: enableLLM,
    );
  }
}
