import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to get the initial theme value
final initialThemeProvider = FutureProvider<ThemeMode>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  // Check if user has explicitly set a theme preference
  if (prefs.containsKey('themeMode')) {
    final themeValue = prefs.getString('themeMode');
    if (themeValue == 'dark') return ThemeMode.dark;
    if (themeValue == 'light') return ThemeMode.light;
  }

  // Default to system theme if no preference is set
  return ThemeMode.system;
});

// Theme state provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  // Get the initial value, fall back to system if not loaded yet
  final initialTheme = ref.watch(initialThemeProvider).value ?? ThemeMode.system;
  return ThemeNotifier(initialTheme);
});

// Current brightness provider (actual dark/light state)
final isDarkProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

  switch (themeMode) {
    case ThemeMode.system:
      return platformBrightness == Brightness.dark;
    case ThemeMode.dark:
      return true;
    case ThemeMode.light:
      return false;
  }
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(super.initialState);

  void setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();

    switch (mode) {
      case ThemeMode.system:
        await prefs.setString('themeMode', 'system');
        break;
      case ThemeMode.light:
        await prefs.setString('themeMode', 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString('themeMode', 'dark');
        break;
    }

    state = mode;
  }

  void toggleTheme() async {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    }
    else if (state == ThemeMode.dark) {

      setThemeMode(ThemeMode.light);
    }
    else {
      // If currently using system theme, check the system brightness
      // and switch to the opposite
      final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
    }
  }
}