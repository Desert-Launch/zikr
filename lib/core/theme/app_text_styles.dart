import 'package:quran/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized text styles using the Cairo font.
///
/// The bulk of this class is a generated palette of every
/// **color × size × weight** combination, named `<color><size>W<weight>`
/// (e.g. [ink16W500], [gold24W900], [white12W400]).
///
/// Palette axes:
/// * Colors  → `white`, `ink` (#1A1A1A), `grey` (#6B6B6B), `gold` (#D4AF37)
/// * Sizes   → 12, 14, 16, 18, 20, 22, 24 (`.sp`)
/// * Weights → w400, w500, w700, w900
///
/// The older semantic getters (h1, bodyMedium, …) are kept for backwards
/// compatibility and now also resolve to Cairo.
class AppTextStyles {
  AppTextStyles._();

  // ==================== Palette colors ====================
  static const Color _white = Colors.white;
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _grey = Color(0xFF6B6B6B);
  static const Color _gold = Color(0xFFD4AF37);

  /// Base Cairo style builder used by every palette getter.
  static TextStyle _cairo(double size, FontWeight weight, Color color) => GoogleFonts.cairo(
    fontSize: size.sp,
    fontWeight: weight,
    color: color,
    height: 1.5,
  );

  // ==================== WHITE ====================
  static TextStyle get white12W400 => _cairo(12, FontWeight.w400, _white);
  static TextStyle get white12W500 => _cairo(12, FontWeight.w500, _white);
  static TextStyle get white12W700 => _cairo(12, FontWeight.w700, _white);
  static TextStyle get white12W900 => _cairo(12, FontWeight.w900, _white);
  static TextStyle get white14W400 => _cairo(14, FontWeight.w400, _white);
  static TextStyle get white14W500 => _cairo(14, FontWeight.w500, _white);
  static TextStyle get white14W700 => _cairo(14, FontWeight.w700, _white);
  static TextStyle get white14W900 => _cairo(14, FontWeight.w900, _white);
  static TextStyle get white16W400 => _cairo(16, FontWeight.w400, _white);
  static TextStyle get white16W500 => _cairo(16, FontWeight.w500, _white);
  static TextStyle get white16W700 => _cairo(16, FontWeight.w700, _white);
  static TextStyle get white16W900 => _cairo(16, FontWeight.w900, _white);
  static TextStyle get white18W400 => _cairo(18, FontWeight.w400, _white);
  static TextStyle get white18W500 => _cairo(18, FontWeight.w500, _white);
  static TextStyle get white18W700 => _cairo(18, FontWeight.w700, _white);
  static TextStyle get white18W900 => _cairo(18, FontWeight.w900, _white);
  static TextStyle get white20W400 => _cairo(20, FontWeight.w400, _white);
  static TextStyle get white20W500 => _cairo(20, FontWeight.w500, _white);
  static TextStyle get white20W700 => _cairo(20, FontWeight.w700, _white);
  static TextStyle get white20W900 => _cairo(20, FontWeight.w900, _white);
  static TextStyle get white22W400 => _cairo(22, FontWeight.w400, _white);
  static TextStyle get white22W500 => _cairo(22, FontWeight.w500, _white);
  static TextStyle get white22W700 => _cairo(22, FontWeight.w700, _white);
  static TextStyle get white22W900 => _cairo(22, FontWeight.w900, _white);
  static TextStyle get white24W400 => _cairo(24, FontWeight.w400, _white);
  static TextStyle get white24W500 => _cairo(24, FontWeight.w500, _white);
  static TextStyle get white24W700 => _cairo(24, FontWeight.w700, _white);
  static TextStyle get white24W900 => _cairo(24, FontWeight.w900, _white);

