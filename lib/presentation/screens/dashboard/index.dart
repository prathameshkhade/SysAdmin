import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Text(
          "Dashboard",
          style: theme.textTheme.displaySmall,
        ),
      ),
    );
  }

}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SysAdmin Tools',
                    style: theme.textTheme.titleLarge
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: <Widget> [
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                //   child: Text("System Management", style: theme.textTheme.labelLarge?.copyWith(color: theme.primaryColor)),
                // ),
                _buildDrawerItem(context, Icons.monitor_rounded, 'System Monitor', () => Navigator.pushNamed(context, '/system-monitor'),),
                _buildDrawerItem(context, Icons.person_outline_rounded, 'Users & Groups', () => Navigator.pushNamed(context, '/system-monitor'),),
                _buildDrawerItem(context, Icons.manage_accounts_rounded, 'SSH Manager', () => Navigator.pushNamed(context, '/ssh-manager'),),
                _buildDrawerItem(context, Icons.folder_open_rounded, 'File Explorer', () => Navigator.pushNamed(context, '/file-explorer'),),
                _buildDrawerItem(context, Icons.schedule, 'Cron Jobs', () => Navigator.pushNamed(context, '/cron-jobs'),),
                _buildDrawerItem(context, Icons.store_rounded, 'Package Manager', () => Navigator.pushNamed(context, '/package-manager'),),
                _buildDrawerItem(context, Icons.terminal_rounded, 'Terminal', () => Navigator.pushNamed(context, '/package-manager'),),
                const Divider(thickness: 0.25),
                _buildDrawerItem(context, Icons.info_outline_rounded, 'About Us', () => Navigator.pushNamed(context, '/about'),),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      horizontalTitleGap: 25,
      titleAlignment: ListTileTitleAlignment.center,
      leading: Icon(icon, color: Theme.of(context).primaryColorLight, size: 28, weight: 0.1,),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15)),
      onTap: onTap,
    );
  }
}
