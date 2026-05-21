import 'package:flutter/material.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Linear gradients translated from the Angular theme tokens.
class AppGradients {
  AppGradients._();

  static const LinearGradient text = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(1, 1),
    colors: [AppColors.brandGradientMagenta, AppColors.brandGradientPink, AppColors.brandGradientCyan],
    stops: [0.07, 0.19, 0.7],
  );

  static const LinearGradient main = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.accentCyan, Color(0xFF672892), Color(0xFF8E2490), Color(0xFFCF1768), Color(0xFFFF7933)],
    stops: [0.005, 0.24, 0.47, 0.71, 0.94],
  );

  static const LinearGradient cardBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x29D7EDED), Color(0x00CCEBEB)],
  );

  static const LinearGradient messageHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B3BDD), Color(0xFF0E6AB4)],
  );

  static const LinearGradient newSessionButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.brandGradientMagenta, AppColors.brandGradientCyan],
  );

  static const LinearGradient aiAssistantName = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(1, 1),
    colors: [AppColors.brandGradientMagenta, AppColors.brandGradientPink, AppColors.brandGradientCyan],
    stops: [0.17, 0.46, 1.0],
  );

  static const LinearGradient profileLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x2900E9FF), Color(0x0CA84FE5), Colors.white],
    stops: [0.0, 0.95, 1.0],
  );

  /// Auth/Button gradient - used for primary buttons across the app
  static const LinearGradient button = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.authPrimary, AppColors.authPrimaryDark],
  );

  /// Primary gradient - vertical direction
  static const LinearGradient primaryVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.brandPurple, AppColors.brandPurpleDark],
  );

  /// Primary gradient - horizontal direction
  static const LinearGradient primaryHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.brandPurple, AppColors.brandMain],
  );

  /// Primary gradient - radial direction
  static const RadialGradient primaryRadial = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [AppColors.brandMain, AppColors.brandPurple],
  );

  /// Theme toggle gradient (dark mode active)
  /// Matches Angular: linear-gradient(to right, #A73EE7, #00EBFF)
  static const LinearGradient themeToggle = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFA73EE7), Color(0xFF00EBFF)],
  );

  static LinearGradient loPlayerBackgroundGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    stops: [0.0, 0.3, 0.5, 1.0],
    colors: [
      Color(0xFF333A30).withValues(alpha: 0.0),
      AppColors.darkSlate.withValues(alpha: 0.6),
      AppColors.darkSlate.withValues(alpha: 0.8),
      AppColors.darkSlate.withValues(alpha: 1),
    ],
  );

  /// Modern audio player warm gradient background
  static const LinearGradient audioPlayerBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.audioPlayerBgStart, AppColors.audioPlayerBgMiddle, AppColors.audioPlayerBgEnd],
    stops: [0.0, 0.5, 1.0],
  );
}
