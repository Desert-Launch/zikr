import 'package:quran/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

extension ColorExtension on ColorScheme {
  // Brand & accent palette
  Color get brandMain => AppColors.brandMain;
  Color get brandPurple => AppColors.brandPurple;
  Color get brandPurpleDark => AppColors.brandPurpleDark;
  Color get brandPurpleAccent => AppColors.brandPurpleAccent;
  Color get brandGradientMagenta => AppColors.brandGradientMagenta;
  Color get brandGradientCyan => AppColors.brandGradientCyan;
  Color get accentBlue => AppColors.accentBlueBright;
  Color get accentCyan => AppColors.accentCyan;

  // Semantics
  Color get success => AppColors.semanticSuccess;
  Color get error => AppColors.semanticError;
  Color get danger => AppColors.semanticDanger;
  Color get warning => AppColors.semanticWarning;
  Color get info => AppColors.semanticInfo;

  // Light theme
  Color get lightBackground => AppColors.lightBackground;
  Color get lightForeground => AppColors.lightForeground;
  Color get lightBodyBackground => AppColors.lightBodyBackground;
  Color get lightAccent => AppColors.lightAccent;
  Color get lightBorder => AppColors.lightBorderDefault;

  // Dark theme
  Color get darkBackground => AppColors.darkBackground;
  Color get darkForeground => AppColors.darkForeground;
  Color get darkBodyBackground => AppColors.darkBodyBackground;
  Color get darkAccent => AppColors.darkAccent;
  Color get darkBorder => AppColors.darkBorderDefault;

  // Component helpers
  Color get questionActionBackground => AppColors.questionActionBackground;
  Color get questionActionBorder => AppColors.questionActionBorder;
  Color get hintColor => AppColors.hintColor;
  Color get chatBubbleBorder => AppColors.chatBubbleBorder;
  Color get listBackground => AppColors.listBackground;
  Color get tabsInactive => AppColors.tabsInactive;
  Color get tabsActive => AppColors.tabsActive;

  // Legacy aliases retained for now
  Color get primaryOrange => AppColors.brandMain;
  Color get primaryLightOrange => AppColors.brandPurple100;
  Color get darkPrimary => AppColors.brandPurpleDark;
  Color get secondaryBlue => AppColors.accentBlueBright;
  Color get white => AppColors.lightForeground;
  Color get scaffoldBackgroundColor => AppColors.lightBackground;
  Color get buttonColor => AppColors.brandMain;
  Color get transparent => AppColors.transparent;
  Color get lightGray => AppColors.lightBorderDefault;
  Color get gray => AppColors.black300;
  Color get darkGray => AppColors.black500;
  Color get red => AppColors.semanticDanger;
  Color get black => AppColors.black800;
  Color get blue => AppColors.accentBlueBright;
  Color get gold => AppColors.mediumLevel;
  Color get green => AppColors.semanticSuccess;
}

extension ColorExtensionOnColor on Color {
  /// Returns a color with the given alpha value (0-255)
  Color blendWithWhite(double percentage) {
    int r = (((toARGB32() >> 16 & 0xFF) * (1 - percentage)) + (255 * percentage)).toInt();
    int g = (((toARGB32() >> 8 & 0xFF) * (1 - percentage)) + (255 * percentage)).toInt();
    int b = (((toARGB32() & 0xFF) * (1 - percentage)) + (255 * percentage)).toInt();
    return Color.fromRGBO(r, g, b, 1.0);
  }
}
