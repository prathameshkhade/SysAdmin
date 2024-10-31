import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IosScaffold extends StatefulWidget {
  final String title;
  final TextStyle? titleStyle;
  final List<Widget>? actions;
  final Widget body;
  final FloatingActionButton? floatingActionButton;

  const IosScaffold({
    super.key,
    required this.title,
    this.titleStyle,
    this.actions,
    required this.body,
    this.floatingActionButton,
  });

  @override
  State<IosScaffold> createState() => _IosScaffoldState();
}

class _IosScaffoldState extends State<IosScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 1.0,
          // IOS Back button
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => Navigator.pop(context),
          ),

          // Title
          title: Text(
            widget.title,
            style: widget.titleStyle ?? const TextStyle(fontWeight: FontWeight.bold),
          ),

          actions: widget.actions
        ),

        // Body
        body: widget.body,

        // Floating Action Button
        floatingActionButton: widget.floatingActionButton,
    );
  }
}
