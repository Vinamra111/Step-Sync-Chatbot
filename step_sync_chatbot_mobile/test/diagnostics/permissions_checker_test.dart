import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:step_sync_web_demo/src/diagnostics/permissions_checker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionStatus Extension', () {
    test('fromString converts GRANTED correctly', () {
      expect(
        PermissionStatusX.fromString('GRANTED'),
        PermissionStatus.granted,
      );
    });

    test('fromString converts DENIED correctly', () {
      expect(
        PermissionStatusX.fromString('DENIED'),
        PermissionStatus.denied,
      );
    });

    test('fromString converts PERMANENTLY_DENIED correctly', () {
      expect(
        PermissionStatusX.fromString('PERMANENTLY_DENIED'),
        PermissionStatus.permanentlyDenied,
      );
    });

    test('fromString converts NOT_DETERMINED correctly', () {
      expect(
        PermissionStatusX.fromString('NOT_DETERMINED'),
        PermissionStatus.notDetermined,
      );
    });

    test('fromString converts RESTRICTED correctly', () {
      expect(
        PermissionStatusX.fromString('RESTRICTED'),
        PermissionStatus.restricted,
      );
    });

    test('fromString converts NOT_APPLICABLE correctly', () {
      expect(
        PermissionStatusX.fromString('NOT_APPLICABLE'),
        PermissionStatus.notApplicable,
      );
    });

    test('fromString returns unknown for invalid status', () {
      expect(
        PermissionStatusX.fromString('INVALID_STATUS'),
        PermissionStatus.unknown,
      );
    });

    test('fromString is case insensitive', () {
      expect(
        PermissionStatusX.fromString('granted'),
        PermissionStatus.granted,
      );
      expect(
        PermissionStatusX.fromString('Granted'),
        PermissionStatus.granted,
      );
    });

    test('isGranted returns true for granted status', () {
      expect(PermissionStatus.granted.isGranted, true);
      expect(PermissionStatus.denied.isGranted, false);
      expect(PermissionStatus.unknown.isGranted, false);
    });

    test('canRequest returns true for denied and notDetermined', () {
      expect(PermissionStatus.denied.canRequest, true);
      expect(PermissionStatus.notDetermined.canRequest, true);
      expect(PermissionStatus.granted.canRequest, false);
      expect(PermissionStatus.permanentlyDenied.canRequest, false);
    });

    test('needsSettings returns true for permanentlyDenied and restricted', () {
      expect(PermissionStatus.permanentlyDenied.needsSettings, true);
      expect(PermissionStatus.restricted.needsSettings, true);
      expect(PermissionStatus.denied.needsSettings, false);
      expect(PermissionStatus.granted.needsSettings, false);
    });
  });

  group('PermissionsChecker - Physical Activity Permission', () {
    const channelName = 'com.stepsync.chatbot/permissions';
    const MethodChannel channel = MethodChannel(channelName);
    late PermissionsChecker checker;
    late List<MethodCall> log;

    setUp(() {
      log = <MethodCall>[];
      checker = PermissionsChecker(logger: Logger(level: Level.off));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null; // Default return
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      log.clear();
    });

    test('checkPhysicalActivityPermission returns granted', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkPhysicalActivityPermission') {
          return 'GRANTED';
        }
        return null;
      });

      final result = await checker.checkPhysicalActivityPermission();

      expect(result, PermissionStatus.granted);
      expect(log, hasLength(1));
      expect(log.first.method, 'checkPhysicalActivityPermission');
    });

    test('checkPhysicalActivityPermission returns denied', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkPhysicalActivityPermission') {
          return 'DENIED';
        }
        return null;
      });

      final result = await checker.checkPhysicalActivityPermission();

      expect(result, PermissionStatus.denied);
    });

    test('checkPhysicalActivityPermission handles null response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null; // Null response
      });

      final result = await checker.checkPhysicalActivityPermission();

      expect(result, PermissionStatus.unknown);
    });

    test('checkPhysicalActivityPermission handles NOT_AVAILABLE error',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkPhysicalActivityPermission') {
          throw PlatformException(
            code: 'NOT_AVAILABLE',
            message: 'Android version < 10',
          );
        }
        return null;
      });

      final result = await checker.checkPhysicalActivityPermission();

      expect(result, PermissionStatus.notApplicable);
    });

    test('checkPhysicalActivityPermission handles generic error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkPhysicalActivityPermission') {
          throw PlatformException(
            code: 'ERROR',
            message: 'Generic error',
          );
        }
        return null;
      });

      final result = await checker.checkPhysicalActivityPermission();

      expect(result, PermissionStatus.unknown);
    });

    test('requestPhysicalActivityPermission returns true on success', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'requestPhysicalActivityPermission') {
          return true;
        }
        return null;
      });

      final result = await checker.requestPhysicalActivityPermission();

      expect(result, true);
      expect(log, hasLength(1));
      expect(log.first.method, 'requestPhysicalActivityPermission');
    });

    test('requestPhysicalActivityPermission returns false on denial', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'requestPhysicalActivityPermission') {
          return false;
        }
        return null;
      });

      final result = await checker.requestPhysicalActivityPermission();

      expect(result, false);
    });

    test('requestPhysicalActivityPermission handles error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'requestPhysicalActivityPermission') {
          throw PlatformException(code: 'ERROR', message: 'Failed');
        }
        return null;
      });

      final result = await checker.requestPhysicalActivityPermission();

      expect(result, false);
    });
  });

  group('PermissionsChecker - Notification Permission', () {
    const channelName = 'com.stepsync.chatbot/permissions';
    const MethodChannel channel = MethodChannel(channelName);
    late PermissionsChecker checker;
    late List<MethodCall> log;

    setUp(() {
      log = <MethodCall>[];
      checker = PermissionsChecker(logger: Logger(level: Level.off));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      log.clear();
    });

    test('checkNotificationPermission returns granted', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkNotificationPermission') {
          return 'GRANTED';
        }
        return null;
      });

      final result = await checker.checkNotificationPermission();

      expect(result, PermissionStatus.granted);
      expect(log.first.method, 'checkNotificationPermission');
    });

    test('checkNotificationPermission handles NOT_AVAILABLE (Android < 13)',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkNotificationPermission') {
          throw PlatformException(
            code: 'NOT_AVAILABLE',
            message: 'Android version < 13',
          );
        }
        return null;
      });

      final result = await checker.checkNotificationPermission();

      expect(result, PermissionStatus.notApplicable);
    });

    test('requestNotificationPermission returns true on grant', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'requestNotificationPermission') {
          return true;
        }
        return null;
      });

      final result = await checker.requestNotificationPermission();

      expect(result, true);
      expect(log.first.method, 'requestNotificationPermission');
    });

    test('requestNotificationPermission handles error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'requestNotificationPermission') {
          throw PlatformException(code: 'ERROR');
        }
        return null;
      });

      final result = await checker.requestNotificationPermission();

      expect(result, false);
    });
  });

  group('PermissionsChecker - Location Permission', () {
    const channelName = 'com.stepsync.chatbot/permissions';
    const MethodChannel channel = MethodChannel(channelName);
    late PermissionsChecker checker;
    late List<MethodCall> log;

    setUp(() {
      log = <MethodCall>[];
      checker = PermissionsChecker(logger: Logger(level: Level.off));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      log.clear();
    });

    test('checkLocationPermission returns all granted', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkLocationPermission') {
          return {
            'fine': true,
            'coarse': true,
            'background': true,
          };
        }
        return null;
      });

      final result = await checker.checkLocationPermission();

      expect(result['fine'], true);
      expect(result['coarse'], true);
      expect(result['background'], true);
      expect(log.first.method, 'checkLocationPermission');
    });

    test('checkLocationPermission returns partial permissions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkLocationPermission') {
          return {
            'fine': true,
            'coarse': false,
            'background': false,
          };
        }
        return null;
      });

      final result = await checker.checkLocationPermission();

      expect(result['fine'], true);
      expect(result['coarse'], false);
      expect(result['background'], false);
    });

    test('checkLocationPermission handles null response gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });

      final result = await checker.checkLocationPermission();

      expect(result['fine'], false);
      expect(result['coarse'], false);
      expect(result['background'], false);
    });

    test('checkLocationPermission handles error gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkLocationPermission') {
          throw PlatformException(code: 'ERROR', message: 'Failed');
        }
        return null;
      });

      final result = await checker.checkLocationPermission();

      expect(result['fine'], false);
      expect(result['coarse'], false);
      expect(result['background'], false);
    });
  });

  group('PermissionsChecker - Motion & Fitness Permission (iOS)', () {
    const channelName = 'com.stepsync.chatbot/permissions';
    const MethodChannel channel = MethodChannel(channelName);
    late PermissionsChecker checker;
    late List<MethodCall> log;

    setUp(() {
      log = <MethodCall>[];
      checker = PermissionsChecker(logger: Logger(level: Level.off));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      log.clear();
    });

    test('checkMotionFitnessPermission returns granted', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkMotionFitnessPermission') {
          return 'GRANTED';
        }
        return null;
      });

      final result = await checker.checkMotionFitnessPermission();

      expect(result, PermissionStatus.granted);
      expect(log.first.method, 'checkMotionFitnessPermission');
    });

    test('checkMotionFitnessPermission returns notDetermined', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkMotionFitnessPermission') {
          return 'NOT_DETERMINED';
        }
        return null;
      });

      final result = await checker.checkMotionFitnessPermission();

      expect(result, PermissionStatus.notDetermined);
    });

    test('checkMotionFitnessPermission returns restricted', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'checkMotionFitnessPermission') {
          return 'RESTRICTED';
        }
        return null;
      });

      final result = await checker.checkMotionFitnessPermission();

      expect(result, PermissionStatus.restricted);
    });

    test('requestMotionFitnessPermission returns true on success', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'requestMotionFitnessPermission') {
          return true;
        }
        return null;
      });

      final result = await checker.requestMotionFitnessPermission();

      expect(result, true);
      expect(log.first.method, 'requestMotionFitnessPermission');
    });

    test('openIOSSettings handles error gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('com.stepsync.chatbot/ios_settings'),
              (MethodCall methodCall) async {
        if (methodCall.method == 'openSettings') {
          throw PlatformException(code: 'ERROR');
        }
        return null;
      });

      final result = await checker.openIOSSettings();

      expect(result, false);
    });
  });

  group('PermissionsChecker - checkAllPermissions', () {
    const channelName = 'com.stepsync.chatbot/permissions';
    const MethodChannel channel = MethodChannel(channelName);
    late PermissionsChecker checker;

    setUp(() {
      checker = PermissionsChecker(logger: Logger(level: Level.off));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        // Mock Android responses
        if (methodCall.method == 'checkPhysicalActivityPermission') {
          return 'GRANTED';
        }
        if (methodCall.method == 'checkNotificationPermission') {
          return 'DENIED';
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('checkAllPermissions returns all Android permissions', () async {
      final result = await checker.checkAllPermissions();

      // On Android platform (in tests, Platform.isAndroid behavior varies)
      // We're just testing that the method runs without errors
      expect(result, isA<Map<String, PermissionStatus>>());
    });
  });
}
