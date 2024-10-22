import 'package:flutter/material.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/index.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Hello(),
    ));

class Hello extends StatelessWidget {
  const Hello({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SSHManagerScreen(),
      ),
    );
  }
}
