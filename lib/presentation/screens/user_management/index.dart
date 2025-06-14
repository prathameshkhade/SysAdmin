import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/services/user_manager_service.dart';
import 'package:sysadmin/presentation/widgets/bottom_sheet.dart';
import 'package:sysadmin/providers/ssh_state.dart';

import '../../../data/models/linux_user.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  late SSHClient sshClient;
  late UserManagerService _userManagerService;
  late List<LinuxUser> users = [];

  @override
  void initState() {
    super.initState();
    sshClient = ref.read(sshClientProvider).value!;
    _userManagerService = UserManagerService(sshClient);
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

  // as I am using the showBottomSheet function from flutter and isScrollable:true but when i drag from upper blanck space it does,nt go up
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
                    onPressed: (){}
                  ),
                  ActionButtonData(
                      text: "DELETE",
                      onPressed: () {},
                      bgColor: Theme.of(context).colorScheme.error
                  )
              ],
              tables: <TableData> [
                  TableData(
                      heading: "User Information",
                      rows: <TableRowData> [
                          TableRowData(label: "Username", value: user.username),
                          TableRowData(label: "Comment", value: user.comment),
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
                  // )

              ]
            ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
        title: "Users",
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
        actions: <IconButton>[
          IconButton(
            onPressed: () => Util.showMsg(context: context, msg: "Add user form", bgColour: theme.primaryColor),
            icon: const Icon(Icons.add_sharp)
          )
        ],
    );
  }
}
