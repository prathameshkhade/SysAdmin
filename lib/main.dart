import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/theme/app_theme.dart';
import 'package:sysadmin/presentation/screens/dashboard/index.dart';
import 'package:sysadmin/providers/theme_provider.dart';

void main() => runApp(
    const ProviderScope(
      child: SysAdminMaterialApp()
    )
);

// Returns Material App
class SysAdminMaterialApp extends ConsumerWidget {

  const SysAdminMaterialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      title: 'SysAdmin',
      home: const SysAdminApp(),
    );
  }

}

// Returns Scaffold
class SysAdminApp extends StatelessWidget {
  const SysAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: DashboardScreen(),
      ),
    );
  }
}
