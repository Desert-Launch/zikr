import 'package:quran/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized text styles using Tajawal font (matching Board app)
/// All styles use GoogleFonts.tajawal() for consistent Arabic typography
class AppTextStyles {
  AppTextStyles._();

  // ============ DISPLAY ============
  static TextStyle get display =>
      GoogleFonts.tajawal(fontSize: 36.sp, fontWeight: FontWeight.w900, color: AppColors.faheemTextPrimary);

  // ============ HEADINGS ============
  static TextStyle get h1 =>
      GoogleFonts.tajawal(fontSize: 28.sp, fontWeight: FontWeight.w900, color: AppColors.faheemTextPrimary);

  static TextStyle get h2 =>
      GoogleFonts.tajawal(fontSize: 22.sp, fontWeight: FontWeight.w800, color: AppColors.faheemTextPrimary);

  static TextStyle get h3 =>
      GoogleFonts.tajawal(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.faheemTextPrimary);

  static TextStyle get h4 =>
      GoogleFonts.tajawal(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.faheemTextPrimary);

  // ============ BODY ============
  static TextStyle get bodyLarge =>
      GoogleFonts.tajawal(fontSize: 16.sp, fontWeight: FontWeight.w500, color: AppColors.faheemTextPrimary);

  static TextStyle get bodyMedium =>
      GoogleFonts.tajawal(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.faheemTextPrimary);

  static TextStyle get bodySmall =>
      GoogleFonts.tajawal(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.faheemTextSecondary);

  // ============ LABELS ============
  static TextStyle get labelLarge =>
      GoogleFonts.tajawal(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.faheemTextPrimary);

  static TextStyle get labelMedium =>
      GoogleFonts.tajawal(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.faheemTextSecondary);

  static TextStyle get labelSmall =>
      GoogleFonts.tajawal(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.faheemTextLight);

  // ============ BUTTONS ============
  static TextStyle get buttonLarge =>
      GoogleFonts.tajawal(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.faheemBgWhite);

  static TextStyle get buttonMedium =>
      GoogleFonts.tajawal(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.faheemBgWhite);

  static TextStyle get buttonSmall =>
      GoogleFonts.tajawal(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.faheemBgWhite);

  // ============ SPECIAL ============
  static TextStyle get mascotTitle => GoogleFonts.tajawal(
    fontSize: 28.sp,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 2))],
  );

  static TextStyle get mascotSubtitle =>
      GoogleFonts.tajawal(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9));

  static TextStyle get cardTitle =>
      GoogleFonts.tajawal(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.faheemTextPrimary);

  static TextStyle get cardSubtitle =>
      GoogleFonts.tajawal(fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.faheemTextSecondary);

  static TextStyle get statValue =>
      GoogleFonts.tajawal(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.faheemTextPrimary);

  static TextStyle get statLabel =>
      GoogleFonts.tajawal(fontSize: 9.sp, fontWeight: FontWeight.w500, color: AppColors.faheemTextSecondary);

  static TextStyle get badge => GoogleFonts.tajawal(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white);

  static TextStyle get progressPercent =>
      GoogleFonts.tajawal(fontSize: 8.sp, fontWeight: FontWeight.w700, color: AppColors.faheemTextSecondary);

  static TextStyle get modeTitle => GoogleFonts.tajawal(fontSize: 22.sp, fontWeight: FontWeight.w800);

  static TextStyle get modeDescription => GoogleFonts.tajawal(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.faheemTextSecondary,
    height: 1.6,
  );

  static TextStyle get featureTag => GoogleFonts.tajawal(fontSize: 12.sp, fontWeight: FontWeight.w600);

  static TextStyle get inputHint =>
      GoogleFonts.tajawal(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.faheemTextLight);

  static TextStyle get chatMessage => GoogleFonts.tajawal(fontSize: 15.sp, fontWeight: FontWeight.w500, height: 1.7);

  static TextStyle get timerDisplay =>
      GoogleFonts.tajawal(fontSize: 24.sp, fontWeight: FontWeight.w800, color: Colors.white);

  static TextStyle get scoreDisplay =>
      GoogleFonts.tajawal(fontSize: 48.sp, fontWeight: FontWeight.w900, color: AppColors.faheemBoard);

  // ============ KEYWORD CHIP ============
  static TextStyle get keywordTerm => GoogleFonts.tajawal(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.brandPurple.withValues(alpha: 0.7),
  );

  static TextStyle get keywordDefinition => GoogleFonts.tajawal(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.faheemTextSecondary,
  );

  // ============ HELPER METHODS ============

  /// Get base Tajawal TextStyle to customize
  static TextStyle tajawal({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.tajawal(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  /// Get TextTheme with Tajawal font for ThemeData
  static TextTheme get textTheme => GoogleFonts.tajawalTextTheme();
}
