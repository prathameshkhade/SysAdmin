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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title,),
      ),

      body: widget.body,

      floatingActionButton: widget.floatingActionButton,
    );
  }
}
