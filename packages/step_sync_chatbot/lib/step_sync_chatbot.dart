/// Step Sync ChatBot - An intelligent troubleshooting assistant for health data syncing.
///
/// This library provides a conversational chatbot that helps users diagnose and
/// resolve step syncing issues across iOS (HealthKit) and Android (Health Connect).
library step_sync_chatbot;

// Configuration
export 'src/config/chatbot_config.dart';

// Core
export 'src/core/chatbot_controller.dart';
export 'src/core/chatbot_state.dart';

// Data Models
export 'src/data/models/chat_message.dart';
export 'src/data/models/conversation.dart';
export 'src/data/models/diagnostic_result.dart';
export 'src/data/models/permission_state.dart';
export 'src/data/models/step_data.dart';
export 'src/data/models/user_preferences.dart';

// Data Repositories
export 'src/data/repositories/conversation_repository.dart';
export 'src/data/repositories/sqlite_conversation_repository.dart';

// Core Services
export 'src/core/diagnostic_service.dart';
export 'src/core/tracking_status_checker.dart';
export 'src/core/intelligent_diagnostic_engine.dart';

// Health Services
export 'src/health/health_service.dart';
export 'src/health/mock_health_service.dart';
export 'src/health/real_health_service.dart';

// Utilities
export 'src/utils/platform_utils.dart';

// LLM & Privacy
export 'src/llm/llm_provider.dart';
export 'src/llm/llm_response.dart';
export 'src/llm/azure_openai_provider.dart';
export 'src/llm/mock_llm_provider.dart';
export 'src/llm/hybrid_intent_router.dart';
export 'src/llm/conversation_context.dart';
export 'src/llm/llm_rate_limiter.dart';
export 'src/privacy/pii_detector.dart';
export 'src/privacy/sanitization_result.dart';

// Services
export 'src/services/groq_streaming_service.dart';
export 'src/services/voice_input_service.dart';
export 'src/services/network_monitor.dart';
export 'src/services/offline_message_queue.dart';
export 'src/services/offline_knowledge_base.dart';
export 'src/services/offline_service.dart';

// UI - Screens
export 'src/ui/screens/chat_screen.dart';

// UI - Widgets
export 'src/ui/widgets/streaming_message_widget.dart';
export 'src/ui/widgets/voice_input_button.dart';
export 'src/ui/widgets/offline_banner.dart';
