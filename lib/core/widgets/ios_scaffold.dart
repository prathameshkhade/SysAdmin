import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class IosScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final FloatingActionButton? floatingActionButton;

  const IosScaffold({
    super.key,
    required this.title,
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
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
