import 'package:flutter/material.dart';

class DeffiredJobScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(child: Text("Differed Text", style: theme.textTheme.labelLarge)),
    );
  }
}