import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/src/core/rule_based_intent_classifier.dart';
import 'package:step_sync_chatbot/src/core/intents.dart';

void main() {
  group('RuleBasedIntentClassifier', () {
    late RuleBasedIntentClassifier classifier;

    setUp(() {
      classifier = RuleBasedIntentClassifier();
    });

    group('Greeting intent', () {
      test('recognizes "hello"', () {
        final result = classifier.classify('hello');
        expect(result.intent, UserIntent.greeting);
        expect(result.confidence, greaterThan(0.9));
      });

      test('recognizes "hi"', () {
        final result = classifier.classify('hi');
        expect(result.intent, UserIntent.greeting);
      });

      test('recognizes "good morning"', () {
        final result = classifier.classify('good morning');
        expect(result.intent, UserIntent.greeting);
      });
    });

    group('Thanks intent', () {
      test('recognizes "thank you"', () {
        final result = classifier.classify('thank you');
        expect(result.intent, UserIntent.thanks);
        expect(result.confidence, greaterThan(0.9));
      });

      test('recognizes "thanks"', () {
        final result = classifier.classify('thanks for your help');
        expect(result.intent, UserIntent.thanks);
      });
    });

    group('Permission intents', () {
      test('recognizes permission denied', () {
        final result = classifier.classify('permission denied');
        expect(result.intent, UserIntent.permissionDenied);
        expect(result.confidence, greaterThan(0.85));
      });

      test('recognizes want to grant permission', () {
        final result = classifier.classify('I want to grant permission');
        expect(result.intent, UserIntent.wantToGrantPermission);
      });

      test('recognizes why permission needed', () {
        final result = classifier.classify('why do you need permission?');
        expect(result.intent, UserIntent.whyPermissionNeeded);
      });
    });

    group('Sync issue intents', () {
      test('recognizes steps not syncing', () {
        final result = classifier.classify('my steps aren\'t syncing');
        expect(result.intent, UserIntent.stepsNotSyncing);
        expect(result.confidence, greaterThan(0.85));
      });

      test('recognizes steps not showing', () {
        final result = classifier.classify('steps not showing up');
        expect(result.intent, UserIntent.stepsNotSyncing);
      });

      test('recognizes sync delayed', () {
        final result = classifier.classify('sync is slow');
        expect(result.intent, UserIntent.syncDelayed);
      });
    });

    group('Data issue intents', () {
      test('recognizes wrong step count', () {
        final result = classifier.classify('wrong step count');
        expect(result.intent, UserIntent.wrongStepCount);
        expect(result.confidence, greaterThan(0.85));
      });

      test('recognizes incorrect steps', () {
        final result = classifier.classify('my steps are incorrect');
        expect(result.intent, UserIntent.wrongStepCount);
      });

      test('recognizes duplicate steps', () {
        final result = classifier.classify('seeing duplicate steps');
        expect(result.intent, UserIntent.duplicateSteps);
      });

      test('recognizes missing data', () {
        final result = classifier.classify('my data is missing');
        expect(result.intent, UserIntent.dataMissing);
      });
    });

    group('Multi-app intents', () {
      test('recognizes multiple apps conflict', () {
        final result = classifier.classify('I have multiple apps tracking steps');
        expect(result.intent, UserIntent.multipleAppsConflict);
        expect(result.confidence, greaterThan(0.8));
      });

      test('recognizes want to switch source', () {
        final result = classifier.classify('I want to switch my data source');
        expect(result.intent, UserIntent.wantToSwitchSource);
      });
    });

    group('Technical issue intents', () {
      test('recognizes battery optimization issue', () {
        final result = classifier.classify('battery saver is blocking sync');
        expect(result.intent, UserIntent.batteryOptimizationIssue);
      });

      test('recognizes Health Connect not installed', () {
        final result = classifier.classify('health connect is not installed');
        expect(result.intent, UserIntent.healthConnectNotInstalled);
      });
    });

    group('General intents', () {
      test('recognizes checking status', () {
        final result = classifier.classify('check my setup');
        expect(result.intent, UserIntent.checkingStatus);
      });

      test('recognizes need help', () {
        final result = classifier.classify('I need help');
        expect(result.intent, UserIntent.needHelp);
      });
    });

    group('Unclear intent', () {
      test('returns unclear for random text', () {
        final result = classifier.classify('asdfghjkl');
        expect(result.intent, UserIntent.unclear);
        expect(result.confidence, lessThan(0.5));
      });

      test('returns unclear for ambiguous query', () {
        final result = classifier.classify('something is happening');
        expect(result.intent, UserIntent.unclear);
      });
    });

    group('Case insensitivity', () {
      test('works with uppercase', () {
        final result = classifier.classify('MY STEPS AREN\'T SYNCING');
        expect(result.intent, UserIntent.stepsNotSyncing);
      });

      test('works with mixed case', () {
        final result = classifier.classify('Permission Denied');
        expect(result.intent, UserIntent.permissionDenied);
      });
    });

    group('Pattern priority', () {
      test('matches most specific pattern first', () {
        // "why do you need permission" should match whyPermissionNeeded
        // not just the general "need help" pattern
        final result = classifier.classify('why do you need permission');
        expect(result.intent, UserIntent.whyPermissionNeeded);
        expect(result.intent, isNot(UserIntent.needHelp));
      });
    });
  });
}
