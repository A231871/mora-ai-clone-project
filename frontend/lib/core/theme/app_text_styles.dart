import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display (Orbitron) ────────────────────────────────────────────────────
  static TextStyle displayLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 42,
    letterSpacing: 4,
    color: AppColors.primary,
  );

  static TextStyle displayMedium = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: 3,
    color: AppColors.primary,
  );

  static TextStyle titleLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 18,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );

  static TextStyle titleMedium = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );

  // ── Body (Rajdhani) ───────────────────────────────────────────────────────
  static TextStyle bodyLarge = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 1,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 1,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 1,
    color: AppColors.textSecondary,
  );

  static TextStyle subtitle = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w400,
    fontSize: 13,
    letterSpacing: 5,
    color: AppColors.textPrimary,
  );

  static TextStyle hint = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static TextStyle caption = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w400,
    fontSize: 11,
    letterSpacing: 1,
    color: AppColors.textSecondary,
  );

  static TextStyle sectionLabel = TextStyle(
    fontFamily: 'Rajdhani',
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: AppSpacing.sm,
    color: AppColors.textSecondary,
  );

  static TextStyle buttonLabel = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    letterSpacing: 2,
    color: AppColors.textPrimary,
  );
}
