import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();

  static const _themeModeKey = 'ims_theme_mode';

  SharedPreferences? _prefs;
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.light,
  );
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _prefs = await SharedPreferences.getInstance();
    final savedThemeMode = _prefs?.getString(_themeModeKey);
    themeModeNotifier.value = _themeModeFromString(savedThemeMode);
    _initialized = true;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await initialize();
    themeModeNotifier.value = mode;
    await _prefs?.setString(_themeModeKey, mode.name);
  }

  Future<void> toggleDarkMode(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
