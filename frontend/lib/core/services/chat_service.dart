import 'dart:async';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:socket_io_client/socket_io_client.dart' as io; // Changed IO to io
import '../constants/api_constants.dart';
import '../../features/auth/services/session_storage.dart';

class ChatService {
  // Singleton pattern for global access
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  io.Socket? _socket;
  
  final _historyController = StreamController<List<dynamic>>.broadcast();
  Stream<List<dynamic>> get historyStream => _historyController.stream;

  // Stream to let the UI listen for new incoming messages
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // Stream for AI typing status
  final _typingController = StreamController<bool>.broadcast();
  Stream<bool> get typingStream => _typingController.stream;

  // Stream for System Warning Popups (Cron/Screen-time)
  final _systemAlertController = StreamController<String>.broadcast();
  Stream<String> get systemAlertStream => _systemAlertController.stream;

  // Stream for Pending Mission Logs
  final _pendingRemindersController = StreamController<List<dynamic>>.broadcast();
  Stream<List<dynamic>> get pendingRemindersStream => _pendingRemindersController.stream;
  List<dynamic> currentReminders =[];

  Future<void>? _connectFuture;

  /// Completes when the socket is connected (or immediately if already connected).
  /// Callers should subscribe to streams before `await connect()` so they do not miss payloads.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    if (_connectFuture != null) return _connectFuture!;

    _connectFuture = _connectOnce();
    try {
      await _connectFuture;
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> _connectOnce() async {
    final token = await SessionStorage.getAccessToken();

    if (token == null) {
      debugPrint("[ChatService] Cannot connect: No JWT token found");
      return;
    }

    debugPrint("[ChatService] Connecting to WebSocket...");

    final completer = Completer<void>();

    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth({'token': token})
          .build(),
    );

    _registerSocketHandlers(completer);
    _socket!.connect();

    try {
      await completer.future.timeout(const Duration(seconds: 25));
    } catch (e, st) {
      debugPrint("[ChatService] Connect failed: $e\n$st");
      disconnect();
      rethrow;
    }
  }

  void _registerSocketHandlers(Completer<void> connectCompleter) {
    _socket!.onConnect((_) {
      debugPrint("[ChatService] Connected to Server successfully");
      if (!connectCompleter.isCompleted) connectCompleter.complete();
    });

    _socket!.onConnectError((err) {
      debugPrint("[ChatService] Connection Error: $err");
      if (!connectCompleter.isCompleted) {
        connectCompleter.completeError(err ?? 'WebSocket connection error');
      }
    });

    _socket!.on('chat:history_loaded', (data) {
      _historyController.add(List<dynamic>.from(data));
    });

    _socket!.on('chat:receive', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('chat:typing', (data) {
      final isTyping = data['status'] ?? false;
      _typingController.add(isTyping);
    });

    _socket!.on('system:alert', (data) {
      _systemAlertController.add(data['message']);
    });

    _socket!.on('reminder:pending_loaded', (data) {
      if (data != null) {
        currentReminders = List<dynamic>.from(data);
        _pendingRemindersController.add(currentReminders);
      }
    });
  }

  void fetchPendingReminders() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('reminder:fetch_pending');
    }
  }

  void fetchHistory() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('chat:fetch_history');
    }
  }

  void clearChatHistory() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('chat:clear_history');
    }
  }

  void createManualReminder(String task, String isoTime, List<String> daysOfWeek) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('reminder:create', {
        'task': task,
        'scheduledTime': isoTime,
        'daysOfWeek': daysOfWeek,
      });
    }
  }

  void updateReminder({
    required String id,
    bool? isCompleted,
    String? task,
    String? isoTime,
    List<String>? daysOfWeek,
  }) {
    if (_socket != null && _socket!.connected) {
      final payload = <String, dynamic>{'id': id};
      if (isCompleted != null) payload['isCompleted'] = isCompleted;
      if (task != null) payload['task'] = task;
      if (isoTime != null) payload['scheduledTime'] = isoTime;
      if (daysOfWeek != null) payload['daysOfWeek'] = daysOfWeek;
      _socket!.emit('reminder:update', payload);
    }
  }

  void deleteReminder(String id) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('reminder:delete', {'id': id});
    }
  }

  void deleteAllReminders() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('reminder:delete_all');
    }
  }

  void completeAllReminders() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('reminder:complete_all');
    }
  }

  void sendMessage(String message, {String lang = 'en'}) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('chat:send', {'message': message, 'lang': lang});
      // Optionally echo the message back to local UI immediately
      _messageController.add({
        'sender': 'User',
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      debugPrint("[ChatService] Error: Socket not connected!");
    }
  }

  void disconnect() {
    debugPrint("[ChatService] Disconnecting WebSocket...");
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    _messageController.close();
    _typingController.close();
    _historyController.close();
    _systemAlertController.close();
    _pendingRemindersController.close();
  }
}
