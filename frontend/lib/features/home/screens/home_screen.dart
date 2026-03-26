import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/glassmorphism_button.dart';
import '../../../shared/widgets/status_chip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                          Text(AppStrings.goodMorning,
                              style: AppTextStyles.caption),
                          Text(AppStrings.commander,
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
                      Text('00:07', style: AppTextStyles.caption),
                    ],
                  ),
                ),

                // ── Status chips row ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: const Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      StatusChip(
                        label: AppStrings.moraOnline,
                        color: AppColors.statusGreen,
                        textColor: AppColors.statusGreen,
                      ),
                      StatusChip(
                        label: AppStrings.moodHappy,
                        color: AppColors.primary,
                      ),
                      StatusChip(
                        label: AppStrings.battery,
                        color: AppColors.accent,
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
                      child: const Text(
                        AppStrings.moraGreeting,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                ),

                // ── Avatar ──────────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: RepaintBoundary(
                      child: Container(
                        key: const ValueKey('avatar-slot'),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 80,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/avatar/mora_avatar.png',
                          width: 240,
                          height: 300,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.face,
                            size: 180,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── QUICK ACCESS section ────────────────────────────────
                const Center(
                  child: Text(
                    AppStrings.quickAccess,
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
                        label: AppStrings.chat,
                        onTap: () => context.push('/chat'),
                      ),
                      GlassmorphismButton(
                        icon: Icons.notifications_outlined,
                        label: AppStrings.remind,
                        onTap: () => context.push('/reminders'),
                      ),
                      GlassmorphismButton(
                        icon: Icons.settings_outlined,
                        label: AppStrings.config,
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
