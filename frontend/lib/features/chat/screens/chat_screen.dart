import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_app_bar.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Message> _messages = const [
    Message(
      text: "Hiii~ Good morning! ✨ I'm Shizuki, your virtual assistant! How are you feeling today?",
      isUser: false,
      timestamp: '09:00',
    ),
    Message(
      text: "I'm doing great! Can you remind me about my 3pm meeting?",
      isUser: true,
      timestamp: '09:01',
    ),
    Message(
      text: "Of course! ✦ I've set a reminder for your 3:00 PM meeting. I'll ping you 15 minutes before! Is there anything else you need? (◕‿◕✿)",
      isUser: false,
      timestamp: '09:01',
    ),
    Message(
      text: "What's the weather like today?",
      isUser: true,
      timestamp: '09:02',
    ),
    Message(
      text: "It's a beautiful sunny day, 24°C! ☀ Perfect for a walk outside~. Don't forget your sunscreen, okay? uwu",
      isUser: false,
      timestamp: '09:02',
    ),
  ];

  List<Message> _dynamicMessages = [];

  @override
  void initState() {
    super.initState();
    _dynamicMessages = List.from(_messages);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _dynamicMessages.add(Message(
        text: text,
        isUser: true,
        timestamp: TimeOfDay.now().format(context),
      ));
    });
    _controller.clear();
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: MechaAppBar(
        title: AppStrings.chatMode,
        trailing: const Icon(Icons.local_florist_outlined,
            color: AppColors.primary, size: 20),
      ),
      body: Stack(
        children: [
          const GridBackground(),
          Column(
            children: [
              // ── TODAY label ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: const Text(AppStrings.todayLabel,
                    style: AppTextStyles.sectionLabel),
              ),

              // ── Messages list ─────────────────────────────────────────
              Expanded(
                child: _dynamicMessages.isEmpty
                    ? const Center(
                        child: Text(AppStrings.noChatYet,
                            style: AppTextStyles.hint),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: _dynamicMessages.length,
                        itemBuilder: (_, i) =>
                            _MessageBubble(message: _dynamicMessages[i]),
                      ),
              ),

              // ── Input bar ─────────────────────────────────────────────
              _InputBar(
                controller: _controller,
                onSend: _sendMessage,
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
  final Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
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
                color: AppColors.primary.withOpacity(0.2),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.white.withOpacity(0.1)
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
                            color: AppColors.primary.withOpacity(0.35),
                            width: 1,
                          ),
                    boxShadow: isUser
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: Text(message.text, style: AppTextStyles.bodyMedium),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isUser ? AppStrings.youSender : AppStrings.shizukiSender} · ${message.timestamp}',
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
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.4)),
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
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: AppStrings.chatHint,
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
                  colors: [AppColors.primary, AppColors.accent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
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
