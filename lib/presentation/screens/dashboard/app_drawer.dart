import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:sysadmin/presentation/screens/dashboard/theme_switcher.dart';
import 'package:sysadmin/presentation/screens/environmental_variables/index.dart';
import 'package:sysadmin/presentation/screens/sftp/index.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/index.dart';
import 'package:sysadmin/presentation/screens/terminal/index.dart';
import 'package:sysadmin/providers/ssh_state.dart';
import 'package:sysadmin/providers/theme_provider.dart';

import '../schedule_jobs/index.dart';

class AppDrawer extends ConsumerWidget {
  final SSHConnection? defaultConnection;
  final SSHClient sshClient;

  const AppDrawer({
    super.key,
    required this.defaultConnection,
    required this.sshClient
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bool isDark = ref.watch(themeProvider);
    final defaultConnectionAsync = ref.watch(defaultConnectionProvider);

    ListTile buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
      return ListTile(
        horizontalTitleGap: 22,
        titleAlignment: ListTileTitleAlignment.center,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        leading: Icon(icon, size: 25),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14,)),
        onTap: onTap,
      );
    }

    // Heading
    Widget buildDrawerHeading(String heading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          heading,
          style: theme.textTheme.titleSmall,
        ),
      );
    }

    return defaultConnectionAsync.when(
        data: (defaultConnection) => Drawer(
          shape: const ContinuousRectangleBorder(),
          surfaceTintColor: theme.colorScheme.primary,
          elevation: 1,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: theme.colorScheme.primaryFixed),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Logo & Theme switcher
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),

                      // Logo
                      leading: const CircleAvatar(
                        backgroundImage: AssetImage('assets/content.png'),
                        radius: 30,
                      ),

                      // Theme Switcher Icon
                      trailing: ThemeSwitcher(
                        isDark: isDark,
                        onThemeChanged: (value) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ),

                    // App Name
                    Text('SysAdmin Tools', style: theme.textTheme.titleLarge),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  children: <Widget>[
                    // System section
                    buildDrawerHeading("System"),
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
                      Icons.manage_accounts_outlined,
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
                                connection: defaultConnection,
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
                      Icons.store_outlined,
                      'Package Manager',
                          () => Navigator.pushNamed(context, '/package-manager'),
                    ),
                    buildDrawerItem(
                      context,
                      Icons.terminal_outlined,
                      'Terminal',
                          () {
                        if (defaultConnection != null) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const TerminalScreen(),
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
                    const SizedBox(height: 14),


                    // Miscellaneous section
                    buildDrawerHeading("Miscellaneous"),
                    buildDrawerItem(context, Icons.schedule, 'Schedule Jobs', () {
                      if (defaultConnection != null) {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const ScheduleJobScreen(),
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
                    }),
                    buildDrawerItem(context, Icons.abc_rounded, 'Environmental Variables', () {
                      Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const EnvScreen())
                      );
                    }),
                    const SizedBox(height: 14),

                    // About section
                    buildDrawerHeading("More"),
                    buildDrawerItem(context, Icons.info_outline_rounded, "About us", () => debugPrint('Clicked About us')),
                    buildDrawerItem(context, Icons.contact_page_outlined, "Contact us", () => debugPrint('Clicked About us')),

                  ],
                ),
              ),
            ],
          ),
        ),
        error: (err, _) => Text('Error: $err'),
        loading: () => const Center(child: CircularProgressIndicator())
    );
  }
}
