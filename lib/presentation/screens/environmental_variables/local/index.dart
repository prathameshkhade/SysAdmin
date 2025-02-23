import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/data/models/env_variable.dart';
import 'package:sysadmin/data/services/env_service.dart';
import 'package:sysadmin/presentation/widgets/bottom_sheet.dart';
import 'package:sysadmin/presentation/widgets/delete_confirmation_dialog.dart';
import '../form.dart';

class LocalVariableTab extends ConsumerStatefulWidget {
  final EnvService envService;

  const LocalVariableTab({super.key, required this.envService});

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
        isDismissible: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CustomBottomSheet(
              data: CustomBottomSheetData(
                title: variable.name,
                subtitle: variable.value,
                actionButtons: <ActionButtonData>[
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
                      }),

                  // Delete Button
                  ActionButtonData(
                      text: "Delete",
                      bgColor: Theme.of(context).colorScheme.error,
                      onPressed: () async {
                        Navigator.pop(context); // Close bottom sheet

                        await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return DeleteConfirmationDialog(
                                title: "Delete Variable?",
                                content: "Are you sure you want to delete ${variable.name}?",
                                onCancel: () => Navigator.pop(context, false),
                                onConfirm: () async {
                                  // Delete the var
                                  final service = widget.envService;
                                  await service.deleteVariable(variable.name, variable.isGlobal);

                                  if (mounted) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                                      // CLose the dialog
                                      Navigator.pop(context);

                                      // Reload the env list
                                      await _loadEnv();
                                    });
                                  }

                                  // Show the deleted message
                                  if(mounted) {
                                    WidgetsBinding.instance.addPostFrameCallback(
                                        (_) => ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                backgroundColor: Colors.green,
                                                content: Text("Deleted ${variable.name}")
                                            )
                                        )
                                    );
                                  }
                                }
                            );
                          },
                        );
                      }),
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
            subtitle: Text(localEnvList[index].value ?? "null",
                style: const TextStyle(color: Color.fromRGBO(255, 00, 255, 1)))),
      ),
    );
  }
}
