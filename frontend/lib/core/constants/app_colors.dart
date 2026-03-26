import 'package:flutter/material.dart';

/// All color constants for the Bubble Mecha Pink design system.
/// Never hardcode hex values in widgets — always reference this class.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const bgDeep = Color(0xFF130822);
  static const bgCard = Color(0xFF1E0F35);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const primary     = Color(0xFFFF3CAC);
  static const primaryDark = Color(0xFFC0006A);
  static const accent      = Color(0xFF7B2FBE);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFD08ACA);

  // ── Status ────────────────────────────────────────────────────────────────
  static const statusGreen = Color(0xFF39FF14);

  // ── Reminder Category Chips ───────────────────────────────────────────────
  static const chipWork   = Color(0xFFFF6B6B);
  static const chipHealth = Color(0xFF6BFF9E);
  static const chipMora   = Color(0xFFFF3CAC);
  static const chipSocial = Color(0xFF6BB5FF);
}
