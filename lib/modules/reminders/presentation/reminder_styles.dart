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

  static const List<IconData> icons = [
    Icons.notifications_rounded, // 0
    Icons.favorite_rounded, // 1
    Icons.schedule_rounded, // 2
    Icons.alarm_rounded, // 3
    Icons.wb_sunny_rounded, // 4
    Icons.star_rounded, // 5
    Icons.self_improvement_rounded, // 6
    Icons.bookmark_added_rounded, // 7
    Icons.nightlight_round, // 8
    Icons.menu_book_rounded, // 9
    Icons.mosque_rounded, // 10
    Icons.water_drop_rounded, // 11
  ];

  static const List<Color> colors = [
    Color(0xFF8B5CF6), // 0 purple
    Color(0xFF4F8EF7), // 1 blue
    AppColorsLight.accent, // 2 gold
    AppColorsLight.primary, // 3 green
  ];

  static IconData iconFor(int id) =>
      (id >= 0 && id < icons.length) ? icons[id] : icons[defaultIcon];

  static Color colorFor(int id) =>
      (id >= 0 && id < colors.length) ? colors[id] : colors[defaultColor];
}
