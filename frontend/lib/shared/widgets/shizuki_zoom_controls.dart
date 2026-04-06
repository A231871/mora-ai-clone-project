import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ShizukiZoomControls extends StatelessWidget {
  const ShizukiZoomControls({
    super.key,
    required this.zoom,
    required this.onZoomOut,
    required this.onReset,
    required this.onZoomIn,
  });

  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZoomButton(
              icon: Icons.remove_rounded,
              onPressed: onZoomOut,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: SizedBox(
                width: 48,
                child: Text(
                  '${zoom.toStringAsFixed(2)}x',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _ZoomButton(
              icon: Icons.restart_alt_rounded,
              onPressed: onReset,
            ),
            const SizedBox(width: AppSpacing.xs),
            _ZoomButton(
              icon: Icons.add_rounded,
              onPressed: onZoomIn,
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
          padding: EdgeInsets.zero,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
