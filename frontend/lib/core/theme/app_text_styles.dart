import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display (Orbitron) ────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 42,
    letterSpacing: 4,
    color: AppColors.primary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: 3,
    color: AppColors.primary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 18,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );

  // ── Body (Rajdhani) ───────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 1,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 1,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 1,
    color: AppColors.textSecondary,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w400,
    fontSize: 13,
    letterSpacing: 5,
    color: AppColors.textPrimary,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w400,
    fontSize: 11,
    letterSpacing: 1,
    color: AppColors.textSecondary,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: AppSpacing.sm,
    color: AppColors.textSecondary,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );
}
