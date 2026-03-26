import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/mecha_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                      onPressed: () => context.go('/'),
                      child: Text(
                        AppStrings.back,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Avatar ────────────────────────────────────────────
                  RepaintBoundary(
                    child: SizedBox(
                      key: const ValueKey('avatar-slot'),
                      width: 120,
                      height: 140,
                      child: Image.asset(
                        'assets/avatar/mora_avatar.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.face,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Title ─────────────────────────────────────────────
                  Text(AppStrings.welcomeBack, style: AppTextStyles.displayMedium),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(AppStrings.loginSubtitle, style: AppTextStyles.hint),

                  const SizedBox(height: AppSpacing.lg),

                  // ── LOG IN / SIGN UP tabs ─────────────────────────────
                  _AuthTabs(activeTab: 0, onSignUpTap: () => context.go('/signup')),

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

                  const SizedBox(height: AppSpacing.sm),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(AppStrings.forgotPassword, style: AppTextStyles.caption),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── LOG IN button ─────────────────────────────────────
                  MechaButton(
                    label: AppStrings.logIn,
                    onTap: () => context.go('/home'),
                  ),

                  const SizedBox(height: AppSpacing.md),
                  const Text(AppStrings.orDivider, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.md),

                  // ── CREATE ACCOUNT button ─────────────────────────────
                  MechaButton(
                    label: AppStrings.createAccount,
                    variant: MechaButtonVariant.outlined,
                    onTap: () => context.go('/signup'),
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

// ── Internal tab row widget ────────────────────────────────────────────────────
class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.activeTab, required this.onSignUpTap});

  final int activeTab; // 0 = LOG IN, 1 = SIGN UP
  final VoidCallback onSignUpTap;

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
          _tab(AppStrings.logIn, isActive: activeTab == 0, onTap: () {}),
          _tab(AppStrings.signUp, isActive: activeTab == 1, onTap: onSignUpTap),
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
              color: isActive
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}