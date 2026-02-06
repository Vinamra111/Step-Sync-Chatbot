/// Offline Knowledge Base
///
/// Provides pre-cached responses for common step tracking questions.
/// Features:
/// - Pattern-based matching
/// - Fuzzy search support
/// - Multi-language support (future)
/// - Confidence scoring
/// - Contextual responses

import 'package:logger/logger.dart';
import '../data/models/chat_message.dart';

/// Knowledge base entry
class KnowledgeEntry {
  final String id;
  final List<String> patterns;
  final String response;
  final List<String> keywords;
  final double confidence;
  final Map<String, dynamic> metadata;

  const KnowledgeEntry({
    required this.id,
    required this.patterns,
    required this.response,
    this.keywords = const [],
    this.confidence = 0.9,
    this.metadata = const {},
  });
}

/// Knowledge base match result
class KnowledgeMatch {
  final KnowledgeEntry entry;
  final double confidence;
  final String matchedPattern;

  const KnowledgeMatch({
    required this.entry,
    required this.confidence,
    required this.matchedPattern,
  });

  ChatMessage toMessage() {
    return ChatMessage.bot(
      text: entry.response,
      data: {
        'source': 'offline_knowledge_base',
        'confidence': confidence,
        'matched_pattern': matchedPattern,
        ...entry.metadata,
      },
    );
  }
}

/// Offline Knowledge Base Service
class OfflineKnowledgeBase {
  final Logger _logger;
  final List<KnowledgeEntry> _entries;

  /// Minimum confidence threshold for matches
  final double minConfidence;

  OfflineKnowledgeBase({
    Logger? logger,
    this.minConfidence = 0.7,
  })  : _logger = logger ?? Logger(),
        _entries = _buildKnowledgeBase();

