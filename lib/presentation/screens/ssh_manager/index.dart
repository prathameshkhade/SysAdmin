import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/add_connection_form.dart';
import '../../../data/models/ssh_connection.dart';
import '../../../data/services/connection_manager.dart';

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

  Future<void> loadConnections() async {
    try {
      List<SSHConnection> conn = await storage.getAll();
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
    return IosScaffold(
      title: "SSH Manager",
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: connections.isEmpty
            // If there is no connections
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
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
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 0.5,
                ),
                itemBuilder: (context, index) {
                  SSHConnection connection = connections[index];
                  return ListTile(
                    title: Text(
                      connection.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Text> [
                        Text(
                          '${connection.username}@${connection.host}:${connection.port}',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                        if (connection.isDefault)
                          Text(
                            'Default Connection',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Implement view details or quick connect
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
