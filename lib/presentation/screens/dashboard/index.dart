import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/index.dart';
import '../../../core/auth/widgets/auth_dialog.dart';
import '../../../core/widgets/blurred_text.dart';
import '../../../providers/ssh_state.dart';
import 'app_drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _connectionStatus = 'Connecting...';
  Color _statusColor = Colors.grey;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _showAuthenticationDialog();
  }

  void _showAuthenticationDialog() {
    if (!_isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,useRootNavigator: true,
          builder: (BuildContext context) {
            return PopScope(
                canPop: false,
                child: AuthenticationDialog(
                  onAuthenticationSuccess: () {
                    setState(() => _isAuthenticated = true);
                  },
                  onAuthenticationFailure: () => debugPrint("Local Auth Failed"),
                )
            );
          },
        );
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /*void _startSystemMonitoring() {
    // TODO: Implement periodic monitoring
    // This will be called once connection is established
    // Set up Timer.periodic to fetch system stats every second
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }*/

Future<void> _refreshConnection() async {
  await ref.read(sshConnectionsProvider.notifier).refreshConnections();
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultConnAsync = ref.watch(defaultConnectionProvider);
    final sshClientAsync = ref.watch(sshClientProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);

    connectionStatus.whenData((isConnected) {
      setState(() {
        _connectionStatus = isConnected ? 'Connected' : 'Disconnected';
        _statusColor = isConnected ? Colors.green : Colors.red;
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 1.0,
        backgroundColor: Colors.transparent,
      ),

      // TODO: fix: App Drawer will be shown only if SSH connection is established
      // drawer: AppDrawer(defaultConnection: defaultConnAsync.value, sshClient: sshClientAsync.value!),

      drawer: sshClientAsync.value != null
          ? AppDrawer(defaultConnection: defaultConnAsync.value, sshClient: sshClientAsync.value!)
          : null,

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

                          // If the default connection was changed then update defaultConnAsync.value
                          await _refreshConnection();
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
                  if (defaultConnAsync.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (defaultConnAsync.value != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Status Icon
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
                        BlurredText(
                          text: 'Name: ${defaultConnAsync.value!.name}',
                          isBlurred: !_isAuthenticated,
                        ),
                        BlurredText(
                          text: 'Username: ${defaultConnAsync.value!.username}',
                          isBlurred: !_isAuthenticated,
                        ),
                        BlurredText(
                          text: 'Socket: ${defaultConnAsync.value!.host}:${defaultConnAsync.value!.port}',
                          isBlurred: !_isAuthenticated,
                        ),
                      ],
                    )
                  else
                    const Text('No connection configured'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // TODO: Other dashboard widgets will go here


          ],
        ),
      ),
    );
  }
}
