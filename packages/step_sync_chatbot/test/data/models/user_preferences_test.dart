import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/data/models/user_preferences.dart';

void main() {
  group('UserPreferences', () {
    test('creates default preferences with factory', () {
      final prefs = UserPreferences.defaults('user-123');

      expect(prefs.userId, 'user-123');
      expect(prefs.notificationsEnabled, true);
      expect(prefs.conversationStyle, ConversationStyle.balanced);
      expect(prefs.learnedTopics, isEmpty);
      expect(prefs.preferredDataSource, isNull);
      expect(prefs.lastUpdated, isA<DateTime>());
    });

    test('allows setting preferred data source', () {
      final prefs = UserPreferences.defaults('user-123').copyWith(
        preferredDataSource: 'com.samsung.android.app.health',
      );

      expect(prefs.preferredDataSource, 'com.samsung.android.app.health');
    });

    test('allows disabling notifications', () {
      final prefs = UserPreferences.defaults('user-123').copyWith(
        notificationsEnabled: false,
      );

      expect(prefs.notificationsEnabled, false);
    });

    test('allows changing conversation style', () {
      final prefs = UserPreferences.defaults('user-123').copyWith(
        conversationStyle: ConversationStyle.concise,
      );

      expect(prefs.conversationStyle, ConversationStyle.concise);
    });

    test('tracks learned topics', () {
      final prefs = UserPreferences.defaults('user-123').copyWith(
        learnedTopics: [
          'battery_optimization',
          'permission_setup',
          'multi_app_sources',
        ],
      );

      expect(prefs.learnedTopics, hasLength(3));
      expect(prefs.learnedTopics, contains('battery_optimization'));
    });
  });

  group('ConversationStyle', () {
    test('has all expected values', () {
      expect(ConversationStyle.values, hasLength(3));
      expect(ConversationStyle.values, contains(ConversationStyle.concise));
      expect(ConversationStyle.values, contains(ConversationStyle.balanced));
      expect(ConversationStyle.values, contains(ConversationStyle.detailed));
    });
  });
}
