import 'package:flutter/material.dart';
import '../../core/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    
    // Connect to WebSockets when entering the screen
    _chatService.connect();

    // Listen to incoming messages and update the UI
    _chatService.messageStream.listen((messageData) {
      if (mounted) {
        setState(() {
          // Insert at the top of the list because ListView is reversed
          _messages.insert(0, messageData); 
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _chatService.sendMessage(text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Base dark theme for Mecha aesthetic
      backgroundColor: const Color(0xFF0F0F0F), 
      appBar: AppBar(
        title: const Text(
          'MORA // CORE LINK', 
          style: TextStyle(
            color: Colors.cyanAccent, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Expanded Chat List
            Expanded(
              child: ListView.builder(
                reverse: true, // Ensures new messages appear at the bottom
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['sender'] == 'User';
                  
                  return _buildChatBubble(message, isUser);
                },
              ),
            ),
            
            // AI "Typing/Thinking" Indicator Area
            StreamBuilder<bool>(
              stream: _chatService.typingStream,
              builder: (context, snapshot) {
                final isTyping = snapshot.data ?? false;
                if (isTyping) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '> Mora is processing data...',
                        style: TextStyle(
                          color: Colors.cyanAccent, 
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Message Input Field
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // --- UI Building Blocks ---

  Widget _buildChatBubble(Map<String, dynamic> message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        // Max width to ensure bubbles don't stretch fully across the screen
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.cyan.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(0), // Sharp edges for Mecha feel
          border: Border.all(
            color: isUser ? Colors.cyanAccent.withOpacity(0.7) : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          message['message'] ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Input command...',
                hintStyle: const TextStyle(color: Colors.white38),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyanAccent, width: 0.5),
                  borderRadius: BorderRadius.zero, // Sharp corners
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyanAccent, width: 1.5),
                  borderRadius: BorderRadius.zero,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent),
              color: Colors.cyan.withOpacity(0.1),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.cyanAccent),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
