import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'chatbot_state.dart';
import 'diagnostic_service.dart';
import 'tracking_status_checker.dart';
import 'intelligent_diagnostic_engine.dart';
import '../data/models/chat_message.dart';
import '../data/models/conversation.dart';
import '../data/models/diagnostic_result.dart';
import '../data/models/permission_state.dart';
import '../data/repositories/conversation_repository.dart';
import '../health/health_service.dart';
import '../utils/platform_utils.dart';
import 'rule_based_intent_classifier.dart';
import 'conversation_templates.dart';
import 'intents.dart';
import '../conversation/conversation_context.dart';
import '../conversation/llm_response_generator.dart';
import '../conversation/response_strategy_selector.dart';
import '../services/groq_chat_service.dart';
import '../services/phi_sanitizer_service.dart';

/// Controller for the chatbot that manages conversation state and orchestrates responses.
class ChatBotController extends StateNotifier<ChatBotState> {
  final HealthService _healthService;
  final RuleBasedIntentClassifier _intentClassifier;
  final ConversationRepository? _conversationRepository;
  final String? _userId;
  late final DiagnosticService _diagnosticService;
  late final TrackingStatusChecker _trackingStatusChecker;
  late final IntelligentDiagnosticEngine _intelligentDiagnosticEngine;
  String? _currentConversationId;

  // === LLM-powered conversation intelligence ===
  final ConversationContext _conversationContext = ConversationContext();
  final bool _enableLLM;
  final Logger _logger;
  LLMResponseGenerator? _llmGenerator;
  ResponseStrategySelector? _strategySelector;

  ChatBotController({
    required HealthService healthService,
    ConversationRepository? conversationRepository,
    String? userId,
    String? groqApiKey,
    bool enableLLM = true,
    Logger? logger,
  })  : _healthService = healthService,
        _conversationRepository = conversationRepository,
        _userId = userId,
        _intentClassifier = RuleBasedIntentClassifier(),
        _enableLLM = enableLLM && groqApiKey != null,
        _logger = logger ?? Logger(),
        super(ChatBotState.initial()) {
    _diagnosticService = DiagnosticService(healthService: healthService);
    _trackingStatusChecker = TrackingStatusChecker(healthService: healthService);
    _intelligentDiagnosticEngine = IntelligentDiagnosticEngine(healthService: healthService);

    // Initialize LLM services if enabled
    if (_enableLLM && groqApiKey != null) {
      _logger.i('Initializing LLM-powered conversation system');

      // Initialize Groq chat service
      final groqService = GroqChatService(
        config: GroqChatConfig(apiKey: groqApiKey),
        logger: _logger,
      );

      // Initialize PHI sanitizer
      final phiSanitizer = PHISanitizerService(strictMode: true);

      // Initialize LLM response generator
      _llmGenerator = LLMResponseGenerator(
        groqService: groqService,
        phiSanitizer: phiSanitizer,
        logger: _logger,
      );

      // Initialize response strategy selector
      _strategySelector = ResponseStrategySelector(
        logger: _logger,
        templateConfidenceThreshold: 0.85,
      );

      _logger.i('LLM conversation system initialized successfully');
    } else {
      _logger.w('LLM disabled - using template-based responses only');
    }
  }

  /// Initialize the chatbot.
  Future<void> initialize({bool loadPreviousConversation = false}) async {
    try {
      // Initialize repository if available
      if (_conversationRepository != null) {
        await _conversationRepository!.initialize();
      }

      // Load previous conversation if requested
      if (loadPreviousConversation &&
          _conversationRepository != null &&
          _userId != null) {
        final previousConversation =
            await _conversationRepository!.loadMostRecentConversation(_userId!);

        if (previousConversation != null &&
            previousConversation.messages.isNotEmpty) {
          // Restore previous conversation
          _currentConversationId = previousConversation.id;
          state = state.copyWith(
            messages: previousConversation.messages,
          );
          return; // Skip initialization greeting if restoring conversation
        }
      }

      // Initialize health service
      await _healthService.initialize();

      // Create new conversation
      if (_userId != null) {
        _currentConversationId = _generateConversationId();
      }

      // Run diagnostics FIRST, then send greeting with results
      await _sendGreetingWithDiagnostics();
    } catch (e) {
      state = state.copyWith(
        status: ConversationStatus.error,
        errorMessage: 'Failed to initialize: $e',
      );
    }
  }

  /// Handle user message.
  Future<void> handleUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage.user(text: text);
    _addMessage(userMessage);

