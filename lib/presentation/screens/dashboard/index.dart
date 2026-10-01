import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/presentation/screens/dashboard/system_information_screen.dart';
import 'package:sysadmin/presentation/screens/dashboard/system_resource_detail_screen.dart';
import 'package:sysadmin/presentation/screens/dashboard/widgets/app_drawer.dart';
import 'package:sysadmin/presentation/screens/ssh_manager/index.dart';
import 'package:sysadmin/presentation/widgets/label.dart';
import 'package:sysadmin/presentation/widgets/overview_container.dart';

import '../../../core/auth/widgets/auth_dialog.dart';
import '../../../core/widgets/blurred_text.dart';
import '../../../providers/ssh_state.dart';
import '../../../providers/system_information_provider.dart';
import '../../../providers/system_resources_provider.dart';
import 'widgets/resource_usage_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final OptimizedSystemResourcesNotifier _resources;
  bool _isAuthenticated = false;
  late int connectionsCount = 0;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _resources = ref.read(optimizedSystemResourcesProvider.notifier);
    _handleUsageConditions();
    _init();
  }

  Future<void> getConnectionCount() async {
    final List<dynamic> connList = await ref.read(connectionManagerProvider).getAll();
    if (!mounted) return;
    setState(() => connectionsCount = connList.length);
  }

  Future<void> _init() async {
    await getConnectionCount();
    if (!mounted) return;
    if (connectionsCount > 0) {
      final bool authResult = await _handleAuth();
      if (!mounted) return;
      if (!authResult) {
        _showAuthenticationDialog();
      }
    }
    else {
      setState(() => _isAuthenticated = true);
    }
  }

  void _handleUsageConditions() {
    ref.listenManual<AsyncValue<SSHClient?>>(sshClientProvider, (
      previous,
      next,
    ) {
      final client = next.asData?.value;
      if (client != null && identical(previous?.asData?.value, client)) return;

      Future.microtask(() async {
        if (!mounted || !identical(ref.read(sshClientProvider), next)) return;
        final resources = ref.read(optimizedSystemResourcesProvider.notifier);
        if (client == null) {
          resources.stopMonitoring();
          resources.resetValues();
        } else {
          resources.startMonitoring();
          await ref
              .read(systemInformationProvider.notifier)
              .fetchSystemInformation();
        }
      });
    }, fireImmediately: true);

    ref.listenManual<AsyncValue<bool>>(connectionStatusProvider, (previous, next) {
      if (next.isLoading) return;
      Future.microtask(() {
        if (!mounted || !identical(ref.read(connectionStatusProvider), next)) return;
        final resources = ref.read(optimizedSystemResourcesProvider.notifier);
        final client = ref.read(sshClientProvider).asData?.value;
        if (next.asData?.value == true && client != null && !client.isClosed) {
          resources.startMonitoring();
        } else {
          resources.stopMonitoring();
          resources.resetValues();
        }
      });
    }, fireImmediately: true);
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
          ));

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
    if (_resources.mounted) _resources.stopMonitoring(resetState: false);
    super.dispose();
  }

  Future<void> _refreshConnection() async => await ref.read(sshConnectionsProvider.notifier).refreshConnections();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultConnAsync = ref.watch(defaultConnectionProvider);
    final sshClientAsync = ref.watch(sshClientProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final systemResources = ref.watch(optimizedSystemResourcesProvider);

    final client = sshClientAsync.asData?.value;
    final isConnected =
        client != null && connectionStatus.asData?.value == true;
    final isLoading = sshClientAsync.isLoading || connectionStatus.isLoading;
    final error =
        sshClientAsync.asError?.error ?? connectionStatus.asError?.error;
    final connectionStatusText = isConnected
        ? 'Connected'
        : isLoading
        ? 'Connecting...'
        : 'Disconnected';
    final statusColor = isConnected
        ? Colors.green
        : isLoading
        ? Colors.amber
        : theme.colorScheme.error;
    final connectionError = error?.toString().replaceAll('Exception: ', '');

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
                  final previousConnection = ref.read(sshClientProvider).value;
                  await Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => const SSHManagerScreen()),
                  );

                  // Check if the connection has changed
                  final newConnection = ref.read(sshClientProvider).value;
                  if (previousConnection != newConnection) {
                    await _refreshConnection();
                  }
                },
              ),
              children: <Widget>[
                // Connection Status Row
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connectionStatusText,
                      style: TextStyle(color: statusColor),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (connectionError != null) ...[
                    Text(connectionError),
                ]
                else if (defaultConnAsync.isLoading || connectionStatus.isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                ]
                else if (defaultConnAsync.value == null) ...[
                    const Text("No connection configured"),
                ]
                else if (connectionStatus.value == true) ...[
                    // Only show details when actually connected
                    const SizedBox(height: 8),
                    BlurredText(
                      text: 'Name: ${defaultConnAsync.value!.name}',
                      isBlurred: !_isAuthenticated,
                    ),
                    const SizedBox(height: 4),
                    BlurredText(
                      text: 'Username: ${defaultConnAsync.value!.username}',
                      isBlurred: !_isAuthenticated,
                    ),
                    const SizedBox(height: 4),
                    BlurredText(
                      text: 'Socket: ${defaultConnAsync.value!.host}:${defaultConnAsync.value!.port}',
                      isBlurred: !_isAuthenticated,
                    ),
                ]
                else if (sshClientAsync.isLoading) ...[
                    const Center(child: CircularProgressIndicator()),
                ]
                else ...[
                    const Text("Disconnected from server. Try refreshing the connection."),
                ]
              ],
            ),

            const SizedBox(height: 24),

            // System Information Container
            Consumer(
              builder: (context, ref, child) {
                final systemInfo = ref.watch(systemInformationProvider);

                return OverviewContainer(
                  title: "System Information",
                  label: Label(
                      label: "More",
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const SystemInformationScreen(),
                          ),
                        );
                      }
                  ),
                  children: <Widget>[
                    const SizedBox(height: 8),

                    // Model
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            "Model",
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            systemInfo.model ?? "NA",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Machine ID
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            "Machine ID",
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: BlurredText(
                            text: systemInfo.machineId ?? "NA",
                            isBlurred: !_isAuthenticated,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Uptime
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            "Uptime",
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            Util.formatTime(systemInfo.uptime ?? 0),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // System Usage Container
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
                      usedValue: systemResources.usedRam / 1024,
                      totalValue: systemResources.totalRam / 1024,
                      unit: 'GB',
                  ),

                  // Swap Usage
                  ResourceUsageCard(
                      title: 'SWAP',
                      usagePercentage: systemResources.swapUsage,
                      usedValue: systemResources.usedSwap / 1024,
                      totalValue: systemResources.totalSwap / 1024,
                      unit: 'GB'),
                ]
            ),

            const SizedBox(height: 24),

            // TODO: Implement other Widgets
          ],
        ),
      ),
    );
  }
}
