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
  
  // Stream to let the UI listen for new incoming messages
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // Stream for AI typing status
  final _typingController = StreamController<bool>.broadcast();
  Stream<bool> get typingStream => _typingController.stream;

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
  }

  void sendMessage(String message) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('chat:send', {'message': message});
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
  }
}
