import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:sysadmin/data/services/connection_manager.dart';
import 'package:sysadmin/presentation/screens/dashboard/app_drawer.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/index.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ConnectionManager _connectionManager = ConnectionManager();
  SSHConnection? _defaultConnection;
  SSHClient? _sshClient;
  bool _isLoading = true;
  String _connectionStatus = 'Connecting...';
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  @override
  void dispose() {
    _disconnectSSH();
    super.dispose();
  }

  Future<void> _initializeConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Connecting...';
      _statusColor = Colors.grey;
    });

    try {
      final connection = await _connectionManager.getDefaultConnection();
      setState(() => _defaultConnection = connection);

      if (connection != null) {
        await _connectSSH(connection);
      } else {
        setState(() {
          _connectionStatus = 'No default connection';
          _statusColor = Colors.orange;
        });
      }
    }
    catch (e) {
      _showError('Failed to get default connection: $e');
    }
    finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectSSH(SSHConnection connection) async {
    try {
      late final SSHClient client;

      if (connection.privateKey != null) {
        // Handle private key authentication
        client = SSHClient(
          await SSHSocket.connect(connection.host, connection.port),
          username: connection.username,
          identities: SSHKeyPair.fromPem(connection.privateKey!),
        );
      }
      else {
        // Handle password authentication
        client = SSHClient(
          await SSHSocket.connect(connection.host, connection.port),
          username: connection.username,
          onPasswordRequest: () => connection.password ?? '',
        );
      }

      await client.authenticated;

      setState(() {
        _sshClient = client;
        _connectionStatus = 'Connected';
        _statusColor = Colors.green;
      });

      // Start periodic system monitoring
      _startSystemMonitoring();
    }
    catch (e) {
      _showError('Connection failed: $e');
      setState(() {
        _connectionStatus = 'Connection failed';
        _statusColor = Colors.red;
      });
    }
  }

  void _startSystemMonitoring() {
    // TODO: Implement periodic monitoring
    // This will be called once connection is established
    // Set up Timer.periodic to fetch system stats every second
  }

  Future<void> _disconnectSSH() async {
    _sshClient?.close();
    _sshClient = null;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _refreshConnection() async {
    await _disconnectSSH();
    await _initializeConnection();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 1.0,
        backgroundColor: Colors.transparent,
      ),

      drawer: const AppDrawer(),

      body: RefreshIndicator(
        onRefresh: () => _refreshConnection(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Connection Details
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(color: theme.colorScheme.outline, width: 0.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget> [
                      Text("Connection Details", style: theme.textTheme.bodyLarge),

                      // Manage Button
                      InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (context) => const SSHManagerScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Manage',
                            style: TextStyle(color: theme.primaryColor, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Connection Status and Details
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_defaultConnection != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _connectionStatus,
                              style: TextStyle(color: _statusColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Name: ${_defaultConnection!.name}'),
                        Text('Host: ${_defaultConnection!.host}'),
                        Text('Port: ${_defaultConnection!.port}'),
                      ],
                    )
                  else
                    const Text('No connection configured'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Other dashboard widgets will go here


          ],
        ),
      ),
    );
  }
}
