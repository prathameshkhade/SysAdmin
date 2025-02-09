import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalEnv extends ConsumerStatefulWidget {
  const GlobalEnv({super.key});

  @override
  ConsumerState<GlobalEnv> createState() => _GlobalEnvState();
}

class _GlobalEnvState extends ConsumerState<GlobalEnv> {
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
