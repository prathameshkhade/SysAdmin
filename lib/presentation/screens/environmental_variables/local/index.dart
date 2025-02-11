import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/data/models/env_variable.dart';
import 'package:sysadmin/data/services/env_service.dart';
import 'package:sysadmin/presentation/widgets/bottom_sheet.dart';
import '../form.dart';

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
  }

  void _showVariableDetails(BuildContext context, EnvVariable variable) {
    showModalBottomSheet(
        context: context,
        builder: (context) => CustomBottomSheet(
          data: CustomBottomSheetData(
              title: variable.name,
              subtitle: variable.value,
              actionButtons: <ActionButtonData> [
                // Edit Button
                ActionButtonData(
                    text: "Edit",
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => EnvForm(
                            isGlobal: variable.isGlobal,
                            initialValue: variable,
                            isEditing: true,
                          ),
                        ),
                      );
                    }
                ),

                // Delete Button
                ActionButtonData(
                    text: "Delete",
                    bgColor: Theme.of(context).colorScheme.error,
                    onPressed: () => debugPrint("Delete clicked!")
                ),
              ],
          ),
        )
    );
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
          onTap: () => _showVariableDetails(context, localEnvList[index]),
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
