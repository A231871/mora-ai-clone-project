import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/status_chip.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const GridBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // ── SYSTEM ONLINE chip ────────────────────────────────
                  const StatusChip(
                    label: AppStrings.systemOnline,
                    color: AppColors.statusGreen,
                    textColor: AppColors.statusGreen,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── MORA title ────────────────────────────────────────
                  Text(
                    AppStrings.moraTitle,
                    style: AppTextStyles.displayLarge.copyWith(
                      shadows: [
                        Shadow(
                          color: AppColors.primary.withOpacity(0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // ── VIRTUAL ASSISTANT ─────────────────────────────────
                  const Text(AppStrings.subtitle, style: AppTextStyles.subtitle),

                  const Spacer(),

                  // ── Avatar ────────────────────────────────────────────
                  RepaintBoundary(
                    child: Container(
                      key: const ValueKey('avatar-slot'),
                      width: 220,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/avatar/mora_avatar.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.face,
                          size: 140,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Version ───────────────────────────────────────────
                  Text(AppStrings.appVersion, style: AppTextStyles.caption),

                  const SizedBox(height: AppSpacing.lg),

                  // ── TAP TO START button ───────────────────────────────
                  MechaButton(
                    label: AppStrings.tapToStart,
                    onTap: () => context.go('/login'),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Caption ───────────────────────────────────────────
                  const Text(AppStrings.startCaption, style: AppTextStyles.caption),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
