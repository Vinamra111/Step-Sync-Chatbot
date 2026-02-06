/// Encryption Key Manager Service
///
/// Provides secure storage and management of database encryption keys:
/// - Generates cryptographically secure encryption keys
/// - Stores keys in platform-specific secure storage
/// - Manages key lifecycle (generate, retrieve, delete)
/// - HIPAA-compliant key management

import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Exception for encryption key errors
class EncryptionKeyException implements Exception {
  final String message;
  final dynamic originalError;

  EncryptionKeyException(this.message, {this.originalError});

  @override
  String toString() => 'EncryptionKeyException: $message';
}

/// Encryption Key Manager
///
/// Manages database encryption keys with secure storage.
/// Keys are stored in platform-specific secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences (AES256)
/// - Windows: Credential Manager
class EncryptionKeyManager {
  final FlutterSecureStorage _storage;
  final Logger _logger;

  static const String _keyStorageKey = 'step_sync_db_encryption_key';
  static const int _keyLengthBytes = 32; // 256-bit key

  EncryptionKeyManager({
    FlutterSecureStorage? storage,
    Logger? logger,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _logger = logger ?? Logger();

  /// Get or generate encryption key
  ///
  /// Returns existing key if one exists, otherwise generates a new one.
  /// This ensures database can be decrypted across app restarts.
  Future<String> getOrGenerateKey() async {
    try {
      // Try to retrieve existing key
      final existingKey = await _storage.read(key: _keyStorageKey);

      if (existingKey != null && existingKey.isNotEmpty) {
        _logger.d('Retrieved existing encryption key from secure storage');
        return existingKey;
      }

      // Generate new key
      _logger.i('No existing key found, generating new encryption key');
      final newKey = _generateSecureKey();

      // Store securely
      await _storage.write(key: _keyStorageKey, value: newKey);
      _logger.i('New encryption key generated and stored securely');

      return newKey;
    } catch (e) {
      _logger.e('Failed to get or generate encryption key: $e');
      throw EncryptionKeyException(
        'Failed to access encryption key',
        originalError: e,
      );
    }
  }

  /// Generate cryptographically secure random key
  String _generateSecureKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(
      _keyLengthBytes,
      (_) => random.nextInt(256),
    );

    // Convert to hex string
    return keyBytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Check if encryption key exists
  Future<bool> hasKey() async {
    try {
      final key = await _storage.read(key: _keyStorageKey);
      return key != null && key.isNotEmpty;
    } catch (e) {
      _logger.e('Failed to check for encryption key: $e');
      return false;
    }
  }

  /// Delete encryption key
  ///
  /// WARNING: This will make existing encrypted databases unreadable!
  /// Only use for testing or when explicitly requested by user.
  Future<void> deleteKey() async {
    try {
      await _storage.delete(key: _keyStorageKey);
      _logger.w('Encryption key deleted from secure storage');
    } catch (e) {
      _logger.e('Failed to delete encryption key: $e');
      throw EncryptionKeyException(
        'Failed to delete encryption key',
        originalError: e,
      );
    }
  }

  /// Delete all stored data (for testing)
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _logger.w('All secure storage data deleted');
    } catch (e) {
      _logger.e('Failed to delete all secure storage: $e');
      throw EncryptionKeyException(
        'Failed to delete all secure storage',
        originalError: e,
      );
    }
  }
}
