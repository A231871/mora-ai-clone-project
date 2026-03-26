import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum MechaButtonVariant { primary, outlined }

/// Pill-shaped mecha-style button with neon glow.
/// Use [MechaButtonVariant.primary] for main CTAs,
/// [MechaButtonVariant.outlined] for secondary actions.
class MechaButton extends StatelessWidget {
  const MechaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = MechaButtonVariant.primary,
    this.width = double.infinity,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final MechaButtonVariant variant;
  final double width;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == MechaButtonVariant.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isPrimary ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.xxl),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isPrimary ? 0.55 : 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.sm)],
            Text(label, style: AppTextStyles.buttonLabel),
          ],
        ),
      ),
    );
  }
}
