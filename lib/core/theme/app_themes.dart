import 'package:quran/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// Builds the v2 green/gold light theme. Used as `MaterialApp.theme`.
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: const [BrandColors.light],
    scaffoldBackgroundColor: AppColorsLight.background,
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.primary,
      onPrimary: AppColorsLight.onPrimary,
      secondary: AppColorsLight.accent,
      onSecondary: AppColorsLight.onPrimary,
      surface: AppColorsLight.surface,
      onSurface: AppColorsLight.onSurface,
      error: AppColorsLight.error,
      onError: AppColorsLight.onPrimary,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsLight.surface,
      foregroundColor: AppColorsLight.onSurface,
      elevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        color: AppColorsLight.onSurface, fontSize: 18.sp, fontWeight: FontWeight.w700,
      ),
    ),
    dividerColor: AppColorsLight.border,
  );
}

/// Builds the v2 green/gold dark theme. Used as `MaterialApp.darkTheme`.
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    extensions: const [BrandColors.dark],
    scaffoldBackgroundColor: AppColorsDark.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.primary,
      onPrimary: AppColorsDark.onPrimary,
      secondary: AppColorsDark.accent,
      onSecondary: Colors.black,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.onSurface,
      error: AppColorsDark.error,
      onError: AppColorsDark.onPrimary,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsDark.surface,
      foregroundColor: AppColorsDark.onSurface,
      elevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        color: AppColorsDark.onSurface, fontSize: 18.sp, fontWeight: FontWeight.w700,
      ),
    ),
    dividerColor: AppColorsDark.border,
  );
}

/// Legacy purple themes preserved for screens that still reference them
/// directly. New screens go through [buildLightTheme]/[buildDarkTheme]
/// and `Theme.of(context).colorScheme`.
class AppThemes {
  static ThemeData get light => ThemeData(
    // Use Tajawal as the default font for the entire app (matching Board app)
    textTheme: GoogleFonts.cairoTextTheme(),
    brightness: Brightness.light,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    scaffoldBackgroundColor: AppColors.lightBackground,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brandMain,
      circularTrackColor: AppColors.lightBorderDefault,
      linearTrackColor: AppColors.lightBorderDefault,
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.lightForeground),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.lightForeground,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      hintStyle: GoogleFonts.cairo(
        color: AppColors.textBodyLight,
        fontSize: 18.sp,
        fontWeight: FontWeight.w400,
        height: 1.1,
      ),
      errorStyle: GoogleFonts.cairo(
        color: AppColors.semanticDanger,
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.brandMain, width: 1.w),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.brandMain, width: 1.w),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.brandMain, width: 1.w),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.black300, width: 1.w),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.semanticDanger, width: 1.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.semanticDanger, width: 1.w),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    // Use Tajawal as the default font for the entire app (matching Board app)
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    brightness: Brightness.dark,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    scaffoldBackgroundColor: AppColors.darkBackground,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brandMain,
      circularTrackColor: AppColors.darkBorderDefault,
      linearTrackColor: AppColors.darkBorderDefault,
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.darkForeground),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.darkForeground,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      hintStyle: GoogleFonts.cairo(
        color: AppColors.textBodyDark,
        fontSize: 18.sp,
        fontWeight: FontWeight.w400,
        height: 1.1,
      ),
      errorStyle: GoogleFonts.cairo(
        color: AppColors.semanticDanger,
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.brandMain, width: 1.w),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.brandMain, width: 1.w),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.darkBorderDefault, width: 1.w),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.darkBorderDefault, width: 1.w),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.semanticDanger, width: 1.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.rCapped(18)),
        borderSide: BorderSide(color: AppColors.semanticDanger, width: 1.w),
      ),
    ),
  );
}
