import 'package:flutter/material.dart';
import 'package:sysadmin/presentation/screens/onboarding/index.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: OnBoarding(),
      ),
    );
  }
}
