import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/cubits/s_theme.dart';
import 'package:quran/modules/settings/data/sources/local/box_theme_pref.dart';

/// App-wide theme singleton. Persists choice to [BoxThemePref] so the next
/// boot starts on the user's last selection without flicker.
class CBTheme extends Cubit<STheme> {
  CBTheme(this._box) : super(const STheme());

  final BoxThemePref _box;

  /// Loads the persisted preference. Falls back to [EThemeMode.system] if the
  /// box is empty or the stored index is malformed.
  Future<void> load() async {
    final pref = _box.current();
    final idx = pref?.modeIndex;
    if (idx == null || idx < 0 || idx >= EThemeMode.values.length) {
      return;
    }
    emit(state.copyWith(mode: EThemeMode.values[idx]));
  }

  Future<void> setMode(EThemeMode mode) async {
    if (state.mode == mode) return;
    await _box.setMode(mode.index);
    emit(state.copyWith(mode: mode));
  }

  ThemeMode toMaterialMode() => switch (state.mode) {
        EThemeMode.system => ThemeMode.system,
        EThemeMode.light => ThemeMode.light,
        EThemeMode.dark => ThemeMode.dark,
      };
}
