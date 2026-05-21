import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Key for storing theme preference in Hive
const String _kThemeBoxName = 'settings';
const String _kThemeKey = 'isDarkMode';

/// Theme manager that handles theme state and persistence
/// Uses Hive for persisting theme preference
class ThemeManager extends ChangeNotifier {
  ThemeManager() {
    _init();
  }

  bool _isDarkMode = false;
  bool _isInitialized = false;
  Box? _settingsBox;

  /// Current theme mode
  bool get isDarkMode => _isDarkMode;

  /// Whether the manager has been initialized
  bool get isInitialized => _isInitialized;

  /// Current theme mode as ThemeMode enum
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Initialize the theme manager and load saved preference
  Future<void> _init() async {
    try {
      _settingsBox = await Hive.openBox(_kThemeBoxName);
      _isDarkMode = _settingsBox?.get(_kThemeKey, defaultValue: false) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[ThemeManager] Error initializing: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveThemePreference();
  }

  /// Set theme mode directly
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    notifyListeners();
    await _saveThemePreference();
  }

  /// Save theme preference to Hive
  Future<void> _saveThemePreference() async {
    try {
      await _settingsBox?.put(_kThemeKey, _isDarkMode);
    } catch (e) {
      debugPrint('[ThemeManager] Error saving theme preference: $e');
    }
  }
}
