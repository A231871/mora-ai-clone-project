import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/mecha_text_field.dart';
import '../../../shared/widgets/shizuki_animator.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const GridBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // ── BACK button ───────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        AppStrings.back,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Shizuki Avatar (cheer — excited to join!) ─────────
                  RepaintBoundary(
                    key: const ValueKey('avatar-slot'),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.accent.withOpacity(0.35),
                                AppColors.accent.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                        const ShizukiAnimator(
                          emotion: ShizukiEmotion.cheer,
                          size: 150,
                          transitionDuration: Duration(milliseconds: 400),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Title ─────────────────────────────────────────────
                  Text(AppStrings.joinMora,
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primary,
                      )),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(AppStrings.signupSubtitle, style: AppTextStyles.hint),

                  const SizedBox(height: AppSpacing.lg),

                  // ── SIGN UP / LOG IN tabs ─────────────────────────────
                  _SignupTabs(onLogInTap: () => context.pop()),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Form ──────────────────────────────────────────────
                  const MechaTextField(
                    label: AppStrings.usernameLabel,
                    hint: AppStrings.usernamePlaceholder,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const MechaTextField(
                    label: AppStrings.passwordLabel,
                    hint: AppStrings.passwordPlaceholder,
                    isPassword: true,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── CREATE ACCOUNT button ─────────────────────────────
                  MechaButton(
                    label: AppStrings.createAccount,
                    onTap: () => context.go('/home'),
                  ),

                  const SizedBox(height: AppSpacing.md),
                  const Text(AppStrings.orDivider, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.md),

                  // ── BACK TO LOGIN button ──────────────────────────────
                  MechaButton(
                    label: AppStrings.backToLogin,
                    variant: MechaButtonVariant.outlined,
                    onTap: () => context.pop(),
                  ),

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

class _SignupTabs extends StatelessWidget {
  const _SignupTabs({required this.onLogInTap});
  final VoidCallback onLogInTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _tab('LOG IN', isActive: false, onTap: onLogInTap),
          _tab('SIGN UP', isActive: true, onTap: () {}),
        ],
      ),
    );
  }

  Widget _tab(String label, {required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  )
                : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
