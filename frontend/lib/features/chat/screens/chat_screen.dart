import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_app_bar.dart';
import '../../../core/providers/language_provider.dart';

enum MoraState { idle, thinking, talking }

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ChatService _chatService = ChatService();
  final VoiceService _voiceService = VoiceService();
  final List<Map<String, dynamic>> _messages =[];

  MoraState _moraState = MoraState.idle;
  Timer? _talkingTimer;
  StreamSubscription<List<dynamic>>? _historySub;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<String>? _systemAlertSub;

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    
    _voiceService.init();
    _chatService.connect();
    
    // LOGIC FIX: Always setup listeners BEFORE fetching data. 
    // Otherwise, if the data is fetched instantly, you will miss the event!
    _historySub = _chatService.historyStream.listen((historyList) {
      if (mounted) {
        setState(() {
          _messages.clear();
          for (var msg in historyList) {
            _messages.add({
               'sender': msg['role'] == 'user' ? 'User' : 'Mora',
               'message': msg['content'],
               'timestamp': msg['timestamp']
            });
          }
        });
        _scrollToBottom();
      }
    });

    _messageSub = _chatService.messageStream.listen((messageData) {
      if (mounted) {
        setState(() {
          _messages.add(messageData); 
          if (messageData['sender'] == 'Shizuki') {
            _moraState = MoraState.talking;
            _startTalkingTimer();
            final langCode = ref.read(languageProvider).languageCode;
            _voiceService.speak(messageData['message'], languageCode: langCode);
          }
        });
        _scrollToBottom();
      }
    });

    _typingSub = _chatService.typingStream.listen((isTyping) {
      if (mounted) {
        setState(() {
          if (isTyping) {
            _moraState = MoraState.thinking;
            _talkingTimer?.cancel();
          } else {
             if (_moraState == MoraState.thinking) {
                 _moraState = MoraState.idle; 
             }
          }
        });
      }
    });

    _systemAlertSub = _chatService.systemAlertStream.listen((alertMessage) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("[ SYSTEM OVERRIDE ]\n$alertMessage", style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 10),
          ),
        );
        final langCode = ref.read(languageProvider).languageCode;
        _voiceService.speak(alertMessage, languageCode: langCode);
      }
    });

    // Now that listeners are ready, fetch the history.
    _chatService.fetchHistory();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startTalkingTimer() {
    _talkingTimer?.cancel();
    _talkingTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _moraState == MoraState.talking) {
        setState(() {
          _moraState = MoraState.idle;
        });
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    final langCode = ref.read(languageProvider).languageCode;
    _chatService.sendMessage(text, lang: langCode);
    _controller.clear();
    _voiceService.stop();
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDeep,
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.redAccent, width: 2),
            borderRadius: BorderRadius.circular(AppSpacing.md)),
        title: const Text('CLEAR MEMORY CORE?',
            style: TextStyle(fontFamily: 'Orbitron', color: Colors.redAccent)),
        content: const Text(
          'Are you sure you want to permanently delete all chat history? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions:[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppTextStyles.buttonLabel.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _chatService.clearChatHistory();
              setState(() {
                _messages.clear();
              });
            },
            child: const Text('DELETE', style: AppTextStyles.buttonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required for voice input.', style: TextStyle(color: Colors.redAccent)),
            backgroundColor: AppColors.bgCard,
          ),
        );
      }
      return;
    }

    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (mounted) setState(() => _isListening = true);
      _controller.clear();
      await _voiceService.startListening((recognizedText) {
        if (mounted) {
          setState(() {
            _controller.text = recognizedText;
          });
        }
      }, languageCode: ref.read(languageProvider).languageCode);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _talkingTimer?.cancel();
    _historySub?.cancel();
    _messageSub?.cancel();
    _typingSub?.cancel();
    _systemAlertSub?.cancel();
    _voiceService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: MechaAppBar(
        title: AppLocalizations.of(context)!.chatMode,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: _clearHistory,
        ),
      ),
      body: Stack(
        children:[
          const GridBackground(),
          Column(
            children:[
              // ── TODAY label ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(AppLocalizations.of(context)!.todayLabel,
                    style: AppTextStyles.sectionLabel),
              ),

              // ── Messages list ─────────────────────────────────────────
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(AppLocalizations.of(context)!.noChatYet,
                            style: AppTextStyles.hint),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _MessageBubble(message: _messages[i]),
                      ),
              ),

              // ── Input bar ─────────────────────────────────────────────
              _InputBar(
                controller: _controller,
                onSend: _sendMessage,
                isListening: _isListening,
                onToggleListen: _toggleListening,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final isUser = message['sender'] == 'User';
    final text = message['message'] ?? '';
    
    DateTime? msgTime;
    if (message['timestamp'] != null) {
        msgTime = DateTime.tryParse(message['timestamp']);
    }
    String timeStr = "";
    if (msgTime != null) {
       final local = msgTime.toLocal();
       timeStr = "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Mora avatar circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: const Icon(Icons.local_florist,
                  size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children:[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.lg),
                      topRight: const Radius.circular(AppSpacing.lg),
                      bottomLeft:
                          Radius.circular(isUser ? AppSpacing.lg : AppSpacing.xs),
                      bottomRight:
                          Radius.circular(isUser ? AppSpacing.xs : AppSpacing.lg),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                    boxShadow: isUser
                        ? null
                        :[
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: AppTextStyles.bodyMedium.copyWith(color: isUser ? Colors.white : AppColors.textPrimary),
                      strong: AppTextStyles.bodyMedium.copyWith(color: isUser ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold),
                      em: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                      code: const TextStyle(
                         color: AppColors.primary,
                         backgroundColor: Colors.black54,
                         fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                         color: Colors.black87,
                         border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isUser ? AppLocalizations.of(context)!.youSender : AppLocalizations.of(context)!.shizukiSender} · $timeStr',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            // User avatar circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.wb_sunny_outlined,
                  size: 16, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Input bar ──────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend, required this.isListening, required this.onToggleListen});
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isListening;
  final VoidCallback onToggleListen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children:[
          GestureDetector(
            onTap: onToggleListen,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isListening ? Colors.redAccent.withValues(alpha: 0.2) : AppColors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: isListening ? Colors.redAccent : AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Icon(isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? Colors.redAccent : AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.chatHint,
                hintStyle: AppTextStyles.hint,
                filled: true,
                fillColor: AppColors.bgCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors:[AppColors.primary, AppColors.accent],
                ),
                shape: BoxShape.circle,
                boxShadow:[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppColors.textPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}