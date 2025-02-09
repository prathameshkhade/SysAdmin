import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalVariableTab extends ConsumerStatefulWidget {
  const LocalVariableTab({super.key});

  @override
  ConsumerState<LocalVariableTab> createState() => _LocalEnvState();
}

class _LocalEnvState extends ConsumerState<LocalVariableTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Local Var List",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
      ),
    );
  }
}
