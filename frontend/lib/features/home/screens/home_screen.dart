import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/session_storage.dart';
import '../../../shared/models/shizuki_dialogue_catalog.dart';
import '../../../shared/widgets/glassmorphism_button.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/shizuki_animator.dart';
import '../../../shared/widgets/shizuki_dialogue_bubble.dart';
import '../../../shared/widgets/shizuki_zoom_controls.dart';
import '../../../shared/widgets/status_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _defaultZoom = 1.0;
  static const double _minZoom = 0.8;
  static const double _maxZoom = 1.75;
  static const double _zoomStep = 0.12;

  String _username = 'SYNCING...';
  String _systemRole = 'MEMBER';
  String _currentTime = '--:--';
  Timer? _clockTimer;
  Timer? _dialogueTimer;
  Timer? _touchTalkTimer;
  String? _bubbleText;
  double _animatorZoom = _defaultZoom;
  int _viewportResetToken = 0;
  bool _isTouchTalking = false;
  final ShizukiDialogueCatalog _dialogues = ShizukiDialogueCatalog();
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    unawaited(_voiceService.init());
    _loadSessionInfo();
    _updateClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showGreetingBubble();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _dialogueTimer?.cancel();
    _touchTalkTimer?.cancel();
    unawaited(_voiceService.stop());
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (_currentTime != timeStr && mounted) {
      setState(() => _currentTime = timeStr);
    }
  }

  Future<void> _loadSessionInfo() async {
    try {
      final user = await SessionStorage.getCurrentUser();
      if (!mounted) {
        return;
      }
      if (user != null) {
        setState(() {
          _username = user.resolvedDisplayName.toUpperCase();
          _systemRole = user.systemRole.toUpperCase();
        });
      } else {
        setState(() {
          _username = 'GUEST';
          _systemRole = 'OFFLINE';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _username = 'COMMANDER';
          _systemRole = 'UNKNOWN';
        });
      }
    }
  }

  void _showGreetingBubble() {
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    _playDialogue(
      _dialogues.pickGreeting(loc),
      duration: const Duration(seconds: 4),
    );
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

  void _handleTouch(ShizukiTouchEvent event) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return;
    _playDialogue(_dialogues.pickTouchLine(loc, event.region));
  }

  Duration _estimateDialogueDuration(String text) {
    final wordCount =
        text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final ms = (1400 + (wordCount * 220)).clamp(1800, 4800);
    return Duration(milliseconds: ms);
  }

  Future<void> _speakDialogue(String text) async {
    await _voiceService.stop();
    if (!mounted) return;
    final langCode = Localizations.localeOf(context).languageCode;
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final showZoomControls = (_animatorZoom - _defaultZoom).abs() >= 0.01;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const GridBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.goodMorning, style: AppTextStyles.caption),
                            Text(
                              'COMMANDER $_username',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(
                        Icons.signal_cellular_alt,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.wifi,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(_currentTime, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      StatusChip(
                        label: _username != 'SYNCING...'
                            ? loc.shizukiOnline
                            : 'CONNECTING...',
                        color: _username != 'SYNCING...'
                            ? AppColors.statusGreen
                            : AppColors.accent,
                        textColor: _username != 'SYNCING...'
                            ? AppColors.statusGreen
                            : AppColors.accent,
                      ),
                      StatusChip(
                        label: _systemRole,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: ShizukiAnimator(
                                emotion: ShizukiEmotion.idle,
                                talking: _isTouchTalking,
                                size: constraints.maxWidth,
                                height: constraints.maxHeight,
                                baseScale: 1.28,
                                cameraPreset: ShizukiCameraPreset.fullBody,
                                lookMode: _isTouchTalking
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
                              top: 0,
                              right: 0,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: _bubbleText == null
                                    ? const SizedBox.shrink()
                                    : ShizukiDialogueBubble(
                                        key: ValueKey<String>(_bubbleText!),
                                        text: _bubbleText!,
                                        maxWidth: constraints.maxWidth * 0.58,
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                opacity: showZoomControls ? 1 : 0.9,
                                child: ShizukiZoomControls(
                                  zoom: _animatorZoom,
                                  onZoomOut: _zoomOut,
                                  onReset: _resetAnimatorZoom,
                                  onZoomIn: _zoomIn,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: AppSpacing.lg,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.bgDeep.withValues(alpha: 0),
                                      AppColors.bgDeep.withValues(alpha: 0.72),
                                      AppColors.bgDeep.withValues(alpha: 0.94),
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.xxl,
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'MISSION LAUNCHER',
                                        style: AppTextStyles.sectionLabel,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Workspace modules route from home while chat and reminders stay live.',
                                        style: AppTextStyles.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                        ),
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: AppSpacing.lg,
                                          runSpacing: AppSpacing.md,
                                          children: [
                                            GlassmorphismButton(
                                              icon: Icons.chat_bubble_outline,
                                              label: loc.chat,
                                              onTap: () =>
                                                  context.push('/chat'),
                                            ),
                                            GlassmorphismButton(
                                              icon:
                                                  Icons.notifications_outlined,
                                              label: loc.remind,
                                              onTap: () => context.push(
                                                '/reminders',
                                              ),
                                            ),
                                            GlassmorphismButton(
                                              icon: Icons.dashboard_outlined,
                                              label: 'Projects',
                                              onTap: () => context.push(
                                                '/projects',
                                              ),
                                            ),
                                            GlassmorphismButton(
                                              icon: Icons.folder_copy_outlined,
                                              label: 'Files',
                                              onTap: () => context.push(
                                                '/files',
                                              ),
                                            ),
                                            GlassmorphismButton(
                                              icon: Icons.person_outline,
                                              label: 'Profile',
                                              onTap: () => context.push(
                                                '/profile',
                                              ),
                                            ),
                                            GlassmorphismButton(
                                              icon: Icons.settings_outlined,
                                              label: loc.config,
                                              onTap: () => context.push(
                                                '/config',
                                              ),
                                            ),
                                            if (_systemRole == 'ADMIN')
                                              GlassmorphismButton(
                                                icon: Icons
                                                    .admin_panel_settings_outlined,
                                                label: 'Admin',
                                                onTap: () => context.push(
                                                  '/admin',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
