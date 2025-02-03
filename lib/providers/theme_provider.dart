import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to get the initial theme value
final initialThemeProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isDark') ?? false;
});

// Theme state provider
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  // Get the initial value synchronously, fall back to false if not loaded yet
  final initialTheme = ref.watch(initialThemeProvider).value ?? false;
  return ThemeNotifier(initialTheme);
});

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier(super.initialState);

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', !state);
    state = !state;
  }
}