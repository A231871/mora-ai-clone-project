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
import '../../chat/chat_screen.dart';

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

  Future<void> _submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Mora A.I Interface!', style: TextStyle(color: Colors.greenAccent))),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
    } 
    }else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'], style: const TextStyle(color: Colors.redAccent))),
        );
      }
    }

    setState(() {
      _isLoading = true;
      _currentEmotion = ShizukiEmotion.talk; // Shizuki "talks" while logging in
    });

    // TODO: Replace with real AuthService call when backend is connected
    // e.g. final result = await _authService.login(username, password);
    // Simulating network delay for now
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // On success — navigate home
    setState(() {
      _isLoading = false;
      _currentEmotion = ShizukiEmotion.smile;
    });
    context.go('/home');
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
                        AppStrings.back,
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
                  Text(AppStrings.welcomeBack, style: AppTextStyles.displayMedium),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(AppStrings.loginSubtitle, style: AppTextStyles.hint),

                  const SizedBox(height: AppSpacing.lg),

                  // ── LOG IN / SIGN UP tabs ─────────────────────────────
                  _AuthTabs(
                    activeTab: 0,
                    onSignUpTap: _isLoading ? () {} : () => context.go('/signup'),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Form ──────────────────────────────────────────────
                  MechaTextField(
                    label: AppStrings.usernameLabel,
                    hint: AppStrings.usernamePlaceholder,
                    controller: _usernameController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MechaTextField(
                    label: AppStrings.passwordLabel,
                    hint: AppStrings.passwordPlaceholder,
                    isPassword: true,
                    controller: _passwordController,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(AppStrings.forgotPassword, style: AppTextStyles.caption),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── LOG IN button ─────────────────────────────────────
                  MechaButton(
                    label: _isLoading ? 'Logging in...' : AppStrings.logIn,
                    onTap: _isLoading ? () {} : _submit,
                  ),

                  const SizedBox(height: AppSpacing.md),
                  const Text(AppStrings.orDivider, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.md),

                  // ── CREATE ACCOUNT button ─────────────────────────────
                  MechaButton(
                    label: AppStrings.createAccount,
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
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}