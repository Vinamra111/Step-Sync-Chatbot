import '../data/models/chat_message.dart';
import 'intents.dart';

/// Response templates for each user intent.
///
/// Templates define the bot's responses to different user intents.
/// They include text and optional quick reply buttons.
class ConversationTemplates {
  /// Get response for a given intent.
  static ChatMessage getResponse(
    UserIntent intent, {
    Map<String, dynamic> context = const {},
  }) {
    switch (intent) {
      case UserIntent.greeting:
        return _greetingResponse(context);

      case UserIntent.thanks:
        return _thanksResponse();

      case UserIntent.whyPermissionNeeded:
        return _whyPermissionNeededResponse();

      case UserIntent.wantToGrantPermission:
        return _wantToGrantPermissionResponse();

      case UserIntent.permissionDenied:
        return _permissionDeniedResponse();

      case UserIntent.stepsNotSyncing:
        return _stepsNotSyncingResponse();

      case UserIntent.syncDelayed:
        return _syncDelayedResponse();

      case UserIntent.wrongStepCount:
        return _wrongStepCountResponse();

      case UserIntent.duplicateSteps:
        return _duplicateStepsResponse();

      case UserIntent.dataMissing:
        return _dataMissingResponse();

      case UserIntent.multipleAppsConflict:
      case UserIntent.multipleDataSources: // Alias for multipleAppsConflict
        return _multipleAppsConflictResponse();

      case UserIntent.wantToSwitchSource:
        return _wantToSwitchSourceResponse();

      case UserIntent.batteryOptimizationIssue:
      case UserIntent.batteryOptimization: // Alias for batteryOptimizationIssue
        return _batteryOptimizationResponse();

      case UserIntent.healthConnectNotInstalled:
      case UserIntent.needsHealthConnect: // Alias for healthConnectNotInstalled
        return _healthConnectNotInstalledResponse();

      case UserIntent.checkingStatus:
        return _checkingStatusResponse();

      case UserIntent.needHelp:
        return _needHelpResponse();

      case UserIntent.unclear:
        return _unclearResponse();
    }
  }

  static ChatMessage _greetingResponse(Map<String, dynamic> context) {
    return ChatMessage.bot(
      text: 'Hi! I\'m Step Sync Assistant. I help fix step syncing issues.\n\n'
          'Let me check your setup...',
      quickReplies: [
        QuickReply(label: 'Steps not syncing', value: 'steps_not_syncing'),
        QuickReply(label: 'Wrong step count', value: 'wrong_count'),
        QuickReply(label: 'Just checking in', value: 'checking_status'),
      ],
    );
  }

  static ChatMessage _thanksResponse() {
    return ChatMessage.bot(
      text: 'You\'re welcome! Let me know if you need anything else.',
      quickReplies: [
        QuickReply(label: 'Check status', value: 'check_status'),
        QuickReply(label: 'All done', value: 'done'),
      ],
    );
  }

  static ChatMessage _whyPermissionNeededResponse() {
    return ChatMessage.bot(
      text: 'Fair question! Here\'s why:\n\n'
          '📊 Step Count Permission:\n'
          '• Reads your daily step data\n'
          '• Detects syncing issues\n'
          '• Shows accurate counts\n\n'
          '🏃 Activity Data Permission:\n'
          '• Identifies your data sources (Fitbit, watch, etc.)\n'
          '• Filters duplicate entries\n'
          '• Detects manual vs automatic tracking\n\n'
          '🔒 Your data stays private and is never shared with AI.',
      quickReplies: [
        QuickReply(label: 'Grant permission', value: 'grant_permission'),
        QuickReply(label: 'Not now', value: 'not_now'),
      ],
    );
  }

  static ChatMessage _wantToGrantPermissionResponse() {
    return ChatMessage.bot(
      text: 'Great! I\'ll open the permission settings for you.\n\n'
          'Please select:\n'
          '✓ Steps\n'
          '✓ Activity\n\n'
          'Then tap "Allow".',
      quickReplies: [
        QuickReply(label: 'Open settings', value: 'open_settings'),
      ],
    );
  }

  static ChatMessage _permissionDeniedResponse() {
    return ChatMessage.bot(
      text: 'I notice permissions are denied. To track your steps, '
          'I need access to step count and activity data.\n\n'
          'Would you like to grant permission now?',
      quickReplies: [
        QuickReply(label: 'Yes, grant permission', value: 'grant_permission'),
        QuickReply(label: 'Why do you need it?', value: 'why_permission'),
      ],
    );
  }

