import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/services/user_manager_service.dart';
import 'package:sysadmin/presentation/screens/user_management/create_user_form.dart';
import 'package:sysadmin/presentation/widgets/bottom_sheet.dart';
import 'package:sysadmin/providers/ssh_state.dart';

import '../../../core/services/sudo_service.dart';
import '../../../data/models/linux_user.dart';
import 'delete_user_screen.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  late UserManagerService _userManagerService;
  late SudoService _sudoService;
  late List<LinuxUser> users = [];

  // States for delete options
  bool removeHomeDirectory = false;
  bool removeForcefully = false;
  bool removeSELinuxMapping = false;

  @override
  void initState() {
    super.initState();
    var sshClient = ref.read(sshClientProvider).value!;
    _sudoService = ref.read(sudoServiceProvider);
    _userManagerService = UserManagerService(sshClient, _sudoService);

    // Set context for sudo prompts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sudoService.setContext(context);
    });

    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      users = await _userManagerService.getAllUsers();
      debugPrint(users.toString());
      setState(() {});
    }
    catch (e) {
      debugPrint("$e");
    }
  }

  void _showModalBottomSheet(BuildContext context, LinuxUser user) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.useOpacity(0.5),
        builder: (context) => CustomBottomSheet(
            data: CustomBottomSheetData(
              title: user.username,
              subtitle: user.comment.isNotEmpty ? user.comment : "N/A",
              actionButtons: <ActionButtonData> [
                ActionButtonData(
                    text: 'EDIT',
                    onPressed: () async {
                      try {
                        Navigator.pop(context); // Close bottom sheet first
                        bool? isUserUpdated = await Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => CreateUserForm(
                              service: _userManagerService,
                              originalUser: user, // Pass the user to edit
                            ),
                          ),
                        );

                        if (isUserUpdated == true) {
                          WidgetsBinding.instance.addPostFrameCallback(
                                (_) => Util.showMsg(
                              context: context,
                              msg: "User updated successfully",
                              bgColour: Colors.green,
                              isError: false,
                            ),
                          );
                          await _loadUsers(); // Refresh the user list
                        }
                      }
                      catch (e) {
                        if (mounted) {
                          WidgetsBinding.instance.addPostFrameCallback(
                                (_) => Util.showMsg(
                              context: context,
                              msg: "Failed to update user: $e",
                              isError: true,
                            ),
                          );
                        }
                      }
                    }
                ),
                  ActionButtonData(
                      text: "DELETE",
                      onPressed: () async {
                          try {
                            Navigator.pop(context);
                            bool? isUserDeleted = await Navigator.push(
                                context,
                                CupertinoPageRoute(builder: (context) => DeleteUserScreen(
                                    user: user,
                                    service: _userManagerService
                                ))
                            );
                            // Refresh user's list if the user is deleted
                            if (isUserDeleted == true) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => Util.showMsg(
                                      context: context,
                                      msg: "User deleted successfully",
                                      bgColour: Colors.green,
                                      isError: false
                                  )
                              );
                              await _loadUsers();
                            }
                          }
                          catch(e) {
                            if (mounted) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => Util.showMsg(context: context, msg: "Failed to delete user: $e", isError: true),
                              );
                            }
                          }
                      },
                      bgColor: Theme.of(context).colorScheme.error
                  )
              ],
              tables: <TableData> [
                  TableData(
                      heading: "User Information",
                      rows: <TableRowData> [
                          TableRowData(label: "Username", value: user.username),
                          TableRowData(label: "Comment", value: user.comment.isNotEmpty ? user.comment : "N/A"),
                          TableRowData(label: "UID", value: user.uid.toString()),
                          TableRowData(label: "GID", value: user.gid.toString()),
                      ]
                  ),
                  TableData(
                      heading: "System Path",
                      rows: <TableRowData> [
                          TableRowData(label: "Home Directory", value: user.homeDirectory),
                          TableRowData(label: "Shell", value: user.shell),
                      ]
                  ),

                  // TODO: fix this info to show this information
                  // TableData(
                  //     heading: "Login Information",
                  //     rows: <TableRowData> [
                  //         TableRowData(label: "Last Login", value: user.lastLogin.toString()),
                  //     ]
                  // ),
                  // TableData(
                  //     heading: "Password Information",
                  //     rows: <TableRowData> [
                  //       TableRowData(label: "Password Changed", value: user.lastLogin.toString()),
                  //       TableRowData(label: "Warning (days)", value: user.passwordWarnDays.toString()),
                  //       TableRowData(label: "Min Age (days)", value: user.passwordMinDays.toString()),
                  //       TableRowData(label: "Max Age (days)", value: user.passwordMaxDays.toString()),
                  //     ]
                  // ),

              ]
                  // )
            ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
        title: "Manage Users",
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) => Divider(
                  height: 1.3,
                  color: theme.colorScheme.surface
              ),
              itemBuilder: (context, index) => ListTile(
                subtitleTextStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: CircleAvatar(
                  maxRadius: 24,
                  backgroundColor: (
                      users[index].uid == 0
                          ? CupertinoColors.systemRed
                          : (users[index].uid > 0 && users[index].uid < 1000)
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.activeGreen
                  ).useOpacity(0.75),
                  child: Icon(
                      users[index].uid == 0
                          ? Icons.admin_panel_settings_outlined
                          : (users[index].uid > 0 && users[index].uid < 1000)
                              ? Icons.settings
                              : Icons.person_outline_rounded,
                          size: 27,
                          color: theme.colorScheme.inverseSurface
                  ),
                ),
                title: Text(users[index].username),
                subtitle: Text(users[index].comment.isNotEmpty ? users[index].comment : "N/A"),
                onTap: () => _showModalBottomSheet(context, users[index])
              ),
            ),
          ),
        ),

        // Create User Button
        floatingActionButton: FloatingActionButton(
            onPressed: () async {
              try {
                bool? isUserCreated = await Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => CreateUserForm(service: _userManagerService))
                );

                if (isUserCreated == true) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => Util.showMsg(
                      context: context,
                      msg: "User created successfully",
                      bgColour: Colors.green,
                      isError: false,
                    ),
                  );
                  await _loadUsers();
                }
              }
              catch (e) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => Util.showMsg(
                      context: context,
                      msg: "Failed to create user: $e",
                      isError: true,
                    ),
                  );
                }
              }
            },
            child: Icon(Icons.add_sharp, color: theme.colorScheme.inverseSurface),
        )
    );
  }

  @override
  void dispose() {
    _sudoService.clearContext();
    super.dispose();
  }
}
