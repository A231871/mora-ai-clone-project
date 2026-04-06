import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/google_sign_in_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/grid_background.dart';
import '../../../shared/widgets/mecha_button.dart';
import '../../../shared/widgets/mecha_text_field.dart';
import '../../../shared/widgets/shizuki_animator.dart';
import '../models/google_sign_in_result.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  ShizukiEmotion _currentEmotion = ShizukiEmotion.smile;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.fillBothFields,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _currentEmotion = ShizukiEmotion.smile;
    });

    final result = await _authService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _currentEmotion =
          result['success'] ? ShizukiEmotion.smile : ShizukiEmotion.sad;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.welcomeShizukiLogin,
            style: const TextStyle(color: Colors.greenAccent),
          ),
        ),
      );
      context.go('/home');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message'] ?? 'Login failed',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _currentEmotion = ShizukiEmotion.smile;
    });

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      setState(() => _currentEmotion = ShizukiEmotion.smile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.welcomeShizukiLogin,
            style: const TextStyle(color: Colors.greenAccent),
          ),
        ),
      );
      context.go('/home');
      return;
    }

    final failure = result.failure;
    if (failure == null) {
      setState(() => _currentEmotion = ShizukiEmotion.sad);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.googleSignInFailed,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
      return;
    }

    if (failure.code == GoogleSignInFailureCode.cancelled) {
      setState(() => _currentEmotion = ShizukiEmotion.smile);
      return;
    }

    setState(() => _currentEmotion = ShizukiEmotion.sad);

    if (failure.isConfigurationIssue) {
      await _showGoogleSignInDiagnostics(failure);
      return;
    }

    final msg = switch (failure.code) {
      GoogleSignInFailureCode.networkError => loc.googleSignInNetworkIssue,
      GoogleSignInFailureCode.backendRejected => result.message,
      _ => loc.googleSignInFailed,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }

  Future<void> _showGoogleSignInDiagnostics(GoogleSignInFailure failure) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _GoogleSignInDiagnosticDialog(failure: failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final mediaSize = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.paddingOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final heroHeight = (mediaSize.height * 0.72).clamp(420.0, 760.0).toDouble();
    final auraWidth = (mediaSize.width * 1.22).clamp(360.0, 720.0).toDouble();
    final panelHeight =
        (mediaSize.height * 0.58).clamp(360.0, 560.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const GridBackground(),
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: viewPadding.top - AppSpacing.sm,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: heroHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: auraWidth,
                            height: heroHeight * 0.78,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(heroHeight),
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.32),
                                  AppColors.accent.withValues(alpha: 0.14),
                                  AppColors.primary.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.48, 1.0],
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            key: const ValueKey('avatar-slot'),
                            child: ShizukiAnimator(
                              emotion: _currentEmotion,
                              talking: _isLoading,
                              size: mediaSize.width,
                              height: heroHeight,
                              baseScale: 1.18,
                              cameraPreset: ShizukiCameraPreset.fullBody,
                              zoom: 0.98,
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.42, 0.68, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            AppColors.bgDeep.withValues(alpha: 0.52),
                            AppColors.bgDeep,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: _isLoading ? null : () => context.go('/'),
                  child: Text(
                    loc.back,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SizedBox(
                  height: panelHeight,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep.withValues(alpha: 0.92),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.24),
                          blurRadius: 32,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg + viewPadding.bottom,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.55),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            loc.welcomeBack,
                            style: AppTextStyles.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            loc.loginSubtitle,
                            style: AppTextStyles.hint,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _AuthTabs(
                            activeTab: 0,
                            onSignUpTap: _isLoading
                                ? () {}
                                : () => context.go('/signup'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          MechaTextField(
                            label: loc.usernameLabel,
                            hint: loc.usernamePlaceholder,
                            controller: _usernameController,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MechaTextField(
                            label: loc.passwordLabel,
                            hint: loc.passwordPlaceholder,
                            isPassword: true,
                            controller: _passwordController,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _signInWithGoogle,
                              child: Text(
                                loc.forgotPassword,
                                style: AppTextStyles.caption.copyWith(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          MechaButton(
                            label: _isLoading ? loc.loggingIn : loc.logIn,
                            onTap: _isLoading ? () {} : _submit,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(loc.orDivider, style: AppTextStyles.caption),
                          const SizedBox(height: AppSpacing.md),
                          MechaButton(
                            label: loc.continueWithGoogle,
                            variant: MechaButtonVariant.outlined,
                            onTap: _isLoading ? () {} : _signInWithGoogle,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MechaButton(
                            label: loc.createAccount,
                            variant: MechaButtonVariant.outlined,
                            onTap: _isLoading
                                ? () {}
                                : () => context.go('/signup'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSignInDiagnosticDialog extends StatelessWidget {
  const _GoogleSignInDiagnosticDialog({required this.failure});

  final GoogleSignInFailure failure;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final diagnostics = failure.diagnostics;
    final packageName =
        diagnostics['androidPackage'] ?? GoogleSignInConfig.androidPackageName;
    final clientId = diagnostics['serverClientId'] ??
        GoogleSignInConfig.serverClientIdDisplay;
    final platformCode = diagnostics['platformCode'];
    final apiStatus = diagnostics['apiStatus'];
    final rawMessage =
        diagnostics['rawMessage'] ?? failure.rawMessage ?? failure.message;

    final summary = switch (failure.code) {
      GoogleSignInFailureCode.androidDeveloperError =>
        loc.googleSignInDeveloperError,
      GoogleSignInFailureCode.noIdToken => loc.googleSignInMissingIdToken,
      GoogleSignInFailureCode.missingClientConfiguration =>
        loc.googleNotConfigured,
      _ => loc.googleSignInFailed,
    };

    return AlertDialog(
      backgroundColor: AppColors.bgDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      title: Text(
        loc.googleSignInConfigTitle,
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(summary, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Text(
              loc.googleSignInChecklist(packageName, clientId),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              loc.googleSignInDiagnosticsHeading,
              style:
                  AppTextStyles.buttonLabel.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            _DiagnosticLine(
              text: loc.googleSignInDiagnosticPackage(packageName),
            ),
            _DiagnosticLine(
              text: loc.googleSignInDiagnosticClientId(clientId),
            ),
            if (platformCode != null)
              _DiagnosticLine(
                text: loc.googleSignInDiagnosticCode(platformCode),
              ),
            if (apiStatus != null)
              _DiagnosticLine(
                text: loc.googleSignInDiagnosticStatus(apiStatus),
              ),
            _DiagnosticLine(text: loc.googleSignInDiagnosticRaw(rawMessage)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            loc.actionCancel,
            style: AppTextStyles.buttonLabel.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _DiagnosticLine extends StatelessWidget {
  const _DiagnosticLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: SelectableText(text, style: AppTextStyles.caption),
    );
  }
}

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
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _tab(
            AppLocalizations.of(context)!.logIn,
            isActive: activeTab == 0,
            onTap: () {},
          ),
          _tab(
            AppLocalizations.of(context)!.signUp,
            isActive: activeTab == 1,
            onTap: onSignUpTap,
          ),
        ],
      ),
    );
  }

  Widget _tab(
    String label, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
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