  static ChatMessage _stepsNotSyncingResponse() {
    return ChatMessage.bot(
      text: 'Let me help figure out what\'s going on.\n\n'
          'When did you last see steps sync?',
      quickReplies: [
        QuickReply(label: 'Today', value: 'today'),
        QuickReply(label: 'Yesterday', value: 'yesterday'),
        QuickReply(label: 'Days ago', value: 'days_ago'),
        QuickReply(label: 'Never synced', value: 'never'),
      ],
    );
  }

  static ChatMessage _syncDelayedResponse() {
    return ChatMessage.bot(
      text: 'Sync delays can happen for a few reasons. '
          'Let me check your setup...\n\n'
          'Running diagnostics...',
    );
  }

  static ChatMessage _wrongStepCountResponse() {
    return ChatMessage.bot(
      text: 'Step count mismatches can happen when:\n'
          '• Multiple apps are tracking steps\n'
          '• Manual entries are included\n'
          '• Different algorithms are used\n\n'
          'Let me check your data sources...',
    );
  }

  static ChatMessage _duplicateStepsResponse() {
    return ChatMessage.bot(
      text: 'Duplicate steps usually mean multiple apps are tracking '
          'at the same time.\n\n'
          'Let me scan for data sources...',
    );
  }

  static ChatMessage _dataMissingResponse() {
    return ChatMessage.bot(
      text: 'Let me help find your missing data.\n\n'
          'Which time period is missing?',
      quickReplies: [
        QuickReply(label: 'Today', value: 'today'),
        QuickReply(label: 'Yesterday', value: 'yesterday'),
        QuickReply(label: 'This week', value: 'this_week'),
        QuickReply(label: 'Older data', value: 'older'),
      ],
    );
  }

  static ChatMessage _multipleAppsConflictResponse() {
    return ChatMessage.bot(
      text: 'Multiple fitness apps can cause conflicts. '
          'I\'ll scan your connected apps and help you choose a primary source...\n\n'
          'Scanning...',
    );
  }

  static ChatMessage _wantToSwitchSourceResponse() {
    return ChatMessage.bot(
      text: 'I can help you switch your primary data source.\n\n'
          'Let me check what\'s currently connected...',
    );
  }

  static ChatMessage _batteryOptimizationResponse() {
    return ChatMessage.bot(
      text: 'Battery optimization can block background sync. '
          'Let me check your settings...',
    );
  }

  static ChatMessage _healthConnectNotInstalledResponse() {
    return ChatMessage.bot(
      text: 'Your Android version requires the Health Connect app.\n\n'
          'Install Health Connect to track steps:\n'
          '1. Download from Google Play Store\n'
          '2. Open and set up\n'
          '3. Come back here to continue',
      quickReplies: [
        QuickReply(label: 'Open Play Store', value: 'open_play_store'),
        QuickReply(label: 'I installed it', value: 'check_again'),
      ],
    );
  }

  static ChatMessage _checkingStatusResponse() {
    return ChatMessage.bot(
      text: 'Let me check your setup...\n\n'
          'Checking:\n'
          '• Permissions\n'
          '• Data sources\n'
          '• Sync status',
    );
  }

  static ChatMessage _needHelpResponse() {
    return ChatMessage.bot(
      text: 'I\'m here to help! What are you having trouble with?',
      quickReplies: [
        QuickReply(label: 'Steps not syncing', value: 'steps_not_syncing'),
        QuickReply(label: 'Wrong step count', value: 'wrong_count'),
        QuickReply(label: 'Multiple apps', value: 'multiple_apps'),
        QuickReply(label: 'Something else', value: 'other'),
      ],
    );
  }

  static ChatMessage _unclearResponse() {
    return ChatMessage.bot(
      text: 'I\'m not quite sure what you need. Can you choose from these options?',
      quickReplies: [
        QuickReply(label: 'Permissions & Settings', value: 'permissions'),
        QuickReply(label: 'Syncing Issues', value: 'syncing'),
        QuickReply(label: 'Data & Privacy', value: 'data'),
        QuickReply(label: 'Contact Support', value: 'support'),
      ],
    );
  }
}
