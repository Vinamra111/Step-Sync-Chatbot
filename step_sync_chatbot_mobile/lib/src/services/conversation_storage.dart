/// Conversation Storage Service - Encrypted Persistence
///
/// Provides HIPAA-compliant encrypted storage for conversation history
/// using AES-256-GCM encryption with platform-specific secure key storage.

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:typed_data';

class ConversationMessage {
  final String id;
  final String content;
  final bool isBot;
  final DateTime timestamp;

  ConversationMessage({
    required this.id,
    required this.content,
    required this.isBot,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isBot': isBot,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isBot: json['isBot'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ConversationStorage {
  static const String _keyStorageKey = 'conversation_encryption_key';
  static const String _conversationKey = 'encrypted_conversations';
  static const String _enabledKey = 'encryption_enabled';

  final FlutterSecureStorage _secureStorage;
  final AesGcm _algorithm = AesGcm.with256bits();
  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _encryptionEnabled = true;

  // Thread-safe lock for concurrent access
  bool _isWriting = false;

  ConversationStorage({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            resetOnError: true, // Auto-recover from BadPaddingException
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  /// Initialize storage (must be called before use)
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _encryptionEnabled = _prefs?.getBool(_enabledKey) ?? true;
    _initialized = true;
  }

  /// Enable or disable encryption
  Future<void> setEncryptionEnabled(bool enabled) async {
    await initialize();
    _encryptionEnabled = enabled;
    await _prefs?.setBool(_enabledKey, enabled);
  }

  /// Get or generate encryption key
  Future<SecretKey> _getOrGenerateKey() async {
    // Try to get existing key from secure storage
    String? keyString = await _secureStorage.read(key: _keyStorageKey);

    if (keyString != null) {
      // Use existing key
      final keyBytes = base64Decode(keyString);
      return SecretKey(keyBytes);
    }

    // Generate new 256-bit AES key
    final key = await _algorithm.newSecretKey();
    final keyBytes = await key.extractBytes();

    // Store in platform-specific secure storage
    // iOS: Keychain with first_unlock accessibility
    // Android: EncryptedSharedPreferences
    await _secureStorage.write(
      key: _keyStorageKey,
      value: base64Encode(keyBytes),
    );

    return key;
  }

  /// Encrypt message content using AES-256-GCM
  Future<String> _encrypt(String plainText) async {
    final key = await _getOrGenerateKey();

    // Convert plaintext to bytes
    final plainBytes = utf8.encode(plainText);

    // Encrypt using AES-GCM (includes authentication)
    final secretBox = await _algorithm.encrypt(
      plainBytes,
      secretKey: key,
    );

    // Use built-in concatenation: nonce + ciphertext + mac
    final concatenated = secretBox.concatenation();

    // Return as base64 string for storage
    return base64Encode(concatenated);
  }

  /// Decrypt message content
  Future<String> _decrypt(String encryptedText) async {
    try {
      final key = await _getOrGenerateKey();

      // Decode from base64
      final concatenated = base64Decode(encryptedText);

      // Split back into SecretBox using built-in method
      final secretBox = SecretBox.fromConcatenation(
        concatenated,
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );

      // Decrypt
      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: key,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      // If decryption fails, data might be corrupted
      throw Exception('Decryption failed: $e');
    }
  }

  /// Save conversation message
  Future<void> saveMessage(ConversationMessage message) async {
    await initialize();

    // Thread-safe lock: wait if another write is in progress
    while (_isWriting) {
      await Future.delayed(Duration(milliseconds: 10));
    }

    _isWriting = true;

    try {
      // Load existing messages
      final messages = await loadMessages();

      // Add new message
      messages.add(message);

      // Serialize to JSON
      final jsonList = messages.map((m) => m.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // Encrypt if enabled
      final dataToStore = _encryptionEnabled
          ? await _encrypt(jsonString)
          : jsonString;

      // Save to storage
      await _prefs?.setString(_conversationKey, dataToStore);
    } finally {
      _isWriting = false;
    }
  }

  /// Load conversation messages
  Future<List<ConversationMessage>> loadMessages() async {
    await initialize();

    final storedData = _prefs?.getString(_conversationKey);

    if (storedData == null || storedData.isEmpty) {
      return [];
    }

    try {
      // Decrypt if needed
      final jsonString = _encryptionEnabled
          ? await _decrypt(storedData)
          : storedData;

      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      return jsonList
          .map((json) => ConversationMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      // CRITICAL: If decryption fails (BadPaddingException), clear corrupted data
      // This can happen if Android Keystore is corrupted after OS update
      if (e.toString().contains('BadPadding') || e.toString().contains('Decryption failed')) {
        print('Encrypted storage corrupted, clearing data to recover: $e');
        try {
          await clearAll();
          await deleteKey();
        } catch (clearError) {
          print('Error clearing corrupted storage: $clearError');
        }
      }
      // Return empty list, app will show welcome message
      return [];
    }
  }

  /// Clear all conversations
  Future<void> clearAll() async {
    await initialize();
    await _prefs?.remove(_conversationKey);
  }

  /// Delete encryption key (WARNING: Makes existing data unrecoverable)
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
  }

  /// Get encryption status
  bool get isEncryptionEnabled => _encryptionEnabled;

  /// Check if key exists
  Future<bool> hasEncryptionKey() async {
    final keyString = await _secureStorage.read(key: _keyStorageKey);
    return keyString != null;
  }
}
