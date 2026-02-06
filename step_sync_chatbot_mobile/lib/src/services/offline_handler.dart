/// Offline Mode Handler - Graceful Degradation
///
/// Detects offline status and provides template-based responses
/// when internet is unavailable.

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class OfflineHandler {
  static bool _isOffline = false;
  static DateTime? _lastCheck;
  static const Duration _checkCacheDuration = Duration(seconds: 10);

  /// Check if device is online
  static Future<bool> isOnline() async {
    // Use cached result if recent
    if (_lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < _checkCacheDuration) {
      return !_isOffline;
    }

    try {
      // Use Google's official connectivity check endpoint
      // This is the same endpoint Android uses for captive portal detection
      // Returns 204 No Content when connected - very lightweight and reliable
      final response = await http.get(
        Uri.parse('http://clients3.google.com/generate_204'),
      ).timeout(
        const Duration(seconds: 7),
      );

      // Check for successful response (204 or 200)
      // Google's endpoint returns 204, but accept 200 as well
      final isConnected = response.statusCode == 204 ||
                         response.statusCode == 200 ||
                         response.statusCode < 400; // Any non-error response means connected

      _isOffline = !isConnected;
      _lastCheck = DateTime.now();
      return isConnected;
    } on SocketException catch (_) {
      // No network connection at all
      _isOffline = true;
      _lastCheck = DateTime.now();
      return false;
    } on TimeoutException catch (_) {
      // Timeout - but connection exists, just slow
      // Try DNS lookup as faster fallback
      try {
        final result = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 3),
        );
        final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        _isOffline = !isConnected;
        _lastCheck = DateTime.now();
        return isConnected;
      } catch (_) {
        _isOffline = true;
        _lastCheck = DateTime.now();
        return false;
      }
    } catch (e) {
      // Any other error - likely means we ARE online but got HTTP error
      // Assume online if we got any kind of HTTP response/error
      _isOffline = false;
      _lastCheck = DateTime.now();
      return true;
    }
  }

  /// Get offline fallback response
  static String getOfflineFallback(String userMessage) {
    final lower = userMessage.toLowerCase();

    // Provide context-specific offline responses
    if (lower.contains('permission')) {
      return '''
📵 **You're Offline**

I can still help with permission issues! Here's what to do:

**Android:**
Settings → Apps → Step Sync → Permissions → Physical activity → Allow

**iOS:**
Settings → Privacy & Security → Motion & Fitness → Step Sync → ON

Once you're back online, I can run a full diagnostic to check all your settings.
''';
    }

    if (lower.contains('battery') || lower.contains('optimization')) {
      return '''
📵 **You're Offline**

For battery optimization issues:

**Android:**
Settings → Apps → Step Sync → Battery → Unrestricted

**Why this matters:**
Battery optimization stops the app from tracking steps in the background.

I'll run a detailed check once you're back online!
''';
    }

    if (lower.contains('sync') || lower.contains('tracking') || lower.contains('not working')) {
      return '''
📵 **You're Offline**

**Quick offline checks:**

1. ✅ Restart the app completely
2. ✅ Check if you granted permissions
3. ✅ Disable battery optimization
4. ✅ Make sure background data is ON

**When you're back online:**
I'll run a full diagnostic to find exactly what's blocking your step tracking.

Your message has been saved and I'll help you as soon as you reconnect!
''';
    }

    // Generic offline response
    return '''
📵 **You're Offline - Limited Mode**

I can provide basic troubleshooting help, but I need internet to:
• Run diagnostics
• Check your specific device settings
• Provide personalized solutions

**Common fixes to try now:**
1. Check app permissions
2. Disable battery optimization
3. Restart the app

Your message has been saved. Once you're back online, I'll give you a detailed answer!
''';
  }

  /// Get offline indicator message
  static String getOfflineIndicator() {
    return '''
⚠️ **Offline Mode**

You're currently offline. I can still provide basic help, but for full diagnostics and personalized troubleshooting, you'll need an internet connection.
''';
  }

  /// Force a fresh connectivity check
  static Future<bool> forceCheck() async {
    _lastCheck = null;
    return await isOnline();
  }

  /// Reset offline state (useful for testing)
  static void reset() {
    _isOffline = false;
    _lastCheck = null;
  }
}
