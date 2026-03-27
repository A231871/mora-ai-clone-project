import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Small pill chip — used for status indicators and reminder category badges.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.textColor = AppColors.textPrimary,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