  // ==================== INK (#1A1A1A) ====================
  static TextStyle get ink12W400 => _cairo(12, FontWeight.w400, _ink);
  static TextStyle get ink12W500 => _cairo(12, FontWeight.w500, _ink);
  static TextStyle get ink12W700 => _cairo(12, FontWeight.w700, _ink);
  static TextStyle get ink12W900 => _cairo(12, FontWeight.w900, _ink);
  static TextStyle get ink14W400 => _cairo(14, FontWeight.w400, _ink);
  static TextStyle get ink14W500 => _cairo(14, FontWeight.w500, _ink);
  static TextStyle get ink14W700 => _cairo(14, FontWeight.w700, _ink);
  static TextStyle get ink14W900 => _cairo(14, FontWeight.w900, _ink);
  static TextStyle get ink16W400 => _cairo(16, FontWeight.w400, _ink);
  static TextStyle get ink16W500 => _cairo(16, FontWeight.w500, _ink);
  static TextStyle get ink16W700 => _cairo(16, FontWeight.w700, _ink);
  static TextStyle get ink16W900 => _cairo(16, FontWeight.w900, _ink);
  static TextStyle get ink18W400 => _cairo(18, FontWeight.w400, _ink);
  static TextStyle get ink18W500 => _cairo(18, FontWeight.w500, _ink);
  static TextStyle get ink18W700 => _cairo(18, FontWeight.w700, _ink);
  static TextStyle get ink18W900 => _cairo(18, FontWeight.w900, _ink);
  static TextStyle get ink20W400 => _cairo(20, FontWeight.w400, _ink);
  static TextStyle get ink20W500 => _cairo(20, FontWeight.w500, _ink);
  static TextStyle get ink20W700 => _cairo(20, FontWeight.w700, _ink);
  static TextStyle get ink20W900 => _cairo(20, FontWeight.w900, _ink);
  static TextStyle get ink22W400 => _cairo(22, FontWeight.w400, _ink);
  static TextStyle get ink22W500 => _cairo(22, FontWeight.w500, _ink);
  static TextStyle get ink22W700 => _cairo(22, FontWeight.w700, _ink);
  static TextStyle get ink22W900 => _cairo(22, FontWeight.w900, _ink);
  static TextStyle get ink24W400 => _cairo(24, FontWeight.w400, _ink);
  static TextStyle get ink24W500 => _cairo(24, FontWeight.w500, _ink);
  static TextStyle get ink24W700 => _cairo(24, FontWeight.w700, _ink);
  static TextStyle get ink24W900 => _cairo(24, FontWeight.w900, _ink);

  // ==================== GREY (#6B6B6B) ====================
  static TextStyle get grey12W400 => _cairo(12, FontWeight.w400, _grey);
  static TextStyle get grey12W500 => _cairo(12, FontWeight.w500, _grey);
  static TextStyle get grey12W700 => _cairo(12, FontWeight.w700, _grey);
  static TextStyle get grey12W900 => _cairo(12, FontWeight.w900, _grey);
  static TextStyle get grey14W400 => _cairo(14, FontWeight.w400, _grey);
  static TextStyle get grey14W500 => _cairo(14, FontWeight.w500, _grey);
  static TextStyle get grey14W700 => _cairo(14, FontWeight.w700, _grey);
  static TextStyle get grey14W900 => _cairo(14, FontWeight.w900, _grey);
  static TextStyle get grey16W400 => _cairo(16, FontWeight.w400, _grey);
  static TextStyle get grey16W500 => _cairo(16, FontWeight.w500, _grey);
  static TextStyle get grey16W700 => _cairo(16, FontWeight.w700, _grey);
  static TextStyle get grey16W900 => _cairo(16, FontWeight.w900, _grey);
  static TextStyle get grey18W400 => _cairo(18, FontWeight.w400, _grey);
  static TextStyle get grey18W500 => _cairo(18, FontWeight.w500, _grey);
  static TextStyle get grey18W700 => _cairo(18, FontWeight.w700, _grey);
  static TextStyle get grey18W900 => _cairo(18, FontWeight.w900, _grey);
  static TextStyle get grey20W400 => _cairo(20, FontWeight.w400, _grey);
  static TextStyle get grey20W500 => _cairo(20, FontWeight.w500, _grey);
  static TextStyle get grey20W700 => _cairo(20, FontWeight.w700, _grey);
  static TextStyle get grey20W900 => _cairo(20, FontWeight.w900, _grey);
  static TextStyle get grey22W400 => _cairo(22, FontWeight.w400, _grey);
  static TextStyle get grey22W500 => _cairo(22, FontWeight.w500, _grey);
  static TextStyle get grey22W700 => _cairo(22, FontWeight.w700, _grey);
  static TextStyle get grey22W900 => _cairo(22, FontWeight.w900, _grey);
  static TextStyle get grey24W400 => _cairo(24, FontWeight.w400, _grey);
  static TextStyle get grey24W500 => _cairo(24, FontWeight.w500, _grey);
  static TextStyle get grey24W700 => _cairo(24, FontWeight.w700, _grey);
  static TextStyle get grey24W900 => _cairo(24, FontWeight.w900, _grey);

