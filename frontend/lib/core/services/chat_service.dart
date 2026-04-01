import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class ChatService {
  // Singleton pattern for global access
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  IO.Socket? _socket;
  
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
  List<dynamic> currentReminders = [];

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      print("[ChatService] Cannot connect: No JWT token found");
      return;
    }

    print("[ChatService] Connecting to WebSocket...");

    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print("[ChatService] Connected to Server successfully");
      
      // FETCH HISTORY AUTOMATICALLY THE MOMENT WE CONNECT!
      _socket!.emit('chat:fetch_history');
    });

    // Listen for history payload
    _socket!.on('chat:history_loaded', (data) {
      _historyController.add(List<dynamic>.from(data));
    });

    _socket!.onConnectError((err) {
      print("[ChatService] Connection Error: $err");
    });

    // Listen for AI replies
    _socket!.on('chat:receive', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    // Listen for typing indicator
    _socket!.on('chat:typing', (data) {
      final isTyping = data['status'] ?? false;
      _typingController.add(isTyping);
    });

    // Listen for proactive scheduled alerts
    _socket!.on('system:alert', (data) {
      _systemAlertController.add(data['message']);
    });

    // Listen for mission logs loaded
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
      print("[ChatService] Error: Socket not connected!");
    }
  }

  void disconnect() {
    print("[ChatService] Disconnecting WebSocket...");
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
