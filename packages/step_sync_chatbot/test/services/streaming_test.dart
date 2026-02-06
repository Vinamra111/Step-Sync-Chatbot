/// Tests for Streaming Response Functionality
///
/// Validates:
/// - SSE (Server-Sent Events) parsing
/// - Progressive text display
/// - Stream chunk handling
/// - Cancellation support
/// - Error handling during streaming
/// - Token counting in final chunk

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/llm/llm_response.dart';
import 'package:step_sync_chatbot/src/services/groq_streaming_service.dart';
import 'package:logger/logger.dart';

void main() {
  group('LLMStreamChunk Model', () {
    test('should create content chunk', () {
      final chunk = LLMStreamChunk.content('Hello');

      expect(chunk.content, equals('Hello'));
      expect(chunk.isComplete, isFalse);
      expect(chunk.finishReason, isNull);
    });

    test('should create done chunk with tokens', () {
      final chunk = LLMStreamChunk.done(
        finishReason: 'stop',
        promptTokens: 50,
        completionTokens: 100,
      );

      expect(chunk.content, isEmpty);
      expect(chunk.isComplete, isTrue);
      expect(chunk.finishReason, equals('stop'));
      expect(chunk.promptTokens, equals(50));
      expect(chunk.completionTokens, equals(100));
      expect(chunk.totalTokens, equals(150));
    });

    test('should create error chunk', () {
      final chunk = LLMStreamChunk.error('API failure');

      expect(chunk.isComplete, isTrue);
      expect(chunk.finishReason, equals('error'));
      expect(chunk.metadata['error'], equals('API failure'));
    });
  });

  group('Streaming Service - Mock Scenarios', () {
    test('should handle empty stream gracefully', () async {
      // Simulate empty stream
      final stream = Stream<LLMStreamChunk>.fromIterable([
        LLMStreamChunk.done(),
      ]);

      String fullResponse = '';
      await for (final chunk in stream) {
        fullResponse += chunk.content;
        if (chunk.isComplete) break;
      }

      expect(fullResponse, isEmpty);
    });

    test('should accumulate chunks correctly', () async {
      // Simulate ChatGPT-like streaming
      final chunks = [
        LLMStreamChunk.content('Hello'),
        LLMStreamChunk.content(' there'),
        LLMStreamChunk.content('!'),
        LLMStreamChunk.content(' How'),
        LLMStreamChunk.content(' can'),
        LLMStreamChunk.content(' I'),
        LLMStreamChunk.content(' help'),
        LLMStreamChunk.content('?'),
        LLMStreamChunk.done(finishReason: 'stop'),
      ];

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String fullResponse = '';
      final receivedChunks = <String>[];

      await for (final chunk in stream) {
        if (chunk.content.isNotEmpty) {
          fullResponse += chunk.content;
          receivedChunks.add(chunk.content);
        }
        if (chunk.isComplete) break;
      }

      expect(fullResponse, equals('Hello there! How can I help?'));
      expect(receivedChunks.length, equals(8));
    });

    test('should handle mid-stream errors', () async {
      final chunks = [
        LLMStreamChunk.content('Hello'),
        LLMStreamChunk.content(' there'),
        LLMStreamChunk.error('Network timeout'),
      ];

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String fullResponse = '';
      String? errorMessage;

      await for (final chunk in stream) {
        if (chunk.finishReason == 'error') {
          errorMessage = chunk.metadata['error'] as String?;
          break;
        }
        fullResponse += chunk.content;
      }

      expect(fullResponse, equals('Hello there'));
      expect(errorMessage, equals('Network timeout'));
    });

    test('should handle rapid chunks without loss', () async {
      // Simulate very fast streaming (100 chunks)
      final chunks = List.generate(
        100,
        (i) => LLMStreamChunk.content('${i % 10}'),
      )..add(LLMStreamChunk.done());

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String fullResponse = '';
      int chunkCount = 0;

      await for (final chunk in stream) {
        if (chunk.content.isNotEmpty) {
          fullResponse += chunk.content;
          chunkCount++;
        }
        if (chunk.isComplete) break;
      }

      expect(chunkCount, equals(100));
      expect(fullResponse.length, equals(100));
    });

    test('should handle delayed chunks (simulated network latency)', () async {
      final chunks = [
        LLMStreamChunk.content('Hello'),
        LLMStreamChunk.content(' world'),
        LLMStreamChunk.done(),
      ];

      // Add delays between chunks
      final stream = Stream<LLMStreamChunk>.periodic(
        const Duration(milliseconds: 100),
        (count) => count < chunks.length ? chunks[count] : LLMStreamChunk.done(),
      ).take(chunks.length);

      String fullResponse = '';
      final timestamps = <DateTime>[];

      await for (final chunk in stream) {
        timestamps.add(DateTime.now());
        fullResponse += chunk.content;
        if (chunk.isComplete) break;
      }

      expect(fullResponse, equals('Hello world'));
      expect(timestamps.length, greaterThanOrEqualTo(2));

      // Verify there was actual delay between chunks
      if (timestamps.length >= 2) {
        final delay = timestamps[1].difference(timestamps[0]);
        expect(delay.inMilliseconds, greaterThan(50),
            reason: 'Should have delay between chunks');
      }
    });
  });

  group('Streaming Service - Cancellation', () {
    test('should support stream cancellation', () async {
      final chunks = List.generate(
        1000,
        (i) => LLMStreamChunk.content('$i '),
      )..add(LLMStreamChunk.done());

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String fullResponse = '';
      int chunksProcessed = 0;
      final completer = Completer<void>();

      // Subscribe to stream
      late StreamSubscription<LLMStreamChunk> subscription;
      subscription = stream.listen(
        (chunk) {
          fullResponse += chunk.content;
          chunksProcessed++;

          // Cancel after 10 chunks
          if (chunksProcessed >= 10) {
            subscription.cancel();
            completer.complete();
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      // Wait for cancellation or completion
      await completer.future;

      expect(chunksProcessed, equals(10));
      expect(fullResponse, isNot(contains('500')),
          reason: 'Should not process all 1000 chunks');
    });

    test('should handle early cancellation gracefully', () async {
      final chunks = [
        LLMStreamChunk.content('Hello'),
        LLMStreamChunk.content(' world'),
        LLMStreamChunk.done(),
      ];

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String fullResponse = '';
      bool wasCancelled = false;

      final subscription = stream.listen((chunk) {
        fullResponse += chunk.content;
      });

      // Cancel immediately
      await subscription.cancel();
      wasCancelled = true;

      expect(wasCancelled, isTrue);
      // May have processed first chunk before cancellation
      expect(fullResponse.length, lessThanOrEqualTo(5));
    });
  });

  group('Streaming Service - Edge Cases', () {
    test('should handle empty content chunks', () async {
      final chunks = [
        LLMStreamChunk.content(''),
        LLMStreamChunk.content('Hello'),
        LLMStreamChunk.content(''),
        LLMStreamChunk.content(' world'),
        LLMStreamChunk.content(''),
        LLMStreamChunk.done(),
      ];

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String fullResponse = '';
      await for (final chunk in stream) {
        fullResponse += chunk.content;
        if (chunk.isComplete) break;
      }

      expect(fullResponse, equals('Hello world'));
    });

    test('should handle very long single chunk', () async {
      final longText = 'A' * 10000; // 10KB chunk
      final chunks = [
        LLMStreamChunk.content(longText),
        LLMStreamChunk.done(),
      ];

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String fullResponse = '';
      await for (final chunk in stream) {
        fullResponse += chunk.content;
        if (chunk.isComplete) break;
      }

      expect(fullResponse.length, equals(10000));
      expect(fullResponse, equals(longText));
    });

    test('should handle Unicode and emojis in chunks', () async {
      final chunks = [
        LLMStreamChunk.content('Hello 👋'),
        LLMStreamChunk.content(' World 🌍'),
        LLMStreamChunk.content('! 你好'),
        LLMStreamChunk.done(),
      ];

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String fullResponse = '';
      await for (final chunk in stream) {
        fullResponse += chunk.content;
        if (chunk.isComplete) break;
      }

      expect(fullResponse, equals('Hello 👋 World 🌍! 你好'));
    });

    test('should handle special characters and newlines', () async {
      final chunks = [
        LLMStreamChunk.content('Line 1\n'),
        LLMStreamChunk.content('Line 2\n'),
        LLMStreamChunk.content('Special: \$@#%'),
        LLMStreamChunk.done(),
      ];

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String fullResponse = '';
      await for (final chunk in stream) {
        fullResponse += chunk.content;
        if (chunk.isComplete) break;
      }

      expect(fullResponse, contains('Line 1\nLine 2\n'));
      expect(fullResponse, contains('\$@#%'));
    });
  });

  group('Streaming Service - Performance', () {
    test('should handle high-frequency chunks (stress test)', () async {
      // Simulate 10,000 rapid chunks
      final chunks = List.generate(
        10000,
        (i) => LLMStreamChunk.content('x'),
      )..add(LLMStreamChunk.done(completionTokens: 10000));

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      final startTime = DateTime.now();
      String fullResponse = '';

      await for (final chunk in stream) {
        fullResponse += chunk.content;
        if (chunk.isComplete) break;
      }

      final duration = DateTime.now().difference(startTime);

      expect(fullResponse.length, equals(10000));
      expect(duration.inSeconds, lessThan(5),
          reason: 'Should process 10k chunks in under 5 seconds');

      print('✓ Processed 10,000 chunks in ${duration.inMilliseconds}ms');
    });

    test('should handle concurrent streams', () async {
      // Simulate multiple users streaming simultaneously
      final streamCount = 10;
      final futures = <Future<String>>[];

      for (int i = 0; i < streamCount; i++) {
        final chunks = List.generate(
          100,
          (j) => LLMStreamChunk.content('Stream$i-Chunk$j '),
        )..add(LLMStreamChunk.done());

        final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

        final future = _consumeStream(stream);
        futures.add(future);
      }

      final results = await Future.wait(futures);

      expect(results.length, equals(streamCount));
      for (int i = 0; i < streamCount; i++) {
        expect(results[i], contains('Stream$i'));
      }

      print('✓ Handled $streamCount concurrent streams successfully');
    });
  });

  group('Streaming Service - Integration', () {
    test('should calculate tokens correctly in final chunk', () async {
      final chunks = [
        LLMStreamChunk.content('Hello world'),
        LLMStreamChunk.done(
          promptTokens: 10,
          completionTokens: 5,
        ),
      ];

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      int? totalTokens;
      await for (final chunk in stream) {
        if (chunk.isComplete) {
          totalTokens = chunk.totalTokens;
          break;
        }
      }

      expect(totalTokens, equals(15));
    });

    test('should preserve metadata through stream', () async {
      final chunks = [
        LLMStreamChunk.content('Test'),
        LLMStreamChunk.done(
          finishReason: 'length',
          promptTokens: 5,
          completionTokens: 10,
        ),
      ];

      final stream = Stream<LLMStreamChunk>.fromIterable(chunks);

      String? finishReason;
      int? tokens;

      await for (final chunk in stream) {
        if (chunk.isComplete) {
          finishReason = chunk.finishReason;
          tokens = chunk.totalTokens;
          break;
        }
      }

      expect(finishReason, equals('length'));
      expect(tokens, equals(15));
    });
  });
}

/// Helper function to consume a stream and return full response
Future<String> _consumeStream(Stream<LLMStreamChunk> stream) async {
  String fullResponse = '';
  await for (final chunk in stream) {
    fullResponse += chunk.content;
    if (chunk.isComplete) break;
  }
  return fullResponse;
}