  /// Build the knowledge base with common Q&A
  static List<KnowledgeEntry> _buildKnowledgeBase() {
    return [
      // Permission Issues
      KnowledgeEntry(
        id: 'permission_denied',
        patterns: [
          r'\bpermission\b.*\bdenied\b',
          r"\bcan'?t access\b",
          r'\bno permission\b',
          r'\ballow access\b',
        ],
        keywords: ['permission', 'denied', 'access', 'allow'],
        response: '''
📱 **Permission Issue**

It looks like the app doesn't have permission to access your step data. Here's how to fix it:

**iOS:**
1. Open **Settings** → **Privacy & Security** → **Health**
2. Tap your app name
3. Enable **Steps** (turn it ON)
4. Return to the app

**Android:**
1. Open **Settings** → **Apps** → Your app
2. Tap **Permissions**
3. Enable **Physical activity** permission
4. Return to the app

Try these steps and let me know if it works!
''',
        confidence: 0.95,
        metadata: {'category': 'permissions'},
      ),

      // Steps Not Syncing
      KnowledgeEntry(
        id: 'steps_not_syncing',
        patterns: [
          r'\bsteps?\b.*\bnot (sync|updat|track|count)',
          r'\b(sync|updat).*\bnot work',
          r'\bsteps?\b.*\bmissing\b',
        ],
        keywords: ['steps', 'sync', 'not', 'update', 'missing'],
        response: '''
🔄 **Steps Not Syncing**

Let's troubleshoot step syncing issues:

**Quick Fixes:**
1. ✅ Check app permissions (Health/Fitness)
2. ✅ Restart the app completely
3. ✅ Check if your phone's pedometer is working
4. ✅ Make sure battery saver isn't blocking the app

**iOS Specific:**
- Go to Health app → Browse → Activity → Steps
- Check if any steps are recorded today
- If yes, the issue is with app permissions

**Android Specific:**
- Go to Google Fit app → Profile → Settings
- Check "Track your activities" is enabled
- Verify connected apps include your app

**Still not working?**
When you're back online, I can run a detailed diagnostic to identify the exact issue.
''',
        confidence: 0.92,
        metadata: {'category': 'syncing'},
      ),

      // Wrong Step Count
      KnowledgeEntry(
        id: 'wrong_count',
        patterns: [
          r'\bwrong\b.*\b(count|number)',
          r'\b(count|number)\b.*\bwrong\b',
          r'\bstep\b.*\bcount\b.*\bwrong\b',
          r'\b(in)?accurate\b.*\bsteps?\b',
          r'\bsteps?\b.*\b(too (high|low)|incorrect|wrong)',
        ],
        keywords: ['wrong', 'count', 'inaccurate', 'incorrect'],
        response: '''
🔢 **Incorrect Step Count**

If your step count looks wrong, here's what might help:

**Common Causes:**
1. **Multiple Data Sources**: Your phone and fitness tracker might both be counting
2. **Duplicate Entries**: Apps can sometimes double-count steps
3. **Calibration**: Your device may need calibration for your stride

**How to Fix:**
1. Check for duplicate data sources in Health/Google Fit
2. Set ONE primary data source (phone OR tracker, not both)
3. Delete duplicate entries if you find any
4. For fitness trackers: Verify they're properly synced

**iOS - Set Primary Source:**
- Health app → Browse → Activity → Steps → Data Sources & Access
- Drag your preferred source to the top

**Android - Manage Sources:**
- Google Fit → Profile → Settings → Manage connected apps
- Disconnect duplicate sources

When online, I can analyze your data sources for you.
''',
        confidence: 0.90,
        metadata: {'category': 'data_quality'},
      ),

      // App Not Tracking
      KnowledgeEntry(
        id: 'app_not_tracking',
        patterns: [
          r'\bapp\b.*\bnot (track|record|count)',
          r'\bno steps?\b.*\btoday\b',
          r'\bstopped (track|record)',
        ],
        keywords: ['app', 'not', 'tracking', 'stopped'],
        response: '''
⚠️ **App Not Tracking Steps**

If the app stopped tracking, try these steps:

**Immediate Fixes:**
1. ✅ Force close and reopen the app
2. ✅ Check if Motion & Fitness permission is enabled
3. ✅ Disable battery optimization for this app
4. ✅ Check if "Background App Refresh" is ON (iOS)

**Battery Settings:**
- **iOS**: Settings → Your App → Background App Refresh → ON
- **Android**: Settings → Apps → Your App → Battery → Unrestricted

**Motion Permission:**
- **iOS**: Settings → Privacy → Motion & Fitness → Your App → ON
- **Android**: Settings → Apps → Permissions → Physical Activity → Allow

**Pro Tip:**
Some phones have aggressive battery saving that stops step counting in the background. Check your phone's battery optimization settings.

Restart the app after making these changes!
''',
        confidence: 0.93,
        metadata: {'category': 'tracking'},
      ),

      // Data Not Loading
      KnowledgeEntry(
        id: 'data_not_loading',
        patterns: [
          r'\bdata\b.*\bnot (load|show|appear)',
          r'\bempty\b.*\b(screen|page)',
          r'\bno data\b',
        ],
        keywords: ['data', 'loading', 'empty', 'show'],
        response: '''
💾 **Data Not Loading**

If your step data isn't showing up:

**Quick Checks:**
1. Pull down to refresh the screen
2. Check your internet connection
3. Verify the app has permission to read health data
4. Try logging out and back in

**Offline Mode:**
Right now you're offline, so only cached data is available. The full data will load once you're back online.

**If Data Was Deleted:**
Health data is stored securely on your device. If you see no data:
- Check if you recently reset your phone
- Verify you're signed in to the correct account
- Check if you disabled health tracking in system settings

When you're online again, I can help recover or re-sync your data.
''',
        confidence: 0.88,
        metadata: {'category': 'data'},
      ),

      // Battery Drain
      KnowledgeEntry(
        id: 'battery_drain',
        patterns: [
          r'\bbattery\b.*\b(drain|usage|consum)',
          r'\bdraining\b.*\bbattery\b',
          r'\bhigh battery\b',
        ],
        keywords: ['battery', 'drain', 'usage'],
        response: '''
🔋 **Battery Concerns**

Step tracking uses minimal battery, but here's how to optimize:

**Battery-Saving Tips:**
1. Use your phone's built-in pedometer (not GPS)
2. Disable continuous heart rate monitoring if available
3. Reduce sync frequency if the app allows
4. Don't force-quit the app (iOS manages background apps efficiently)

**Expected Usage:**
- Normal step tracking: 1-3% battery per day
- GPS tracking: 5-10% per hour
- Background sync: <1% per day

**If Battery Drain is High:**
1. Check if another app is using GPS
2. Update to the latest app version
3. Restart your phone (clears background processes)
4. Check Settings → Battery to see actual app usage

Step tracking itself is very battery-efficient. High usage usually indicates GPS or continuous sync issues.
''',
        confidence: 0.85,
        metadata: {'category': 'performance'},
      ),

      // Greeting
      KnowledgeEntry(
        id: 'greeting',
        patterns: [
          r'\b(hi|hello|hey|greetings)\b',
          r'\bgood (morning|afternoon|evening)\b',
          r"\bwhat's up\b",
        ],
        keywords: ['hi', 'hello', 'hey', 'greetings'],
        response: '''
👋 Hi! I'm the Step Sync Assistant.

**⚠️ Offline Mode**
You're currently offline, so I have limited capabilities. I can still help with common step tracking issues using my offline knowledge base!

**What I Can Help With (Offline):**
- Permission problems
- Steps not syncing
- Incorrect step counts
- App not tracking
- Battery concerns

**What I Need Internet For:**
- Detailed diagnostics
- Real-time data analysis
- Advanced troubleshooting
- Account-specific issues

Ask me anything about step tracking!
''',
        confidence: 0.98,
        metadata: {'category': 'greeting'},
      ),

      // Help Request
      KnowledgeEntry(
        id: 'help',
        patterns: [
          r'\bhelp\b',
          r'\bhow (do|can)\b',
          r'\bwhat can you\b',
        ],
        keywords: ['help', 'how', 'what'],
        response: '''
🆘 **How I Can Help**

**⚠️ You're Offline**
Right now, I can provide help with common issues from my offline knowledge base.

**Common Issues I Can Solve:**
1. 📱 Permission problems
2. 🔄 Steps not syncing
3. 🔢 Wrong step counts
4. ⚠️ App not tracking
5. 🔋 Battery concerns
6. 💾 Data not loading

**When You're Back Online:**
I'll have access to advanced diagnostics, real-time data analysis, and personalized troubleshooting.

**How to Use:**
Just describe your issue in plain language. For example:
- "My steps aren't syncing"
- "I have permission issues"
- "The step count is wrong"

What's the issue you're facing?
''',
        confidence: 0.95,
        metadata: {'category': 'help'},
      ),

      // Offline Status
      KnowledgeEntry(
        id: 'offline_query',
        patterns: [
          r'\boffline\b',
          r'\bno (internet|connection|network)\b',
          r'\bwhy.*offline\b',
        ],
        keywords: ['offline', 'internet', 'connection'],
        response: '''
📡 **Offline Mode**

You're currently offline, but I can still help!

**What Works Offline:**
✅ Common troubleshooting guides
✅ Permission help
✅ Basic diagnostic tips
✅ Battery optimization advice
✅ Step tracking tips

**What Needs Internet:**
❌ Advanced diagnostics
❌ Real-time data analysis
❌ Cloud sync
❌ Account verification
❌ LLM-powered responses

**Your Messages Are Safe:**
Any questions you ask while offline will be saved and I'll respond once you're back online.

**To Reconnect:**
1. Check your WiFi or mobile data
2. Toggle Airplane mode OFF
3. Restart the app if needed

In the meantime, I can still help with common step tracking issues!
''',
        confidence: 0.97,
        metadata: {'category': 'offline'},
      ),

      // Fitness Tracker Sync
      KnowledgeEntry(
        id: 'tracker_sync',
        patterns: [
          r'\b(fitbit|garmin|apple watch|samsung|xiaomi)\b',
          r'\bfitness tracker\b',
          r'\bwatch\b.*\bnot sync',
        ],
        keywords: ['tracker', 'watch', 'fitbit', 'garmin'],
        response: '''
⌚ **Fitness Tracker Syncing**

To sync data from your fitness tracker:

**General Steps:**
1. Make sure your tracker is paired via Bluetooth
2. Open the tracker's companion app (Fitbit, Garmin Connect, etc.)
3. Wait for sync to complete in the companion app
4. The companion app should write data to Health/Google Fit
5. Our app reads from Health/Google Fit

**Common Issues:**
- **Not syncing to phone**: Unpair and re-pair Bluetooth
- **Syncing to tracker app but not here**: Check data source priorities
- **Duplicate steps**: Choose ONE primary source (phone OR tracker)

**iOS - Data Flow:**
Tracker → Tracker App → Apple Health → Our App

**Android - Data Flow:**
Tracker → Tracker App → Google Fit → Our App

**Pro Tip:**
Keep the tracker's companion app installed and updated for best results.

When online, I can check if your tracker is properly connected!
''',
        confidence: 0.87,
        metadata: {'category': 'devices'},
      ),
    ];
  }

