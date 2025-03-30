import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sysadmin/presentation/screens/dashboard/system_resource_details.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/index.dart';
import 'package:sysadmin/presentation/widgets/label.dart';
import 'package:sysadmin/presentation/widgets/overview_container.dart';

import '../../../core/auth/widgets/auth_dialog.dart';
import '../../../core/widgets/blurred_text.dart';
import '../../../providers/ssh_state.dart';
import '../../../providers/system_resources_provider.dart';
import 'app_drawer.dart';
import 'resource_usage_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _connectionStatus = 'Connecting...';
  Color _statusColor = Colors.grey;
  bool _isAuthenticated = false;
  late int connectionsCount = 0;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check connection status to start/stop monitoring
    final connectionStatus = ref.read(connectionStatusProvider);
    connectionStatus.whenData((isConnected) {
      if (isConnected) {
        ref.read(systemResourcesProvider.notifier).startMonitoring();
      }
      else {
        ref.read(systemResourcesProvider.notifier).stopMonitoring();
      }
    });
  }

  Future<void> getConnectionCount() async {
    final List<dynamic> connList = await ref.read(connectionManagerProvider).getAll();
    setState(() => connectionsCount = connList.length);
  }

  Future<void> _init() async {
    await getConnectionCount();
    if (connectionsCount > 0) {
      final bool authResult = await _handleAuth();
      if (!authResult) {
        _showAuthenticationDialog();
      }
    }
    else {
      setState(() => _isAuthenticated = true);
    }
  }

  Future<bool> _handleAuth() async {
    try {
      final bool canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() => _isAuthenticated = true);
        return true;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Enter phone screen lock pattern, PIN, password or fingerprint',
          options: const AuthenticationOptions(
            biometricOnly: false,
            useErrorDialogs: true,
            sensitiveTransaction: true,
            stickyAuth: true,
          )
      );

      setState(() => _isAuthenticated = didAuthenticate);
      return didAuthenticate;
    }
    catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  void _showAuthenticationDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
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

  @override
  void dispose() {
    ref.read(systemResourcesProvider.notifier).stopMonitoring();
    super.dispose();
  }

  Future<void> _refreshConnection() async => await ref.read(sshConnectionsProvider.notifier).refreshConnections();

  @override
  Widget build(BuildContext context) {
    final defaultConnAsync = ref.watch(defaultConnectionProvider);
    final sshClientAsync = ref.watch(sshClientProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final systemResources = ref.watch(systemResourcesProvider);

    connectionStatus.whenData((isConnected) {
      setState(() {
        _connectionStatus = isConnected ? 'Connected' : 'Disconnected';
        _statusColor = isConnected ? Colors.green : Colors.red;
      });

      // Start or stop monitoring based on connection status
      if (isConnected) {
        ref.read(systemResourcesProvider.notifier).startMonitoring();
      }
      else {
        ref.read(systemResourcesProvider.notifier).stopMonitoring();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 1.0,
        backgroundColor: Colors.transparent,
      ),

      drawer: sshClientAsync.value != null
          ? AppDrawer(defaultConnection: defaultConnAsync.value, sshClient: sshClientAsync.value!)
          : null,

      body: RefreshIndicator(
        onRefresh: () => _refreshConnection(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Connection Details Container
            OverviewContainer(
              title: "Connection Details",
              label: Label(
                label: "Manage",
                onTap: () async {
                  await Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => const SSHManagerScreen()),
                  );
                  await _refreshConnection();
                },
              ),
              children: <Widget>[
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
            ),

            const SizedBox(height: 24),

            // System Resources Container
            OverviewContainer(
                title: "System Usage",
                label: Label(
                    label: "Details",
                    onTap: () {
                      // TODO: Implement the System Monitor Screen and link it here and in AppDrawer
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const SystemResourceDetailsScreen(),
                        ),
                      );
                    }
                ),
                children: <Widget>[
                  const SizedBox(height: 16),

                  // CPU Usage
                  ResourceUsageCard(
                    title: 'CPU',
                    usagePercentage: systemResources.cpuUsage,
                    usedValue: systemResources.cpuUsage,
                    totalValue: 100,
                    unit: '%',
                    isCpu: true,
                    cpuCount: systemResources.cpuCount,
                  ),

                  // RAM Usage
                  ResourceUsageCard(
                    title: 'RAM',
                    usagePercentage: systemResources.ramUsage,
                    usedValue: systemResources.usedRam/1024,
                    totalValue: systemResources.totalRam/1024,
                    unit: 'GiB',
                  ),

                  // Swap Usage
                  ResourceUsageCard(
                      title: 'Swap',
                      usagePercentage: systemResources.swapUsage,
                      usedValue: systemResources.usedSwap/1024,
                      totalValue: systemResources.totalSwap/1024,
                      unit: 'GiB'),
                ]
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
