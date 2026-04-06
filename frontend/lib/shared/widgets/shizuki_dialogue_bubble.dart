import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/core/constants/app_spacing.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class ShizukiDialogueBubble extends StatelessWidget {
  const ShizukiDialogueBubble({
    required this.text,
    super.key,
    this.maxWidth = 240,
  });

  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
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
          color: AppColors.primary.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 16,
          ),
        ],
      ),
      child: Text(text, style: AppTextStyles.bodyMedium),
    );
  }
}