  /// Search knowledge base for matching entry
  Future<KnowledgeMatch?> search(String query) async {
    _logger.d('Searching knowledge base for: "$query"');

    final normalizedQuery = query.toLowerCase().trim();

    KnowledgeMatch? bestMatch;
    double bestScore = 0.0;

    for (final entry in _entries) {
      // Check pattern matching
      for (final pattern in entry.patterns) {
        final regex = RegExp(pattern, caseSensitive: false);
        if (regex.hasMatch(normalizedQuery)) {
          final score = entry.confidence;
          if (score > bestScore && score >= minConfidence) {
            bestScore = score;
            bestMatch = KnowledgeMatch(
              entry: entry,
              confidence: score,
              matchedPattern: pattern,
            );
          }
        }
      }

      // Check keyword matching (fuzzy)
      if (entry.keywords.isNotEmpty) {
        final keywordScore = _calculateKeywordScore(normalizedQuery, entry.keywords);
        final adjustedScore = entry.confidence * keywordScore;

        if (adjustedScore > bestScore && adjustedScore >= minConfidence) {
          bestScore = adjustedScore;
          bestMatch = KnowledgeMatch(
            entry: entry,
            confidence: adjustedScore,
            matchedPattern: 'keyword_match',
          );
        }
      }
    }

    if (bestMatch != null) {
      _logger.i('Knowledge base match found: ${bestMatch.entry.id} (confidence: ${bestMatch.confidence.toStringAsFixed(2)})');
    } else {
      _logger.d('No knowledge base match found for query');
    }

    return bestMatch;
  }

