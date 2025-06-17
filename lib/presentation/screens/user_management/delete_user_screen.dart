import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart' show ColorOpacity;
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/models/linux_user.dart';
import 'package:sysadmin/data/services/user_manager_service.dart';

import '../../../core/services/sudo_service.dart';

/// Delete User: john
///
/// Are you sure you want to delete this user?
///
/// ✅ Remove home directory (/home/john)
/// ✅ Force deletion (kill running processes)
/// 🔲 Remove SELinux mapping
/// TODO: Future enhancement - extra delete options
/// 🔲 Backup home to /backup/john/
/// 🔲 Remove user's cron jobs
///
class DeleteUserScreen extends ConsumerStatefulWidget {
  final LinuxUser user;
  final UserManagerService service;

  const DeleteUserScreen({
    super.key,
    required this.user,
    required this.service
  });

  @override
  ConsumerState<DeleteUserScreen> createState() => _DeleteUserScreenState();
}

class _DeleteUserScreenState extends ConsumerState<DeleteUserScreen> {
  bool removeHomeDirectory = false;
  bool removeForcefully = false;
  bool removeSELinuxMapping = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
        title: "Delete ${widget.user.username}?",
        body:  ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          children: <Widget> [
            Text(
              "Warning!",
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.deepOrange)
            ),
            const SizedBox(height: 28),
            Text(
              "This action cannot be undone! Are you sure you want to delete this user?",
              style: theme.textTheme.titleMedium
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 0.1),
            const SizedBox(height: 24),

            ListTile(
              contentPadding: EdgeInsets.zero,
              subtitleTextStyle: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.inverseSurface.useOpacity(0.5)),
              title: const Text("Remove home directory?"),
              subtitle: Text(widget.user.homeDirectory),
              trailing: Checkbox.adaptive(
                  value: removeHomeDirectory,
                  onChanged: (bool? newValue) => setState(() {
                    removeHomeDirectory = newValue!;
                  }),
              )
            ),
            ListTile(
                contentPadding: EdgeInsets.zero,
                subtitleTextStyle: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.inverseSurface.useOpacity(0.5)),
                title: const Text("Force deletion?"),
                subtitle: const Text("Kills the running processes!"),
                trailing: Checkbox.adaptive(
                  value: removeForcefully,
                  onChanged: (bool? newValue) => setState(() {
                    removeForcefully = newValue!;
                  }),
                )
            ),
            ListTile(
                contentPadding: EdgeInsets.zero,
                subtitleTextStyle: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.inverseSurface.useOpacity(0.5)),
                title: const Text("Remove SELinux mapping?"),
                subtitle: const Text("Removes any SELinux user mapping for the user"),
                trailing: Checkbox.adaptive(
                  value: removeSELinuxMapping,
                  onChanged: (bool? newValue) => setState(() {
                    removeSELinuxMapping = newValue!;
                  }),
                )
            )

          ],
        ),

        floatingActionButton: FloatingActionButton(
            backgroundColor: theme.colorScheme.error,
            isExtended: true,
            tooltip: "Deletes the ${widget.user.username} user permanently with specified options!",
            onPressed: () async {
              final sudoService = ref.read(sudoServiceProvider);
              sudoService.setContext(context);

              try {
                // delete user
                bool isUserDeleted = await widget.service.deleteUser(
                    user: widget.user,
                    removeForcefully: removeForcefully,
                    removeHomeDirectory: removeHomeDirectory,
                    removeSELinuxMapping: removeSELinuxMapping
                );

                // Return user deleted or not?
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pop(context, isUserDeleted);
                  }
                });
              }
              catch (e) {
                if (mounted) {
                  Util.showMsg(context: context, msg: "Failed to delete user: $e", isError: true);
                }
              } finally {
                // Clear context when done
                sudoService.clearContext();
              }
            },
            child: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.inverseSurface)
        ),
    );
  }
}
