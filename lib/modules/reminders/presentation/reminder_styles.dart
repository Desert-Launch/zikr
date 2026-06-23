import 'package:flutter/material.dart';
import 'package:quran/core/theme/app_colors.dart';

/// Selectable icon + color catalog for reminders.
///
/// The list **indices** are persisted in [MReminder.iconId] / [MReminder.colorId],
/// so their order must stay stable forever — only ever append new entries.
class ReminderStyles {
  ReminderStyles._();

  /// Defaults for a brand-new reminder (clock icon, brand green) — these match
  /// the field defaults on [MReminder].
  static const int defaultIcon = 2;
  static const int defaultColor = 3;

  /// SVG asset paths (from `assets/icons/`) shown in the icon picker.
  /// The index is persisted via [MReminder.iconId] — only append, never reorder.
  static const List<String> iconAssets = [
    'assets/icons/bell.svg', // 0
    'assets/icons/heart.svg', // 1
    'assets/icons/clock.svg', // 2  (default)
    'assets/icons/moon.svg', // 3
    'assets/icons/sun.svg', // 4
    'assets/icons/star_outline.svg', // 5
    'assets/icons/sunset.svg', // 6
    'assets/icons/sunrise.svg', // 7
    'assets/icons/coffee.svg', // 8
    'assets/icons/book_open.svg', // 9
  ];

  static const List<Color> colors = [
    Color(0xFF8B5CF6), // 0 purple
    Color(0xFF4F8EF7), // 1 blue
    AppColorsLight.accent, // 2 gold
    AppColorsLight.primary, // 3 green
  ];

  static String iconAssetFor(int id) => (id >= 0 && id < iconAssets.length)
      ? iconAssets[id]
      : iconAssets[defaultIcon];

  static Color colorFor(int id) =>
      (id >= 0 && id < colors.length) ? colors[id] : colors[defaultColor];
}
