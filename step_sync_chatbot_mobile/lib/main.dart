/// Step Sync ChatBot - Mobile with Native Diagnostics
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:markdown/markdown.dart' as md;
import 'src/diagnostics/battery_checker.dart';
import 'src/diagnostics/permissions_checker.dart';
import 'src/diagnostics/health_platform_checker.dart';
import 'src/diagnostics/power_checker.dart' hide BackgroundAppRefreshStatus;
import 'src/diagnostics/network_checker.dart';
import 'src/diagnostics/sensors_checker.dart';
import 'src/diagnostics/ios_settings_checker.dart';
import 'src/services/phi_sanitizer.dart';
import 'src/services/circuit_breaker.dart';
import 'src/services/token_counter.dart';
import 'src/services/sentiment_detector.dart';
import 'src/services/offline_handler.dart';
import 'src/services/conversation_context.dart';
import 'src/services/conversation_storage.dart';
import 'src/services/crash_logger.dart';
import 'src/services/step_verifier.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart' as ph;

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize crash logger FIRST to catch all errors
  await CrashLogger.initialize();

  // Run app in error-catching zone
  runZonedGuarded(
    () => runApp(const StepSyncMobileApp()),
    (error, stackTrace) async {
      // Catch any uncaught errors
      await CrashLogger.logError(
        error: error.toString(),
        stackTrace: stackTrace.toString(),
        context: 'Uncaught error in zone',
      );
    },
  );
}

