import 'package:flutter/material.dart';

/// Centralized color tokens migrated from the Angular THEME_COLORS document.
///
/// Convention: each unique hex is declared ONCE (the canonical).
/// All semantic aliases point at that canonical — so every hex has a single
/// source of truth while existing names remain available to callers.
class AppColors {
  AppColors._();

  // ==================== Auth (Native) Tokens ====================

  // Core brand / purple identity
  static const Color brandMain = Color(0xFFC441F4);

  // Noble black scale
  static const Color black600 = Color(0xFF1A1D21);

  // Text & semantics
  static const Color semanticWarning = Color(0xFFE26F20);

  // Surfaces - Dark theme
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkBodyBackground = black600;

  // Surfaces - Light theme
  static const Color lightForeground = Colors.white;

  // Quiz / assessment
  static const Color hintColor = semanticWarning;

  // Utility
  static const Color transparent = Colors.transparent;

  static const Color secondScaffoldBackground = Color(0xFFF6F6F6);

  static const Color grey = Color(0xFF454545);

  // ==================== Faheem Text Colors (matching Board app) ====================

  /// Primary text color - dark gray for main content
  static const Color faheemTextPrimary = Color(0xFF1F2937);

  /// Light text color - light gray for hints/placeholders
  static const Color faheemTextLight = Color(0xFF9CA3AF);

  // ==================== Faheem Home Screen Colors ====================

  // Subject-specific colors (matching Board design)
  static const Color subjectMathBg = Color(0xFFD1FAE5);

  // ==================== Clean Home Redesign Colors ====================

  // Clean Text Colors
  static const Color cleanTextTertiary = faheemTextLight;

  // ==================== Progress — Misc ====================
  static const Color progressMasteryGold = Color(0xFFFFD700);

  // ==================== General Semantic Neutrals ====================
  static const Color neutralBorderMedium = Color(0xFFD1D5DB);

  // ==================== General Accents (bright Tailwind-ish palette) ====================
  static const Color accentGoldAmber = progressMasteryGold;

  // ==================== Light Surface Backgrounds ====================
  static const Color surfaceLightGreen = subjectMathBg;

  // ==================== Tier-4 Shared Colors (3+ uses) ====================
  static const Color paperWarm = Color(0xFFFAF6ED);
}

/// Green/gold palette for the v2 brand (per All_Modules_Plan §3).
///
/// Coexists with the existing purple tokens in [AppColors] so screens migrate
/// at their own pace. New screens should pull from here; existing Quran-module
/// screens stay on [AppColors] until they're refreshed.
class AppColorsLight {
  AppColorsLight._();
  static const Color primary = Color(0xFF0E6B47);
  static const Color primaryDark = Color(0xFF0A5639);
  static const Color accent = Color(0xFFC9A227);
  static const Color background = Color(0xFFF8F8F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1A1A1A);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B6B6B);
  static const Color border = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
}

class AppColorsDark {
  AppColorsDark._();
  static const Color primary = Color(0xFF2A9D6B);
  static const Color primaryDark = Color(0xFF0E6B47);
  static const Color accent = Color(0xFFE0BD4A);
  static const Color background = Color(0xFF0F1411);
  static const Color surface = Color(0xFF1A211D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFFEDEDED);
  static const Color onSurface = Color(0xFFEDEDED);
  static const Color muted = Color(0xFF9A9A9A);
  static const Color border = Color(0xFF2A3530);
  static const Color error = Color(0xFFEF5350);
  static const Color success = Color(0xFF66BB6A);
}
