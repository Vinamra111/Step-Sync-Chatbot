import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:step_sync_chatbot/src/conversation/llm_response_generator.dart';
import 'package:step_sync_chatbot/src/conversation/conversation_context.dart';
import 'package:step_sync_chatbot/src/core/intents.dart';
import 'package:step_sync_chatbot/src/services/groq_chat_service.dart';
import 'package:step_sync_chatbot/src/services/phi_sanitizer_service.dart';

// Mocks
class MockGroqChatService extends Mock implements GroqChatService {}
class MockPHISanitizerService extends Mock implements PHISanitizerService {}

void main() {
  group('LLMResponseGenerator - Basic Generation', () {
    late MockGroqChatService mockGroq;
    late MockPHISanitizerService mockSanitizer;
    late LLMResponseGenerator generator;

    setUp(() {
      mockGroq = MockGroqChatService();
      mockSanitizer = MockPHISanitizerService();
      generator = LLMResponseGenerator(
        groqService: mockGroq,
        phiSanitizer: mockSanitizer,
      );

      // Setup default mocks
      when(() => mockSanitizer.sanitize(any())).thenReturn(
        SanitizationResult(
          sanitizedText: 'sanitized text',
          originalText: 'original text',
          wasSanitized: false,
          replacements: [],
        ),
      );
    });

    test('generates response successfully', () async {
      // Arrange
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenAnswer((_) async => ChatResponse(
            content: 'Let me help you with that!',
            tokenCount: 50,
            responseTime: Duration(seconds: 1),
            wasSanitized: false,
          ));

      final context = ConversationContext();
      context.addUserMessage('my steps arent working');

      // Act
      final response = await generator.generate(
        userMessage: 'my steps arent working',
        intent: UserIntent.stepsNotSyncing,
        context: context,
      );

      // Assert
      expect(response, 'Let me help you with that!');
      verify(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).called(1);
    });

    test('sanitizes input before sending to LLM', () async {
      // Arrange
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenAnswer((_) async => ChatResponse(
            content: 'Response',
            tokenCount: 10,
            responseTime: Duration(seconds: 1),
            wasSanitized: false,
          ));

      when(() => mockSanitizer.sanitize(any())).thenReturn(
        SanitizationResult(
          sanitizedText: 'I walked [NUMBER] steps',
          originalText: 'I walked 10000 steps',
          wasSanitized: true,
          replacements: ['10000 → [NUMBER]'],
        ),
      );

      final context = ConversationContext();

      // Act
      await generator.generate(
        userMessage: 'I walked 10000 steps',
        intent: UserIntent.wrongStepCount,
        context: context,
      );

      // Assert
      verify(() => mockSanitizer.sanitize(any())).called(1);
      verify(() => mockGroq.sendMessage(
            any(that: contains('[NUMBER]')),
            systemPrompt: any(named: 'systemPrompt'),
          )).called(1);
    });
  });

  group('LLMResponseGenerator - System Prompt Building', () {
    late MockGroqChatService mockGroq;
    late MockPHISanitizerService mockSanitizer;
    late LLMResponseGenerator generator;

    setUp(() {
      mockGroq = MockGroqChatService();
      mockSanitizer = MockPHISanitizerService();
      generator = LLMResponseGenerator(
        groqService: mockGroq,
        phiSanitizer: mockSanitizer,
      );

      when(() => mockSanitizer.sanitize(any())).thenReturn(
        SanitizationResult(
          sanitizedText: 'sanitized',
          originalText: 'original',
          wasSanitized: false,
          replacements: [],
        ),
      );
    });

    test('includes sentiment in system prompt', () async {
      // Arrange
      String? capturedPrompt;
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenAnswer((invocation) async {
        capturedPrompt = invocation.namedArguments[#systemPrompt] as String?;
        return ChatResponse(
          content: 'Response',
          tokenCount: 10,
          responseTime: Duration(seconds: 1),
          wasSanitized: false,
        );
      });

      final context = ConversationContext();
      context.addUserMessage('this is so frustrating!!!');

      // Act
      await generator.generate(
        userMessage: 'help',
        intent: UserIntent.needHelp,
        context: context,
      );

      // Assert
      expect(capturedPrompt, isNotNull);
      expect(capturedPrompt, contains('frustrated'));
      expect(capturedPrompt, contains('empathetic'));
    });

    test('includes concise preference in system prompt', () async {
      // Arrange
      String? capturedPrompt;
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenAnswer((invocation) async {
        capturedPrompt = invocation.namedArguments[#systemPrompt] as String?;
        return ChatResponse(
          content: 'Response',
          tokenCount: 10,
          responseTime: Duration(seconds: 1),
          wasSanitized: false,
        );
      });

      final context = ConversationContext();
      context.preferredStyle = ResponseStyle.concise;

      // Act
      await generator.generate(
        userMessage: 'help',
        intent: UserIntent.needHelp,
        context: context,
      );

      // Assert
      expect(capturedPrompt, contains('Concise'));
      expect(capturedPrompt, contains('2 sentences max'));
    });

    test('includes new conversation indicator', () async {
      // Arrange
      String? capturedPrompt;
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenAnswer((invocation) async {
        capturedPrompt = invocation.namedArguments[#systemPrompt] as String?;
        return ChatResponse(
          content: 'Response',
          tokenCount: 10,
          responseTime: Duration(seconds: 1),
          wasSanitized: false,
        );
      });

      final context = ConversationContext();
      context.addUserMessage('hello');

      // Act
      await generator.generate(
        userMessage: 'hello',
        intent: UserIntent.greeting,
        context: context,
      );

      // Assert
      expect(capturedPrompt, contains('new conversation'));
      expect(capturedPrompt, contains('introduce yourself'));
    });
  });

  group('LLMResponseGenerator - Diagnostic Integration', () {
    late MockGroqChatService mockGroq;
    late MockPHISanitizerService mockSanitizer;
    late LLMResponseGenerator generator;

    setUp(() {
      mockGroq = MockGroqChatService();
      mockSanitizer = MockPHISanitizerService();
      generator = LLMResponseGenerator(
        groqService: mockGroq,
        phiSanitizer: mockSanitizer,
      );

      // Pass through the input text unchanged (no PHI to sanitize)
      when(() => mockSanitizer.sanitize(any())).thenAnswer((invocation) {
        final input = invocation.positionalArguments[0] as String;
        return SanitizationResult(
          sanitizedText: input,
          originalText: input,
          wasSanitized: false,
          replacements: [],
        );
      });
    });

    test('includes diagnostic results in user prompt', () async {
      // Arrange
      String? capturedMessage;
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenAnswer((invocation) async {
        capturedMessage = invocation.positionalArguments[0] as String;
        return ChatResponse(
          content: 'Response',
          tokenCount: 10,
          responseTime: Duration(seconds: 1),
          wasSanitized: false,
        );
      });

      final diagnostics = {
        'permissionStatus': 'denied',
        'dataSourceCount': 0,
      };

      // Act
      await generator.generate(
        userMessage: 'check status',
        intent: UserIntent.checkingStatus,
        context: ConversationContext(),
        diagnosticResults: diagnostics,
      );

      // Assert
      expect(capturedMessage, contains('DIAGNOSTIC RESULTS'));
      expect(capturedMessage, contains('permissionStatus'));
      expect(capturedMessage, contains('denied'));
    });
  });

  group('LLMResponseGenerator - Fallback Behavior', () {
    late MockGroqChatService mockGroq;
    late MockPHISanitizerService mockSanitizer;
    late LLMResponseGenerator generator;

    setUp(() {
      mockGroq = MockGroqChatService();
      mockSanitizer = MockPHISanitizerService();
      generator = LLMResponseGenerator(
        groqService: mockGroq,
        phiSanitizer: mockSanitizer,
      );

      when(() => mockSanitizer.sanitize(any())).thenReturn(
        SanitizationResult(
          sanitizedText: 'sanitized',
          originalText: 'original',
          wasSanitized: false,
          replacements: [],
        ),
      );
    });

    test('returns fallback on LLM error', () async {
      // Arrange
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenThrow(Exception('API error'));

      final context = ConversationContext();

      // Act
      final response = await generator.generate(
        userMessage: 'hello',
        intent: UserIntent.greeting,
        context: context,
      );

      // Assert - should not throw, should return fallback
      expect(response, isNotEmpty);
      expect(response, contains('Step Sync Assistant'));
    });

    test('uses sentiment-aware fallback for frustrated users', () async {
      // Arrange
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenThrow(Exception('API error'));

      final context = ConversationContext();
      context.addUserMessage('this is so annoying!!!');

      // Act
      final response = await generator.generate(
        userMessage: 'help',
        intent: UserIntent.needHelp,
        context: context,
      );

      // Assert
      expect(response, contains('frustrating'));
      expect(response, contains('understand'));
    });

    test('uses intent-specific fallback', () async {
      // Arrange
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenThrow(Exception('API error'));

      // Act - Permission intent
      final permissionResponse = await generator.generate(
        userMessage: 'why permission',
        intent: UserIntent.whyPermissionNeeded,
        context: ConversationContext(),
      );

      expect(permissionResponse, contains('permission'));
      expect(permissionResponse, contains('private'));

      // Act - Steps not syncing
      final syncResponse = await generator.generate(
        userMessage: 'not syncing',
        intent: UserIntent.stepsNotSyncing,
        context: ConversationContext(),
      );

      expect(syncResponse, contains('sync'));
      expect(syncResponse, contains('diagnostic'));
    });
  });

  group('LLMResponseGenerator - Hybrid Mode (Enhancement)', () {
    late MockGroqChatService mockGroq;
    late MockPHISanitizerService mockSanitizer;
    late LLMResponseGenerator generator;

    setUp(() {
      mockGroq = MockGroqChatService();
      mockSanitizer = MockPHISanitizerService();
      generator = LLMResponseGenerator(
        groqService: mockGroq,
        phiSanitizer: mockSanitizer,
      );

      when(() => mockSanitizer.sanitize(any())).thenReturn(
        SanitizationResult(
          sanitizedText: 'sanitized',
          originalText: 'original',
          wasSanitized: false,
          replacements: [],
        ),
      );
    });

    test('enhances template with LLM content', () async {
      // Arrange
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenAnswer((_) async => ChatResponse(
            content: 'Your battery saver is blocking background updates',
            tokenCount: 20,
            responseTime: Duration(seconds: 1),
            wasSanitized: false,
          ));

      final template = 'Issue found: [LLM_ENHANCEMENT]';

      // Act
      final enhanced = await generator.generateEnhancement(
        templateMessage: template,
        context: ConversationContext(),
      );

      // Assert
      expect(enhanced, isNot(contains('[LLM_ENHANCEMENT]')));
      expect(enhanced, contains('battery'));
    });

    test('returns template unchanged if no placeholder', () async {
      final template = 'This is a simple template';

      // Act
      final result = await generator.generateEnhancement(
        templateMessage: template,
        context: ConversationContext(),
      );

      // Assert
      expect(result, template);
      verifyNever(() => mockGroq.sendMessage(any(), systemPrompt: any(named: 'systemPrompt')));
    });

    test('removes placeholder on LLM failure', () async {
      // Arrange
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenThrow(Exception('API error'));

      final template = 'Issue: [LLM_ENHANCEMENT]';

      // Act
      final result = await generator.generateEnhancement(
        templateMessage: template,
        context: ConversationContext(),
      );

      // Assert
      expect(result, 'Issue: '); // Placeholder removed
    });
  });

  group('LLMResponseGenerator - Conversation History', () {
    late MockGroqChatService mockGroq;
    late MockPHISanitizerService mockSanitizer;
    late LLMResponseGenerator generator;

    setUp(() {
      mockGroq = MockGroqChatService();
      mockSanitizer = MockPHISanitizerService();
      generator = LLMResponseGenerator(
        groqService: mockGroq,
        phiSanitizer: mockSanitizer,
      );

      // Pass through the input text unchanged (no PHI to sanitize)
      when(() => mockSanitizer.sanitize(any())).thenAnswer((invocation) {
        final input = invocation.positionalArguments[0] as String;
        return SanitizationResult(
          sanitizedText: input,
          originalText: input,
          wasSanitized: false,
          replacements: [],
        );
      });
    });

    test('includes recent messages in prompt', () async {
      // Arrange
      String? capturedMessage;
      when(() => mockGroq.sendMessage(
            any(),
            systemPrompt: any(named: 'systemPrompt'),
          )).thenAnswer((invocation) async {
        capturedMessage = invocation.positionalArguments[0] as String;
        return ChatResponse(
          content: 'Response',
          tokenCount: 10,
          responseTime: Duration(seconds: 1),
          wasSanitized: false,
        );
      });

      final context = ConversationContext();
      context.addUserMessage('hello');
      context.addBotMessage('Hi there!');
      context.addUserMessage('my steps arent working');

      // Act
      await generator.generate(
        userMessage: 'my steps arent working',
        intent: UserIntent.stepsNotSyncing,
        context: context,
      );

      // Assert
      expect(capturedMessage, contains('RECENT CONVERSATION'));
      expect(capturedMessage, contains('hello'));
      expect(capturedMessage, contains('Hi there!'));
    });
  });
}
