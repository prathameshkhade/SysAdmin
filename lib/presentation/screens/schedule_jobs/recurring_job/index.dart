import 'package:flutter/material.dart';

class RecurringJobScreen extends StatelessWidget {
  const RecurringJobScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(child: Text("Recurring Text", style: theme.textTheme.headlineLarge)),
    );
  }
}