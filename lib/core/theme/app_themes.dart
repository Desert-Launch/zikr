import 'package:quran/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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

