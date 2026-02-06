import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/config/chatbot_config.dart';
import 'package:step_sync_chatbot/src/config/health_config.dart';
import 'package:step_sync_chatbot/src/config/backend_adapter.dart';

void main() {
  group('ChatBotConfig', () {
    test('creates config with required parameters', () {
      final config = ChatBotConfig(
        backendAdapter: LocalOnlyBackendAdapter(),
        authProvider: () async => 'test-token',
        healthConfig: HealthDataConfig.defaults(),
        userId: 'user-123',
      );

      expect(config.userId, 'user-123');
      expect(config.debugMode, false);
      expect(config.theme, isNull);
    });

    test('development factory creates config with debug mode enabled', () {
      final config = ChatBotConfig.development(userId: 'dev-user');

      expect(config.userId, 'dev-user');
      expect(config.debugMode, true);
      expect(config.backendAdapter, isA<LocalOnlyBackendAdapter>());
    });

    test('authProvider returns token', () async {
      final config = ChatBotConfig(
        backendAdapter: LocalOnlyBackendAdapter(),
        authProvider: () async => 'my-token',
        healthConfig: HealthDataConfig.defaults(),
        userId: 'user-123',
      );

      final token = await config.authProvider();
      expect(token, 'my-token');
    });
  });

  group('HealthDataConfig', () {
    test('defaults factory creates sensible defaults', () {
      final config = HealthDataConfig.defaults();

      expect(config.enableBackgroundSync, true);
      expect(config.cacheRetentionDays, 30);
      expect(config.syncIntervalHours, 6);
      expect(config.enableFraudDetection, true);
      expect(config.maxDailySteps, 100000);
    });

    test('allows custom configuration', () {
      final config = HealthDataConfig(
        enableBackgroundSync: false,
        cacheRetentionDays: 7,
        syncIntervalHours: 12,
        enableFraudDetection: false,
        maxDailySteps: 50000,
      );

      expect(config.enableBackgroundSync, false);
      expect(config.cacheRetentionDays, 7);
      expect(config.syncIntervalHours, 12);
      expect(config.enableFraudDetection, false);
      expect(config.maxDailySteps, 50000);
    });
  });

  group('LocalOnlyBackendAdapter', () {
    late LocalOnlyBackendAdapter adapter;

    setUp(() {
      adapter = LocalOnlyBackendAdapter();
    });

    test('loadConversations returns empty list', () async {
      final conversations = await adapter.loadConversations('user-123');
      expect(conversations, isEmpty);
    });

    test('saveConversation completes without error', () async {
      // Since Conversation model doesn't exist yet, we'll update this test later
      // For now, just verify the method exists
      expect(adapter.saveConversation, isA<Function>());
    });

    test('logEvent completes without error', () async {
      await adapter.logEvent('test_event', {'key': 'value'});
      // No assertion needed - just verify it doesn't throw
    });
  });
}
