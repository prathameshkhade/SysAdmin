import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sysadmin/core/theme/app_theme.dart';
import 'package:sysadmin/presentation/screens/dashboard/index.dart';
import 'package:sysadmin/presentation/screens/onboarding/index.dart';
import 'package:sysadmin/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isOnBoardingDone = prefs.getBool('isOnBoardingDone') ?? false;
  runApp(
      ProviderScope(
          child: SysAdminMaterialApp(
            isOnBoardingDone: isOnBoardingDone,
          )
      )
  );
}

// Returns Material App
class SysAdminMaterialApp extends ConsumerWidget {
  final bool isOnBoardingDone;

  const SysAdminMaterialApp({
    super.key,
    this.isOnBoardingDone = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkTheme = ref.watch(themeProvider);
    final initialThemeAsync = ref.watch(initialThemeProvider);

    return initialThemeAsync.when(
      data: (_) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
        title: 'SysAdmin',
        home: SysAdminApp(isOnBoardingDone: isOnBoardingDone),
      ),
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error loading theme: $error'),
          ),
        ),
      ),
    );
  }
}

class SysAdminApp extends StatelessWidget {
  final bool isOnBoardingDone;

  const SysAdminApp({
    super.key,
    this.isOnBoardingDone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isOnBoardingDone ? const DashboardScreen() : const OnBoarding(),
      ),
    );
  }
}