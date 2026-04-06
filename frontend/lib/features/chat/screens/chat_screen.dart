import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/shizuki_dialogue_catalog.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_app_bar.dart';
import '../../../shared/widgets/shizuki_animator.dart';
import '../../../shared/widgets/shizuki_dialogue_bubble.dart';
import '../../../shared/widgets/shizuki_zoom_controls.dart';

enum ShizukiChatPhase { idle, thinking, talking }

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const double _defaultZoom = 1.0;
  static const double _minZoom = 0.82;
  static const double _maxZoom = 1.9;
  static const double _zoomStep = 0.12;
  static const double _minPaneFraction = 0.24;
  static const double _maxPaneFraction = 0.58;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final VoiceService _voiceService = VoiceService();
  final List<Map<String, dynamic>> _messages = [];
  final ShizukiDialogueCatalog _dialogues = ShizukiDialogueCatalog();

  ShizukiChatPhase _phase = ShizukiChatPhase.idle;
  Timer? _talkingTimer;
  Timer? _sadTimer;
  Timer? _dialogueTimer;
  Timer? _touchTalkTimer;
  StreamSubscription<List<dynamic>>? _historySub;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<String>? _systemAlertSub;

  bool _isListening = false;
  bool _sadOverride = false;
  bool _isTouchTalking = false;
  String? _bubbleText;
  double _animatorZoom = _defaultZoom;
  int _viewportResetToken = 0;
  double _mascotPaneFraction = 0.34;

  ShizukiEmotion get _mascotEmotion {
    if (_sadOverride) {
      return ShizukiEmotion.sad;
    }

    switch (_phase) {
      case ShizukiChatPhase.talking:
        return ShizukiEmotion.smile;
      case ShizukiChatPhase.thinking:
        return ShizukiEmotion.idle;
      case ShizukiChatPhase.idle:
        return ShizukiEmotion.smile;
    }
  }

  bool get _isMascotTalking =>
      !_sadOverride && (_phase == ShizukiChatPhase.talking || _isTouchTalking);

  @override
  void initState() {
    super.initState();
    unawaited(_voiceService.init());

    _historySub = _chatService.historyStream.listen((historyList) {
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            historyList.map((msg) => <String, dynamic>{
                  'sender': msg['role'] == 'user' ? 'User' : 'Mora',
                  'message': msg['content'],
                  'timestamp': msg['timestamp'],
                }),
          );
      });
      _scrollToBottom();
    });

    _messageSub = _chatService.messageStream.listen((messageData) {
      if (!mounted) return;
      setState(() {
        _messages.add(messageData);
        if (messageData['sender'] == 'Shizuki') {
          _phase = ShizukiChatPhase.talking;
          _startTalkingTimer();
          final langCode = ref.read(languageProvider).languageCode;
          unawaited(
            _voiceService.speak(
              messageData['message'],
              languageCode: langCode,
            ),
          );
        }
      });
      _scrollToBottom();
    });

    _typingSub = _chatService.typingStream.listen((isTyping) {
      if (!mounted) return;
      setState(() {
        if (isTyping) {
          _phase = ShizukiChatPhase.thinking;
          _talkingTimer?.cancel();
        } else if (_phase == ShizukiChatPhase.thinking) {
          _phase = ShizukiChatPhase.idle;
        }
      });
    });

    _systemAlertSub = _chatService.systemAlertStream.listen((alertMessage) {
      if (!mounted) return;
      setState(() => _sadOverride = true);
      _sadTimer?.cancel();
      _sadTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _sadOverride = false);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            88,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          content: Text(
            "[ SYSTEM OVERRIDE ]\n$alertMessage",
            style:
                const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 10),
        ),
      );

      final langCode = ref.read(languageProvider).languageCode;
      unawaited(
        _voiceService.speak(
          alertMessage,
          languageCode: langCode,
        ),
      );
    });

    _connectAndLoadHistory();
  }

  Future<void> _connectAndLoadHistory() async {
    try {
      await _chatService.connect();
    } catch (e) {
      debugPrint('[ChatScreen] Socket connect failed: $e');
    }
    if (!mounted) return;
    _chatService.fetchHistory();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _startTalkingTimer() {
    _talkingTimer?.cancel();
    _talkingTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _phase == ShizukiChatPhase.talking) {
        setState(() => _phase = ShizukiChatPhase.idle);
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final langCode = ref.read(languageProvider).languageCode;
    _chatService.sendMessage(text, lang: langCode);
    _controller.clear();
    unawaited(_voiceService.stop());
  }

  void _showBubble(
    String text, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _dialogueTimer?.cancel();
    setState(() => _bubbleText = text);
    _dialogueTimer = Timer(duration, () {
      if (mounted) {
        setState(() => _bubbleText = null);
      }
    });
  }

  Duration _estimateDialogueDuration(String text) {
    final wordCount =
        text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final ms = (1400 + (wordCount * 220)).clamp(1800, 4600);
    return Duration(milliseconds: ms);
  }

  Future<void> _speakDialogue(String text) async {
    if (_phase == ShizukiChatPhase.talking) {
      return;
    }
    await _voiceService.stop();
    if (!mounted) return;
    final langCode = ref.read(languageProvider).languageCode;
    await _voiceService.speak(text, languageCode: langCode);
  }

  void _setTouchTalkingFor(Duration duration) {
    _touchTalkTimer?.cancel();
    if (!_isTouchTalking) {
      setState(() => _isTouchTalking = true);
    }
    _touchTalkTimer = Timer(duration, () {
      if (mounted) {
        setState(() => _isTouchTalking = false);
      }
    });
  }

  void _playDialogue(
    String text, {
    Duration? duration,
  }) {
    final playbackDuration = duration ?? _estimateDialogueDuration(text);
    _showBubble(text, duration: playbackDuration);
    _setTouchTalkingFor(playbackDuration);
    unawaited(_speakDialogue(text));
  }

  void _handleTouch(ShizukiTouchEvent event) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    _playDialogue(_dialogues.pickTouchLine(loc, event.region));
  }

  void _updateAnimatorZoom(double zoom) {
    final nextZoom = zoom.clamp(_minZoom, _maxZoom).toDouble();
    if ((_animatorZoom - nextZoom).abs() < 0.01) return;
    setState(() => _animatorZoom = nextZoom);
  }

  void _zoomIn() => _updateAnimatorZoom(_animatorZoom + _zoomStep);

  void _zoomOut() => _updateAnimatorZoom(_animatorZoom - _zoomStep);

  void _resetAnimatorZoom() {
    setState(() {
      _animatorZoom = _defaultZoom;
      _viewportResetToken++;
    });
  }

  void _updateMascotPane(double deltaY, double availableHeight) {
    if (availableHeight <= 0) return;
    final deltaFraction = deltaY / availableHeight;
    setState(() {
      _mascotPaneFraction = (_mascotPaneFraction + deltaFraction).clamp(
        _minPaneFraction,
        _maxPaneFraction,
      );
    });
  }

  void _clearHistory() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDeep,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.redAccent, width: 2),
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        title: Text(
          loc.clearMemoryTitle,
          style:
              const TextStyle(fontFamily: 'Orbitron', color: Colors.redAccent),
        ),
        content: Text(loc.clearMemoryBody, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              loc.actionCancel,
              style: AppTextStyles.buttonLabel
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _chatService.clearChatHistory();
              setState(_messages.clear);
            },
            child: Text(loc.actionDelete, style: AppTextStyles.buttonLabel),
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
            content: Text(
              'Microphone permission required for voice input.',
              style: TextStyle(color: Colors.redAccent),
            ),
            backgroundColor: AppColors.bgCard,
          ),
        );
      }
      return;
    }

    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isListening = true);
    }
    _controller.clear();
    await _voiceService.startListening(
      (recognizedText) {
        if (mounted) {
          setState(() => _controller.text = recognizedText);
        }
      },
      languageCode: ref.read(languageProvider).languageCode,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _talkingTimer?.cancel();
    _sadTimer?.cancel();
    _dialogueTimer?.cancel();
    _touchTalkTimer?.cancel();
    _historySub?.cancel();
    _messageSub?.cancel();
    _typingSub?.cancel();
    _systemAlertSub?.cancel();
    unawaited(_voiceService.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: MechaAppBar(
        title: loc.chatMode,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: _clearHistory,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, viewport) {
          final mascotHeight = (viewport.maxHeight * _mascotPaneFraction)
              .clamp(180.0, viewport.maxHeight * _maxPaneFraction)
              .toDouble();

          return Stack(
            children: [
              const GridBackground(),
              Column(
                children: [
                  SizedBox(
                    height: mascotHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        0,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ShizukiAnimator(
                                  emotion: _mascotEmotion,
                                  talking: _isMascotTalking,
                                  size: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  baseScale: 1.22,
                                  cameraPreset: ShizukiCameraPreset.bust,
                                  lookMode: _isMascotTalking
                                      ? ShizukiLookMode.forward
                                      : ShizukiLookMode.idle,
                                  zoom: _animatorZoom,
                                  minZoom: _minZoom,
                                  maxZoom: _maxZoom,
                                  resetViewportToken: _viewportResetToken,
                                  enableTouch: true,
                                  onTouch: _handleTouch,
                                  onZoomChanged: _updateAnimatorZoom,
                                ),
                              ),
                              Positioned(
                                top: AppSpacing.sm,
                                right: 0,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _bubbleText == null
                                      ? const SizedBox.shrink()
                                      : ShizukiDialogueBubble(
                                          key: ValueKey<String>(_bubbleText!),
                                          text: _bubbleText!,
                                          maxWidth: constraints.maxWidth * 0.56,
                                        ),
                                ),
                              ),
                              Positioned(
                                top: AppSpacing.sm,
                                left: 0,
                                child: ShizukiZoomControls(
                                  zoom: _animatorZoom,
                                  onZoomOut: _zoomOut,
                                  onReset: _resetAnimatorZoom,
                                  onZoomIn: _zoomIn,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (details) => _updateMascotPane(
                      details.delta.dy,
                      viewport.maxHeight,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 64,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      loc.todayLabel,
                      style: AppTextStyles.sectionLabel,
                    ),
                  ),
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child:
                                Text(loc.noChatYet, style: AppTextStyles.hint),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) =>
                                _MessageBubble(message: _messages[i]),
                          ),
                  ),
                  _InputBar(
                    controller: _controller,
                    onSend: _sendMessage,
                    isListening: _isListening,
                    onToggleListen: _toggleListening,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

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
    var timeStr = '';
    if (msgTime != null) {
      final local = msgTime.toLocal();
      timeStr =
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: const Icon(
                Icons.local_florist,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.lg),
                      topRight: const Radius.circular(AppSpacing.lg),
                      bottomLeft: Radius.circular(
                        isUser ? AppSpacing.lg : AppSpacing.xs,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? AppSpacing.xs : AppSpacing.lg,
                      ),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                    boxShadow: isUser
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: AppTextStyles.bodyMedium.copyWith(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      strong: AppTextStyles.bodyMedium.copyWith(
                        color: isUser ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      em: AppTextStyles.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      code: const TextStyle(
                        color: AppColors.primary,
                        backgroundColor: Colors.black54,
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.black87,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.wb_sunny_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.isListening,
    required this.onToggleListen,
  });

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
        children: [
          GestureDetector(
            onTap: onToggleListen,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isListening
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : AppColors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isListening
                      ? Colors.redAccent
                      : AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: isListening ? Colors.redAccent : AppColors.primary,
                size: 20,
              ),
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
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
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
                  colors: [AppColors.primary, AppColors.accent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
