import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/services/user_manager_service.dart';
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
      setState(() {});
    }
    catch (e) {
      debugPrint("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
        title: "User Management",
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) => Divider(
                color: theme.colorScheme.inverseSurface.useOpacity(0.5),
                thickness: 0.08,
                height: 1.4,
                indent: 10,
                endIndent: 10,
              ),
              itemBuilder: (context, index) => ListTile(
                leading: Icon(Icons.person_outline_rounded, color: theme.colorScheme.surface),
                title: Text(users[index].username),
                subtitle: Text(users[index].comment.isNotEmpty ? users[index].comment : "NA"),
                subtitleTextStyle: const TextStyle(color: Colors.grey),
                trailing: Icon(
                  users[index].isLocked ? Icons.lock : Icons.lock_open,
                  color: users[index].isLocked ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
                onTap: () => Util.showMsg(context: context, msg: "${users[index]}", bgColour: Colors.purpleAccent),
              ),
            ),
          ),
        )
    );
  }
}
