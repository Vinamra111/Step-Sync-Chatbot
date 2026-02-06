/// Offline Service
///
/// Main coordinator for offline mode functionality.
/// Features:
/// - Network connectivity monitoring
/// - Message queuing when offline
/// - Auto-retry when connection restored
/// - Offline knowledge base responses
/// - Graceful degradation

import 'dart:async';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'network_monitor.dart';
import 'offline_message_queue.dart';
import 'offline_knowledge_base.dart';
import '../data/models/chat_message.dart';

/// Offline mode status
class OfflineStatus {
  final bool isOnline;
  final ConnectionType connectionType;
  final ConnectionQuality connectionQuality;
  final int queuedMessageCount;
  final bool isProcessingQueue;

  const OfflineStatus({
    required this.isOnline,
    required this.connectionType,
    required this.connectionQuality,
    required this.queuedMessageCount,
    required this.isProcessingQueue,
  });

  @override
  String toString() =>
      'OfflineStatus(online: $isOnline, type: $connectionType, queued: $queuedMessageCount)';
}

/// Callback for processing queued messages
typedef MessageProcessor = Future<bool> Function(String messageId, String messageText);

/// Offline Service
class OfflineService {
  final String userId;
  final Logger _logger;
  final NetworkMonitor _networkMonitor;
  final OfflineMessageQueue _messageQueue;
  final OfflineKnowledgeBase _knowledgeBase;

  /// Whether currently processing queue
  bool _isProcessingQueue = false;

  /// Message processor callback
  MessageProcessor? _messageProcessor;

  /// Stream subscription for connectivity changes
  StreamSubscription<ConnectivityInfo>? _connectivitySubscription;

  /// Stream subscription for queue size changes
  StreamSubscription<int>? _queueSizeSubscription;

  /// Stream of offline status changes
  final StreamController<OfflineStatus> _statusController =
      StreamController<OfflineStatus>.broadcast();
  Stream<OfflineStatus> get statusStream => _statusController.stream;

  /// Current offline status
  OfflineStatus get currentStatus => OfflineStatus(
        isOnline: _networkMonitor.isOnline,
        connectionType: _networkMonitor.connectionType,
        connectionQuality: _networkMonitor.quality,
        queuedMessageCount: _queuedMessageCount,
        isProcessingQueue: _isProcessingQueue,
      );

  int _queuedMessageCount = 0;

  OfflineService({
    required this.userId,
    Logger? logger,
    NetworkMonitor? networkMonitor,
    OfflineMessageQueue? messageQueue,
    OfflineKnowledgeBase? knowledgeBase,
  })  : _logger = logger ?? Logger(),
        _networkMonitor = networkMonitor ?? NetworkMonitor(logger: logger),
        _messageQueue = messageQueue ?? OfflineMessageQueue(userId: userId, logger: logger),
        _knowledgeBase = knowledgeBase ?? OfflineKnowledgeBase(logger: logger);

