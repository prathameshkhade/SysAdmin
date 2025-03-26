import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/add_connection_form.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:sysadmin/data/services/connection_manager.dart';
import 'package:sysadmin/presentation/widgets/lable.dart';
import '../../../providers/ssh_state.dart';
import 'modal_bottom_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SSHManagerScreen extends ConsumerStatefulWidget {
  const SSHManagerScreen({super.key});

  @override
  ConsumerState<SSHManagerScreen> createState() => _SSHManagerScreenState();
}

class _SSHManagerScreenState extends ConsumerState<SSHManagerScreen> {
  List<SSHConnection> connections = [];
  final ConnectionManager storage = ConnectionManager();

  @override
  void initState() {
    super.initState();
  }

  void _handleConnectionUpdate(SSHConnection updatedConnection) async {
    await loadConnections();
  }

  Future<void> loadConnections() async {
    await ref.read(sshConnectionsProvider.notifier).refreshConnections();
  }

  Future<void> _onRefresh() async {
    await loadConnections();
  }

  Future<void> _handleEdit(BuildContext context, SSHConnection connection) async {
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
    if (result == true && mounted) {
      await loadConnections();
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String connectionName) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Are you sure you want to delete $connectionName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, SSHConnection connection) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final bool? confirm = await _showDeleteConfirmationDialog(context, connection.name);

    if (!mounted) return;

    if (confirm == true) {
      try {
        await ref.read(sshConnectionsProvider.notifier).deleteConnection(connection.name);
        if (!mounted) return;

        navigator.pop();
      } catch (e) {
        if (!mounted) return;

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to delete connection. Please try again.'),
          ),
        );
      }
    }
  }

  void showConnectionDetails(BuildContext context, SSHConnection connection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) => SSHConnectionDetailsSheet(
        connection: connection,
        onEdit: () => _handleEdit(bottomSheetContext, connection),
        onDelete: () => _handleDelete(bottomSheetContext, connection),
        onConnectionUpdated: (conn) async {
          // Update default connection
          if (conn.isDefault) {
            await ref.read(sshConnectionsProvider.notifier).setDefaultConnection(conn.name);
          }
          _handleConnectionUpdate(conn);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectionsAsync = ref.watch(sshConnectionsProvider);

    return IosScaffold(
      title: "SSH Manager",
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: connectionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading connections: ${error.toString()}'),
          ),
          data: (connections) {
            if (connections.isEmpty) {
              return ListView(
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
              );
            }

            return ListView.separated(
              itemCount: connections.length,
              separatorBuilder: (context, index) => Divider(
                color: theme.primaryColorLight,
                height: 1,
                thickness: 0.1,
              ),
              itemBuilder: (context, index) {
                SSHConnection connection = connections[index];
                return ListTile(
                  leading: Icon(
                      Icons.laptop_mac_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 30.0
                  ),
                  title: Text(
                    connection.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${connection.username}@${connection.host}:${connection.port}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),

                      if (connection.isDefault)
                        Label(label: "Default", fontSize: 12, onTap: (){})
                    ],
                  ),

                  onTap: () => showConnectionDetails(context, connection),
                );
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
          if (result == true && mounted) {
            await loadConnections();
          }
        },
        tooltip: "Add Connection",
        elevation: 4.0,
        child: const Icon(Icons.add),
      ),
    );
  }
}
