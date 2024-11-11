import 'package:flutter/material.dart';

class DeferredJobScreen extends StatelessWidget {
  const DeferredJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(child: Text("Differed Text", style: theme.textTheme.labelLarge)),
    );
  }
}