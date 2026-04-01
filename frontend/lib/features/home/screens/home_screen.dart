import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/glassmorphism_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/shizuki_animator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'SYNCING...';
  String _currentTime = '--:--';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (_currentTime != timeStr && mounted) {
      setState(() {
        _currentTime = timeStr;
      });
    }
  }

  Future<void> _loadSessionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null) {
        final parts = token.split('.');
        if (parts.length >= 2) {
          final normalized = base64Url.normalize(parts[1]);
          final payloadStr = utf8.decode(base64Url.decode(normalized));
          final data = jsonDecode(payloadStr);
          if (mounted) {
            setState(() {
              _username = data['username']?.toString().toUpperCase() ?? 'COMMANDER';
            });
          }
        }
      } else {
        if (mounted) setState(() => _username = 'GUEST');
      }
    } catch (e) {
      if (mounted) setState(() => _username = 'COMMANDER');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const GridBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.goodMorning,
                              style: AppTextStyles.caption),
                          Text('COMMANDER $_username',
                              style: AppTextStyles.titleMedium),
                        ],
                      ),
                      const Spacer(),
                      // Static status icons
                      const Icon(Icons.signal_cellular_alt,
                          color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.wifi,
                          color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(_currentTime, style: AppTextStyles.caption),
                    ],
                  ),
                ),

                // ── Status chips row ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      StatusChip(
                        label: _username != 'SYNCING...' ? AppLocalizations.of(context)!.shizukiOnline : 'CONNECTING...',
                        color: _username != 'SYNCING...' ? AppColors.statusGreen : AppColors.accent,
                        textColor: _username != 'SYNCING...' ? AppColors.statusGreen : AppColors.accent,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Speech bubble ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 200),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppSpacing.lg),
                          topRight: Radius.circular(AppSpacing.lg),
                          bottomLeft: Radius.circular(AppSpacing.lg),
                          bottomRight: Radius.circular(AppSpacing.xs),
                        ),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.shizukiGreeting,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                ),

                // ── Avatar (Shizuki) ─────────────────────────────────────
                Expanded(
                  child: Center(
                    child: RepaintBoundary(
                      key: ValueKey('avatar-slot'),
                      child: ShizukiAnimator(
                        emotion: ShizukiEmotion.idle,
                        size: 380, // Substantially increased scale so she fills the screen properly
                      ),
                    ),
                  ),
                ),

                // ── QUICK ACCESS section ────────────────────────────────
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.quickAccess,
                    style: AppTextStyles.sectionLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GlassmorphismButton(
                        icon: Icons.chat_bubble_outline,
                        label: AppLocalizations.of(context)!.chat,
                        onTap: () => context.push('/chat'),
                      ),
                      GlassmorphismButton(
                        icon: Icons.notifications_outlined,
                        label: AppLocalizations.of(context)!.remind,
                        onTap: () => context.push('/reminders'),
                      ),
                      GlassmorphismButton(
                        icon: Icons.settings_outlined,
                        label: AppLocalizations.of(context)!.config,
                        onTap: () => context.push('/config'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
