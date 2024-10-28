import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sysadmin Dashboard'),
        actions: [
          _buildConnectionStatus(context),
        ],
      ),
      drawer: const AppDrawer(),
      body: GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            'System Monitor',
            Icons.monitor,
            'Monitor system resources',
                () => Navigator.pushNamed(context, '/system-monitor'),
          ),
          _buildDashboardCard(
            context,
            'Terminal',
            Icons.code,
            'Access system terminal',
                () => Navigator.pushNamed(context, '/terminal'),
          ),
          _buildDashboardCard(
            context,
            'SSH Manager',
            Icons.terminal,
            'Manage SSH connections',
                () => Navigator.pushNamed(context, '/ssh-manager'),
          ),
          _buildDashboardCard(
            context,
            'File Explorer',
            Icons.folder,
            'Browse file system',
                () => Navigator.pushNamed(context, '/file-explorer'),
          ),
          _buildDashboardCard(
            context,
            'Cron Jobs',
            Icons.schedule,
            'Manage scheduled tasks',
                () => Navigator.pushNamed(context, '/cron-jobs'),
          ),
          _buildDashboardCard(
            context,
            'Package Manager',
            Icons.archive,
            'Manage system packages',
                () => Navigator.pushNamed(context, '/package-manager'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    // This can be connected to your actual connection status
    bool isConnected = true;
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon,
      String description, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
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
                    'Sysadmin Tools',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                _buildDrawerItem(
                  context,
                  'System Monitor',
                  Icons.monitor,
                      () => Navigator.pushNamed(context, '/system-monitor'),
                ),
                _buildDrawerItem(
                  context,
                  'SSH Manager',
                  Icons.terminal,
                      () => Navigator.pushNamed(context, '/ssh-manager'),
                ),
                _buildDrawerItem(
                  context,
                  'File Explorer',
                  Icons.folder,
                      () => Navigator.pushNamed(context, '/file-explorer'),
                ),
                _buildDrawerItem(
                  context,
                  'Cron Jobs',
                  Icons.schedule,
                      () => Navigator.pushNamed(context, '/cron-jobs'),
                ),
                _buildDrawerItem(
                  context,
                  'Package Manager',
                  Icons.archive,
                      () => Navigator.pushNamed(context, '/package-manager'),
                ),
                _buildDrawerItem(
                  context,
                  'Terminal',
                  Icons.code,
                      () => Navigator.pushNamed(context, '/terminal'),
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  context,
                  'About Us',
                  Icons.info_outline,
                      () => Navigator.pushNamed(context, '/about'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(icon),
          title: Text(title),
          onTap: onTap,
          tileColor: Theme.of(context).colorScheme.secondaryContainer,
        ),
      ),
    );
  }
}