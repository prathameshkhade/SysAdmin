import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/add_connection.dart';

class SSHManagerScreen extends StatefulWidget {
  const SSHManagerScreen({super.key});

  @override
  State<SSHManagerScreen> createState() => _SSHManagerScreenState();
}

class _SSHManagerScreenState extends State<SSHManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SSH Manager"),
      ),

      body: const Center(child: Text("SSH manager screen"),
      ),

      floatingActionButton: ElevatedButton(
          onPressed: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => const AddConnectionForm()));
          },
          child: const Icon(Icons.add)
      ),
    );
  }
}