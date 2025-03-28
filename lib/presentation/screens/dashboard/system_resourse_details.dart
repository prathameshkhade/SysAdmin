import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:sysadmin/providers/system_resources_provider.dart';

class SystemResourceDetailsScreen extends ConsumerStatefulWidget {
  const SystemResourceDetailsScreen({super.key});

  @override
  ConsumerState<SystemResourceDetailsScreen> createState() => _SystemResourceDetailsScreenState();
}

class _SystemResourceDetailsScreenState extends ConsumerState<SystemResourceDetailsScreen> {
  // Simulated historical data lists for sparkline charts
  final List<double> _cpuHistory = [];
  final List<double> _memoryHistory = [];
  final List<double> _swapHistory = [];

  @override
  void initState() {
    super.initState();
    // Initialize with some dummy data or start tracking
    _initializeHistoricalData();
  }

  void _initializeHistoricalData() {
    // In a real app, you'd want to implement a more robust historical tracking mechanism
    for (int i = 0; i < 20; i++) {
      _cpuHistory.add(0);
      _memoryHistory.add(0);
      _swapHistory.add(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final systemResources = ref.watch(systemResourcesProvider);
    final theme = Theme.of(context);

    // Update historical data (simple implementation)
    _cpuHistory.removeAt(0);
    _cpuHistory.add(systemResources.cpuUsage);
    _memoryHistory.removeAt(0);
    _memoryHistory.add(systemResources.ramUsage);
    _swapHistory.removeAt(0);
    _swapHistory.add(systemResources.swapUsage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Resources Details'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resource Usage Charts Section
          _buildResourceChartsSection(theme, systemResources),

          const SizedBox(height: 24),

          // Top Services Section
          _buildTopServicesSection(theme),
        ],
      ),
    );
  }

  Widget _buildResourceChartsSection(ThemeData theme, SystemResources systemResources) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resource Usage',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // CPU Usage Chart
          _buildResourceChart(
            title: 'CPU Usage',
            subtitle: '${systemResources.cpuUsage.toStringAsFixed(2)}%',
            data: _cpuHistory,
            color: Colors.blue,
          ),

          // Memory Usage Chart
          _buildResourceChart(
            title: 'Memory Usage',
            subtitle: '${systemResources.ramUsage.toStringAsFixed(2)}%',
            data: _memoryHistory,
            color: Colors.green,
          ),

          // Swap Usage Chart
          _buildResourceChart(
            title: 'Swap Usage',
            subtitle: '${systemResources.swapUsage.toStringAsFixed(2)}%',
            data: _swapHistory,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChart({
    required String title,
    required String subtitle,
    required List<double> data,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(subtitle),
          ],
        ),
        const SizedBox(height: 8),
        SfSparkLineChart(
          data: data,
          color: color,
          width: 2,
          marker: const SparkChartMarker(
            displayMode: SparkChartMarkerDisplayMode.none,
          ),
          trackball: const SparkChartTrackball(
            backgroundColor: Colors.white,
            activationMode: SparkChartActivationMode.tap,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTopServicesSection(ThemeData theme) {
    // TODO: Implement actual top services fetching logic
    final topServices = [
      {'name': 'Chrome', 'cpu': 25.5, 'memory': 1.2, 'swap': 0.1},
      {'name': 'VSCode', 'cpu': 15.3, 'memory': 0.8, 'swap': 0.05},
      {'name': 'Docker', 'cpu': 10.2, 'memory': 0.6, 'swap': 0.3},
      {'name': 'Slack', 'cpu': 5.1, 'memory': 0.4, 'swap': 0.02},
      {'name': 'System', 'cpu': 4.7, 'memory': 0.3, 'swap': 0.1},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 Services',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                children: [
                  _tableHeader('Service'),
                  _tableHeader('CPU %'),
                  _tableHeader('Memory %'),
                  _tableHeader('Swap %'),
                ],
              ),
              ...topServices.map((service) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(service['name'] as String),
                  ),
                  Text('${service['cpu']}%'),
                  Text('${service['memory']}%'),
                  Text('${service['swap']}%'),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}