/// Chat message model — UI-only, ready for Riverpod/backend later.
class Message {
  const Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final String timestamp; // e.g. "09:01"
}
