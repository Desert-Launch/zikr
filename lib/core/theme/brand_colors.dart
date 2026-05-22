import 'package:flutter/material.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Theme-aware brand tokens. Add a [BrandColors] instance to each [ThemeData]
/// so widgets can pick up the right palette automatically when the user
/// switches between light, dark, and system themes.
///
/// Usage:
/// ```dart
/// final brand = context.brand;
/// container.color = brand.surface;
/// ```
///
/// Tokens that genuinely don't change between modes (e.g., the green/gold
/// brand identity) live on [AppColorsLight] and are referenced as constants
/// where const-ness matters (gradient stops on `const LinearGradient`).
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.onSurface,
    required this.muted,
    required this.border,
    required this.error,
    required this.success,
  });

  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color background;
  final Color surface;

  /// Slightly tinted version of [surface] for cards inside a card (nested
  /// container backgrounds).
  final Color surfaceMuted;
  final Color onSurface;
  final Color muted;
  final Color border;
  final Color error;
  final Color success;

  static const light = BrandColors(
    primary: AppColorsLight.primary,
    primaryDark: AppColorsLight.primaryDark,
    accent: AppColorsLight.accent,
    background: AppColorsLight.background,
    surface: AppColorsLight.surface,
    surfaceMuted: Color(0xFFF1F1F1),
    onSurface: AppColorsLight.onSurface,
    muted: AppColorsLight.muted,
    border: AppColorsLight.border,
    error: AppColorsLight.error,
    success: AppColorsLight.success,
  );

  static const dark = BrandColors(
    primary: AppColorsDark.primary,
    primaryDark: AppColorsDark.primaryDark,
    accent: AppColorsDark.accent,
    background: AppColorsDark.background,
    surface: AppColorsDark.surface,
    surfaceMuted: Color(0xFF222B26),
    onSurface: AppColorsDark.onSurface,
    muted: AppColorsDark.muted,
    border: AppColorsDark.border,
    error: AppColorsDark.error,
    success: AppColorsDark.success,
  );

  @override
  ThemeExtension<BrandColors> copyWith({
    Color? primary,
    Color? primaryDark,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? onSurface,
    Color? muted,
    Color? border,
    Color? error,
    Color? success,
  }) {
    return BrandColors(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      onSurface: onSurface ?? this.onSurface,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  ThemeExtension<BrandColors> lerp(
      covariant ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension BrandColorsX on BuildContext {
  /// Theme-aware brand tokens. Pulls from `Theme.of(this).extension<BrandColors>()`,
  /// falling back to [BrandColors.light] if the extension isn't registered yet.
  BrandColors get brand =>
      Theme.of(this).extension<BrandColors>() ?? BrandColors.light;
}
