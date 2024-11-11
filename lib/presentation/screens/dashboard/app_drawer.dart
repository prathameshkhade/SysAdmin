import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:sysadmin/presentation/screens/sftp/index.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/index.dart';
import 'package:sysadmin/presentation/screens/terminal/index.dart';

import '../schedule_jobs/index.dart';

class AppDrawer extends StatelessWidget {
  final SSHConnection? defaultConnection;

  const AppDrawer({
    super.key,
    required this.defaultConnection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ListTile buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
      return ListTile(
        horizontalTitleGap: 25,
        titleAlignment: ListTileTitleAlignment.center,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        leading: Icon(
          icon,
          color: theme.colorScheme.secondary,
          size: 28,
          weight: 0.1,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15)),
        onTap: onTap,
      );
    }

    return Drawer(
      elevation: 1,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text('SysAdmin Tools', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: <Widget>[
                buildDrawerItem(
                  context,
                  Icons.monitor_rounded,
                  'System Monitor',
                  () => Navigator.pushNamed(context, '/system-monitor'),
                ),
                buildDrawerItem(
                  context,
                  Icons.person_outline_rounded,
                  'Users & Groups',
                  () => Navigator.pushNamed(context, '/system-monitor'),
                ),
                buildDrawerItem(
                  context,
                  Icons.manage_accounts_rounded,
                  'SSH Manager',
                  () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const SSHManagerScreen())),
                ),
                buildDrawerItem(
                  context,
                  Icons.folder_open_rounded,
                  'File Explorer',
                  () {
                    if (defaultConnection != null) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => SftpExplorerScreen(
                            connection: defaultConnection!,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No default connection configured'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
                buildDrawerItem(
                  context,
                  Icons.schedule,
                  'Cron Jobs',
                  () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const ScheduleJobScreen())),
                ),
                buildDrawerItem(
                  context,
                  Icons.store_rounded,
                  'Package Manager',
                  () => Navigator.pushNamed(context, '/package-manager'),
                ),
                buildDrawerItem(
                  context,
                  Icons.terminal_rounded,
                  'Terminal',
                  () {
                    if (defaultConnection != null) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => TerminalScreen(
                            connection: defaultConnection!,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No default connection configured'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),

                // TODO: Add more Drawer Items here...
              ],
            ),
          ),
        ],
      ),
    );
  }
}