  /// Initialize offline service
  Future<void> initialize() async {
    _logger.d('Initializing offline service for user: $userId');

    // Initialize network monitor
    await _networkMonitor.initialize();

    // Initialize message queue
    final appDir = await getApplicationDocumentsDirectory();
    await _messageQueue.initialize(appDir.path);

    // Get initial queue size
    _queuedMessageCount = await _messageQueue.getQueueSize();

    // Listen for connectivity changes
    _connectivitySubscription =
        _networkMonitor.connectivityStream.listen(_onConnectivityChanged);

    // Listen for queue size changes
    _queueSizeSubscription = _messageQueue.queueSizeStream.listen((size) {
      _queuedMessageCount = size;
      _emitStatus();
    });

    // Emit initial status
    _emitStatus();

    _logger.i('Offline service initialized. Online: ${_networkMonitor.isOnline}, Queued: $_queuedMessageCount');

    // If online on startup, process any queued messages
    if (_networkMonitor.isOnline) {
      _processQueue();
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityInfo info) {
    _logger.i('Connectivity changed: ${info.status.name} (${info.type.name})');
    _emitStatus();

    // If went online, process queued messages
    if (info.isOnline && !_isProcessingQueue) {
      _processQueue();
    }
  }

  /// Set message processor callback
  void setMessageProcessor(MessageProcessor processor) {
    _messageProcessor = processor;
  }

  /// Send message (queue if offline, send if online)
  Future<bool> sendMessage(
    String messageId,
    String messageText, {
    MessagePriority priority = MessagePriority.normal,
  }) async {
    if (_networkMonitor.isOffline) {
      // Queue message for later
      _logger.d('Offline - queuing message: $messageId');
      await _messageQueue.enqueue(
        messageId,
        messageText,
        priority: priority,
        metadata: {
          'queued_at': DateTime.now().toIso8601String(),
        },
      );
      return false; // Not sent yet
    }

    // Online - try to send immediately
    if (_messageProcessor != null) {
      try {
        final success = await _messageProcessor!(messageId, messageText);
        if (success) {
          _logger.d('Message sent successfully: $messageId');
          return true;
        } else {
          // Failed to send - queue it
          _logger.w('Failed to send message, queuing: $messageId');
          await _messageQueue.enqueue(messageId, messageText, priority: priority);
          return false;
        }
      } catch (e) {
        _logger.e('Error sending message, queuing: $e');
        await _messageQueue.enqueue(messageId, messageText, priority: priority);
        return false;
      }
    }

    // No processor set - queue it
    _logger.w('No message processor set, queuing message');
    await _messageQueue.enqueue(messageId, messageText, priority: priority);
    return false;
  }

  /// Process queued messages
  Future<void> _processQueue() async {
    if (_isProcessingQueue) {
      _logger.d('Already processing queue');
      return;
    }

    if (_networkMonitor.isOffline) {
      _logger.d('Offline - skipping queue processing');
      return;
    }

    if (_messageProcessor == null) {
      _logger.w('No message processor set - cannot process queue');
      return;
    }

    _isProcessingQueue = true;
    _emitStatus();

    _logger.i('Processing queued messages...');

    try {
      while (_networkMonitor.isOnline) {
        final message = await _messageQueue.dequeue();
        if (message == null) {
          // Queue is empty
          break;
        }

        _logger.d('Processing queued message: ${message.id} (retry ${message.retryCount})');

        try {
          final success = await _messageProcessor!(message.id, message.messageText);

          if (success) {
            // Successfully sent - remove from queue
            await _messageQueue.markSent(message.id);
            _logger.i('Queued message sent successfully: ${message.id}');
          } else {
            // Failed to send - increment retry count
            await _messageQueue.markFailed(message.id);
            _logger.w('Failed to send queued message: ${message.id}');
          }
        } catch (e) {
          _logger.e('Error processing queued message: $e');
          await _messageQueue.markFailed(message.id);
        }

        // Brief delay between messages
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _logger.i('Queue processing complete');
    } finally {
      _isProcessingQueue = false;
      _emitStatus();
    }
  }

  /// Get offline response from knowledge base
  Future<ChatMessage?> getOfflineResponse(String query) async {
    if (_networkMonitor.isOnline) {
      // Online - return null to indicate online processing should be used
      return null;
    }

    _logger.d('Searching offline knowledge base for: "$query"');

    final match = await _knowledgeBase.search(query);

    if (match != null) {
      _logger.i('Offline response found: ${match.entry.id} (confidence: ${match.confidence})');
      return match.toMessage();
    }

    // No match found - return fallback
    _logger.d('No offline match found, returning fallback');
    return _knowledgeBase.getFallbackResponse();
  }

  /// Check if online
  bool get isOnline => _networkMonitor.isOnline;

  /// Check if offline
  bool get isOffline => _networkMonitor.isOffline;

  /// Get connection type
  ConnectionType get connectionType => _networkMonitor.connectionType;

  /// Get connection quality
  ConnectionQuality get connectionQuality => _networkMonitor.quality;

  /// Get queued message count
  int get queuedMessageCount => _queuedMessageCount;

  /// Get all queued messages
  Future<List<QueuedMessage>> getQueuedMessages() async {
    return _messageQueue.getAllQueued();
  }

  /// Get failed messages
  Future<List<QueuedMessage>> getFailedMessages() async {
    return _messageQueue.getFailedMessages();
  }

  /// Clear failed messages
  Future<void> clearFailedMessages() async {
    await _messageQueue.clearFailedMessages();
  }

  /// Clear entire queue
  Future<void> clearQueue() async {
    await _messageQueue.clear();
  }

  /// Force connectivity check
  Future<void> forceConnectivityCheck() async {
    await _networkMonitor.forceCheck();
  }

  /// Wait for online status
  Future<bool> waitForOnline({Duration timeout = const Duration(seconds: 30)}) async {
    return _networkMonitor.waitForOnline(timeout: timeout);
  }

  /// Get knowledge base statistics
  Map<String, dynamic> getKnowledgeBaseStats() {
    return _knowledgeBase.getStatistics();
  }

  /// Emit current status to stream
  void _emitStatus() {
    _statusController.add(currentStatus);
  }

  /// Get detailed status information
  Map<String, dynamic> getStatusInfo() {
    return {
      'is_online': isOnline,
      'connection_type': connectionType.name,
      'connection_quality': connectionQuality.name,
      'queued_messages': queuedMessageCount,
      'is_processing_queue': _isProcessingQueue,
      'knowledge_base': _knowledgeBase.getStatistics(),
    };
  }

  /// Dispose resources
  void dispose() {
    _logger.d('Disposing offline service');
    _connectivitySubscription?.cancel();
    _queueSizeSubscription?.cancel();
    _statusController.close();
    _networkMonitor.dispose();
    _messageQueue.dispose();
  }
}