  /// Calculate keyword match score
  double _calculateKeywordScore(String query, List<String> keywords) {
    if (keywords.isEmpty) return 0.0;

    int matchCount = 0;
    for (final keyword in keywords) {
      if (query.contains(keyword.toLowerCase())) {
        matchCount++;
      }
    }

    return matchCount / keywords.length;
  }

  /// Get fallback response when no match found
  ChatMessage getFallbackResponse() {
    return ChatMessage.bot(
      text: '''
🤔 **I'm not sure (Offline Mode)**

I don't have a specific answer for that in my offline knowledge base.

**What I Can Help With:**
- Permission issues
- Steps not syncing
- Wrong step counts
- App not tracking
- Battery concerns

**For Advanced Help:**
Your message will be saved and I'll provide a detailed answer once you're back online. The full AI assistant needs internet to analyze your specific issue.

Can you rephrase your question, or would you like help with one of the common issues above?
''',
      data: {
        'source': 'offline_fallback',
        'offline': true,
      },
    );
  }

  /// Get all knowledge categories
  Map<String, int> getCategories() {
    final categories = <String, int>{};

    for (final entry in _entries) {
      final category = entry.metadata['category'] as String? ?? 'general';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return categories;
  }

  /// Get knowledge base statistics
  Map<String, dynamic> getStatistics() {
    return {
      'total_entries': _entries.length,
      'categories': getCategories(),
      'min_confidence': minConfidence,
    };
  }
}
