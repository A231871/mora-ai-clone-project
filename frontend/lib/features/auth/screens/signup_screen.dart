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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields', style: TextStyle(color: Colors.redAccent))),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match', style: TextStyle(color: Colors.redAccent))),
      );
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W]).{8,}$');
    if (!passwordRegex.hasMatch(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must contain upper/lower, number, and special char (min 8 chars)', style: TextStyle(color: Colors.redAccent)),
          backgroundColor: AppColors.bgCard,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.register(
      _usernameController.text.trim(), 
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please log in.', style: TextStyle(color: Colors.greenAccent))),
      );
      context.go('/'); // Explicit route instead of context.pop() due to go_router stack
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed', style: TextStyle(color: Colors.redAccent))),
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
                      onPressed: () => context.go('/'),
                      child: Text(
                        AppLocalizations.of(context)!.back,
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
                  Text(AppLocalizations.of(context)!.joinMora,
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primary,
                      )),
                  const SizedBox(height: AppSpacing.xs),
                  Text(AppLocalizations.of(context)!.signupSubtitle, style: AppTextStyles.hint),

                  const SizedBox(height: AppSpacing.lg),

                  // ── SIGN UP / LOG IN tabs ─────────────────────────────
                  _SignupTabs(onLogInTap: _isLoading ? () {} : () => context.go('/')),

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
                  const SizedBox(height: AppSpacing.md),
                  MechaTextField(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    isPassword: true,
                    controller: _confirmPasswordController,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── CREATE ACCOUNT button ─────────────────────────────
                  MechaButton(
                    label: _isLoading ? 'Creating...' : AppLocalizations.of(context)!.createAccount,
                    onTap: _isLoading ? () {} : _submit,
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Text(AppLocalizations.of(context)!.orDivider, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.md),

                  MechaButton(
                    label: AppLocalizations.of(context)!.backToLogin,
                    variant: MechaButtonVariant.outlined,
                    onTap: _isLoading ? () {} : () => context.go('/'),
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
