import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/add_connection.dart';

class SSHManagerScreen extends StatefulWidget {
  const SSHManagerScreen({super.key});

  @override
  State<SSHManagerScreen> createState() => _SSHManagerScreenState();
}

class _SSHManagerScreenState extends State<SSHManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return IosScaffold(
      title: "SSH Manager",
      body: const Center(
        child: Text("SSH manager screen"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => AddConnectionForm())),
        tooltip: "Add Connection",
        elevation: 10.0,
        child: const Icon(Icons.add),
      )
    );
  }
}