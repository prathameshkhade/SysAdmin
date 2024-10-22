import 'package:flutter/material.dart';

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
          onPressed: () {},
          child: const Icon(Icons.add)
      ),
    );
  }
}