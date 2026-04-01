import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import '../services/auth_service.dart';

// ── Login screen with full backend AuthService + Shizuki avatar UI ─────────────
// Merged: feature/UI (design + ShizukiAnimator) + develop (AuthService backend)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  ShizukiEmotion _currentEmotion = ShizukiEmotion.smile;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final AuthService _authService = AuthService();

  Future<void> _submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields', style: TextStyle(color: Colors.redAccent))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _currentEmotion = ShizukiEmotion.talk; // Shizuki "talks" while logging in
    });

    final result = await _authService.login(
      _usernameController.text.trim(), 
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _currentEmotion = result['success'] ? ShizukiEmotion.smile : ShizukiEmotion.sad;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to Mora A.I Interface!', style: TextStyle(color: Colors.greenAccent))),
      );
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login failed', style: TextStyle(color: Colors.redAccent))),
      );
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // ── BACK button ───────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _isLoading ? null : () => context.go('/'),
                      child: Text(
                        AppLocalizations.of(context)!.back,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Shizuki Avatar — emotion reacts to login state ────
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
                                AppColors.primary.withOpacity(0.35),
                                AppColors.primary.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                        ShizukiAnimator(
                          emotion: _currentEmotion,
                          size: 150,
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Title ─────────────────────────────────────────────
                  Text(AppLocalizations.of(context)!.welcomeBack, style: AppTextStyles.displayMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(AppLocalizations.of(context)!.loginSubtitle, style: AppTextStyles.hint),

                  const SizedBox(height: AppSpacing.lg),

                  // ── LOG IN / SIGN UP tabs ─────────────────────────────
                  _AuthTabs(
                    activeTab: 0,
                    onSignUpTap: _isLoading ? () {} : () => context.go('/signup'),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Form ──────────────────────────────────────────────
                  MechaTextField(
                    label: AppLocalizations.of(context)!.usernameLabel,
                    hint: AppLocalizations.of(context)!.usernamePlaceholder,
                    controller: _usernameController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MechaTextField(
                    label: AppLocalizations.of(context)!.passwordLabel,
                    hint: AppLocalizations.of(context)!.passwordPlaceholder,
                    isPassword: true,
                    controller: _passwordController,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please login via Google', style: TextStyle(color: Colors.cyanAccent)),
                              backgroundColor: AppColors.bgCard,
                          ),
                        );
                      },
                      child: Text(AppLocalizations.of(context)!.forgotPassword, style: AppTextStyles.caption.copyWith(decoration: TextDecoration.underline)),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── LOG IN button ─────────────────────────────────────
                  MechaButton(
                    label: _isLoading ? 'Logging in...' : AppLocalizations.of(context)!.logIn,
                    onTap: _isLoading ? () {} : _submit,
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Text(AppLocalizations.of(context)!.orDivider, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.md),

                  // ── CREATE ACCOUNT button ─────────────────────────────
                  MechaButton(
                    label: AppLocalizations.of(context)!.createAccount,
                    variant: MechaButtonVariant.outlined,
                    onTap: _isLoading ? () {} : () => context.go('/signup'),
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

  final int activeTab;
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
          _tab(AppLocalizations.of(context)!.logIn, isActive: activeTab == 0, onTap: () {}),
          _tab(AppLocalizations.of(context)!.signUp, isActive: activeTab == 1, onTap: onSignUpTap),
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