import 'package:flutter/material.dart';
import 'package:sysadmin/core/theme/app_theme.dart';
import 'package:sysadmin/presentation/screens/dashboard/index.dart';

void main() => runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const Hello(),
    )
);

class Hello extends StatelessWidget {
  const Hello({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: DashboardScreen(),
      ),
    );
  }
}