    // Set processing state
    state = state.copyWith(
      status: ConversationStatus.processing,
      isTyping: true,
    );

    try {
      // Classify intent
      final intentResult = _intentClassifier.classify(text);

      // Add to conversation context
      _conversationContext.addUserMessage(
        text,
        detectedIntent: intentResult.intent.name,
      );

      // === LLM-POWERED RESPONSE GENERATION ===
      if (_enableLLM && _llmGenerator != null && _strategySelector != null) {
        // Select response strategy (template vs LLM vs hybrid)
        final strategy = _strategySelector!.selectStrategy(
          intent: intentResult.intent,
          context: _conversationContext,
          intentConfidence: intentResult.confidence,
        );

        _logger.d('Response strategy selected: ${strategy.name}');

        // Generate response based on strategy
        if (strategy == ResponseStrategy.llm) {
          // === LLM-POWERED RESPONSE ===
          await _handleIntentWithLLM(
            intentResult.intent,
            text,
            intentResult.entities,
          );
        } else if (strategy == ResponseStrategy.hybrid) {
          // === HYBRID RESPONSE (template + LLM enhancement) ===
          await _handleIntentHybrid(
            intentResult.intent,
            text,
            intentResult.entities,
          );
        } else {
          // === TEMPLATE RESPONSE ===
          await _handleIntent(intentResult.intent, intentResult.entities);
        }
      } else {
        // LLM disabled - use template-based flow
        await _handleIntent(intentResult.intent, intentResult.entities);
      }
    } catch (e) {
      _handleError('Failed to process message: $e');
    } finally {
      state = state.copyWith(
        isTyping: false,
        status: ConversationStatus.idle,
      );
    }
  }

  /// Handle a classified intent.
  Future<void> _handleIntent(
    UserIntent intent,
    Map<String, dynamic> entities,
  ) async {
    switch (intent) {
      case UserIntent.wantToGrantPermission:
        await _handlePermissionRequest();
        break;

      case UserIntent.checkingStatus:
        await _handleStatusCheck();
        break;

      case UserIntent.stepsNotSyncing:
        await _handleStepsNotSyncing();
        break;

      default:
        // For other intents, use template response
        final response = ConversationTemplates.getResponse(intent);
        await _sendBotMessage(response);
    }
  }

  /// Handle permission request.
  Future<void> _handlePermissionRequest() async {
    state = state.copyWith(status: ConversationStatus.checkingPermissions);

    await _sendBotMessage(
      ChatMessage.bot(
        text: 'Opening permission settings...\n\n'
            'Please select:\n✓ Steps\n✓ Activity\n\nThen tap "Allow".',
      ),
    );

    try {
      final permissionState = await _healthService.requestPermissions();
      state = state.copyWith(permissionState: permissionState);

      if (permissionState.status == PermissionStatus.granted) {
        await _sendBotMessage(
          ChatMessage.bot(
            text: 'Thanks! Permissions granted. ✓\n\n'
                'Syncing your steps now...',
          ),
        );

        // Fetch recent step data
        await _fetchRecentStepData();

        await _sendBotMessage(
          ChatMessage.bot(
            text: 'All set! Your step tracking is working. 🎉',
            quickReplies: [
              QuickReply(label: 'Show my steps', value: 'show_steps'),
              QuickReply(label: 'All good', value: 'done'),
            ],
          ),
        );
      } else {
        await _sendBotMessage(
          ChatMessage.bot(
            text: 'Permissions were not granted. To use step tracking, '
                'I need permission to access your step data.\n\n'
                'Would you like to try again?',
            quickReplies: [
              QuickReply(label: 'Try again', value: 'grant_permission'),
              QuickReply(label: 'Not now', value: 'not_now'),
            ],
          ),
        );
      }
    } catch (e) {
      _handleError('Failed to request permissions: $e');
    }

    state = state.copyWith(status: ConversationStatus.idle);
  }

  /// Handle status check with comprehensive diagnostics.
  Future<void> _handleStatusCheck() async {
    await _sendBotMessage(
      ChatMessage.bot(
        text: 'Let me run a comprehensive diagnostic...\n\n'
            'Checking:\n• Platform availability\n• Permissions\n• Data sources\n• System configuration',
      ),
    );

    state = state.copyWith(status: ConversationStatus.diagnosing);

    try {
      // Run comprehensive diagnostics
      final diagnosticResult = await _diagnosticService.runDiagnostics();

      // Update state with diagnostic data
      state = state.copyWith(
        permissionState: diagnosticResult.permissionState,
        dataSources: diagnosticResult.dataSources,
        recentStepData: diagnosticResult.recentStepData,
      );

      // Format and send diagnostic report
      final reportText = _diagnosticService.formatDiagnosticReport(diagnosticResult);
      await _sendBotMessage(ChatMessage.bot(text: reportText));

      // Offer quick actions based on issues found
      if (diagnosticResult.issues.isNotEmpty) {
        await _offerDiagnosticActions(diagnosticResult);
      }
    } catch (e) {
      _handleError('Failed to run diagnostics: $e');
    }

    state = state.copyWith(status: ConversationStatus.idle);
  }

  /// Offer quick actions based on diagnostic issues.
  Future<void> _offerDiagnosticActions(DiagnosticResult result) async {
    final quickReplies = <QuickReply>[];

    for (final issue in result.issues) {
      if (issue.action != null) {
        quickReplies.add(_actionToQuickReply(issue.action!));
      }
    }

    if (quickReplies.isNotEmpty) {
      await _sendBotMessage(
        ChatMessage.bot(
          text: 'What would you like to do?',
          quickReplies: quickReplies,
        ),
      );
    }
  }

  /// Convert diagnostic action to quick reply button.
  QuickReply _actionToQuickReply(IssueAction action) {
    switch (action) {
      case IssueAction.grantPermissions:
        return QuickReply(label: 'Grant permissions', value: 'grant_permission');
      case IssueAction.installHealthConnect:
        return QuickReply(label: 'Install Health Connect', value: 'install_health_connect');
      case IssueAction.openBatterySettings:
        return QuickReply(label: 'Fix battery settings', value: 'open_battery_settings');
      case IssueAction.openAppSettings:
        return QuickReply(label: 'Open app settings', value: 'open_app_settings');
      case IssueAction.selectPrimarySource:
        return QuickReply(label: 'Select primary source', value: 'select_primary_source');
      case IssueAction.contactSupport:
        return QuickReply(label: 'Contact support', value: 'contact_support');
    }
  }

  /// Handle diagnostic action (opening settings, installing apps, etc.).
  Future<void> handleDiagnosticAction(String action) async {
    switch (action) {
      case 'install_health_connect':
        await _handleInstallHealthConnect();
        break;
      case 'open_battery_settings':
        await _handleOpenBatterySettings();
        break;
      case 'open_app_settings':
        await _handleOpenAppSettings();
        break;
      default:
        // Let normal intent handling take care of it
        await handleUserMessage(action);
    }
  }

  /// Handle Health Connect installation.
  Future<void> _handleInstallHealthConnect() async {
    await _sendBotMessage(
      ChatMessage.bot(
        text: 'Opening Google Play Store...\n\n'
            'Please install "Health Connect by Google" and return here when done.',
      ),
    );

    final opened = await PlatformUtils.openHealthConnectPlayStore();

    if (!opened) {
      await _sendBotMessage(
        ChatMessage.bot(
          text: 'Could not open Play Store automatically.\n\n'
              'Please search for "Health Connect" in the Play Store and install it.',
        ),
      );
    }
  }

  /// Handle opening battery settings.
  Future<void> _handleOpenBatterySettings() async {
    await _sendBotMessage(
      ChatMessage.bot(
        text: 'Opening battery settings...\n\n'
            'Find this app in the list and disable battery optimization.',
      ),
    );

    final opened = await PlatformUtils.openBatteryOptimizationSettings();

    if (!opened) {
      await _sendBotMessage(
        ChatMessage.bot(
          text: 'Could not open settings automatically.\n\n'
              'Please go to Settings > Apps > [This App] > Battery > Unrestricted',
        ),
      );
    }
  }

  /// Handle opening app settings.
  Future<void> _handleOpenAppSettings() async {
    await _sendBotMessage(
      ChatMessage.bot(
        text: 'Opening app settings...',
      ),
    );

    final opened = await PlatformUtils.openAppSettings();

    if (!opened) {
      await _sendBotMessage(
        ChatMessage.bot(
          text: 'Could not open settings automatically.\n\n'
              'Please go to Settings > Apps > [This App]',
        ),
      );
    }
  }

  /// Handle steps not syncing issue.
  Future<void> _handleStepsNotSyncing() async {
    await _sendBotMessage(
      ConversationTemplates.getResponse(UserIntent.stepsNotSyncing),
    );
  }

  /// Handle intent with LLM-powered response generation.
  Future<void> _handleIntentWithLLM(
    UserIntent intent,
    String userMessage,
    Map<String, dynamic> entities,
  ) async {
    _logger.d('Generating LLM-powered response for intent: ${intent.name}');

    try {
      // Run diagnostics if needed for troubleshooting intents
      Map<String, dynamic>? diagnosticResults;
      if (_requiresDiagnostics(intent)) {
        diagnosticResults = await _runDiagnosticsForIntent(intent);
      }

      // Generate natural, context-aware response using LLM
      final response = await _llmGenerator!.generate(
        userMessage: userMessage,
        intent: intent,
        context: _conversationContext,
        diagnosticResults: diagnosticResults,
      );

      // Send the LLM-generated response
      await _sendBotMessage(ChatMessage.bot(text: response));

      // Offer context-aware quick replies if appropriate
      if (_shouldOfferQuickReplies(intent)) {
        await _offerContextualQuickReplies(intent, diagnosticResults);
      }
    } catch (e) {
      _logger.e('LLM generation failed: $e');
      // Fallback to template-based response
      _logger.i('Falling back to template response');
      await _handleIntent(intent, entities);
    }
  }

  /// Handle intent with hybrid approach (template + LLM enhancement).
  Future<void> _handleIntentHybrid(
    UserIntent intent,
    String userMessage,
    Map<String, dynamic> entities,
  ) async {
    _logger.d('Generating hybrid response for intent: ${intent.name}');

    try {
      // Get template message
      final templateMessage = ConversationTemplates.getResponse(intent);

      // Run diagnostics if needed
      Map<String, dynamic>? diagnosticResults;
      if (_requiresDiagnostics(intent)) {
        diagnosticResults = await _runDiagnosticsForIntent(intent);
      }

      // Enhance template with LLM if it has enhancement placeholder
      final enhancedMessage = await _llmGenerator!.generateEnhancement(
        templateMessage: templateMessage.text,
        context: _conversationContext,
        placeholder: '[LLM_ENHANCEMENT]',
      );

      // Send the enhanced message
      await _sendBotMessage(
        ChatMessage.bot(
          text: enhancedMessage,
          quickReplies: templateMessage.quickReplies,
        ),
      );
    } catch (e) {
      _logger.e('Hybrid generation failed: $e');
      // Fallback to pure template
      _logger.i('Falling back to template response');
      await _handleIntent(intent, entities);
    }
  }

  /// Check if intent requires diagnostic information.
  bool _requiresDiagnostics(UserIntent intent) {
    const diagnosticIntents = {
      UserIntent.stepsNotSyncing,
      UserIntent.wrongStepCount,
      UserIntent.batteryOptimization,
      UserIntent.permissionDenied,
      UserIntent.healthConnectNotInstalled,
      UserIntent.checkingStatus,
    };

    return diagnosticIntents.contains(intent);
  }

  /// Run diagnostics for a specific intent.
  Future<Map<String, dynamic>> _runDiagnosticsForIntent(
    UserIntent intent,
  ) async {
    try {
      // Run comprehensive diagnostic
      final diagnosticResult = await _diagnosticService.runDiagnostics();

      // Convert to LLM-friendly format
      return {
        'permissionStatus': diagnosticResult.permissionState.status.name,
        'dataSourceCount': diagnosticResult.dataSources.length,
        'issuesFound': diagnosticResult.issues.length,
        'primaryIssue': diagnosticResult.issues.isNotEmpty
            ? diagnosticResult.issues.first.description
            : 'No issues detected',
        'platformAvailable': diagnosticResult.platformAvailability.isAvailable,
      };
    } catch (e) {
      _logger.w('Diagnostics failed: $e');
      return {'error': 'Could not run diagnostics'};
    }
  }

  /// Check if we should offer quick replies after this intent.
  bool _shouldOfferQuickReplies(UserIntent intent) {
    // Offer quick replies for intents that typically need follow-up actions
    const quickReplyIntents = {
      UserIntent.stepsNotSyncing,
      UserIntent.permissionDenied,
      UserIntent.batteryOptimization,
      UserIntent.multipleAppsConflict,
      UserIntent.needHelp,
    };

    return quickReplyIntents.contains(intent);
  }

  /// Offer contextual quick replies based on intent and diagnostics.
  Future<void> _offerContextualQuickReplies(
    UserIntent intent,
    Map<String, dynamic>? diagnosticResults,
  ) async {
    final quickReplies = <QuickReply>[];

    switch (intent) {
      case UserIntent.stepsNotSyncing:
        if (diagnosticResults?['permissionStatus'] != 'granted') {
          quickReplies.add(QuickReply(
            label: 'Grant Permission',
            value: 'grant_permission',
          ));
        } else {
          quickReplies.addAll([
            QuickReply(label: 'Check Battery', value: 'check_battery'),
            QuickReply(label: 'View Sources', value: 'view_sources'),
          ]);
        }
        break;

      case UserIntent.needHelp:
        quickReplies.addAll([
          QuickReply(label: 'Steps not syncing', value: 'steps_not_syncing'),
          QuickReply(label: 'Check status', value: 'check_status'),
          QuickReply(label: 'Grant permissions', value: 'grant_permission'),
        ]);
        break;

      default:
        return; // No quick replies for this intent
    }

    if (quickReplies.isNotEmpty) {
      // Send a brief follow-up with quick replies
      await _sendBotMessage(
        ChatMessage.bot(
          text: 'What would you like to do?',
          quickReplies: quickReplies,
        ),
      );
    }
  }

  /// Fetch recent step data.
  Future<void> _fetchRecentStepData() async {
    state = state.copyWith(status: ConversationStatus.fetchingData);

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final stepData = await _healthService.getStepData(
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(recentStepData: stepData);
    } catch (e) {
      // Don't fail the whole flow if data fetch fails
      state = state.copyWith(recentStepData: []);
    }

    state = state.copyWith(status: ConversationStatus.idle);
  }

  /// Build status message from diagnostics.
  String _buildStatusMessage(
    permissionState,
    List<dynamic> dataSources,
  ) {
    final buffer = StringBuffer('Status check complete!\n\n');

    // Permissions
    if (permissionState.status == PermissionStatus.granted) {
      buffer.writeln('✓ Permissions: Granted');
    } else {
      buffer.writeln('⚠ Permissions: Not granted');
    }

    // Data sources
    if (dataSources.isNotEmpty) {
      buffer.writeln('✓ Data sources: ${dataSources.length} connected');
      for (final source in dataSources.take(3)) {
        buffer.writeln('  • ${source.name}');
      }
    } else {
      buffer.writeln('⚠ Data sources: None found');
    }

    // Recent data
    if (state.recentStepData != null && state.recentStepData!.isNotEmpty) {
      final todaySteps = state.recentStepData!.last.steps;
      buffer.writeln('\n✓ Today: $todaySteps steps');
    }

    return buffer.toString();
  }

  /// Add a message to the conversation.
  void _addMessage(ChatMessage message) {
    state = state.copyWith(
      messages: [...state.messages, message],
    );

    // Save conversation after adding message
    _saveCurrentConversation();
  }

  /// Send a bot message with delay for natural feel.
  Future<void> _sendBotMessage(ChatMessage message) async {
    // Small delay to simulate typing
    await Future.delayed(const Duration(milliseconds: 500));
    _addMessage(message);

    // Add to conversation context for LLM awareness
    _conversationContext.addBotMessage(message.text);
  }

  /// Handle an error.
  void _handleError(String message) {
    state = state.copyWith(
      status: ConversationStatus.error,
      errorMessage: message,
      isTyping: false,
    );

    _addMessage(ChatMessage.error(text: message));
  }

  /// Save the current conversation to repository.
  Future<void> _saveCurrentConversation() async {
    if (_conversationRepository == null ||
        _userId == null ||
        _currentConversationId == null) {
      return;
    }

    try {
      final conversation = Conversation(
        id: _currentConversationId!,
        userId: _userId!,
        messages: state.messages,
        status: state.status == ConversationStatus.error
            ? ConversationLifecycleStatus.archived
            : ConversationLifecycleStatus.active,
        createdAt: DateTime.now(), // TODO: Track actual creation time
        updatedAt: DateTime.now(),
      );

      await _conversationRepository!.saveConversation(conversation);
    } catch (e) {
      // Don't fail the chatbot if save fails
      // Could add logging here
    }
  }

  /// Generate a unique conversation ID.
  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${_userId?.hashCode ?? 0}';
  }

  /// Start a new conversation.
  void startNewConversation() {
    _currentConversationId = _generateConversationId();
    state = ChatBotState.initial();

    // Clear conversation context for fresh start
    _conversationContext.clear();
    _logger.d('Started new conversation, context cleared');
  }

  /// Send greeting combined with diagnostic results.
  ///
  /// Runs diagnostics FIRST, then sends a single message with:
  /// - Greeting
  /// - Diagnostic results
  /// - Issue-specific quick replies
  Future<void> _sendGreetingWithDiagnostics() async {
    try {
      // Run intelligent diagnostic (takes ~2-3 seconds)
      final report = await _intelligentDiagnosticEngine.runDiagnostic();

      // Update state with permission info
      final permissionState = await _healthService.checkPermissions();
      state = state.copyWith(permissionState: permissionState);

      // Build combined greeting + diagnostic message
      final messageBuffer = StringBuffer();

      // === GREETING ===
      messageBuffer.writeln('Hi! I\'m Step Sync Assistant 👟');
      messageBuffer.writeln();

      // === DIAGNOSTIC RESULTS ===
      // Count total issues
      final issueCount = (report.primaryIssue != null ? 1 : 0) + report.secondaryIssues.length;

      if (issueCount == 0) {
        // All good - positive message
        messageBuffer.writeln('✅ I scanned your setup and everything looks good!');
        messageBuffer.writeln();
        if (report.todaySteps > 0) {
          messageBuffer.writeln('👟 You have **${report.todaySteps} steps** recorded today.');
        }
      } else {
        // Issues found - show count and details
        messageBuffer.writeln('I scanned your setup and found **$issueCount issue${issueCount > 1 ? 's' : ''}**:');
        messageBuffer.writeln();

        // === PRIMARY ISSUE ===
        if (report.primaryIssue != null) {
          final issue = report.primaryIssue!;
          final emoji = _getIssueEmoji(issue.type);
          messageBuffer.writeln('$emoji **${issue.title}**');
          messageBuffer.writeln('   ${issue.description}');

          if (report.secondaryIssues.isNotEmpty) {
            messageBuffer.writeln();
            for (final secondaryIssue in report.secondaryIssues.take(2)) {
              final secondaryEmoji = _getIssueEmoji(secondaryIssue.type);
              messageBuffer.writeln('$secondaryEmoji ${secondaryIssue.title}');
            }
            if (report.secondaryIssues.length > 2) {
              final remaining = report.secondaryIssues.length - 2;
              messageBuffer.writeln('   ...and $remaining more');
            }
          }
        }

        messageBuffer.writeln();
        messageBuffer.writeln('Let\'s fix these!');
      }

      // === QUICK REPLIES (Context-aware based on issues) ===
      List<QuickReply> quickReplies = [];

      if (report.primaryIssue != null) {
        switch (report.primaryIssue!.type) {
          case TrackingIssueType.permissionsNotGranted:
            quickReplies = [
              QuickReply(label: 'Grant Permission', value: 'grant_permission'),
              QuickReply(label: 'Why needed?', value: 'why_permission'),
            ];
            break;

          case TrackingIssueType.batteryOptimizationBlocking:
            quickReplies = [
              QuickReply(label: 'Fix Battery Issue', value: 'fix_battery'),
              QuickReply(label: 'Explain Issue', value: 'explain_battery'),
            ];
            break;

          case TrackingIssueType.healthConnectNotInstalled:
            quickReplies = [
              QuickReply(label: 'Install Health Connect', value: 'install_health_connect'),
              QuickReply(label: 'What is it?', value: 'explain_health_connect'),
            ];
            break;

          case TrackingIssueType.multipleDataSourcesConflict:
            quickReplies = [
              QuickReply(label: 'Choose Primary App', value: 'choose_primary_source'),
              QuickReply(label: 'Why does this matter?', value: 'explain_multiple_sources'),
            ];
            break;

          case TrackingIssueType.noDataSources:
            quickReplies = [
              QuickReply(label: 'Recommend Apps', value: 'recommend_apps'),
              QuickReply(label: 'Help me set up', value: 'setup_help'),
            ];
            break;

          default:
            quickReplies = [
              QuickReply(label: 'Fix This', value: 'fix_issue'),
              QuickReply(label: 'Show Details', value: 'show_details'),
            ];
        }

        // Add "Show All Issues" if there are secondary issues
        if (report.secondaryIssues.isNotEmpty) {
          quickReplies.add(
            QuickReply(label: 'Show All Issues', value: 'show_all_issues'),
          );
        }
      } else {
        // No issues - offer helpful next actions
        quickReplies = [
          QuickReply(label: 'Show My Steps', value: 'show_steps'),
          QuickReply(label: 'View History', value: 'view_history'),
        ];
      }

      // Send the combined message
      await _sendBotMessage(
        ChatMessage.bot(
          text: messageBuffer.toString(),
          quickReplies: quickReplies,
        ),
      );
    } catch (e) {
      _logger.e('Failed to run diagnostics during greeting: $e');

      // Fallback: Send simple greeting if diagnostics fail
      await _sendBotMessage(
        ChatMessage.bot(
          text: 'Hi! I\'m Step Sync Assistant 👟\n\n'
                'I had trouble scanning your setup, but I can still help you!\n\n'
                'What would you like to do?',
          quickReplies: [
            QuickReply(label: 'Check My Steps', value: 'check_steps'),
            QuickReply(label: 'Fix Syncing Issue', value: 'fix_syncing'),
            QuickReply(label: 'Help', value: 'help'),
          ],
        ),
      );
    }
  }

  /// Helper: Get emoji for issue type
  String _getIssueEmoji(TrackingIssueType type) {
    switch (type) {
      case TrackingIssueType.permissionsNotGranted:
        return '🔐';
      case TrackingIssueType.batteryOptimizationBlocking:
        return '🔋';
      case TrackingIssueType.healthConnectNotInstalled:
        return '📲';
      case TrackingIssueType.multipleDataSourcesConflict:
        return '📊';
      case TrackingIssueType.noDataSources:
        return '⚠️';
      case TrackingIssueType.noRecentData:
        return '⏰';
      case TrackingIssueType.stepCountDiscrepancy:
        return '🔢';
      case TrackingIssueType.platformNotAvailable:
        return '📱';
      case TrackingIssueType.lowPowerMode:
        return '🪫';
      case TrackingIssueType.backgroundSyncDisabled:
        return '⏸️';
      case TrackingIssueType.appForceQuit:
        return '🚫';
      case TrackingIssueType.deviceOffline:
        return '📴';
      case TrackingIssueType.manualEntriesDetected:
        return '✍️';
      case TrackingIssueType.apiRateLimitExceeded:
        return '⏱️';
      case TrackingIssueType.healthServiceUnavailable:
        return '⚠️';
    }
  }

  /// Check and report tracking status with intelligent diagnostics.
  ///
  /// Uses Bayesian reasoning, causal analysis, and explainable AI.
  /// Implements progressive disclosure (primary issue first).
  Future<void> _checkAndReportTrackingStatus() async {
    try {
      // Show "checking" indicator
      await Future.delayed(const Duration(milliseconds: 500));

      // Run intelligent diagnostic
      final report = await _intelligentDiagnosticEngine.runDiagnostic();

      // Update state with permission info
      final permissionState = await _healthService.checkPermissions();
      state = state.copyWith(permissionState: permissionState);

      // Build message with progressive disclosure
      final messageBuffer = StringBuffer();

      // === HEADLINE STATUS ===
      if (report.trackingStatus == TrackingStatus.working) {
        messageBuffer.writeln('✅ **Step tracking is working!**');
        messageBuffer.writeln();
        if (report.todaySteps > 0) {
          messageBuffer.writeln('You have **${report.todaySteps} steps** recorded today.');
        }

        // Minor issues notification (if any)
        if (report.secondaryIssues.isNotEmpty) {
          messageBuffer.writeln();
          messageBuffer.writeln('ℹ️ ${report.secondaryIssues.length} minor issue(s) detected but not blocking tracking.');
        }
      } else {
        messageBuffer.writeln('⚠️ **Step tracking may not be working**');
        messageBuffer.writeln();
        messageBuffer.writeln('**Current status:** ${report.todaySteps} steps today');
      }

      messageBuffer.writeln();

      // === PRIMARY ISSUE (Progressive Disclosure - Show First) ===
      if (report.primaryIssue != null) {
        final issue = report.primaryIssue!;
        final confidencePercent = (issue.confidence * 100).toInt();
        final emoji = _getConfidenceEmoji(issue.confidence);

        messageBuffer.writeln('## $emoji Primary Issue');
        messageBuffer.writeln();
        messageBuffer.writeln('**${issue.title}** ($confidencePercent% confident)');
        messageBuffer.writeln();
        messageBuffer.writeln(issue.description);

        // Show fix instructions prominently
        if (issue.fixInstructions != null) {
          messageBuffer.writeln();
          messageBuffer.writeln('**How to fix:**');
          messageBuffer.writeln('→ ${issue.fixInstructions}');
        }

        // Show causal explanation if exists
        final relatedChain = report.causalChains.where(
          (chain) => chain.cause == issue || chain.effect == issue
        ).firstOrNull;

        if (relatedChain != null) {
          messageBuffer.writeln();
          messageBuffer.writeln('**Why this matters:**');
          messageBuffer.writeln(relatedChain.explanation);
        }

        messageBuffer.writeln();
      }

      // === EXPLAINABLE REASONING (Transparency) ===
      messageBuffer.writeln('## 🧠 How I determined this');
      messageBuffer.writeln();
      messageBuffer.writeln(report.reasoning.reasoning);

      // === SECONDARY ISSUES (Collapsed - Progressive Disclosure) ===
      if (report.secondaryIssues.isNotEmpty) {
        messageBuffer.writeln();
        messageBuffer.writeln('---');
        messageBuffer.writeln();
        messageBuffer.writeln('_📋 ${report.secondaryIssues.length} other issue(s) detected_');
        messageBuffer.writeln('_(Tap "Show All Issues" to see details)_');
      }

      // === CONFIDENCE SCORE ===
      final overallPercent = (report.overallConfidence * 100).toInt();
      messageBuffer.writeln();
      messageBuffer.writeln('**Diagnostic confidence:** $overallPercent%');

      // === QUICK REPLIES (Context-aware) ===
      List<QuickReply> quickReplies;

      if (report.primaryIssue != null) {
        switch (report.primaryIssue!.type) {
          case TrackingIssueType.permissionsNotGranted:
            quickReplies = [
              QuickReply(label: 'Grant Permission', value: 'grant_permission'),
              QuickReply(label: 'Why needed?', value: 'why_permission'),
              if (report.secondaryIssues.isNotEmpty)
                QuickReply(label: 'Show All Issues', value: 'show_all_issues'),
            ];
            break;

          case TrackingIssueType.batteryOptimizationBlocking:
            quickReplies = [
              QuickReply(label: 'Fix Battery Settings', value: 'fix_battery'),
              QuickReply(label: 'How does this work?', value: 'explain_battery'),
              if (report.secondaryIssues.isNotEmpty)
                QuickReply(label: 'Show All Issues', value: 'show_all_issues'),
            ];
            break;

          case TrackingIssueType.healthConnectNotInstalled:
            quickReplies = [
              QuickReply(label: 'Install Health Connect', value: 'install_hc'),
              QuickReply(label: 'Learn More', value: 'learn_more_hc'),
            ];
            break;

          case TrackingIssueType.lowPowerMode:
            quickReplies = [
              QuickReply(label: 'Open Settings', value: 'open_settings'),
              QuickReply(label: 'Keep Low Power Mode', value: 'keep_low_power'),
              if (report.secondaryIssues.isNotEmpty)
                QuickReply(label: 'Show All Issues', value: 'show_all_issues'),
            ];
            break;

          case TrackingIssueType.multipleDataSourcesConflict:
            quickReplies = [
              QuickReply(label: 'Choose Primary Source', value: 'choose_source'),
              QuickReply(label: 'Why different counts?', value: 'explain_sources'),
            ];
            break;

          default:
            quickReplies = [
              QuickReply(label: 'Try to Fix', value: 'try_fix'),
              QuickReply(label: 'Need Help', value: 'escalate_support'),
              if (report.secondaryIssues.isNotEmpty)
                QuickReply(label: 'Show All Issues', value: 'show_all_issues'),
            ];
        }
      } else {
        // No issues found
        quickReplies = [
          QuickReply(label: 'Show My Steps', value: 'show_steps'),
          QuickReply(label: 'All Good!', value: 'all_good'),
        ];
      }

      await _sendBotMessage(
        ChatMessage.bot(
          text: messageBuffer.toString(),
          quickReplies: quickReplies,
        ),
      );
    } catch (e) {
      // Graceful error handling
      await _sendBotMessage(
        ChatMessage.bot(
          text: '❌ I encountered an error while running diagnostics.\n\n'
              'Error: $e\n\n'
              'Let me know if you need help troubleshooting!',
          quickReplies: [
            QuickReply(label: 'Try Again', value: 'check_again'),
            QuickReply(label: 'Steps not syncing', value: 'steps_not_syncing'),
            QuickReply(label: 'Contact Support', value: 'escalate_support'),
          ],
        ),
      );
    }
  }

  /// Get emoji based on confidence level.
  String _getConfidenceEmoji(double confidence) {
    if (confidence >= 0.95) return '🎯'; // Very high
    if (confidence >= 0.85) return '✅'; // High
    if (confidence >= 0.70) return '⚠️'; // Medium
    return 'ℹ️'; // Low
  }

  @override
  void dispose() {
    _healthService.dispose();
    _conversationRepository?.close();
    super.dispose();
  }
}
