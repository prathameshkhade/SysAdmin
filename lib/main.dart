import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/theme/app_theme.dart';
import 'package:sysadmin/presentation/screens/dashboard/index.dart';

void main() => runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        title: 'SysAdmin',
        home: const SysAdminApp(),
      ),
    )
);

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
