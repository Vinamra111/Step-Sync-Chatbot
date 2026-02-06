/// Tests for Encryption Key Manager
///
/// Validates:
/// - Secure key generation
/// - Key persistence across sessions
/// - Key retrieval
/// - Key deletion
/// - Error handling

import 'package:test/test.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../lib/src/services/encryption_key_manager.dart';

// Mock secure storage for testing
class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _storage = {};

  MockSecureStorage() : super();

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }
}

void main() {
  group('EncryptionKeyManager - Key Generation', () {
    late EncryptionKeyManager keyManager;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
      keyManager = EncryptionKeyManager(
        storage: mockStorage,
        logger: Logger(level: Level.off),
      );
    });

    test('Generates new key if none exists', () async {
      final key = await keyManager.getOrGenerateKey();

      expect(key, isNotEmpty);
      expect(key.length, equals(64)); // 32 bytes = 64 hex chars
      expect(key, matches(RegExp(r'^[0-9a-f]{64}$'))); // Valid hex
    });

    test('Returns same key on subsequent calls', () async {
      final key1 = await keyManager.getOrGenerateKey();
      final key2 = await keyManager.getOrGenerateKey();

      expect(key1, equals(key2));
    });

    test('Generates unique keys for different instances', () async {
      final keyManager1 = EncryptionKeyManager(
        storage: MockSecureStorage(),
        logger: Logger(level: Level.off),
      );
      final keyManager2 = EncryptionKeyManager(
        storage: MockSecureStorage(),
        logger: Logger(level: Level.off),
      );

      final key1 = await keyManager1.getOrGenerateKey();
      final key2 = await keyManager2.getOrGenerateKey();

      // Different storage instances should have different keys
      expect(key1, isNot(equals(key2)));
    });

    test('Persists key across manager instances', () async {
      final storage = MockSecureStorage();

      final keyManager1 = EncryptionKeyManager(
        storage: storage,
        logger: Logger(level: Level.off),
      );
      final key1 = await keyManager1.getOrGenerateKey();

      // Create new manager with same storage
      final keyManager2 = EncryptionKeyManager(
        storage: storage,
        logger: Logger(level: Level.off),
      );
      final key2 = await keyManager2.getOrGenerateKey();

      expect(key1, equals(key2));
    });

    test('Generates cryptographically random keys', () async {
      final keys = <String>{};

      // Generate multiple keys
      for (int i = 0; i < 100; i++) {
        final storage = MockSecureStorage();
        final km = EncryptionKeyManager(
          storage: storage,
          logger: Logger(level: Level.off),
        );
        final key = await km.getOrGenerateKey();
        keys.add(key);
      }

      // All keys should be unique
      expect(keys.length, equals(100));
    });
  });

  group('EncryptionKeyManager - Key Management', () {
    late EncryptionKeyManager keyManager;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
      keyManager = EncryptionKeyManager(
        storage: mockStorage,
        logger: Logger(level: Level.off),
      );
    });

    test('hasKey returns false initially', () async {
      final exists = await keyManager.hasKey();
      expect(exists, isFalse);
    });

    test('hasKey returns true after key generation', () async {
      await keyManager.getOrGenerateKey();

      final exists = await keyManager.hasKey();
      expect(exists, isTrue);
    });

    test('deleteKey removes the key', () async {
      await keyManager.getOrGenerateKey();
      expect(await keyManager.hasKey(), isTrue);

      await keyManager.deleteKey();
      expect(await keyManager.hasKey(), isFalse);
    });

    test('Generates new key after deletion', () async {
      final key1 = await keyManager.getOrGenerateKey();
      await keyManager.deleteKey();

      final key2 = await keyManager.getOrGenerateKey();

      expect(key1, isNot(equals(key2)));
    });

    test('deleteAll clears all storage', () async {
      await keyManager.getOrGenerateKey();
      await keyManager.deleteAll();

      final hasKey = await keyManager.hasKey();
      expect(hasKey, isFalse);
    });
  });

  group('EncryptionKeyManager - Error Handling', () {
    test('Handles storage read errors gracefully', () async {
      // Mock storage that throws on read
      final errorStorage = _ErrorThrowingStorage();
      final keyManager = EncryptionKeyManager(
        storage: errorStorage,
        logger: Logger(level: Level.off),
      );

      expect(
        () => keyManager.getOrGenerateKey(),
        throwsA(isA<EncryptionKeyException>()),
      );
    });

    test('hasKey returns false on error', () async {
      final errorStorage = _ErrorThrowingStorage();
      final keyManager = EncryptionKeyManager(
        storage: errorStorage,
        logger: Logger(level: Level.off),
      );

      final hasKey = await keyManager.hasKey();
      expect(hasKey, isFalse);
    });
  });

  group('EncryptionKeyManager - Security Properties', () {
    test('Key has sufficient entropy', () async {
      final keyManager = EncryptionKeyManager(
        storage: MockSecureStorage(),
        logger: Logger(level: Level.off),
      );

      final key = await keyManager.getOrGenerateKey();

      // Check for patterns (should be random)
      final bytes = <String>[];
      for (int i = 0; i < key.length; i += 2) {
        bytes.add(key.substring(i, i + 2));
      }

      // Count unique bytes (should be high for good entropy)
      final uniqueBytes = bytes.toSet().length;
      expect(uniqueBytes, greaterThan(20)); // At least 20 unique bytes out of 32
    });

    test('Key format is valid hex string', () async {
      final keyManager = EncryptionKeyManager(
        storage: MockSecureStorage(),
        logger: Logger(level: Level.off),
      );

      final key = await keyManager.getOrGenerateKey();

      // Should be 64 character hex string (32 bytes)
      expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('Key is 256-bit (32 bytes)', () async {
      final keyManager = EncryptionKeyManager(
        storage: MockSecureStorage(),
        logger: Logger(level: Level.off),
      );

      final key = await keyManager.getOrGenerateKey();

      // 32 bytes * 2 hex chars per byte = 64 chars
      expect(key.length, equals(64));
    });
  });
}

// Helper class that throws errors
class _ErrorThrowingStorage extends FlutterSecureStorage {
  _ErrorThrowingStorage() : super();


  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Storage error');
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Storage error');
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Storage error');
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Storage error');
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Storage error');
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Storage error');
  }
}
