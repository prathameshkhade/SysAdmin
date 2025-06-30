// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IosScaffold extends StatefulWidget {
  final double? elevation;
  final String title;
  final TextStyle? titleStyle;
  final List<Widget>? actions;
  final Widget body;
  final FloatingActionButton? floatingActionButton;
  final Widget? bottomNavigationBar;

  const IosScaffold({
    super.key,
    this.elevation = 1.0,
    required this.title,
    this.titleStyle,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  State<IosScaffold> createState() => _IosScaffoldState();
}

class _IosScaffoldState extends State<IosScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: widget.elevation,

          // Title
          title: Text(
            widget.title,
            style: widget.titleStyle ?? const TextStyle(fontWeight: FontWeight.bold),
          ),

          actions: widget.actions
        ),

        // Body
        body: widget.body,

        // Bottom Navigation Bar
        bottomNavigationBar: widget.bottomNavigationBar,

        // Floating Action Button
        floatingActionButton: widget.floatingActionButton,
    );
  }
}
