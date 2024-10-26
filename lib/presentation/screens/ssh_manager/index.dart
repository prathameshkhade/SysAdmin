import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/add_connection_form.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:sysadmin/data/services/connection_manager.dart';
import 'modal_bottom_sheet.dart';

class SSHManagerScreen extends StatefulWidget {
  const SSHManagerScreen({super.key});

  @override
  State<SSHManagerScreen> createState() => _SSHManagerScreenState();
}

class _SSHManagerScreenState extends State<SSHManagerScreen> {
  List<SSHConnection> connections = [];
  final ConnectionManager storage = ConnectionManager();

  @override
  void initState() {
    super.initState();
    loadConnections();
  }

  // Add method to handle connection updates
  void _handleConnectionUpdate(SSHConnection updatedConnection) async {
    await loadConnections(); // Reload the connections list
  }

  Future<void> loadConnections() async {
    try {
      List<SSHConnection> conn = await storage.getAll();

      // Handle single connection case
      if (conn.length == 1 && !conn[0].isDefault) {
        await storage.setDefaultConnection(conn[0].name);
        conn = await storage.getAll(); // Reload to get updated connection
      }

      if (mounted) {
        setState(() {
          connections = conn;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load connections. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Error loading connections: $e');
    }
  }

  Future<void> _onRefresh() async {
    await loadConnections();
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    // Bottom sheet
    void showConnectionDetails(SSHConnection connection) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SSHConnectionDetailsSheet(
          connection: connection,
          onEdit: () async {
            Navigator.pop(context);
            final result = await Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => AddConnectionForm(
                  connection: connection,
                  originalName: connection.name,
                ),
              ),
            );
            if (result == true) {
              loadConnections();
            }
          },
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Connection'),
                content: Text('Are you sure you want to delete ${connection.name}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('DELETE'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await storage.delete(connection.name);
              if (mounted) {
                Navigator.pop(context);
                loadConnections();
              }
            }
          },
          onConnectionUpdated: _handleConnectionUpdate, // Add the new callback
        ),
      );
    }

    return IosScaffold(
      title: "SSH Manager",
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: connections.isEmpty
            // If there is no connections
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Center(
                    heightFactor: 15.0,
                    child: Text(
                      'No connections yet.\nPull down to refresh or add a new connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              )

            // View for the Connections
            : ListView.separated(
                itemCount: connections.length,
                separatorBuilder: (context, index) => Divider(
                  color: theme.primaryColorLight,
                  height: 1,
                  thickness: 0.1,
                ),
                itemBuilder: (context, index) {
                  SSHConnection connection = connections[index];
                  return ListTile(
                    leading: Icon(Icons.laptop_mac_rounded, color: Theme.of(context).primaryColor, size: 30.0),
                    title: Text(
                      connection.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget> [
                        Text(
                          '${connection.username}@${connection.host}:${connection.port}',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                        if (connection.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Default', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Calls the ShowBottomSheet() to show details of connections
                      showConnectionDetails(connection);
                    },
                  );
                },
              ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const AddConnectionForm(),
            ),
          );
          if (result == true) {
            loadConnections(); // Refresh the list after adding a new connection
          }
        },
        tooltip: "Add Connection",
        elevation: 4.0,
        child: const Icon(Icons.add),
      ),

    );
  }
}