class StepSyncMobileApp extends StatelessWidget {
  const StepSyncMobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Sync Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF0078D4),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF0078D4),
          secondary: Color(0xFF107C10),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFF5F7FA),
          error: Color(0xFFDC2626),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A), height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  // ═══════════════════════════════════════════════════════════════════════
  // PROFESSIONAL MEDICAL APP COLOR SCHEME - FLAT, NO GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════
  static const Color primaryColor = Color(0xFF0078D4);        // Professional Blue
  static const Color secondaryColor = Color(0xFF107C10);      // Medical Green
  static const Color backgroundColor = Color(0xFFECE5DD);      // WhatsApp Background
  static const Color surfaceColor = Color(0xFFF7F8FA);         // Light Surface
  static const Color textPrimaryColor = Color(0xFF1A1A1A);     // Dark Gray Text
  static const Color textSecondaryColor = Color(0xFF667781);   // WhatsApp Gray Text
  static const Color borderColor = Color(0xFFE5E7EB);          // Light Border
  static const Color botMessageColor = Color(0xFFFFFFFF);      // White for Bot Messages
  static const Color userMessageColor = Color(0xFF0078D4);     // Blue for User
  static const Color errorColor = Color(0xFFDC2626);           // Red for Errors
  static const Color successColor = Color(0xFF059669);         // Green for Success
  static const Color warningColor = Color(0xFFD97706);         // Orange for Warnings

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  bool _loading = false;
  final _log = Logger();
  late final BatteryChecker _batteryChecker;
  late final PermissionsChecker _permissionsChecker;
  late final HealthPlatformChecker _healthPlatformChecker;
  late final PowerChecker _powerChecker;
  late final NetworkChecker _networkChecker;
  late final SensorsChecker _sensorsChecker;
  late final IOSSettingsChecker _iosSettingsChecker;
  int _troubleshootLevel = 1; // Progressive troubleshooting: 1=basic, 2=deep, 3=extreme

  // Issue tracking for progressive troubleshooting
  List<Map<String, dynamic>> _issueQueue = [];
  int _currentIssueIndex = 0;
  int _totalIssuesFound = 0;
  bool _isCheckingSteps = false; // Prevent duplicate "Give it a moment"

  // Auto-detected device information
  String _deviceName = 'Android Device';
  String _androidVersion = '';
  String _manufacturer = '';
  bool _deviceDetected = false;

  // New services for full flow implementation
  late final CircuitBreaker _circuitBreaker;
  late final ConversationContext _context;
  late final ConversationStorage _conversationStorage;
  bool _isOffline = false;

  // FLOW 14: Voice input
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechInitialized = false;
  String _voiceText = '';
  String _lastSpeechError = '';

  // App lifecycle tracking for permission re-checks
  bool _isWaitingForPermission = false;
  String _pendingPermissionType = ''; // 'health_connect', 'healthkit', 'physical_activity'

  static const _apiKey = 'YOUR_GROQ_API_KEY_HERE'; // Replace with your actual Groq API key
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';

  @override
  void initState() {
    super.initState();

    // Register app lifecycle observer to detect backgrounding/resuming
    WidgetsBinding.instance.addObserver(this);

    _batteryChecker = BatteryChecker(logger: _log);
    _permissionsChecker = PermissionsChecker(logger: _log);
    _healthPlatformChecker = HealthPlatformChecker(logger: _log);
    _powerChecker = PowerChecker(logger: _log);
    _networkChecker = NetworkChecker(logger: _log);
    _sensorsChecker = SensorsChecker(logger: _log);
    _iosSettingsChecker = IOSSettingsChecker(logger: _log);

    // Initialize new services
    _circuitBreaker = CircuitBreaker(
      failureThreshold: 5,
      timeout: Duration(seconds: 60),
      successThreshold: 2,
    );
    _context = ConversationContext();
    _conversationStorage = ConversationStorage();
    _speech = stt.SpeechToText();

    // Initialize in correct order
    _initializeStorage();  // Load encrypted chat history first
    _detectDevice();
    _checkConnectivity();
  }

  @override
  void dispose() {
    // Unregister app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Handle app lifecycle changes (background/foreground transitions)
  /// Critical for detecting when user returns from Settings after granting permissions
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    _log.i('App lifecycle changed to: $state');

    // When app resumes from background, re-check permissions if we were waiting
    if (state == AppLifecycleState.resumed && _isWaitingForPermission) {
      _log.i('App resumed, re-checking permission: $_pendingPermissionType');

      // Wait a bit for system to update permission state
      Future.delayed(Duration(milliseconds: 500), () {
        // CRITICAL: Check if widget is still mounted before calling setState
        if (mounted) {
          _recheckPermissionAfterResume();
        } else {
          _log.w('Widget disposed before permission recheck could complete');
        }
      });
    } else if (state == AppLifecycleState.paused) {
      _log.i('App paused (user may have gone to Settings)');
    }
  }

  /// Check if device manufacturer requires additional permission steps
  /// Samsung, Xiaomi, Oppo have aggressive background restrictions
  void _checkAndShowOEMWarning() {
    if (!_deviceDetected || _manufacturer.isEmpty) return;

    String? warning;
    List<String>? steps;

    // Xiaomi/MIUI/Redmi - Most aggressive restrictions
    // Don't show manufacturer warnings at startup - too verbose
    // User will get specific warnings if issues are detected during troubleshooting
  }

  /// Re-check specific permission after app resumes from Settings
  Future<void> _recheckPermissionAfterResume() async {
    if (!_isWaitingForPermission || !mounted) return;

    try {
      switch (_pendingPermissionType) {
        case 'health_connect':
          final permStatus = await _permissionsChecker.checkPhysicalActivityPermission();
          if (!mounted) return; // Check again after async call
          if (permStatus == PermissionStatus.granted) {
            _isWaitingForPermission = false;
            _pendingPermissionType = '';
            _add(true,
              '✅ **Permission Granted!**\n\n'
              'Great! Health Connect permissions are now enabled.\n\n'
              'Let me check your health data sources...',
            );
            await _checkHealthPlatforms();
          }
          break;

        case 'physical_activity':
          final permStatus = await _permissionsChecker.checkPhysicalActivityPermission();
          if (!mounted) return; // Check again after async call
          if (permStatus == PermissionStatus.granted) {
            _isWaitingForPermission = false;
            _pendingPermissionType = '';
            _add(true,
              '✅ **Physical Activity Permission Granted!**\n\n'
              'Your step tracking is now enabled.',
            );
          }
          break;

        case 'healthkit':
          final availability = await _healthPlatformChecker.checkHealthKitAvailability();
          if (!mounted) return; // Check again after async call
          if (availability.authStatus == HealthKitAuthStatus.authorized) {
            _isWaitingForPermission = false;
            _pendingPermissionType = '';
            _add(true,
              '✅ **HealthKit Authorized!**\n\n'
              'Great! HealthKit permissions are now enabled.\n\n'
              'Let me check your health data sources...',
            );
            await _checkHealthPlatforms();
          }
          break;
      }
    } catch (e) {
      _log.e('Error re-checking permission after resume: $e');
      // Don't call _add() if widget is disposed
    }
  }

  /// Check internet connectivity
  Future<void> _checkConnectivity() async {
    final isOnline = await OfflineHandler.isOnline();
    // CRITICAL: Check if widget is still mounted
    if (!mounted) return;

    setState(() {
      _isOffline = !isOnline;
    });
  }

  /// FLOW 12: Initialize encrypted storage
  Future<void> _initializeStorage() async {
    try {
      await _conversationStorage.initialize();
      _log.i('Encrypted conversation storage initialized');

      // Clear old chat history for fresh start each time
      // This prevents confusing fragmented messages from previous sessions
      await _conversationStorage.clearAll();
      _log.i('Cleared previous conversation history for fresh start');
    } catch (e) {
      _log.e('Error initializing storage: $e');
    }
  }

  /// FLOW 14: Initialize speech recognition (call once)
  Future<void> _initializeSpeech() async {
    if (_speechInitialized) return;

    try {
      _speechInitialized = await _speech.initialize(
        onError: (error) {
          _log.e('Speech recognition error: ${error.errorMsg}');
          _lastSpeechError = error.errorMsg;

          // CRITICAL: Check if widget is still mounted
          if (!mounted) return;

          setState(() {
            _isListening = false;
          });

          // Show user-friendly error messages
          if (error.errorMsg.contains('error_no_match')) {
            _add(true, '🎤 No speech detected. Try again.');
          } else if (error.errorMsg.contains('error_busy')) {
            _add(true, '🎤 Recognizer busy. Wait a moment.');
          } else if (error.errorMsg.contains('error_speech_timeout')) {
            _add(true, '🎤 Listening timeout. Try again.');
          } else if (error.errorMsg.contains('error_audio')) {
            _add(true, '🎤 Microphone error. Check settings.');
          }
        },
        onStatus: (status) {
          _log.i('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            // CRITICAL: Check if widget is still mounted
            if (!mounted) return;
            setState(() => _isListening = false);
          }
        },
      );

      if (_speechInitialized) {
        _log.i('Speech recognition initialized successfully');
      } else {
        _log.w('Speech recognition not available on this device');
      }
    } catch (e) {
      _log.e('Failed to initialize speech recognition: $e');
      _speechInitialized = false;
      // Don't crash if speech recognition unavailable - some devices don't support it
      if (mounted) {
        _add(true, '⚠️ Voice input not available on this device');
      }
    }
  }

  /// FLOW 14: Start voice input
  Future<void> _startListening() async {
    // Check/request microphone permission
    var permissionStatus = await ph.Permission.microphone.status;
    if (!permissionStatus.isGranted) {
      permissionStatus = await ph.Permission.microphone.request();
      if (!permissionStatus.isGranted) {
        _add(true, '🎤 Microphone permission needed for voice input');
        return;
      }
    }

    // Initialize speech recognition if not already done
    if (!_speechInitialized) {
      await _initializeSpeech();
    }

    if (!_speechInitialized) {
      _add(true, '❌ Speech recognition not available. Please type instead.');
      return;
    }

    // Check if already listening
    if (_speech.isListening) {
      _log.w('Already listening, ignoring start request');
      return;
    }

    // Start listening
    // CRITICAL: Check if widget is still mounted
    if (!mounted) return;

    setState(() {
      _isListening = true;
      _voiceText = '';
      _lastSpeechError = '';
    });

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5), // Auto-stop after 5 seconds of silence
        partialResults: true, // Live transcription
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      _log.e('Error starting speech recognition: $e');
      if (mounted) {
        setState(() => _isListening = false);
        _add(true, '❌ Voice input failed. Try typing instead.');
      }
    }
  }

  /// FLOW 14: Stop voice input
  void _stopListening() {
    _speech.stop();
    // CRITICAL: Check if widget is still mounted
    if (!mounted) return;

    setState(() => _isListening = false);

    // Fill text input with transcribed text
    if (_voiceText.isNotEmpty) {
      _controller.text = _voiceText;
      _voiceText = '';
    }
  }

  /// FLOW 14: Handle speech recognition result
  void _onSpeechResult(result) {
    // CRITICAL: Check if widget is still mounted
    if (!mounted) return;

    setState(() {
      _voiceText = result.recognizedWords;
      // Show live transcription in text field
      _controller.text = _voiceText;
    });
  }

  Future<void> _detectDevice() async {
    if (Platform.isAndroid) {
      try {
        final deviceInfo = await _batteryChecker.getDeviceInfo();
        // CRITICAL: Check if widget is still mounted after async call
        if (!mounted) return;

        if (deviceInfo != null) {
          setState(() {
            _deviceName = deviceInfo['displayName'] ?? 'Android Device';
            _androidVersion = deviceInfo['androidVersion'] ?? '';
            _manufacturer = (deviceInfo['manufacturer'] ?? '').toLowerCase();
            _deviceDetected = true;
          });
          _log.i('Device detected: $_deviceName, Android $_androidVersion');

          // Show auto greeting if no chat history
          if (_messages.isEmpty && mounted) {
            _showAutoGreeting();
          }
        }
      } catch (e) {
        _log.w('Could not detect device info: $e');
      }
    } else if (Platform.isIOS) {
      if (!mounted) return;

      setState(() {
        _deviceName = 'iPhone';
        _deviceDetected = true;
      });
      if (_messages.isEmpty && mounted) {
        _showAutoGreeting();
      }
    }
  }

  Future<void> _showAutoGreeting() async {
    final platform = Platform.isAndroid ? 'Android' : 'iOS';
    final deviceInfo = _androidVersion.isNotEmpty ? '$_deviceName (Android $_androidVersion)' : _deviceName;

    // Run diagnostics FIRST, then show greeting with results
    await _showGreetingWithDiagnostics();
  }

  /// Show greeting combined with diagnostic results
  Future<void> _showGreetingWithDiagnostics() async {
    try {
      // Run diagnostics to collect issues with FULL details for progressive flow
      List<Map<String, dynamic>> criticalIssues = [];
      List<Map<String, dynamic>> warningIssues = [];

      // Run the same diagnostic checks as _runSmartTroubleshoot
      if (Platform.isAndroid) {
        // 1. Physical Activity Permission
        try {
          final permission = await _permissionsChecker.checkPhysicalActivityPermission();
          if (permission == PermissionStatus.denied) {
            criticalIssues.add({
              'title': '🚨 Physical Activity permission denied',
              'description': 'I need this to read your step sensor data.',
              'buttonPurpose': 'Clicking will open Android settings to grant permission.',
              'action': 'Grant Activity Permission',
              'icon': Icons.error,
              'fix': () => _requestPhysicalActivityPermission(),
            });
          }
        } catch (e) {}

        // 2. Battery Optimization
        try {
          final batteryResult = await _batteryChecker.checkBatteryOptimization();
          if (batteryResult == BatteryCheckResult.enabled) {
            criticalIssues.add({
              'title': '⚠️ Battery optimization enabled',
              'description': 'Your device restricts this app to save battery. Steps won\'t sync when closed.',
              'buttonPurpose': 'Clicking will open battery settings to disable optimization.',
              'action': 'Disable Battery Optimization',
              'icon': Icons.battery_alert,
              'fix': () => _requestBatteryExemption(),
            });
          }
        } catch (e) {}

        // 3. Health Connect Availability & Permissions
        try {
          bool canCheckPermissions = false;
          bool hasPermissions = false;

          try {
            hasPermissions = await _healthPlatformChecker.checkHealthConnectPermissions();
            canCheckPermissions = true;
          } catch (e) {
            canCheckPermissions = false;
          }

          if (canCheckPermissions && !hasPermissions) {
            criticalIssues.add({
              'title': '🔒 Health Connect permissions not granted',
              'description': 'I need this permission to read your step data.\n\n**Follow these steps:**\n1. Tap **"Grant Permissions"** below\n2. Health Connect will open\n3. Tap **"App permissions"**\n4. Find **"Step Sync Assistant"** in the list\n5. Toggle **"Steps"** to ON\n6. Press back to return here',
              'buttonPurpose': 'This will open Health Connect settings.',
              'action': 'Grant Permissions',
              'icon': Icons.health_and_safety,
              'fix': () => _requestHealthConnectPermissions(),
            });
          } else if (!canCheckPermissions) {
            final healthConnect = await _healthPlatformChecker.checkHealthConnectAvailability();
            if (healthConnect.status == HealthPlatformStatus.notInstalled) {
              criticalIssues.add({
                'title': '⚠️ Health Connect not installed',
                'description': 'Your device needs Health Connect to track steps.',
                'buttonPurpose': 'Clicking will open Play Store to install it.',
                'action': 'Install Health Connect',
                'icon': Icons.download,
                'fix': () => _installHealthConnect(),
              });
            } else if (healthConnect.status == HealthPlatformStatus.needsUpdate) {
              criticalIssues.add({
                'title': '⚠️ Health Connect needs update',
                'description': 'You have the basic version. Need the full version.',
                'buttonPurpose': 'Clicking will open Play Store to update it.',
                'action': 'Update Health Connect',
                'icon': Icons.system_update,
                'fix': () => _installHealthConnect(),
              });
            }
          }
        } catch (e) {}

        // 4. Data Saver Mode
        try {
          final dataSaver = await _networkChecker.checkDataSaverMode();
          if (dataSaver.blocksBackgroundData) {
            criticalIssues.add({
              'title': '📶 Data Saver is blocking background sync',
              'description': 'Data Saver prevents background data usage. Steps won\'t upload.',
              'buttonPurpose': 'Clicking will open settings to whitelist this app.',
              'action': 'Whitelist This App',
              'icon': Icons.data_saver_off,
              'fix': () => _requestDataSaverWhitelist(),
            });
          }
        } catch (e) {}

        // 5. Background Data Restriction
        try {
          final backgroundData = await _networkChecker.checkBackgroundDataRestriction();
          if (backgroundData.isRestricted) {
            warningIssues.add({
              'title': '🚫 Background data is restricted',
              'description': 'This app can\'t use mobile data in the background. Only syncs on Wi-Fi.',
              'buttonPurpose': 'Clicking will open app data settings to enable it.',
              'action': 'Enable Background Data',
              'icon': Icons.signal_cellular_off,
              'fix': () => _openAppDataSettings(),
            });
          }
        } catch (e) {}

        // 6. Connectivity Check
        try {
          final connectivity = await _networkChecker.checkConnectivity();
          if (!connectivity.isConnected) {
            warningIssues.add({
              'title': '❌ No internet connection',
              'description': 'Can\'t sync without internet. Connect to Wi-Fi or mobile data.',
              'buttonPurpose': null,
              'action': null,
              'icon': Icons.wifi_off,
              'fix': null,
            });
          }
        } catch (e) {}
      }

      // Build greeting message with ALL issues listed
      final totalIssues = criticalIssues.length + warningIssues.length;
      StringBuffer message = StringBuffer();

      // Recognition over recall (Nielsen): Clear identity
      // Aesthetic minimalism (Dieter Rams): Simple, purposeful
      message.write('**👋 Hi! I\'m Step Sync Assistant**');
      message.write('\n\n');

      if (totalIssues == 0) {
        // Positive feedback (Visibility of system status)
        // Law of Proximity: Group positive message elements
        message.write('**✅ Everything looks good!**');
        message.write('\n\n');
        message.write('Your setup is complete and step tracking is working properly.');

        _add(true, message.toString(), actions: [
          ActionButton(
            label: 'Show My Steps',
            icon: Icons.directions_walk,
            onPressed: () async {
              await _showStepsDirectly();
            },
          ),
        ]);
      } else {
        // Hick's Law: Clear, simple status (not overwhelming with details)
        // Visibility of system status: Tell user what was found
        // Miller's Law: Chunk info (just the count, details come progressively)
        message.write('I found **$totalIssues issue${totalIssues > 1 ? 's' : ''}** with your setup.');
        message.write('\n\n');
        message.write('Let\'s fix them together, one at a time.');

        _add(true, message.toString());

        // Now start the progressive flow using existing logic
        _issueQueue = [...criticalIssues, ...warningIssues];
        _totalIssuesFound = _issueQueue.length;
        _currentIssueIndex = 0;
        _isCheckingSteps = false;

        // Show first issue immediately
        _showNextIssue();
      }
    } catch (e) {
      _log.e('Failed to run diagnostics during greeting: $e');

      // Fallback: Show simple greeting if diagnostics fail
      _add(true,
        '👋 Hi! I can help troubleshoot step tracking problems.',
        actions: [
          ActionButton(
            label: 'Fix Sync Issues',
            icon: Icons.sync_problem,
            onPressed: () {
              _controller.text = 'My steps are not syncing';
              _send();
            },
          ),
        ],
      );
    }
  }

  // ========================================================================
  // CHAT HISTORY PERSISTENCE
  // ========================================================================

  static const String _chatHistoryKey = 'chat_history';
  static const String _historyTimestampKey = 'history_timestamp';
  static const int _historyExpiryHours = 24; // Auto-clear after 24 hours

  /// Load chat history from storage
  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if history has expired (24 hours)
      final timestamp = prefs.getInt(_historyTimestampKey);
      if (timestamp != null) {
        final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(savedTime);

        if (difference.inHours >= _historyExpiryHours) {
          _log.i('Chat history expired (${difference.inHours} hours old), clearing...');
          await _clearChatHistory();
          _add(true, 'Hi! I\'m your Step Sync assistant. I can help you troubleshoot step tracking issues.\n\nWhat brings you here today?');
          return;
        }
      }

      // Load messages
      final historyJson = prefs.getString(_chatHistoryKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _messages.clear();
          for (var msgData in decoded) {
            _messages.add(ChatMessage(
              msgData['text'] as String,
              msgData['isBot'] as bool,
              DateTime.fromMillisecondsSinceEpoch(msgData['timestamp'] as int),
            ));
          }
        });
        _log.i('Loaded ${_messages.length} messages from history');

        // Add welcome back message
        if (_messages.isNotEmpty) {
          _add(true, '👋 Welcome back! I remember our previous conversation. How can I help you today?');
        }
      } else {
        // No history, show welcome message
        _add(true, 'Hi! I\'m your Step Sync assistant. I can help you troubleshoot step tracking issues.\n\nWhat brings you here today?');
      }
    } catch (e) {
      _log.e('Error loading chat history: $e');
      // Show welcome message on error
      _add(true, 'Hi! I\'m your Step Sync assistant. I can help you troubleshoot step tracking issues.\n\nWhat brings you here today?');
    }
  }

  /// Save chat history to storage
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Filter out messages with action buttons (they shouldn't persist)
      final messagesToSave = _messages.where((m) => m.actions == null).toList();

      // Convert to JSON
      final historyJson = jsonEncode(
        messagesToSave.map((msg) => {
          'text': msg.text,
          'isBot': msg.isBot,
          'timestamp': msg.time.millisecondsSinceEpoch,
        }).toList(),
      );

      await prefs.setString(_chatHistoryKey, historyJson);
      await prefs.setInt(_historyTimestampKey, DateTime.now().millisecondsSinceEpoch);
      _log.d('Saved ${messagesToSave.length} messages to history');
    } catch (e) {
      _log.e('Error saving chat history: $e');
    }
  }

  /// Clear chat history from storage
  Future<void> _clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
      await prefs.remove(_historyTimestampKey);
      _log.i('Chat history cleared');
    } catch (e) {
      _log.e('Error clearing chat history: $e');
    }
  }

  /// Clear chat history UI and storage
  Future<void> _clearChat() async {
    // FLOW 12: Clear encrypted storage
    try {
      await _conversationStorage.clearAll();
      _log.i('Encrypted conversation storage cleared');
    } catch (e) {
      _log.e('Error clearing encrypted storage: $e');
    }
    setState(() {
      _messages.clear();
      _troubleshootLevel = 1; // Reset troubleshoot level
    });

    // Show smooth transition: first the cleared message, then greeting
    _add(true, '✅ Chat cleared');

    // Small delay for smooth transition, then show full greeting
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      _showAutoGreeting();
    }
  }

  /// Show crash logs dialog
  Future<void> _showCrashLogs(BuildContext context) async {
    final logs = await CrashLogger.getCrashLogs();

    if (!mounted) return;

    if (logs.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: secondaryColor, size: 24),
              SizedBox(width: 8),
              Text('No Crashes Detected'),
            ],
          ),
          content: Text('Your app is running smoothly! No crash logs found.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bug_report, color: errorColor, size: 24),
            SizedBox(width: 8),
            Text('Crash Logs (${logs.length})'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent crashes detected. Scroll down to see all details.',
                  style: TextStyle(color: textSecondaryColor, fontSize: 13),
                ),
                SizedBox(height: 16),
                ...logs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final log = entry.value;
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.05),
                      border: Border.all(color: errorColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crash #${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: errorColor,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SelectableText(
                            log,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              color: textPrimaryColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await CrashLogger.clearCrashLogs();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Crash logs cleared'),
                    backgroundColor: secondaryColor,
                    duration: Duration(seconds: 2),
                  ),
                );
                // Trigger rebuild to update the badge
                setState(() {});
              }
            },
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text('Clear Logs'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _add(bool isBot, String text, {List<ActionButton>? actions}) {
    final timestamp = DateTime.now();
    setState(() => _messages.add(ChatMessage(text, isBot, timestamp, actions: actions)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    });

    // FLOW 12: Save to encrypted storage (only if no actions to avoid duplicate saves)
    if (actions == null) {
      _saveMessageToStorage(text, isBot, timestamp);
    }
  }

  /// FLOW 12: Save message to encrypted storage
  Future<void> _saveMessageToStorage(String content, bool isBot, DateTime timestamp) async {
    try {
      final message = ConversationMessage(
        id: '${timestamp.millisecondsSinceEpoch}',
        content: content,
        isBot: isBot,
        timestamp: timestamp,
      );
      await _conversationStorage.saveMessage(message);
    } catch (e) {
      _log.e('Error saving message to encrypted storage: $e');
    }
  }

  Future<void> _checkBatteryOptimization() async {
    if (!Platform.isAndroid) {
      _add(true, '⚠️ iOS: Check Low Power Mode in Settings');
      return;
    }

    try {
      final deviceInfo = await _batteryChecker.getDeviceInfo();
      final displayName = deviceInfo?['displayName'] ?? 'Android Device';
      final androidVersion = deviceInfo?['androidVersion'] ?? 'Unknown';

      final result = await _batteryChecker.checkBatteryOptimization();

      switch (result) {
        case BatteryCheckResult.enabled:
          _add(true,
            '⚠️ Battery optimization detected\n\nYour device is restricting this app to save battery. This prevents steps from syncing when the app is closed.\n\nTap below to allow unrestricted background activity.',
            actions: [
              ActionButton(
                label: 'Disable Battery Optimization',
                icon: Icons.settings,
                onPressed: () => _requestBatteryExemption(),
              ),
            ],
          );
          break;

        case BatteryCheckResult.disabled:
          _add(true, '✅ Battery optimization disabled\n\nBackground sync is enabled. Steps will sync automatically even when the app is closed.');
          break;

        case BatteryCheckResult.notApplicable:
          _add(true, '⚠️ Not available on this Android version');
          break;

        case BatteryCheckResult.unknown:
          _add(true, '❓ Could not check. Try Settings manually.');
          break;
      }
    } catch (e) {
      _log.e('Error checking battery optimization: $e');
      _add(true, '❌ Check failed');
    }
  }

  Future<void> _requestBatteryExemption() async {
    try {
      final deviceInfo = await _batteryChecker.getDeviceInfo();
      final manufacturer = (deviceInfo?['manufacturer'] ?? '').toLowerCase();

      final success = await _batteryChecker.requestBatteryOptimizationExemption();

      if (!success) {
        _add(true, '❌ Could not open Settings');
        return;
      }

      // Show waiting message
      _add(true, 'Waiting for you to disable battery optimization...');

      // Wait for user to disable and return to app (give time for settings navigation)
      await Future.delayed(Duration(seconds: 3));

      // Check if battery optimization was disabled
      final batteryStatus = await _batteryChecker.checkBatteryOptimization();

      if (batteryStatus == BatteryCheckResult.disabled) {
        // Battery optimization disabled - advance to next issue
        _add(true, '✅ Battery optimization disabled!');
        await Future.delayed(Duration(milliseconds: 500));

        setState(() => _currentIssueIndex++);
        if (_currentIssueIndex < _issueQueue.length) {
          await Future.delayed(Duration(milliseconds: 500));
          _showNextIssue();
        } else {
          // All issues fixed - check steps
          await _checkStepsAfterFixes();
        }
      } else {
        _add(true,
          '❌ Battery optimization still enabled\n\nPlease disable it.',
          actions: [
            ActionButton(
              label: 'Try Again',
              icon: Icons.refresh,
              onPressed: () => _requestBatteryExemption(),
            ),
          ],
        );
      }
    } catch (e) {
      _log.e('Error requesting battery exemption: $e');
      _add(true, '❌ Failed');
    }
  }

  /// Poll permission status with exponential backoff for slow devices
  /// Checks at intervals [2s, 5s, 10s] by default to handle:
  /// - Slow permission dialog appearance (old/slow devices)
  /// - User taking time to read and grant permission
  /// - Network delays in permission synchronization
  Future<PermissionStatus> _pollPermissionStatus({
    required Future<PermissionStatus> Function() checkFunction,
    required List<int> pollIntervals,
    required PermissionStatus targetStatus,
  }) async {
    PermissionStatus currentStatus = PermissionStatus.denied;
    int cumulativeTime = 0;

    for (int i = 0; i < pollIntervals.length; i++) {
      await Future.delayed(Duration(seconds: pollIntervals[i]));
      cumulativeTime += pollIntervals[i];

      currentStatus = await checkFunction();

      // Found target status
      if (currentStatus == targetStatus) {
        return currentStatus;
      }

      // Stop early if permanently denied (no point in continuing)
      if (currentStatus == PermissionStatus.permanentlyDenied) {
        return currentStatus;
      }
    }

    // Return final status after all polls
    return currentStatus;
  }

  Future<void> _checkPermissions() async {

    try {
      if (Platform.isAndroid) {
        // Check Physical Activity Permission (Android 10+)
        final physicalActivityStatus = await _permissionsChecker.checkPhysicalActivityPermission();
        final deviceInfo = await _batteryChecker.getDeviceInfo();
        final displayName = deviceInfo?['displayName'] ?? 'Android Device';
        final androidVersion = deviceInfo?['androidVersion'] ?? 'Unknown';

        if (physicalActivityStatus == PermissionStatus.notApplicable) {
          _add(true, '✅ Permissions check complete\n\nYour Android version doesn\'t require special permissions. Step tracking should work automatically.');
          return;
        }

        if (physicalActivityStatus == PermissionStatus.denied ||
            physicalActivityStatus == PermissionStatus.permanentlyDenied ||
            physicalActivityStatus == PermissionStatus.notDetermined) {
          _add(true,
            '🚨 Physical Activity permission required\n\nAndroid needs this permission to access your device\'s step sensor. Without it, step counting won\'t work.\n\nTapping the button below will show a permission dialog.',
            actions: [
              ActionButton(
                label: 'Grant Activity Permission',
                icon: Icons.build_circle,
                onPressed: () => _explainAndRequestPermission(),
              ),
            ],
          );
          return;
        }

        if (physicalActivityStatus == PermissionStatus.granted) {
          _add(true, '✅ Physical Activity permission granted\n\nStep tracking is enabled and working correctly.');
        }
      } else if (Platform.isIOS) {
        // Check Motion & Fitness Permission (iOS)
        final motionStatus = await _permissionsChecker.checkMotionFitnessPermission();

        if (motionStatus == PermissionStatus.denied ||
            motionStatus == PermissionStatus.notDetermined) {
          _add(true,
            '🚨 Motion & Fitness permission needed to track steps',
            actions: [
              ActionButton(
                label: 'Open Settings',
                icon: Icons.settings,
                onPressed: () => _requestMotionFitnessPermission(),
              ),
            ],
          );
        } else if (motionStatus == PermissionStatus.restricted) {
          _add(true, '⛔ Motion & Fitness restricted by device policy');
        } else if (motionStatus == PermissionStatus.granted) {
          _add(true, '✅ Motion & Fitness enabled. Step tracking active!');
        } else {
          _add(true, '❓ Could not check. Try Settings → Privacy → Motion & Fitness');
        }
      }
    } catch (e) {
      _log.e('Error checking permissions: $e');
      _add(true, '❌ Check failed');
    }
  }

  Future<void> _requestPhysicalActivityPermission() async {
    try {
      // First check if already granted
      final currentStatus = await _permissionsChecker.checkPhysicalActivityPermission();

      if (currentStatus == PermissionStatus.granted) {
        // Already granted - advance to next issue
        setState(() => _currentIssueIndex++);
        if (_currentIssueIndex < _issueQueue.length) {
          await Future.delayed(Duration(milliseconds: 500));
          _showNextIssue();
        } else {
          // All issues fixed - check steps
          await _checkStepsAfterFixes();
        }
        return;
      }

      // Not granted - request it
      final granted = await _permissionsChecker.requestPhysicalActivityPermission();

      // Wait for user to respond to dialog and check result
      await Future.delayed(Duration(seconds: 1));

      final newStatus = await _permissionsChecker.checkPhysicalActivityPermission();

      if (newStatus == PermissionStatus.granted) {
        // Permission granted - advance to next issue
        _add(true, '✅ Permission granted!');
        await Future.delayed(Duration(milliseconds: 500));

        setState(() => _currentIssueIndex++);
        if (_currentIssueIndex < _issueQueue.length) {
          await Future.delayed(Duration(milliseconds: 500));
          _showNextIssue();
        } else {
          // All issues fixed - check steps
          await _checkStepsAfterFixes();
        }
      } else {
        _add(true,
          '❌ Permission denied\n\nPlease grant the permission.',
          actions: [
            ActionButton(
              label: 'Try Again',
              icon: Icons.refresh,
              onPressed: () => _requestPhysicalActivityPermission(),
            ),
          ],
        );
      }
    } catch (e) {
      _log.e('Error requesting physical activity permission: $e');
      _add(true, '❌ Request failed');
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final granted = await _permissionsChecker.requestNotificationPermission();

      if (granted) {
        _add(true, '✅ Notifications enabled');
      } else {
        _add(true, '⚠️ Notifications denied (optional)');
      }
    } catch (e) {
      _log.e('Error requesting notification permission: $e');
      _add(true, '❌ Could not request permission');
    }
  }

  Future<void> _requestMotionFitnessPermission() async {
    try {
      final success = await _permissionsChecker.openIOSSettings();

      if (success) {
        _add(true,
          '📱 **Settings Should Open!**\n\n'
          '**Follow these steps:**\n'
          '1. Find "Privacy & Security"\n'
          '2. Tap "Motion & Fitness"\n'
          '3. Enable for "Step Sync Assistant"\n'
          '4. Return to the app',
          actions: [
            ActionButton(
              label: 'Check Again',
              icon: Icons.refresh,
              onPressed: () => _checkPermissions(),
            ),
          ],
        );
      } else {
        _add(true, '⚠️ Could not open Settings automatically. Please open Settings manually and enable Motion & Fitness for this app.');
      }
    } catch (e) {
      _log.e('Error opening iOS settings: $e');
      _add(true, '⚠️ Please open Settings manually and enable Motion & Fitness → Step Sync Assistant.');
    }
  }

  Future<void> _explainAndRequestPermission() async {
    // Just request directly - no need for long explanation
    _add(true, 'Opening permission dialog...');
    await Future.delayed(Duration(milliseconds: 500));
    await _requestPhysicalActivityPermission();
  }

  Future<void> _showManualPermissionSteps() async {
    final deviceInfo = await _batteryChecker.getDeviceInfo();
    final displayName = deviceInfo?['displayName'] ?? 'Android Device';

    _add(true,
      '📖 **Manual Steps to Grant Permission**\n\n'
      '**Your Device:** $displayName\n\n'
      '**Method 1 - App Settings (Recommended):**\n'
      '1. Open **Settings** on your phone\n'
      '2. Tap **Apps** or **Applications**\n'
      '3. Find and tap **Step Sync Assistant**\n'
      '4. Tap **Permissions**\n'
      '5. Find **Physical activity** in the list\n'
      '6. Tap it and select **Allow**\n\n'
      '**Method 2 - Permission Manager:**\n'
      '1. Open **Settings**\n'
      '2. Tap **Privacy** or **Security & Privacy**\n'
      '3. Tap **Permission manager**\n'
      '4. Tap **Physical activity**\n'
      '5. Find **Step Sync Assistant**\n'
      '6. Select **Allow**\n\n'
      'Once done, come back and tap "Check Again" to verify!',
      actions: [
        ActionButton(
          label: 'Check Again',
          icon: Icons.refresh,
          onPressed: () => _checkPermissions(),
        ),
        ActionButton(
          label: 'Try Automatic Fix',
          icon: Icons.auto_fix_high,
          onPressed: () => _explainAndRequestPermission(),
        ),
      ],
    );
  }

  Future<void> _checkHealthPlatforms() async {
    _add(true, '🏥 Checking health platforms...');

    if (Platform.isAndroid) {
      await _checkHealthConnect();
    } else if (Platform.isIOS) {
      await _checkHealthKit();
    } else {
      _add(true, '⚠️ Health platform checks are only available on Android and iOS devices.');
    }
  }

  Future<void> _checkHealthConnect() async {
    try {
      final availability = await _healthPlatformChecker.checkHealthConnectAvailability();

      if (availability.status == HealthPlatformStatus.builtIn) {
        _add(true,
          '✅ Health Connect available (built-in)',
          actions: [
            ActionButton(
              label: 'Grant Permissions',
              icon: Icons.health_and_safety,
              onPressed: () => _requestHealthConnectPermissions(),
            ),
          ],
        );
      } else if (availability.status == HealthPlatformStatus.available) {
        _add(true,
          '✅ Health Connect found\n\nGrant permissions to sync step data.',
          actions: [
            ActionButton(
              label: 'Grant Permissions',
              icon: Icons.health_and_safety,
              onPressed: () => _requestHealthConnectPermissions(),
            ),
          ],
        );
      } else if (availability.status == HealthPlatformStatus.needsUpdate) {
        _add(true,
          '⚠️ Health Connect needs update\n\nDownload the full version from Play Store.',
          actions: [
            ActionButton(
              label: 'Download Update',
              icon: Icons.cloud_download,
              onPressed: () => _installHealthConnect(),
            ),
          ],
        );
      } else if (availability.status == HealthPlatformStatus.notInstalled) {
        _add(true,
          '⚠️ Health Connect not installed\n\nInstall it to enable step tracking.',
          actions: [
            ActionButton(
              label: 'Install Health Connect',
              icon: Icons.download,
              onPressed: () => _installHealthConnect(),
            ),
          ],
        );
      } else if (availability.status == HealthPlatformStatus.notSupported) {
        _add(true, '⚠️ Health Connect not supported on this Android version');
      } else {
        _add(true, '❓ Could not check Health Connect. Try manually in Settings.');
      }
    } catch (e) {
      _log.e('Error checking Health Connect: $e');
      _add(true, '❌ Error checking Health Connect. Try again.');
    }
  }

  Future<void> _installHealthConnect() async {
    try {
      final success = await _healthPlatformChecker.openHealthConnectPlayStore();

      if (success) {
        _add(true,
          '📱 Install Health Connect, then tap button below.',
          actions: [
            ActionButton(
              label: 'Done Installing',
              icon: Icons.check_circle,
              onPressed: () => _verifyHealthConnectInstallation(),
            ),
          ],
        );
      } else {
        _add(true, '❌ Could not open Play Store\n\nSearch "Health Connect" manually.');
      }
    } catch (e) {
      _log.e('Error opening Play Store: $e');
      _add(true, '❌ Error opening Play Store');
    }
  }

  /// Verify Health Connect installation with retry logic
  ///
  /// After installing from Play Store, the SDK status may take a few seconds to update.
  /// This method polls the status with delays to detect the installation.
  Future<void> _verifyHealthConnectInstallation() async {
    try {

      // Retry checking with delays: 1s, 2s, 3s (total ~6 seconds)
      for (int attempt = 1; attempt <= 3; attempt++) {
        _log.d('Health Connect verification attempt $attempt/3');

        // Wait before checking (except first attempt)
        if (attempt > 1) {
          await Future.delayed(Duration(seconds: attempt));
        }

        final availability = await _healthPlatformChecker.checkHealthConnectAvailability();

        // Check if installation successful
        if (availability.status == HealthPlatformStatus.available ||
            availability.status == HealthPlatformStatus.builtIn) {
          _add(true,
            '✅ Health Connect installed\n\nNow grant permissions.',
            actions: [
              ActionButton(
                label: 'Grant Permissions',
                icon: Icons.health_and_safety,
                onPressed: () => _requestHealthConnectPermissions(),
              ),
            ],
          );
          return;
        }

        // If still showing needs update/stub, continue trying
        if (attempt < 3) {
          _log.d('Health Connect status: ${availability.status}, retrying...');
        }
      }

      // After all retries, still not detected
      _add(true,
        '⚠️ Not detected yet\n\nWait 20 seconds or open Health Connect app once.',
        actions: [
          ActionButton(
            label: 'Check Again',
            icon: Icons.refresh,
            onPressed: () => _verifyHealthConnectInstallation(),
          ),
        ],
      );

    } catch (e) {
      _log.e('Error verifying Health Connect installation: $e');
      _add(true, '❌ Could not verify installation');
    }
  }

  /// Open Health Connect app directly (to initialize it after installation)
  Future<void> _openHealthConnectApp() async {
    try {
      final success = await _healthPlatformChecker.requestHealthConnectPermissions();
      if (!success) {
        _add(true, '❌ Could not open Health Connect');
      }
    } catch (e) {
      _log.e('Error opening Health Connect app: $e');
    }
  }

  Future<void> _requestHealthConnectPermissions() async {
    try {
      // Silently check if permission is already granted
      bool hasPermission = false;
      try {
        hasPermission = await _healthPlatformChecker.checkHealthConnectPermissions();
        if (hasPermission) {
          // Permission already granted - advance to next issue
          setState(() => _currentIssueIndex++);
          if (_currentIssueIndex < _issueQueue.length) {
            final remaining = _issueQueue.length - _currentIssueIndex;
            _add(true, '✅ Fixed! $remaining more to go...');
            await Future.delayed(Duration(milliseconds: 800));
            _showNextIssue();
          } else {
            // All issues fixed - check steps
            await _checkStepsAfterFixes();
          }
          return;
        }
      } catch (e) {
        // Permission check failed - HC might not be available, proceed anyway
        _log.w('Permission check failed: $e');
      }

      // Open Health Connect permission screen
      final success = await _healthPlatformChecker.requestHealthConnectPermissions();

      if (!success) {
        _add(true, '❌ Could not open Health Connect');
        return;
      }

      // Add a single message that will update with timer
      _add(true, 'Checking permission status... 0s');
      final checkingMessageIndex = _messages.length - 1;
      final checkingMessageTime = _messages[checkingMessageIndex].time;

      // Create timer to update the message every second
      Timer? checkTimer;
      int elapsedSeconds = 0;
      bool permissionGranted = false;
      const maxAttempts = 5;
      const checkInterval = Duration(seconds: 4);
      int attempts = 0;

      checkTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        elapsedSeconds++;
        setState(() {
          if (checkingMessageIndex < _messages.length) {
            _messages[checkingMessageIndex] = ChatMessage(
              'Checking permission status... ${elapsedSeconds}s',
              true,
              checkingMessageTime,
            );
          }
        });
      });

      // Poll for permission with multiple checks (20 seconds total)
      while (attempts < maxAttempts && !permissionGranted) {
        await Future.delayed(checkInterval);
        attempts++;

        try {
          permissionGranted = await _healthPlatformChecker.checkHealthConnectPermissions();
          if (permissionGranted) {
            break;
          }
        } catch (e) {
          _log.w('Permission check attempt $attempts failed: $e');
        }
      }

      // Cancel the timer
      checkTimer?.cancel();

      if (permissionGranted) {
        // Permission granted - advance to next issue
        _add(true, '✅ Permission granted!');
        await Future.delayed(Duration(milliseconds: 500));

        setState(() => _currentIssueIndex++);
        if (_currentIssueIndex < _issueQueue.length) {
          await Future.delayed(Duration(milliseconds: 500));
          _showNextIssue();
        } else {
          // All issues fixed - check steps
          await _checkStepsAfterFixes();
        }
      } else {
        _add(true,
          '❌ Permission not granted\n\nPlease grant the permission.',
          actions: [
            ActionButton(
              label: 'Try Again',
              icon: Icons.refresh,
              onPressed: () => _requestHealthConnectPermissions(),
            ),
          ],
        );
      }
    } catch (e) {
      _log.e('Error requesting Health Connect permissions: $e');
      _add(true, '❌ Failed');
    }
  }

  Future<void> _checkHealthKit() async {
    try {
      final availability = await _healthPlatformChecker.checkHealthKitAvailability();

      if (!availability.available) {
        _add(true,
          '⚠️ **HealthKit Not Available**\n\n'
          'HealthKit is not available on this device.\n\n'
          '**Note:** HealthKit is typically not available on iPad and iPod touch.',
        );
        return;
      }

      if (availability.authStatus == HealthKitAuthStatus.authorized) {
        _add(true,
          '✅ **HealthKit Authorized**\n\n'
          'Your iPhone has permission to read step count from Apple Health.\n\n'
          'Step tracking should work correctly!',
        );
      } else if (availability.authStatus == HealthKitAuthStatus.denied) {
        _add(true,
          '❌ **HealthKit Permission Denied**\n\n'
          'Your iPhone cannot read step count from Apple Health.\n\n'
          '**To fix:**\n'
          '1. Tap "Open Settings" below\n'
          '2. Scroll to Health\n'
          '3. Find Step Sync Assistant\n'
          '4. Enable "Steps" permission',
          actions: [
            ActionButton(
              label: 'Open Settings',
              icon: Icons.settings,
              onPressed: () => _openIOSSettings(),
            ),
          ],
        );
      } else if (availability.authStatus == HealthKitAuthStatus.notDetermined) {
        _add(true,
          '📱 **HealthKit Permission Needed**\n\n'
          'To track steps, we need permission to read your step count from Apple Health.\n\n'
          'Tap the button below to grant permission.',
          actions: [
            ActionButton(
              label: 'Grant Permission',
              icon: Icons.health_and_safety,
              onPressed: () => _requestHealthKitAuthorization(),
            ),
          ],
        );
      } else {
        _add(true, '❓ Could not determine HealthKit status. Please check your iOS settings.');
      }
    } catch (e) {
      _log.e('Error checking HealthKit: $e');
      _add(true, '❌ Error checking HealthKit. Please try again or check Settings → Privacy & Security → Health.');
    }
  }

  Future<void> _requestHealthKitAuthorization() async {
    try {
      _add(true, '📱 Requesting HealthKit authorization...');
      final success = await _healthPlatformChecker.requestHealthKitAuthorization();

      if (success) {
        _add(true, 'HealthKit dialog opened. Please grant permissions...');

        // FLOW 2: Poll authorization status with increased delays for slow devices
        // iOS HealthKit authorization can take 1-2 seconds to appear on old devices
        bool authorized = false;
        for (int delay in [2, 3, 4]) {
          await Future.delayed(Duration(seconds: delay));
          final availability = await _healthPlatformChecker.checkHealthKitAvailability();
          if (availability.authStatus == HealthKitAuthStatus.authorized) {
            authorized = true;
            break;
          }
        }

        if (authorized) {
          _add(true,
            '✅ **HealthKit Authorized!**\n\n'
            'Great! HealthKit permissions have been granted.\n\n'
            'Let me check your data sources now...',
          );

          // Check data sources after successful permission grant
          await _checkHealthPlatforms();
        } else {
          // Check final status for better messaging
          final availability = await _healthPlatformChecker.checkHealthKitAvailability();

          if (availability.authStatus == HealthKitAuthStatus.notDetermined) {
            // User dismissed without choosing
            _add(true,
              '⚠️ **Authorization Dismissed**\n\n'
              'The authorization dialog was closed without granting permission.\n\n'
              'Would you like to try again?',
              actions: [
                ActionButton(
                  label: 'Try Again',
                  icon: Icons.refresh,
                  onPressed: () => _requestHealthKitAuthorization(),
                ),
              ],
            );
          } else if (availability.authStatus == HealthKitAuthStatus.denied) {
            // EDGE CASE: Explicitly denied
            _add(true,
              '🚫 **HealthKit Access Denied**\n\n'
              'You\'ve denied access to HealthKit.\n\n'
              'To enable it, you must go to Settings:\n'
              '1. Open Settings\n'
              '2. Privacy & Security → Health\n'
              '3. Data Access & Devices\n'
              '4. Step Sync Assistant → Enable Steps',
              actions: [
                ActionButton(
                  label: 'Open Settings',
                  icon: Icons.settings,
                  onPressed: () => _openIOSSettings(),
                ),
              ],
            );
          } else {
            _add(true,
              '⚠️ **Authorization Not Complete**\n\n'
              'It looks like you didn\'t authorize HealthKit access.\n\n'
              'Would you like to try again?',
              actions: [
                ActionButton(
                  label: 'Try Again',
                  icon: Icons.refresh,
                  onPressed: () => _requestHealthKitAuthorization(),
                ),
                ActionButton(
                  label: 'Open Settings',
                  icon: Icons.settings,
                  onPressed: () => _openIOSSettings(),
                ),
              ],
            );
          }
        }
      } else {
        _add(true, '❌ Could not request HealthKit authorization. Please check Settings → Privacy & Security → Health manually.');
      }
    } catch (e) {
      _log.e('Error requesting HealthKit authorization: $e');
      _add(true, '❌ Error requesting authorization. Please check your settings manually.');
    }
  }

  Future<void> _openIOSSettings() async {
    try {
      _add(true, '📱 Opening iOS Settings...');
      final success = await _permissionsChecker.openIOSSettings();

      if (success) {
        _isWaitingForPermission = true;
        _pendingPermissionType = 'healthkit';
        _add(true,
          '✅ **Settings Opened**\n\n'
          'Navigate to: Health → Data Access & Devices → Step Sync Assistant\n\n'
          'Enable "Steps" permission, then come back and I\'ll detect it automatically!',
          actions: [
            ActionButton(
              label: 'I Enabled It',
              icon: Icons.check_circle,
              onPressed: () => _checkHealthPlatforms(),
            ),
          ],
        );
      } else {
        _add(true, '❌ Could not open Settings. Please open Settings app manually.');
      }
    } catch (e) {
      _log.e('Error opening iOS Settings: $e');
      _add(true, '❌ Error opening Settings. Please check manually.');
    }
  }

  Future<void> _checkPowerManagement() async {
    _add(true, '🔋 Checking power management settings...');

    if (Platform.isAndroid) {
      await _checkAndroidPower();
    } else if (Platform.isIOS) {
      await _checkIOSPower();
    } else {
      _add(true, '⚠️ Power management checks are only available on Android and iOS devices.');
    }
  }

  Future<void> _checkAndroidPower() async {
    try {
      // Check Power Saving Mode
      final powerSaving = await _powerChecker.checkPowerSavingMode();

      // Check Doze Mode
      final dozeStatus = await _powerChecker.checkDozeModeStatus();

      final deviceInfo = await _batteryChecker.getDeviceInfo();
      final displayName = deviceInfo?['displayName'] ?? 'Android Device';

      // Build message based on findings
      StringBuffer message = StringBuffer();
      bool hasIssues = false;

      if (powerSaving.isEnabled) {
        hasIssues = true;
        message.write('⚠️ **Power Saving Mode Enabled**\n\n');
        message.write('Your device: $displayName\n\n');
        message.write('Power Saving Mode reduces background activity:\n');
        message.write('• Background sync may be delayed\n');
        message.write('• Network access limited\n');
        message.write('• Performance reduced\n\n');
        message.write('**Impact on step tracking:**\n');
        message.write('Steps may not sync until you open the app.\n\n');
      }

      if (dozeStatus.isDeviceInDozeMode) {
        hasIssues = true;
        message.write('🌙 **Device in Doze Mode**\n\n');
        message.write('Your device is in deep sleep to save battery.\n\n');
        message.write('**What this means:**\n');
        message.write('• Network access suspended\n');
        message.write('• Background sync paused\n');
        message.write('• App will sync when device wakes up\n\n');
      }

      if (dozeStatus.appStandbyBucket.isBadForBackground) {
        hasIssues = true;
        message.write('📊 **App Usage Bucket: ${dozeStatus.appStandbyBucket.description}**\n\n');
        message.write('Android categorized this app as ${dozeStatus.appStandbyBucket.description.toLowerCase()}.\n\n');
        message.write('**What this means:**\n');
        message.write('• App runs less frequently in background\n');
        message.write('• Sync intervals are extended\n');
        message.write('• Open the app regularly to improve\n\n');
      }

      if (!hasIssues) {
        _add(true,
          '✅ **Power Management Looks Good**\n\n'
          'Your device: $displayName\n\n'
          '• Power Saving Mode: Off\n'
          '• Doze Mode: Not active\n'
          '• App Standby: ${dozeStatus.appStandbyBucket.description}\n\n'
          'Background sync should work normally!',
        );
      } else {
        message.write('These are normal power-saving features.\n');
        message.write('Sync will resume when conditions improve.');

        List<ActionButton> actions = [];

        if (dozeStatus.appStandbyBucket.isBadForBackground && !dozeStatus.isAppWhitelisted) {
          actions.add(ActionButton(
            label: 'Request Whitelist',
            icon: Icons.battery_charging_full,
            onPressed: () => _requestDozeModeWhitelist(),
          ));
        }

        actions.add(ActionButton(
          label: 'Check Again',
          icon: Icons.refresh,
          onPressed: () => _checkPowerManagement(),
        ));

        _add(true, message.toString(), actions: actions);
      }
    } catch (e) {
      _log.e('Error checking Android power management: $e');
      _add(true, '❌ Error checking power management. Please try again.');
    }
  }

  Future<void> _checkIOSPower() async {
    try {
      // Check Low Power Mode
      final lowPowerMode = await _powerChecker.checkLowPowerMode();

      // Check Background App Refresh
      final backgroundRefresh = await _powerChecker.checkBackgroundAppRefresh();

      // Build message based on findings
      StringBuffer message = StringBuffer();
      bool hasIssues = false;
      List<ActionButton> actions = [];

      if (lowPowerMode.isEnabled) {
        hasIssues = true;
        message.write('🔋 **Low Power Mode Enabled**\n\n');
        message.write('Your iPhone is conserving battery.\n\n');
        message.write('**Impact:**\n');
        message.write('• Background App Refresh disabled\n');
        message.write('• Automatic downloads paused\n');
        message.write('• Visual effects reduced\n');
        message.write('• Step syncing paused until charged\n\n');
        message.write('**What to do:**\n');
        message.write('Charge your iPhone or disable Low Power Mode in Settings → Battery.\n\n');
      }

      if (backgroundRefresh.isBlocked) {
        hasIssues = true;
        message.write('⚠️ **Background App Refresh ${backgroundRefresh.description}**\n\n');

        if (backgroundRefresh == BackgroundAppRefreshStatus.disabled) {
          message.write('Background refresh is disabled for this app.\n\n');
          message.write('**Impact:**\n');
          message.write('• Steps only sync when app is open\n');
          message.write('• No automatic background updates\n\n');

          actions.add(ActionButton(
            label: 'Enable in Settings',
            icon: Icons.settings,
            onPressed: () => _openBackgroundAppRefreshSettings(),
          ));
        } else {
          message.write('Background refresh is restricted by system policy.\n\n');
          message.write('This may be due to parental controls or device management.\n\n');
        }
      }

      if (!hasIssues) {
        _add(true,
          '✅ **Power Management Looks Good**\n\n'
          'Your iPhone:\n\n'
          '• Low Power Mode: Off\n'
          '• Background App Refresh: Available\n\n'
          'Background sync should work normally!',
        );
      } else {
        actions.add(ActionButton(
          label: 'Check Again',
          icon: Icons.refresh,
          onPressed: () => _checkPowerManagement(),
        ));

        _add(true, message.toString(), actions: actions);
      }
    } catch (e) {
      _log.e('Error checking iOS power management: $e');
      _add(true, '❌ Error checking power management. Please try again.');
    }
  }

  Future<void> _requestDozeModeWhitelist() async {
    try {
      _add(true, '📱 Opening battery optimization settings...');
      final success = await _powerChecker.requestDozeModeWhitelist();

      if (success) {
        _add(true,
          '✅ **Settings Opened**\n\n'
          'Grant permission to ignore battery optimizations.\n\n'
          '**Note:** Use this only if you need real-time step syncing. '
          'It will increase battery usage.',
          actions: [
            ActionButton(
              label: 'I Granted It',
              icon: Icons.check_circle,
              onPressed: () => _add(true, '🎉 Great! Background sync should now work more reliably.'),
            ),
            ActionButton(
              label: 'Check Status',
              icon: Icons.refresh,
              onPressed: () => _checkPowerManagement(),
            ),
          ],
        );
      } else {
        _add(true, '❌ Could not open settings. Please check Settings → Battery → Battery optimization manually.');
      }
    } catch (e) {
      _log.e('Error requesting Doze whitelist: $e');
      _add(true, '❌ Error opening settings. Please try manually.');
    }
  }

  Future<void> _openBackgroundAppRefreshSettings() async {
    try {
      _add(true, '📱 Opening iOS Settings...');
      final success = await _powerChecker.openBackgroundAppRefreshSettings();

      if (success) {
        _add(true,
          '✅ **Settings Opened**\n\n'
          'Navigate to: General → Background App Refresh\n\n'
          'Enable it globally and for Step Sync Assistant.',
          actions: [
            ActionButton(
              label: 'I Enabled It',
              icon: Icons.check_circle,
              onPressed: () => _checkPowerManagement(),
            ),
          ],
        );
      } else {
        _add(true, '❌ Could not open Settings. Please open Settings app manually.');
      }
    } catch (e) {
      _log.e('Error opening Background App Refresh settings: $e');
      _add(true, '❌ Error opening Settings. Please try manually.');
    }
  }

  // ========================================================================
  // NETWORK & DATA CHECKING (WEEK 4)
  // ========================================================================

  Future<void> _checkNetwork() async {
    _add(true, '📶 Checking network and data settings...');

    if (Platform.isAndroid) {
      await _checkAndroidNetwork();
    } else {
      _add(true, '⚠️ Network diagnostics: Android only');
    }
  }

  Future<void> _checkAndroidNetwork() async {
    try {
      // Check Data Saver Mode
      final dataSaver = await _networkChecker.checkDataSaverMode();

      // Check Background Data Restriction
      final backgroundData = await _networkChecker.checkBackgroundDataRestriction();

      // Check Connectivity
      final connectivity = await _networkChecker.checkConnectivity();

      final deviceInfo = await _batteryChecker.getDeviceInfo();
      final displayName = deviceInfo?['displayName'] ?? 'Android Device';

      // Build message based on findings
      StringBuffer message = StringBuffer();
      bool hasIssues = false;
      List<ActionButton> actions = [];

      // Check connectivity first
      if (!connectivity.isConnected) {
        hasIssues = true;
        message.write('❌ **No Internet Connection**\n\n');
        message.write('Your device: $displayName\n\n');
        message.write('${connectivity.type.icon} Status: ${connectivity.type.description}\n\n');
        message.write('**What to check:**\n');
        message.write('• Enable WiFi or mobile data\n');
        message.write('• Check airplane mode is off\n');
        message.write('• Verify network settings\n\n');
      } else {
        message.write('✅ **Connected to ${connectivity.type.description}**\n\n');
        message.write('Your device: $displayName\n');
        if (connectivity.isMetered) {
          message.write('⚠️ Network Type: Metered (${connectivity.type.description})\n\n');
        } else {
          message.write('📶 Network Type: Unmetered (${connectivity.type.description})\n\n');
        }
      }

      // Check Data Saver Mode
      if (dataSaver.blocksBackgroundData) {
        hasIssues = true;
        message.write('⚠️ **Data Saver Mode Enabled**\n\n');
        message.write('Android 7+ Data Saver is blocking background data.\n\n');
        message.write('**Impact:**\n');
        message.write('• App cannot sync when closed\n');
        message.write('• Background network access blocked\n');
        message.write('• Only foreground apps can use data\n\n');
        message.write('**How to fix:**\n');
        message.write('Whitelist this app to allow background data.\n\n');

        actions.add(ActionButton(
          label: 'Whitelist App',
          icon: Icons.network_check,
          onPressed: () => _requestDataSaverWhitelist(),
        ));
      } else if (dataSaver == DataSaverStatus.whitelisted) {
        message.write('✅ **Data Saver: App Whitelisted**\n\n');
        message.write('Data Saver is enabled, but this app can use background data.\n\n');
      } else if (dataSaver == DataSaverStatus.disabled) {
        message.write('✅ **Data Saver: Disabled**\n\n');
        message.write('Background data is allowed for all apps.\n\n');
      }

      // Check Background Data Restriction
      if (backgroundData.isRestricted) {
        hasIssues = true;
        message.write('⚠️ **Background Data Restricted**\n\n');
        message.write('Background data is restricted for this app specifically.\n\n');
        message.write('**Impact:**\n');
        message.write('• Steps sync only when app is open\n');
        message.write('• Manual sync required\n\n');
        message.write('**How to fix:**\n');
        message.write('Settings → Apps → Step Sync → Mobile data & WiFi → Enable Background data\n\n');

        actions.add(ActionButton(
          label: 'Open Settings',
          icon: Icons.settings,
          onPressed: () => _openAppDataSettings(),
        ));
      } else {
        message.write('✅ **Background Data: Allowed**\n\n');
      }

      if (!hasIssues) {
        _add(true,
          '✅ **Network Settings Look Good**\n\n'
          'Your device: $displayName\n\n'
          '${connectivity.type.icon} Connection: ${connectivity.detailedDescription}\n'
          '📊 Data Saver: ${dataSaver.description}\n'
          '📶 Background Data: ${backgroundData.description}\n\n'
          'Network sync should work normally!',
        );
      } else {
        message.write('Fix these issues for reliable background sync.');

        actions.add(ActionButton(
          label: 'Check Again',
          icon: Icons.refresh,
          onPressed: () => _checkNetwork(),
        ));

        _add(true, message.toString(), actions: actions);
      }
    } catch (e) {
      _log.e('Error checking Android network: $e');
      _add(true, '❌ Error checking network settings. Please try again.');
    }
  }

  Future<void> _requestDataSaverWhitelist() async {
    try {
      _add(true, '📱 Opening Data Saver whitelist settings...');
      final success = await _networkChecker.requestDataSaverWhitelist();

      if (success) {
        _add(true,
          '✅ **Settings Opened**\n\n'
          'Enable "Unrestricted data usage" for Step Sync Assistant.\n\n'
          '**What this does:**\n'
          'Allows the app to use background data even when Data Saver is on.',
          actions: [
            ActionButton(
              label: 'I Whitelisted It',
              icon: Icons.check_circle,
              onPressed: () => _add(true, '🎉 Great! Background sync should now work even with Data Saver enabled.'),
            ),
            ActionButton(
              label: 'Check Status',
              icon: Icons.refresh,
              onPressed: () => _checkNetwork(),
            ),
          ],
        );
      } else {
        _add(true, '❌ Could not open settings. Please check Settings → Network & internet → Data Saver manually.');
      }
    } catch (e) {
      _log.e('Error requesting Data Saver whitelist: $e');
      _add(true, '❌ Error opening settings. Please try manually.');
    }
  }

  Future<void> _openAppDataSettings() async {
    try {
      _add(true, '📱 Opening app data settings...');
      final success = await _networkChecker.openAppDataSettings();

      if (success) {
        _add(true,
          '✅ **Settings Opened**\n\n'
          'Enable "Background data" for Step Sync Assistant.\n\n'
          '**Where to find it:**\n'
          'Mobile data & WiFi → Background data (toggle on)',
          actions: [
            ActionButton(
              label: 'I Enabled It',
              icon: Icons.check_circle,
              onPressed: () => _checkNetwork(),
            ),
          ],
        );
      } else {
        _add(true, '❌ Could not open settings. Please check Settings → Apps → Step Sync manually.');
      }
    } catch (e) {
      _log.e('Error opening app data settings: $e');
      _add(true, '❌ Error opening settings. Please try manually.');
    }
  }

  Future<void> _updatePlayServices() async {
    try {
      _add(true, '📱 Opening Google Play Services in Play Store...');
      final success = await _sensorsChecker.openPlayServicesInStore();

      if (success) {
        _add(true,
          '✅ **Play Store Opened**\n\n'
          'Update Google Play Services to the latest version, then return to this app.\n\n'
          '**Why this matters:**\n'
          'Health Connect requires up-to-date Play Services to work properly.',
          actions: [
            ActionButton(
              label: 'I Updated It',
              icon: Icons.check_circle,
              onPressed: () => _checkHealthPlatforms(),
            ),
          ],
        );
      } else {
        _add(true, '❌ Could not open Play Store. Please search for "Google Play Services" in Play Store manually.');
      }
    } catch (e) {
      _log.e('Error opening Play Services in store: $e');
      _add(true, '❌ Error opening Play Store. Please try manually.');
    }
  }

  Future<void> _openCellularDataSettings() async {
    try {
      _add(true, '📱 Opening iOS Settings...');
      final success = await _iosSettingsChecker.openCellularDataSettings();

      if (success) {
        _add(true,
          '✅ **Settings Opened**\n\n'
          'Enable Cellular Data for Step Sync Assistant:\n\n'
          '**Steps:**\n'
          '1. Scroll down to find "Step Sync Assistant"\n'
          '2. Toggle **ON** the switch\n'
          '3. Return to this app\n\n'
          '**Why this matters:**\n'
          'Fitbit sync requires internet. Without cellular data, sync only works on WiFi.',
          actions: [
            ActionButton(
              label: 'I Enabled It',
              icon: Icons.check_circle,
              onPressed: () => _askIfWorking(),
            ),
          ],
        );
      } else {
        _add(true,
          '❌ Could not open settings automatically.\n\n'
          '**Manual Steps:**\n'
          '1. Open **Settings** app\n'
          '2. Tap **Cellular** (or **Mobile Data**)\n'
          '3. Scroll down to find **Step Sync Assistant**\n'
          '4. Toggle **ON** the switch\n'
          '5. Return to this app'
        );
      }
    } catch (e) {
      _log.e('Error opening cellular data settings: $e');
      _add(true, '❌ Error opening settings. Please try manually: Settings → Cellular → Step Sync Assistant');
    }
  }

  // ========================================================================
  // STEP VERIFICATION - Read and verify step count from Health Connect
  // ========================================================================

  /// Verify step count from Health Connect
  Future<void> _verifyStepCount() async {
    if (!Platform.isAndroid) {
      _add(true, 'ℹ️ Step verification only works on Android');
      return;
    }

    // Add a single message that will update with timer
    _add(true, 'Verifying steps... 0s');
    final verifyingMessageIndex = _messages.length - 1;
    final verifyingMessageTime = _messages[verifyingMessageIndex].time;

    // Create timer to update the message every second
    Timer? verifyTimer;
    int elapsedSeconds = 0;

    verifyTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      elapsedSeconds++;
      setState(() {
        if (verifyingMessageIndex < _messages.length) {
          _messages[verifyingMessageIndex] = ChatMessage(
            'Verifying steps... ${elapsedSeconds}s',
            true,
            verifyingMessageTime,
          );
        }
      });
    });

    try {
      final result = await StepVerifier.readSteps();

      // Cancel the timer
      verifyTimer?.cancel();

      if (result.status == StepVerificationStatus.success) {
        final totalSteps = result.totalSteps ?? 0;
        final sources = result.sources ?? {};

        String stepMessage;
        if (sources.isEmpty) {
          stepMessage = '**Steps today:** $totalSteps\n\n⚠️ No data sources\n\nNo app is writing step data to Health Connect.';
        } else if (sources.length == 1) {
          final appName = _getAppName(sources.keys.first);
          stepMessage = '**Steps today:** $totalSteps\n\n**Source:** $appName';
        } else {
          final message = StringBuffer();
          message.write('**Steps today:** $totalSteps\n\n**Sources:**\n');
          for (final entry in sources.entries) {
            message.write('• ${_getAppName(entry.key)}: ${entry.value}\n');
          }
          stepMessage = message.toString();
        }

        // Show step count
        _add(true, stepMessage);

        // Ask if tracking is working
        await Future.delayed(Duration(milliseconds: 500));
        _add(true, 'Is step tracking working now?',
          actions: [
            ActionButton(
              label: 'Yes, It Works!',
              icon: Icons.check_circle,
              onPressed: () {
                setState(() {
                  _troubleshootLevel = 1;
                  _issueQueue.clear();
                  _currentIssueIndex = 0;
                  _totalIssuesFound = 0;
                  _isCheckingSteps = false;
                });
                _add(true, '✅ Perfect! Step tracking is working.');
              },
            ),
            ActionButton(
              label: 'Still Not Working',
              icon: Icons.error_outline,
              onPressed: () {
                setState(() {
                  _issueQueue.clear();
                  _currentIssueIndex = 0;
                  _totalIssuesFound = 0;
                  _isCheckingSteps = false;
                });
                _add(true,
                  '😔 I\'ve tried everything I can automatically fix.\n\n'
                  '**Need more help?**\n'
                  'Contact our support team:\n\n'
                  '📧 Email: support@stepsync.com\n'
                  '📱 Phone: +1 (555) 123-4567\n\n'
                  'They can help troubleshoot device-specific issues.',
                );
              },
            ),
          ],
        );

      } else if (result.status == StepVerificationStatus.permissionDenied) {
        _add(true,
          '🔒 Permission denied\n\nGrant permission to read step data.',
          actions: [
            ActionButton(
              label: 'Grant Permission',
              icon: Icons.security,
              onPressed: () => _requestStepsPermission(),
            ),
          ],
        );

      } else if (result.status == StepVerificationStatus.unavailable) {
        _add(true,
          '⚠️ Health Connect unavailable\n\nNot installed properly.',
          actions: [
            ActionButton(
              label: 'Check Health Connect',
              icon: Icons.health_and_safety,
              onPressed: () => _checkHealthPlatforms(),
            ),
          ],
        );

      } else if (result.status == StepVerificationStatus.error) {
        _add(true, '❌ Read error\n\nFailed to get step count. Try again.');
      } else {
        _add(true, '❓ Unknown status\n\nCheck Health Connect in Settings.');
      }

    } catch (e, stackTrace) {
      // Cancel the timer
      verifyTimer?.cancel();

      _log.e('Error verifying steps: $e\n$stackTrace');
      await CrashLogger.logError(
        error: e.toString(),
        stackTrace: stackTrace.toString(),
        context: 'Step verification failed',
      );
      _add(true, '❌ Could not read step count');
    }
  }

  /// Show steps directly without any "Verifying..." message (for button clicks)
  Future<void> _showStepsDirectly() async {
    if (!Platform.isAndroid) {
      _add(true, 'ℹ️ Step verification only works on Android');
      return;
    }

    try {
      final result = await StepVerifier.readSteps();

      if (result.status == StepVerificationStatus.success) {
        final totalSteps = result.totalSteps ?? 0;
        final sources = result.sources ?? {};

        String stepMessage;
        if (sources.isEmpty) {
          stepMessage = '**Steps today:** $totalSteps\n\n⚠️ No data sources\n\nNo app is writing step data to Health Connect.';
        } else if (sources.length == 1) {
          final appName = _getAppName(sources.keys.first);
          stepMessage = '**Steps today:** $totalSteps\n\n**Source:** $appName';
        } else {
          final message = StringBuffer();
          message.write('**Steps today:** $totalSteps\n\n**Sources:**\n');
          for (final entry in sources.entries) {
            message.write('• ${_getAppName(entry.key)}: ${entry.value}\n');
          }
          stepMessage = message.toString();
        }

        // Show step count with action buttons
        _add(true, stepMessage,
          actions: [
            ActionButton(
              label: 'Yes, Looks Right!',
              icon: Icons.check_circle,
              onPressed: () {
                _add(true, '✅ Great! Your steps are tracking correctly.');
              },
            ),
            ActionButton(
              label: 'Something\'s Wrong',
              icon: Icons.error_outline,
              onPressed: () {
                _add(true,
                  '😔 I see there\'s an issue with your step count.\n\n'
                  '**Need help?**\n'
                  'Contact our support team:\n\n'
                  '📧 Email: support@stepsync.com\n'
                  '📱 Phone: +1 (555) 123-4567\n\n'
                  'They can help investigate step tracking issues.',
                );
              },
            ),
          ],
        );

      } else if (result.status == StepVerificationStatus.permissionDenied) {
        _add(true,
          '🔒 Permission denied\n\nGrant permission to read step data.',
          actions: [
            ActionButton(
              label: 'Grant Permission',
              icon: Icons.security,
              onPressed: () => _requestStepsPermission(),
            ),
          ],
        );

      } else if (result.status == StepVerificationStatus.unavailable) {
        _add(true,
          '⚠️ Health Connect unavailable\n\nNot installed properly.',
          actions: [
            ActionButton(
              label: 'Check Health Connect',
              icon: Icons.health_and_safety,
              onPressed: () => _checkHealthPlatforms(),
            ),
          ],
        );

      } else if (result.status == StepVerificationStatus.error) {
        _add(true, '❌ Read error\n\nFailed to get step count. Try again.');
      } else {
        _add(true, '❓ Unknown status\n\nCheck Health Connect in Settings.');
      }

    } catch (e, stackTrace) {
      _log.e('Error showing steps: $e\n$stackTrace');
      await CrashLogger.logError(
        error: e.toString(),
        stackTrace: stackTrace.toString(),
        context: 'Show steps failed',
      );
      _add(true, '❌ Could not read step count');
    }
  }

  /// Request permission to read steps from Health Connect
  Future<void> _requestStepsPermission() async {
    try {
      final granted = await StepVerifier.requestPermission();

      if (granted) {
        _add(true,
          '✅ Permission granted\n\nTap below to check your steps.',
          actions: [
            ActionButton(
              label: 'Verify Steps',
              icon: Icons.check_circle,
              onPressed: () => _verifyStepCount(),
            ),
          ],
        );
      } else {
        _add(true, '❌ Permission dialog failed\n\nOpen Health Connect manually from Settings.');
      }
    } catch (e) {
      _log.e('Error requesting steps permission: $e');
      _add(true, '❌ Permission error');
    }
  }

  /// Open Health Connect settings
  Future<void> _openHealthConnectSettings() async {
    try {
      final success = await _healthPlatformChecker.requestHealthConnectPermissions();
      if (!success) {
        _add(true, '❌ Could not open Health Connect');
      }
    } catch (e) {
      _log.e('Error opening Health Connect settings: $e');
    }
  }

  /// Get human-readable app name from package name
  String _getAppName(String packageName) {
    // Map of common package names to friendly names
    final knownApps = {
      'com.google.android.apps.fitness': 'Google Fit',
      'com.samsung.health': 'Samsung Health',
      'com.fitbit.FitbitMobile': 'Fitbit',
      'com.garmin.android.apps.connectmobile': 'Garmin Connect',
      'com.xiaomi.hm.health': 'Mi Fitness',
      'com.sec.android.app.shealth': 'Samsung Health',
      'com.huawei.health': 'Huawei Health',
      'com.google.android.gms': 'Google Play Services',
      'com.android.healthconnect.controller': 'Health Connect',
      'android': 'Health Connect (Sensor data only)',
    };

    // Check if it's in known apps
    if (knownApps.containsKey(packageName)) {
      return knownApps[packageName]!;
    }

    // Check if it's a Nothing Phone package
    if (packageName.toLowerCase().contains('nothing')) {
      return 'Nothing Phone';
    }

    // For unknown packages, show a friendly name based on the package
    if (packageName.contains('.')) {
      final parts = packageName.split('.');
      // Try to get manufacturer or app name
      if (parts.length >= 2) {
        final company = parts[parts.length - 2];
        final app = parts.last;
        if (app == 'android' || app == 'health') {
          return '${_capitalize(company)} (${app})';
        }
        return _capitalize(app);
      }
    }

    return packageName;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // ========================================================================
  // SMART TROUBLESHOOTER - AUTO-DIAGNOSE AND FIX
  // ========================================================================

  Future<void> _runSmartTroubleshoot() async {
    final deviceInfo = await _batteryChecker.getDeviceInfo();
    final displayName = deviceInfo?['displayName'] ?? 'Your device';

    // Removed verbose analyzing messages - just show results

    try {
      // Storage for found issues
      List<Map<String, dynamic>> criticalIssues = [];
      List<Map<String, dynamic>> warningIssues = [];

      // LEVEL 1: CRITICAL CHECKS (Always run)
      if (Platform.isAndroid) {
        // 1. Physical Activity Permission
        try {
          final permission = await _permissionsChecker.checkPhysicalActivityPermission();
          if (permission == PermissionStatus.denied) {
            criticalIssues.add({
              'title': '🚨 Physical Activity permission denied',
              'description': 'I need this to read your step sensor data.',
              'buttonPurpose': 'Clicking will open Android settings to grant permission.',
              'action': 'Grant Activity Permission',
              'icon': Icons.error,
              'fix': () => _requestPhysicalActivityPermission(),
            });
          }
        } catch (e) {
          // Permission not applicable (Android < 10)
        }

        // 2. Battery Optimization
        try {
          final batteryResult = await _batteryChecker.checkBatteryOptimization();
          if (batteryResult == BatteryCheckResult.enabled) {
            criticalIssues.add({
              'title': '⚠️ Battery optimization enabled',
              'description': 'Your device restricts this app to save battery. Steps won\'t sync when closed.',
              'buttonPurpose': 'Clicking will open battery settings to disable optimization.',
              'action': 'Disable Battery Optimization',
              'icon': Icons.battery_alert,
              'fix': () => _requestBatteryExemption(),
            });
          }
        } catch (e) {
          _log.e('Battery check failed: $e');
        }

        // 3. Health Connect Availability & Permissions
        try {
          final healthConnect = await _healthPlatformChecker.checkHealthConnectAvailability();
          _log.i('=== HEALTH CONNECT CHECK ===');
          _log.i('Status: ${healthConnect.status.description}');
          _log.i('isStubOnly: ${healthConnect.isStubOnly}');
          _log.i('Version: ${healthConnect.version}');

          // Try to check permissions first - if we CAN check permissions, HC is functional
          bool canCheckPermissions = false;
          bool hasPermissions = false;
          String? permissionCheckError;

          try {
            hasPermissions = await _healthPlatformChecker.checkHealthConnectPermissions();
            canCheckPermissions = true;
            _log.i('✅ Permission check SUCCEEDED: hasPermissions=$hasPermissions');
          } catch (e) {
            canCheckPermissions = false;
            permissionCheckError = e.toString();
            _log.w('❌ Permission check FAILED: $e');
          }

          // If we can check permissions, HC is functional regardless of SDK status
          if (canCheckPermissions) {
            _log.i('HC is FUNCTIONAL (permission check succeeded)');
            if (!hasPermissions) {
              _log.w('Adding issue: permissions not granted');
              criticalIssues.add({
                'title': '🔒 Health Connect permissions not granted',
                'description': 'I need this permission to read your step data.\n\n**Follow these steps:**\n1. Tap **"Grant Permissions"** below\n2. Health Connect will open\n3. Tap **"App permissions"**\n4. Find **"Step Sync Assistant"** in the list\n5. Toggle **"Steps"** to ON\n6. Press back to return here',
                'buttonPurpose': 'This will open Health Connect settings.',
                'action': 'Grant Permissions',
                'icon': Icons.health_and_safety,
                'fix': () => _requestHealthConnectPermissions(),
              });
            } else {
              _log.i('HC has permissions - no issue to add');

              // Check if it's stub-only and suggest installing full version
              if (healthConnect.isStubOnly) {
                _log.i('HC is stub-only, adding recommendation to install full version');
                warningIssues.add({
                  'title': '💡 Consider installing full Health Connect',
                  'description': 'You\'re using the basic version. Install the full version from Play Store to sync with fitness apps like Google Fit, Fitbit, etc.',
                  'action': 'Install Full Version',
                  'icon': Icons.download,
                  'fix': () => _installHealthConnect(),
                });
              }
            }
          } else {
            // Cannot check permissions, check installation status
            _log.w('HC NOT FUNCTIONAL (permission check failed). SDK Status: ${healthConnect.status.description}. Error: $permissionCheckError');

            if (healthConnect.status == HealthPlatformStatus.notInstalled) {
              _log.w('Adding issue: not installed');
              criticalIssues.add({
                'title': '⚠️ Health Connect not installed',
                'description': 'Your device needs Health Connect to track steps.',
                'buttonPurpose': 'Clicking will open Play Store to install it.',
                'action': 'Install Health Connect',
                'icon': Icons.download,
                'fix': () => _installHealthConnect(),
              });
            } else if (healthConnect.status == HealthPlatformStatus.needsUpdate) {
              _log.w('Adding issue: needs update (stub version)');
              criticalIssues.add({
                'title': '⚠️ Health Connect needs update',
                'description': 'You have the basic version. Need the full version.',
                'buttonPurpose': 'Clicking will open Play Store to update it.',
                'action': 'Update Health Connect',
                'icon': Icons.system_update,
                'fix': () => _installHealthConnect(),
              });
            } else {
              _log.w('Unknown HC status: ${healthConnect.status.description} - no issue added');
            }
          }
        } catch (e) {
          // Not supported or other error
          _log.e('Health Connect check failed: $e');
        }

        // 4. Data Saver Mode
        try {
          final dataSaver = await _networkChecker.checkDataSaverMode();
          if (dataSaver.blocksBackgroundData) {
            criticalIssues.add({
              'title': '📶 Data Saver is blocking background sync',
              'description': 'Data Saver prevents background data usage. Steps won\'t upload.',
              'buttonPurpose': 'Clicking will open settings to whitelist this app.',
              'action': 'Whitelist This App',
              'icon': Icons.data_saver_off,
              'fix': () => _requestDataSaverWhitelist(),
            });
          }
        } catch (e) {
          // Data Saver not available
        }

        // 5. Background Data Restriction
        try {
          final backgroundData = await _networkChecker.checkBackgroundDataRestriction();
          if (backgroundData.isRestricted) {
            criticalIssues.add({
              'title': '🚫 Background data is restricted',
              'description': 'This app can\'t use mobile data in the background. Only syncs on Wi-Fi.',
              'buttonPurpose': 'Clicking will open app data settings to enable it.',
              'action': 'Enable Background Data',
              'icon': Icons.signal_cellular_off,
              'fix': () => _openAppDataSettings(),
            });
          }
        } catch (e) {
          _log.e('Background data check failed: $e');
        }

        // 6. Connectivity Check
        try {
          final connectivity = await _networkChecker.checkConnectivity();
          if (!connectivity.isConnected) {
            warningIssues.add({
              'title': '❌ No internet connection',
              'description': 'Can\'t sync without internet. Connect to Wi-Fi or mobile data.',
              'buttonPurpose': null,
              'action': null,
              'icon': Icons.wifi_off,
              'fix': null,
            });
          }
        } catch (e) {
          _log.e('Connectivity check failed: $e');
        }
      } else if (Platform.isIOS) {
        // iOS Critical Checks
        // 1. Motion & Fitness Permission
        try {
          final permission = await _permissionsChecker.checkMotionFitnessPermission();
          if (permission == PermissionStatus.denied) {
            criticalIssues.add({
              'title': '🚨 Motion & Fitness Permission Denied',
              'description': 'iPhone cannot track steps without this.',
              'action': 'Open Settings',
              'icon': Icons.error,
              'fix': () => _openIOSSettings(),
            });
          }
        } catch (e) {
          _log.e('Motion permission check failed: $e');
        }

        // 2. HealthKit Availability
        try {
          final healthKit = await _healthPlatformChecker.checkHealthKitAvailability();
          if (!healthKit.available) {
            criticalIssues.add({
              'title': '📱 HealthKit Not Available',
              'description': 'This device doesn\'t support Apple Health.',
              'action': null,
              'icon': Icons.error,
              'fix': null,
            });
          } else if (!healthKit.isAuthorized) {
            criticalIssues.add({
              'title': '🔒 HealthKit Access Denied',
              'description': 'Cannot read step count from Apple Health.',
              'action': 'Grant Access',
              'icon': Icons.lock,
              'fix': () => _requestHealthKitAuthorization(),
            });
          }
        } catch (e) {
          _log.e('HealthKit check failed: $e');
        }

        // 3. Low Power Mode
        try {
          final lowPowerMode = await _powerChecker.checkLowPowerMode();
          if (lowPowerMode.isEnabled) {
            warningIssues.add({
              'title': '🔋 Low Power Mode Enabled',
              'description': 'Background sync is paused.',
              'action': 'Open Settings',
              'icon': Icons.battery_saver,
              'fix': () => _openIOSSettings(),
            });
          }
        } catch (e) {
          _log.e('Low Power Mode check failed: $e');
        }

        // 4. Background App Refresh
        try {
          final backgroundRefresh = await _powerChecker.checkBackgroundAppRefresh();
          if (backgroundRefresh.isBlocked) {
            criticalIssues.add({
              'title': '⚠️ Background App Refresh Disabled',
              'description': 'Steps only sync when app is open.',
              'action': 'Enable Refresh',
              'icon': Icons.sync_disabled,
              'fix': () => _openBackgroundAppRefreshSettings(),
            });
          }
        } catch (e) {
          _log.e('Background Refresh check failed: $e');
        }
      }

      // LEVEL 2: DEEP CHECKS (Power management)
      if (_troubleshootLevel >= 2 && Platform.isAndroid) {
        // Power Saving Mode
        try {
          final powerSaving = await _powerChecker.checkPowerSavingMode();
          if (powerSaving.isEnabled) {
            warningIssues.add({
              'title': '🔋 Power Saving Mode Active',
              'description': 'Background activity is limited.',
              'action': null,
              'icon': Icons.power_settings_new,
              'fix': null,
            });
          }
        } catch (e) {
          _log.e('Power Saving check failed: $e');
        }

        // Doze Mode
        try {
          final dozeStatus = await _powerChecker.checkDozeModeStatus();
          if (dozeStatus.hasSignificantImpact && !dozeStatus.isAppWhitelisted) {
            warningIssues.add({
              'title': '🌙 Doze Mode Affecting Sync',
              'description': 'App usage bucket: ${dozeStatus.appStandbyBucket.description}',
              'action': 'Request Whitelist',
              'icon': Icons.nightlight,
              'fix': () => _requestDozeModeWhitelist(),
            });
          }
        } catch (e) {
          _log.e('Doze Mode check failed: $e');
        }
      }

      // LEVEL 3: EXTREME CHECKS (Hardware, sensors, system services)
      if (_troubleshootLevel >= 3) {
        if (Platform.isAndroid) {
          // Step Counter Sensor
          try {
            final sensorStatus = await _sensorsChecker.checkStepCounterSensor();
            if (sensorStatus == SensorStatus.notAvailable) {
              warningIssues.add({
                'title': '⚠️ Step Counter Sensor Missing',
                'description': 'Device lacks hardware step sensor. Battery usage will be higher.',
                'action': null,
                'icon': Icons.sensors_off,
                'fix': null,
              });
            }
          } catch (e) {
            _log.e('Sensor check failed: $e');
          }

          // Google Play Services (Android 9-13 only)
          try {
            final playServices = await _sensorsChecker.checkPlayServices();
            if (playServices == PlayServicesStatus.unavailable) {
              criticalIssues.add({
                'title': '📱 Google Play Services Outdated',
                'description': 'Health Connect requires updated Play Services.',
                'action': 'Update Now',
                'icon': Icons.system_update,
                'fix': () => _updatePlayServices(),
              });
            }
          } catch (e) {
            _log.e('Play Services check failed: $e');
          }
        } else if (Platform.isIOS) {
          // iOS Cellular Data Status (Critical for Fitbit sync)
          try {
            final cellularData = await _iosSettingsChecker.checkCellularDataStatus();
            if (cellularData == CellularDataStatus.disabled) {
              warningIssues.add({
                'title': '📱 Cellular Data Disabled for App',
                'description': 'Fitbit sync only works on WiFi. Enable cellular data for real-time sync.',
                'action': 'Open Settings',
                'icon': Icons.signal_cellular_off,
                'fix': () => _openCellularDataSettings(),
              });
            }
          } catch (e) {
            _log.e('Cellular data check failed: $e');
          }
        }
      }

      // BUILD SMART RESPONSE
      await _buildSmartResponse(criticalIssues, warningIssues, displayName);

    } catch (e) {
      _log.e('Smart troubleshoot failed: $e');
      _add(true, '❌ Diagnostics failed');
    }
  }

  Future<void> _buildSmartResponse(
    List<Map<String, dynamic>> criticalIssues,
    List<Map<String, dynamic>> warningIssues,
    String displayName,
  ) async {
    StringBuffer message = StringBuffer();
    List<ActionButton> actions = [];

    // NO ISSUES FOUND
    if (criticalIssues.isEmpty && warningIssues.isEmpty) {
      message.write('✅ System check complete\n\n');
      message.write('All permissions and settings look correct.\n\n');
      message.write('Now let\'s verify your steps are syncing.');

      actions.add(ActionButton(
        label: 'Verify Steps',
        icon: Icons.check_circle,
        onPressed: () async {
          setState(() => _isCheckingSteps = false);
          await _verifyStepCount();
        },
      ));

      _add(true, message.toString(), actions: actions.isEmpty ? null : actions);
      return;
    }

    // ISSUES FOUND - Use progressive approach
    // Combine critical and warning issues
    _issueQueue = [...criticalIssues, ...warningIssues];
    _totalIssuesFound = _issueQueue.length;
    _currentIssueIndex = 0;
    _isCheckingSteps = false; // Reset flag for new troubleshooting session

    // Show first issue with progress indicator
    _showNextIssue();
  }

  void _showNextIssue() {
    // All issues resolved
    if (_currentIssueIndex >= _issueQueue.length) {
      // Check current step count after all fixes
      _checkStepsAfterFixes();
      return;
    }

    final issue = _issueQueue[_currentIssueIndex];

    // Apply Miller's Law + Gestalt Proximity: Group related info
    StringBuffer message = StringBuffer();

    // Progress indicator (Visibility of system status - Nielsen)
    if (_totalIssuesFound > 1) {
      message.write('Issue ${_currentIssueIndex + 1} of $_totalIssuesFound');
      message.write('\n\n');
    }

    // Title with clear hierarchy (Figure-Ground principle)
    message.write('**${issue['title']}**');
    message.write('\n\n');

    // Description - chunked for readability (Miller's Law: 7±2 chunks)
    if (issue['description'] != null && issue['description'].toString().isNotEmpty) {
      message.write(issue['description']);
      message.write('\n\n');
    }

    // Secondary info - grouped by common region (Gestalt)
    if (issue['buttonPurpose'] != null && issue['buttonPurpose'].toString().isNotEmpty) {
      message.write('> ${issue['buttonPurpose']}');
    }

    List<ActionButton> actions = [];
    if (issue['action'] != null && issue['fix'] != null) {
      actions.add(ActionButton(
        label: issue['action'] as String,
        icon: issue['icon'] as IconData,
        onPressed: () async {
          // Execute the fix - it will handle advancement internally
          await (issue['fix'] as Function)();
        },
      ));
    }

    _add(true, message.toString(), actions: actions.isEmpty ? null : actions);
  }

  Future<void> _checkStepsAfterFixes() async {
    // Prevent duplicate execution
    if (_isCheckingSteps) {
      _log.w('Already checking steps, skipping duplicate call');
      return;
    }

    setState(() => _isCheckingSteps = true);

    try {
      // Verify steps silently in background
      final result = await StepVerifier.readSteps();

      // Reset the checking flag
      setState(() => _isCheckingSteps = false);

      // Build combined message
      StringBuffer message = StringBuffer();
      message.write('✅ All issues resolved!\n\n');

      if (result.status == StepVerificationStatus.success) {
        final totalSteps = result.totalSteps ?? 0;
        final sources = result.sources ?? {};

        message.write('**Steps today:** $totalSteps\n\n');

        if (sources.isEmpty) {
          message.write('⚠️ No data sources\n\nNo app is writing step data to Health Connect.');
        } else if (sources.length == 1) {
          final appName = _getAppName(sources.keys.first);
          message.write('**Source:** $appName');
        } else {
          message.write('**Sources:**\n');
          for (final entry in sources.entries) {
            message.write('• ${_getAppName(entry.key)}: ${entry.value}\n');
          }
        }

        // Show combined message
        _add(true, message.toString());

        // Determine what to show next based on step count and sources
        await Future.delayed(Duration(milliseconds: 500));

        if (totalSteps == 0 && sources.isNotEmpty) {
          // Successfully retrieved 0 steps with sources - user hasn't walked yet
          _add(true,
            '✅ I\'ve tried everything I can.\n\n'
            'Your step count is 0 because you haven\'t walked yet today.\n\n'
            'All settings are correct and step tracking should work when you start walking.',
            actions: [
              ActionButton(
                label: 'I Walked, Check Again',
                icon: Icons.directions_walk,
                onPressed: () => _recheckStepsAfterWalking(),
              ),
            ],
          );
        } else {
          // Either steps > 0, or steps == 0 with no sources (which needs verification)
          // Ask if tracking is working
          _add(true, 'Is step tracking working now?',
            actions: [
              ActionButton(
                label: 'Yes, It Works!',
                icon: Icons.check_circle,
                onPressed: () {
                  setState(() {
                    _troubleshootLevel = 1;
                    _issueQueue.clear();
                    _currentIssueIndex = 0;
                    _totalIssuesFound = 0;
                    _isCheckingSteps = false;
                  });
                  _add(true, '✅ Perfect! Step tracking is working.');
                },
              ),
              ActionButton(
                label: 'Still Not Working',
                icon: Icons.error_outline,
                onPressed: () {
                  setState(() {
                    _issueQueue.clear();
                    _currentIssueIndex = 0;
                    _totalIssuesFound = 0;
                    _isCheckingSteps = false;
                  });
                  _add(true,
                    '😔 I\'ve tried everything I can automatically fix.\n\n'
                    '**Need more help?**\n'
                    'Contact our support team:\n\n'
                    '📧 Email: support@stepsync.com\n'
                    '📱 Phone: +1 (555) 123-4567\n\n'
                    'They can help troubleshoot device-specific issues.',
                  );
                },
              ),
            ],
          );
        }

      } else if (result.status == StepVerificationStatus.permissionDenied) {
        message.write('🔒 Permission needed to verify steps.\n\nPlease grant permission to read step data.');
        _add(true, message.toString(),
          actions: [
            ActionButton(
              label: 'Grant Permission',
              icon: Icons.security,
              onPressed: () => _requestStepsPermission(),
            ),
          ],
        );

      } else if (result.status == StepVerificationStatus.unavailable) {
        message.write('⚠️ Health Connect unavailable.\n\nNot installed properly.');
        _add(true, message.toString(),
          actions: [
            ActionButton(
              label: 'Check Health Connect',
              icon: Icons.health_and_safety,
              onPressed: () => _checkHealthPlatforms(),
            ),
          ],
        );

      } else {
        message.write('❌ Could not verify steps.\n\nTry checking manually.');
        _add(true, message.toString());
      }

    } catch (e) {
      _log.e('Error in checkStepsAfterFixes: $e');
      setState(() => _isCheckingSteps = false);
      _add(true, '✅ All issues resolved!\n\n❌ Could not verify steps automatically.');
    }
  }

  /// Recheck steps after user has walked (handles the "I Walked, Check Again" flow)
  Future<void> _recheckStepsAfterWalking() async {
    if (!Platform.isAndroid) {
      _add(true, 'ℹ️ Step verification only works on Android');
      return;
    }

    // Prevent duplicate execution if user clicks button multiple times
    if (_isCheckingSteps) {
      _log.w('Already checking steps, skipping duplicate recheck');
      return;
    }

    setState(() => _isCheckingSteps = true);

    // Add a single message that will update with timer
    _add(true, 'Verifying steps... 0s');
    final verifyingMessageIndex = _messages.length - 1;
    final verifyingMessageTime = _messages[verifyingMessageIndex].time;

    // Create timer to update the message every second
    Timer? verifyTimer;
    int elapsedSeconds = 0;

    verifyTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      elapsedSeconds++;
      setState(() {
        if (verifyingMessageIndex < _messages.length) {
          _messages[verifyingMessageIndex] = ChatMessage(
            'Verifying steps... ${elapsedSeconds}s',
            true,
            verifyingMessageTime,
          );
        }
      });
    });

    try {
      final result = await StepVerifier.readSteps();

      // Cancel the timer
      verifyTimer?.cancel();

      // Reset the checking flag
      setState(() => _isCheckingSteps = false);

      if (result.status == StepVerificationStatus.success) {
        final totalSteps = result.totalSteps ?? 0;
        final sources = result.sources ?? {};

        // Build message
        StringBuffer message = StringBuffer();
        message.write('**Steps today:** $totalSteps\n\n');

        if (sources.isEmpty) {
          message.write('⚠️ No data sources\n\nNo app is writing step data to Health Connect.');
        } else if (sources.length == 1) {
          final appName = _getAppName(sources.keys.first);
          message.write('**Source:** $appName');
        } else {
          message.write('**Sources:**\n');
          for (final entry in sources.entries) {
            message.write('• ${_getAppName(entry.key)}: ${entry.value}\n');
          }
        }

        // Show step count
        _add(true, message.toString());

        await Future.delayed(Duration(milliseconds: 500));

        if (totalSteps == 0 && sources.isNotEmpty) {
          // Still 0 after walking - something's wrong
          _add(true,
            '🤔 Still showing 0 steps.\n\n'
            'Even after walking, your step count hasn\'t updated. This might be a device-specific issue.',
            actions: [
              ActionButton(
                label: 'Get Support',
                icon: Icons.support_agent,
                onPressed: () {
                  _add(true,
                    '**Need more help?**\n'
                    'Contact our support team:\n\n'
                    '📧 Email: support@stepsync.com\n'
                    '📱 Phone: +1 (555) 123-4567\n\n'
                    'They can help troubleshoot device-specific issues.',
                  );
                },
              ),
            ],
          );
        } else if (totalSteps == 0 && sources.isEmpty) {
          // 0 steps with no sources - data source issue
          _add(true,
            '⚠️ No data sources found.\n\n'
            'No app is writing step data to Health Connect. Please check your fitness app settings.',
          );
        } else {
          // Steps > 0 - tracking is working!
          _add(true, 'Is step tracking working now?',
            actions: [
              ActionButton(
                label: 'Yes, It Works!',
                icon: Icons.check_circle,
                onPressed: () {
                  setState(() {
                    _troubleshootLevel = 1;
                    _issueQueue.clear();
                    _currentIssueIndex = 0;
                    _totalIssuesFound = 0;
                    _isCheckingSteps = false;
                  });
                  _add(true, '✅ Perfect! Step tracking is working.');
                },
              ),
              ActionButton(
                label: 'Still Not Working',
                icon: Icons.error_outline,
                onPressed: () {
                  setState(() {
                    _issueQueue.clear();
                    _currentIssueIndex = 0;
                    _totalIssuesFound = 0;
                    _isCheckingSteps = false;
                  });
                  _add(true,
                    '😔 I\'ve tried everything I can automatically fix.\n\n'
                    '**Need more help?**\n'
                    'Contact our support team:\n\n'
                    '📧 Email: support@stepsync.com\n'
                    '📱 Phone: +1 (555) 123-4567\n\n'
                    'They can help troubleshoot device-specific issues.',
                  );
                },
              ),
            ],
          );
        }

      } else if (result.status == StepVerificationStatus.permissionDenied) {
        _add(true,
          '🔒 Permission denied\n\nGrant permission to read step data.',
          actions: [
            ActionButton(
              label: 'Grant Permission',
              icon: Icons.security,
              onPressed: () => _requestStepsPermission(),
            ),
          ],
        );

      } else if (result.status == StepVerificationStatus.unavailable) {
        _add(true,
          '⚠️ Health Connect unavailable\n\nNot installed properly.',
          actions: [
            ActionButton(
              label: 'Check Health Connect',
              icon: Icons.health_and_safety,
              onPressed: () => _checkHealthPlatforms(),
            ),
          ],
        );

      } else if (result.status == StepVerificationStatus.error) {
        _add(true, '❌ Read error\n\nFailed to get step count. Try again.');
      } else {
        _add(true, '❓ Unknown status\n\nCheck Health Connect in Settings.');
      }

    } catch (e, stackTrace) {
      // Cancel the timer
      verifyTimer?.cancel();

      // Reset the checking flag
      setState(() => _isCheckingSteps = false);

      _log.e('Error rechecking steps: $e\n$stackTrace');
      await CrashLogger.logError(
        error: e.toString(),
        stackTrace: stackTrace.toString(),
        context: 'Step recheck after walking failed',
      );
      _add(true, '❌ Could not read step count');
    }
  }

  void _askIfWorking() {
    _add(true,
      'Is step sync working now?',
      actions: [
        ActionButton(
          label: 'Yes, Working!',
          icon: Icons.check_circle,
          onPressed: () {
            setState(() => _troubleshootLevel = 1); // Reset for future
            _add(true, '✅ Perfect! Step tracking is working.');
          },
        ),
        ActionButton(
          label: 'Still Not Working',
          icon: Icons.error_outline,
          onPressed: () async {
            setState(() => _troubleshootLevel++);
            await _runSmartTroubleshoot();
          },
        ),
      ],
    );
  }

  // ========================================================================
  // BONUS TIPS - NON-CRITICAL UX ENHANCEMENTS
  // ========================================================================

  /// Adds bonus tips for non-critical features that enhance UX but don't
  /// block step syncing. Only shown when all critical checks pass.
  ///
  /// Features checked here:
  /// - Notification Permission (Android 13+)
  /// - Future non-critical features can be added here
  Future<void> _addBonusTips(StringBuffer message, List<ActionButton> actions) async {
    bool hasTips = false;

    // Check notification permission (Android 13+ only)
    if (Platform.isAndroid) {
      try {
        final notifPerm = await _permissionsChecker.checkNotificationPermission();
        if (notifPerm == PermissionStatus.denied) {
          if (!hasTips) {
            message.write('---\n\n');
            message.write('💡 **Bonus Tips** _(Optional - doesn\'t affect step tracking)_\n\n');
            hasTips = true;
          }

          message.write('**Enable Notifications:**\n');
          message.write('Get alerts about sync status and updates.\n\n');

          actions.add(ActionButton(
            label: 'Enable Notifications',
            icon: Icons.notifications,
            onPressed: () => _requestNotificationPermission(),
          ));
        }
      } catch (e) {
        // Notification permission not applicable (Android < 13) or error
        _log.d('Notification check skipped: $e');
      }
    }

    // Future bonus tips can be added here:
    // - Battery level warnings
    // - Storage space checks
    // - App updates available
    // - Other non-critical enhancements
  }

  Future<void> _send() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;

    final lowerMsg = msg.toLowerCase();

    // Check for explicit diagnostic commands only (user must explicitly ask)
    if (lowerMsg == 'check permissions' ||
        lowerMsg == 'run diagnostics' ||
        lowerMsg == 'check my permissions' ||
        lowerMsg == 'diagnostic') {
      _add(false, msg);
      _controller.clear();
      await _checkPermissions();
      return;
    }

    // Check for health platform commands
    if (lowerMsg == 'check health' ||
        lowerMsg == 'check health connect' ||
        lowerMsg == 'check healthkit' ||
        lowerMsg == 'health platforms') {
      _add(false, msg);
      _controller.clear();
      await _checkHealthPlatforms();
      return;
    }

    // Check for power management commands
    if (lowerMsg == 'check power' ||
        lowerMsg == 'check battery' ||
        lowerMsg == 'power mode' ||
        lowerMsg == 'low power mode' ||
        lowerMsg == 'doze mode') {
      _add(false, msg);
      _controller.clear();
      await _checkPowerManagement();
      return;
    }

    // Check for network commands
    if (lowerMsg == 'check network' ||
        lowerMsg == 'check data' ||
        lowerMsg == 'data saver' ||
        lowerMsg == 'wifi' ||
        lowerMsg == 'cellular' ||
        lowerMsg == 'connectivity' ||
        lowerMsg == 'network issues') {
      _add(false, msg);
      _controller.clear();
      await _checkNetwork();
      return;
    }

    // Check for step verification commands
    if (lowerMsg == 'verify steps' ||
        lowerMsg == 'check steps' ||
        lowerMsg == 'read steps' ||
        lowerMsg == 'step count' ||
        lowerMsg == 'my steps' ||
        lowerMsg == 'show steps' ||
        lowerMsg == 'show my steps' ||
        lowerMsg.contains('verify') && lowerMsg.contains('step')) {
      _add(false, msg);
      _controller.clear();
      await _verifyStepCount();
      return;
    }

    // Check for acknowledgement/completion messages that shouldn't trigger LLM
    if (lowerMsg == 'done' ||
        lowerMsg == 'ok' ||
        lowerMsg == 'okay' ||
        lowerMsg == 'thanks' ||
        lowerMsg == 'thank you' ||
        lowerMsg == 'got it') {
      _add(false, msg);
      _controller.clear();
      // Just acknowledge, don't send to LLM
      return;
    }

    // SMART TROUBLESHOOTER - Auto-detect ANY problem and run diagnostics immediately
    final isProblemReport =
        // Sync/tracking issues
        lowerMsg.contains('not syncing') ||
        lowerMsg.contains('not working') ||
        lowerMsg.contains('stopped syncing') ||
        lowerMsg.contains('steps not syncing') ||
        lowerMsg.contains('sync stopped') ||
        lowerMsg.contains('not tracking') ||
        lowerMsg.contains('stopped tracking') ||
        lowerMsg.contains('not counting') ||
        lowerMsg.contains('stopped counting') ||
        lowerMsg.contains('steps') && (lowerMsg.contains('not') || lowerMsg.contains('no')) ||
        lowerMsg.contains('still not working') ||
        lowerMsg.contains('still not syncing') ||
        // General problem keywords
        lowerMsg.contains('issue') ||
        lowerMsg.contains('problem') ||
        lowerMsg.contains('trouble') ||
        lowerMsg.contains('having trouble') ||
        lowerMsg.contains('help') && lowerMsg.length < 30 || // Short help messages
        lowerMsg.contains('fix') && !lowerMsg.contains('how to') || // "fix it" not "how to fix"
        lowerMsg.contains('broken') ||
        lowerMsg.contains('wrong') ||
        lowerMsg.contains('incorrect') ||
        lowerMsg.contains('missing') ||
        lowerMsg.contains('can\'t') ||
        lowerMsg.contains('cannot') ||
        lowerMsg.contains('don\'t work') ||
        lowerMsg.contains('doesn\'t work') ||
        lowerMsg.contains('won\'t') ||
        // Zero/low steps
        lowerMsg.contains('0 steps') ||
        lowerMsg.contains('zero steps') ||
        lowerMsg.contains('no steps') ||
        // Permission hints
        lowerMsg.contains('permission') && !lowerMsg.startsWith('check');

    if (isProblemReport) {
      _add(false, msg);
      _controller.clear();

      // Reset to level 1 if new problem, or increment if "still not working"
      if (lowerMsg.contains('still')) {
        _troubleshootLevel = (_troubleshootLevel < 3) ? _troubleshootLevel + 1 : 3;
      } else {
        _troubleshootLevel = 1;
      }

      await _runSmartTroubleshoot();
      return;
    }

    // Check for battery keywords
    if (lowerMsg.contains('battery') ||
        lowerMsg.contains('background') ||
        lowerMsg.contains('close') && lowerMsg.contains('app') ||
        lowerMsg.contains('not syncing') && lowerMsg.contains('closed')) {
      _add(false, msg);
      _controller.clear();

      if (Platform.isAndroid) {
        await _checkBatteryOptimization();
        return;
      }
    }

    _add(false, msg);
    _controller.clear();

    // FLOW 13: OFFLINE MODE CHECK - Check connectivity first
    final isOnline = await OfflineHandler.isOnline();
    if (!isOnline) {
      _isOffline = true;
      final offlineResponse = OfflineHandler.getOfflineFallback(msg);
      _add(true, offlineResponse);
      _log.w('User is offline, provided template fallback');
      return;
    }
    _isOffline = false;

    // FLOW 6: MULTI-TURN CONTEXT - Update conversation context
    _context.updateFromMessage(msg);
    if (_deviceDetected) {
      _context.deviceInfo = {
        'name': _deviceName,
        'version': _androidVersion,
        'manufacturer': _manufacturer,
      };
    }

    // FLOW 5: SENTIMENT DETECTION - Detect user frustration
    final sentiment = SentimentDetector.detect(msg);
    _context.lastSentiment = sentiment.name;

    setState(() => _loading = true);

    // FLOW 9: PHI SANITIZATION - Sanitize before sending to LLM
    final sanitizedMsg = PHISanitizer.sanitize(msg);
    if (PHISanitizer.containsPHI(msg)) {
      final phiTypes = PHISanitizer.detectPHITypes(msg);
      _log.w('PHI detected and sanitized: ${phiTypes.join(", ")}');
    }

    // Build conversation history (exclude action messages)
    final history = _messages
        .where((m) => m.actions == null)
        .map((m) => {'role': m.isBot ? 'assistant' : 'user', 'content': m.text})
        .toList();

    // Build device context
    final platform = Platform.isAndroid ? 'Android' : 'iOS';
    final deviceContext = _deviceDetected
        ? 'User\'s device: $_deviceName${_androidVersion.isNotEmpty ? " (Android $_androidVersion)" : ""}${_manufacturer.isNotEmpty ? " by $_manufacturer" : ""}'
        : 'User\'s platform: $platform';

    // Build system prompt with sentiment and context
    final contextSummary = _context.getContextSummary();
    final sentimentPrompt = SentimentDetector.getEmpatheticPrompt(sentiment);

    final baseSystemPrompt = '''You are a Step Sync troubleshooting assistant - an expert at helping users resolve step tracking issues.

━━━ DEVICE CONTEXT (AUTO-DETECTED) ━━━
$deviceContext$contextSummary

**IMPORTANT:** You ALREADY KNOW the user's device. DO NOT ask "What device are you using?" or "iPhone or Android?". The device info above is automatically detected.

━━━ AUTOMATIC DIAGNOSTICS ━━━
**CRITICAL:** When users report ANY problem, the system AUTOMATICALLY runs full diagnostics BEFORE you respond. You will see diagnostic results in the conversation history.

**DO NOT:**
• Ask "Would you like me to run diagnostics?"
• Say "Let me check your settings"
• Offer to run checks - they're ALREADY DONE
• Mention issues that were NOT detected (e.g., don't say "check battery" if battery is fine)
• Give generic advice about issues that don't exist

**INSTEAD:**
• **ONLY talk about issues that are ACTUALLY DETECTED in diagnostics**
• Review the diagnostic results shown above
• Acknowledge specific issues found (e.g., "I see **battery optimization** is enabled")
• If NO issues detected, say so briefly and suggest support contact if problem persists

$sentimentPrompt

━━━ CORE IDENTITY ━━━
• You are a human support specialist (NEVER reveal you're AI/LLM/bot)
• Show empathy and acknowledge user frustration
• Be conversational, patient, and encouraging
• Be PROACTIVE - analyze problems immediately

━━━ RESPONSE STYLE ━━━
• **CRITICAL: Keep responses EXTREMELY SHORT - max 2-3 sentences**
• NO long explanations, NO step-by-step instructions, NO detailed guides
• Use **bold** for key terms only
• **BE CERTAIN, NEVER use "likely", "probably", "might be", "could be", "maybe"**
• **If you're uncertain about the issue, give support contact instead of guessing**
• Trust that the automated troubleshooter handles the heavy lifting
• Examples of GOOD responses:
  - "Got it!"
  - "That should help - let me know if issues persist."
  - "The issue is **battery optimization**."
  - "I need more information. Contact support: support@stepsync.com or +1 (555) 123-4567"
• Examples of BAD responses (DON'T DO THIS):
  - "The issue is likely battery optimization" (remove "likely")
  - "It might be a permission problem" (remove "might be")
  - Long paragraphs or step-by-step instructions
  - Multiple suggestions with "Additionally" or "Also try"''';

    // FLOW 11: TOKEN COUNTING - Trim history to fit context window
    final trimmedHistory = TokenCounter.trimToFit(
      systemPrompt: baseSystemPrompt,
      history: history,
      currentMessage: sanitizedMsg,
    );

    if (trimmedHistory.length < history.length) {
      _log.i('Trimmed history from ${history.length} to ${trimmedHistory.length} messages to fit token limit');
    }

    // FLOW 10: CIRCUIT BREAKER - Wrap API call with circuit breaker
    final result = await _circuitBreaker.execute<String>(
      () async {
        final body = {
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': baseSystemPrompt},
            ...trimmedHistory,
            {'role': 'user', 'content': sanitizedMsg}
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        };

        final client = http.Client();
        try {
          final res = await client.post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              'User-Agent': 'StepSyncChatbot/1.0 (Flutter; Mobile)',
            },
            body: jsonEncode(body),
          ).timeout(Duration(seconds: 15));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            return data['choices'][0]['message']['content'] as String;
          } else {
            _log.e('API error: ${res.statusCode}');
            throw Exception('API error: ${res.statusCode}');
          }
        } finally {
          client.close();
        }
      },
      fallback: () {
        // Circuit breaker fallback - use template response
        _log.w('Circuit breaker open or API failed, using template fallback');
        return _getOfflineFallback(msg);
      },
    );

    // Display the result (either LLM response or fallback)
    // Fix bullet point formatting for proper markdown rendering
    final formattedResult = _fixBulletPoints(result);
    _add(true, formattedResult);

    setState(() => _loading = false);
  }

  /// Fix bullet point formatting for proper markdown rendering
  /// Ensures each bullet point is on its own line with proper spacing
  String _fixBulletPoints(String text) {
    // Replace single newline before bullet with double newline
    // This ensures each bullet renders on a separate line
    return text
        .replaceAll('\n•', '\n\n•')
        .replaceAll('\n-', '\n\n-')
        .replaceAll('\n*', '\n\n*')
        // Fix cases where we might have added too many newlines
        .replaceAll('\n\n\n•', '\n\n•')
        .replaceAll('\n\n\n-', '\n\n-')
        .replaceAll('\n\n\n*', '\n\n*');
  }

  String _getOfflineFallback(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('hi') || lower.contains('hello') || lower.contains('hey')) {
      return 'Hi! I\'m here to help with step tracking issues.\n\n**What\'s going on with your steps?**\n\nCommon issues:\n\n• Not syncing\n\n• Wrong count\n\n• Missing data\n\n• Background sync problems';
    }

    if (lower.contains('sync') && (lower.contains('stop') || lower.contains('not') || lower.contains('isn\'t'))) {
      return '**Steps Not Syncing?**\n\nMost common causes:\n\n**1. Battery Optimization** (tap battery icon above ⚡)\nDisable battery optimization for this app\n\n**2. Permissions**\nEnsure Motion & Fitness permission granted\n\n**3. Background Data**\nAllow app to use data in background\n\nWhich device: iPhone or Android?';
    }

    if (lower.contains('permission')) {
      return '**Permission Issues:**\n\n**Android:**\nSettings → Apps → Step Sync Assistant → Permissions → Enable all\n\n**iPhone:**\nSettings → Privacy & Security → Motion & Fitness → Enable for your app\n\nHave you granted permissions?';
    }

    if (lower.contains('iphone') || lower.contains('ios')) {
      return '**iPhone Step Tracking:**\n\n**Check these:**\n\n• Settings → Privacy → Motion & Fitness → ON\n\n• Low Power Mode OFF (Settings → Battery)\n\n• Apple Health app installed and working\n\nWhat specific issue are you having?';
    }

    if (lower.contains('android')) {
      return '**Android Step Tracking:**\n\n**Priority checks:**\n1. **Battery optimization** (tap ⚡ icon above)\n2. Health Connect installed (Android 14+)\n3. Background data enabled\n\nTap the battery icon to check optimization!';
    }

    // Auto-detected device context
    final platform = Platform.isAndroid ? 'Android' : 'iOS';
    final deviceInfo = _deviceDetected ? ' on your $_deviceName' : '';

    return '**I can help with$deviceInfo:**\n\n• Battery optimization issues (tap ⚡ above)\n\n• Permission problems\n\n• Step syncing troubleshooting\n\n• Background tracking issues\n\nWhat seems to be the problem?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: surfaceColor,
        title: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.directions_walk,
                color: primaryColor,
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step Sync Assistant',
                  style: TextStyle(
                    color: textPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Healthcare Support',
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Crash Log Viewer Button
          FutureBuilder<bool>(
            future: CrashLogger.hasCrashLogs(),
            builder: (context, snapshot) {
              final hasCrashes = snapshot.data ?? false;
              return Container(
                margin: EdgeInsets.only(right: 4),
                child: IconButton(
                  icon: Stack(
                    children: [
                      Icon(Icons.bug_report_outlined, color: textSecondaryColor, size: 24),
                      if (hasCrashes)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: errorColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'View Crash Logs',
                  onPressed: () => _showCrashLogs(context),
                ),
              );
            },
          ),
          // Clear Chat Button
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: textSecondaryColor, size: 24),
              tooltip: 'Clear Chat History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Clear Chat History?'),
                    content: Text('This will delete all conversation history. You cannot undo this action.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _clearChat();
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _buildAvatar(true),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: botMessageColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Typing...',
                                style: TextStyle(
                                  color: textSecondaryColor,
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final msg = _messages[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: msg.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.isBot) ...[
                            _buildAvatar(true),
                            SizedBox(width: 12),
                          ],
                          Flexible(
                            child: Container(
                              // Gestalt: Common Region - clear visual grouping
                              // WhatsApp-style compact padding
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                // WhatsApp-style solid colors
                                color: msg.isBot ? botMessageColor : userMessageColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(msg.isBot ? 2 : 16),
                                  topRight: Radius.circular(msg.isBot ? 16 : 2),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                // Minimal shadow like WhatsApp
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: msg.isBot
                                  ? MarkdownBody(
                                      data: msg.text,
                                      builders: {
                                        'blockquote': BlockquoteBuilder(),
                                      },
                                      styleSheet: MarkdownStyleSheet(
                                        // Readability: Optimal line height 1.6-1.8 for body text
                                        // Law of Similarity: Consistent text patterns
                                        p: TextStyle(
                                          color: textPrimaryColor,
                                          fontSize: 15,
                                          height: 1.65,
                                          letterSpacing: 0.15,
                                        ),
                                        // Figure-ground: Bold text stands out clearly
                                        strong: TextStyle(
                                          color: textPrimaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          height: 1.4,
                                          letterSpacing: 0.1,
                                        ),
                                        listBullet: TextStyle(
                                          color: primaryColor,
                                          fontSize: 15,
                                          height: 1.65,
                                        ),
                                        listBulletPadding: EdgeInsets.only(right: 8),
                                        listIndent: 24,
                                        h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimaryColor, height: 1.3, letterSpacing: -0.3),
                                        h2: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimaryColor, height: 1.35, letterSpacing: -0.2),
                                        h3: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryColor, height: 1.4, letterSpacing: 0),
                                        // Secondary info: De-emphasized through color + size
                                        blockquote: TextStyle(
                                          color: Color(0xFF1A73E8),
                                          fontSize: 13,
                                          height: 1.5,
                                          letterSpacing: 0.1,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        blockquoteDecoration: BoxDecoration(
                                          color: Color(0xFFE8F0FE),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        blockquotePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        code: TextStyle(
                                          backgroundColor: Color(0xFFF6F8FA),
                                          color: Color(0xFFD73A49),
                                          fontSize: 13,
                                        ),
                                        codeblockDecoration: BoxDecoration(
                                          color: Color(0xFFF6F8FA),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: borderColor, width: 1),
                                        ),
                                        codeblockPadding: EdgeInsets.all(12),
                                      ),
                                    )
                                  : Text(
                                      msg.text,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.5,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),
                          if (!msg.isBot) ...[
                            SizedBox(width: 12),
                            _buildAvatar(false),
                          ],
                        ],
                      ),
                      if (msg.actions != null && msg.actions!.isNotEmpty) ...[
                        SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.only(left: msg.isBot ? 44 : 0, right: msg.isBot ? 0 : 44),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: msg.actions!.map((action) => _buildActionButton(action)).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: surfaceColor,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(color: textSecondaryColor, fontSize: 16),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: TextStyle(fontSize: 16, color: textPrimaryColor),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // FLOW 14: Microphone button for voice input
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isListening ? errorColor : Color(0xFFECEFF1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? surfaceColor : Color(0xFF607D8B),
                        size: 22,
                      ),
                      onPressed: _loading
                          ? null
                          : _isListening
                              ? _stopListening
                              : _startListening,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _loading ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isBot) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isBot
          ? primaryColor.withOpacity(0.15)
          : Color(0xFFD1D7DB),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isBot ? Icons.directions_walk : Icons.person_rounded,
        color: isBot ? primaryColor : Color(0xFF54656F),
        size: 22,
      ),
    );
  }

  Widget _buildActionButton(ActionButton action) {
    // WhatsApp-style pill buttons with minimal shadow
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: 18),
        label: Text(
          action.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            height: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: Size(100, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReply(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFF2196F3), width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Color(0xFF2196F3),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom builder for full-width blockquotes
class BlockquoteBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Get the text content from the blockquote element
    final String text = element.textContent;

    return Container(
      width: double.infinity, // Full width
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Color(0xFF1A73E8),
          fontSize: 13,
          height: 1.5,
          letterSpacing: 0.1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime time;
  final List<ActionButton>? actions;
  ChatMessage(this.text, this.isBot, this.time, {this.actions});
}

class ActionButton {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  ActionButton({required this.label, required this.icon, required this.onPressed});
}
