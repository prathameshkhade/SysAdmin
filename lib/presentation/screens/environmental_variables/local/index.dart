import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/data/models/env_variable.dart';
import 'package:sysadmin/data/services/env_service.dart';

class LocalVariableTab extends ConsumerStatefulWidget {
  final EnvService envService;

  const LocalVariableTab({
    super.key,
    required this.envService
  });

  @override
  ConsumerState<LocalVariableTab> createState() => _LocalEnvState();
}

class _LocalEnvState extends ConsumerState<LocalVariableTab> {
  List<EnvVariable> localEnvList = [];

  @override
  void initState() {
    super.initState();
    _loadEnv();
  }

  Future<void> _loadEnv() async {
    localEnvList = await widget.envService.fetchLocalVariables();
    setState(() {});
    debugPrint("Local Variables length: ${localEnvList.length}");
    debugPrint(localEnvList.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadEnv,
      child: ListView.separated(
        itemCount: localEnvList.length,
        physics: const AlwaysScrollableScrollPhysics(),

        separatorBuilder: (context, index) => Divider(
          color: theme.colorScheme.inverseSurface,
          thickness: 0.05,
          height: 12,
        ),

        itemBuilder: (context, index) => ListTile(
          title: Text(localEnvList[index].name),
          subtitle: Text(
              localEnvList[index].value ?? "null",
              style: const TextStyle(
                color: Color.fromRGBO(255, 00, 255, 1)
              )
          )
        ),

      ),
    );
  }
}
