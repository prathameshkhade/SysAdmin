import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalVariableTab extends ConsumerStatefulWidget {
  const GlobalVariableTab({super.key});

  @override
  ConsumerState<GlobalVariableTab> createState() => _GlobalEnvState();
}

class _GlobalEnvState extends ConsumerState<GlobalVariableTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Global var List",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
      ),
    );
  }
}
