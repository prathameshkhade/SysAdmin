import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/data/models/env_variable.dart';
import 'package:sysadmin/data/services/env_service.dart';

class GlobalVariableTab extends ConsumerStatefulWidget {
  final EnvService envService;

  const GlobalVariableTab({
    super.key,
    required this.envService
  });

  @override
  ConsumerState<GlobalVariableTab> createState() => _GlobalEnvState();
}

class _GlobalEnvState extends ConsumerState<GlobalVariableTab> {
  List<EnvVariable> globalVarList = [];

  @override
  void initState() {
    super.initState();
    _loadEnv();
  }

  Future<void> _loadEnv() async {
    globalVarList = await widget.envService.fetchGlobalVariables();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadEnv,
      child: ListView.separated(
          itemCount: globalVarList.length,
          separatorBuilder: (context, index) => Divider(
            color: theme.colorScheme.inverseSurface,
            thickness: 0.05,
            height: 12,
          ),
          itemBuilder: (context, index) => ListTile(
            title: Text(globalVarList[index].name),
            subtitle: Text(
                globalVarList[index].value!,
                style: const TextStyle(color: Color.fromRGBO(255, 0, 255, 1))
            ),
          )
      ),
    );
  }
}