  // ==================== GOLD (#D4AF37) ====================
  static TextStyle get gold12W400 => _cairo(12, FontWeight.w400, _gold);
  static TextStyle get gold12W500 => _cairo(12, FontWeight.w500, _gold);
  static TextStyle get gold12W700 => _cairo(12, FontWeight.w700, _gold);
  static TextStyle get gold12W900 => _cairo(12, FontWeight.w900, _gold);
  static TextStyle get gold14W400 => _cairo(14, FontWeight.w400, _gold);
  static TextStyle get gold14W500 => _cairo(14, FontWeight.w500, _gold);
  static TextStyle get gold14W700 => _cairo(14, FontWeight.w700, _gold);
  static TextStyle get gold14W900 => _cairo(14, FontWeight.w900, _gold);
  static TextStyle get gold16W400 => _cairo(16, FontWeight.w400, _gold);
  static TextStyle get gold16W500 => _cairo(16, FontWeight.w500, _gold);
  static TextStyle get gold16W700 => _cairo(16, FontWeight.w700, _gold);
  static TextStyle get gold16W900 => _cairo(16, FontWeight.w900, _gold);
  static TextStyle get gold18W400 => _cairo(18, FontWeight.w400, _gold);
  static TextStyle get gold18W500 => _cairo(18, FontWeight.w500, _gold);
  static TextStyle get gold18W700 => _cairo(18, FontWeight.w700, _gold);
  static TextStyle get gold18W900 => _cairo(18, FontWeight.w900, _gold);
  static TextStyle get gold20W400 => _cairo(20, FontWeight.w400, _gold);
  static TextStyle get gold20W500 => _cairo(20, FontWeight.w500, _gold);
  static TextStyle get gold20W700 => _cairo(20, FontWeight.w700, _gold);
  static TextStyle get gold20W900 => _cairo(20, FontWeight.w900, _gold);
  static TextStyle get gold22W400 => _cairo(22, FontWeight.w400, _gold);
  static TextStyle get gold22W500 => _cairo(22, FontWeight.w500, _gold);
  static TextStyle get gold22W700 => _cairo(22, FontWeight.w700, _gold);
  static TextStyle get gold22W900 => _cairo(22, FontWeight.w900, _gold);
  static TextStyle get gold24W400 => _cairo(24, FontWeight.w400, _gold);
  static TextStyle get gold24W500 => _cairo(24, FontWeight.w500, _gold);
  static TextStyle get gold24W700 => _cairo(24, FontWeight.w700, _gold);
  static TextStyle get gold24W900 => _cairo(24, FontWeight.w900, _gold);

  // ==================== Semantic styles (legacy, now Cairo) ====================

  // ---- HEADINGS ----
  static TextStyle get h1 =>
      GoogleFonts.cairo(fontSize: 28.sp, fontWeight: FontWeight.w900, color: AppColors.faheemTextPrimary);

  static TextStyle get h2 =>
      GoogleFonts.cairo(fontSize: 22.sp, fontWeight: FontWeight.w800, color: AppColors.faheemTextPrimary);

  static TextStyle get h3 =>
      GoogleFonts.cairo(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.faheemTextPrimary);

  // ---- BODY ----
  static TextStyle get bodyMedium =>
      GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.faheemTextPrimary);

  // ---- SPECIAL ----
  static TextStyle get badge => GoogleFonts.cairo(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white);

  // ==================== HELPER METHODS ====================

  /// Get a base Cairo [TextStyle] to customize on the fly.
  static TextStyle cairo({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  /// Get a [TextTheme] with the Cairo font for [ThemeData].
  static TextTheme get textTheme => GoogleFonts.cairoTextTheme();
}
