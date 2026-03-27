import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get mechaTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDeep,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.bgCard,
          onPrimary: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
        ),

        // ── AppBar ─────────────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: AppTextStyles.titleLarge,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),

        // ── Input Fields ───────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgCard,
          hintStyle: AppTextStyles.hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),

        // ── Slider ─────────────────────────────────────────────────────────
        sliderTheme: const SliderThemeData(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.bgCard,
          thumbColor: AppColors.primary,
          overlayColor: Color(0x33FF3CAC),
        ),

        // ── Switch ─────────────────────────────────────────────────────────
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            return states.contains(MaterialState.selected)
                ? AppColors.textPrimary
                : AppColors.textSecondary;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            return states.contains(MaterialState.selected)
                ? AppColors.primary
                : AppColors.bgCard;
          }),
          trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
        ),

        // ── Progress Indicator ─────────────────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.bgCard,
        ),

        // ── FloatingActionButton ───────────────────────────────────────────
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
        ),

        textTheme: const TextTheme(
          displayLarge:  AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          titleLarge:    AppTextStyles.titleLarge,
          titleMedium:   AppTextStyles.titleMedium,
          bodyLarge:     AppTextStyles.bodyLarge,
          bodyMedium:    AppTextStyles.bodyMedium,
          bodySmall:     AppTextStyles.bodySmall,
          labelSmall:    AppTextStyles.caption,
        ),

        useMaterial3: true,
      );
}