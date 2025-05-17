import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/providers/process_monitor_provider.dart';
import 'package:sysadmin/providers/system_resources_provider.dart';

class SystemResourceDetailsScreen extends ConsumerStatefulWidget {
  const SystemResourceDetailsScreen({super.key});

  @override
  ConsumerState<SystemResourceDetailsScreen> createState() => _SystemResourceDetailsScreenState();
}

class _SystemResourceDetailsScreenState extends ConsumerState<SystemResourceDetailsScreen>
    with AutomaticKeepAliveClientMixin {
  // Historical data lists for live charts
  final List<ResourceDataPoint> _cpuHistory = [];
  final List<ResourceDataPoint> _memoryHistory = [];
  final List<ResourceDataPoint> _swapHistory = [];

  // Maximum number of data points to display
  final int _maxDataPoints = 60; // 1 minute of data at 1 second intervals

  // Chart controllers for forcing updates
  late TrackballBehavior _trackballBehavior;

  // Timer for periodic UI updates
  Timer? _chartUpdateTimer;
  bool _mounted = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
      lineType: TrackballLineType.vertical,
    );

    _initializeHistoricalData();

    // Start process monitoring
    ref.read(processMonitorProvider.notifier).startMonitoring();

    // Set up a timer to specifically update the UI every second
    _chartUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_mounted) {
        setState(() {
          // Just trigger a rebuild to update charts
        });
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _chartUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeHistoricalData() {
    final now = DateTime.now();
    for (int i = _maxDataPoints; i > 0; i--) {
      final time = now.subtract(Duration(seconds: i));
      _cpuHistory.add(ResourceDataPoint(time, 0));
      _memoryHistory.add(ResourceDataPoint(time, 0));
      _swapHistory.add(ResourceDataPoint(time, 0));
    }
  }

  void _updateHistoricalData(SystemResources resources) {
    final now = DateTime.now();

    // Update CPU history
    if (_cpuHistory.length >= _maxDataPoints) {
      _cpuHistory.removeAt(0);
    }
    _cpuHistory.add(ResourceDataPoint(now, resources.cpuUsage));

    // Update Memory history
    if (_memoryHistory.length >= _maxDataPoints) {
      _memoryHistory.removeAt(0);
    }
    _memoryHistory.add(ResourceDataPoint(now, resources.ramUsage));

    // Update Swap history
    if (_swapHistory.length >= _maxDataPoints) {
      _swapHistory.removeAt(0);
    }
    _swapHistory.add(ResourceDataPoint(now, resources.swapUsage));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final systemResources = ref.watch(systemResourcesProvider);
    final processes = ref.watch(processMonitorProvider);
    final theme = Theme.of(context);

    // Update historical data
    _updateHistoricalData(systemResources);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Resources Details'),
        elevation: 1.0,
      ),
      body: ListView(
        key: const PageStorageKey('system_resource_details'),
        padding: const EdgeInsets.all(16),
        children: [
          // CPU Section
          _buildResourceSection(
            title: 'CPU Usage',
            value: '${systemResources.cpuUsage.toStringAsFixed(1)}%',
            chartData: _cpuHistory,
            color: Colors.blue,
            processes: processes.cpuProcesses,
            resourceType: 'CPU',
            theme: theme,
          ),

          const SizedBox(height: 24),

          // RAM Section
          _buildResourceSection(
            title: 'Memory Usage',
            value:
                '${systemResources.ramUsage.toStringAsFixed(1)}% (${(systemResources.usedRam / 1024).toStringAsFixed(1)}GB / ${(systemResources.totalRam / 1024).toStringAsFixed(1)}GB)',
            chartData: _memoryHistory,
            color: Colors.green,
            processes: processes.memoryProcesses,
            resourceType: 'Memory',
            theme: theme,
          ),

          const SizedBox(height: 24),

          // Swap Section
          _buildResourceSection(
            title: 'Swap Usage',
            value:
                '${systemResources.swapUsage.toStringAsFixed(1)}% (${(systemResources.usedSwap / 1024).toStringAsFixed(1)}GB / ${(systemResources.totalSwap / 1024).toStringAsFixed(1)}GB)',
            chartData: _swapHistory,
            color: Colors.purpleAccent,
            processes: processes.swapProcesses,
            resourceType: 'Swap',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceSection({
    required String title,
    required String value,
    required List<ResourceDataPoint> chartData,
    required Color color,
    required List<ProcessInfo> processes,
    required String resourceType,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.useOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Live Chart
          SizedBox(
            height: 150,
            child: _buildLiveChart(chartData, color, resourceType),
          ),

          const SizedBox(height: 32),

          // Top Processes Title
          Text(
            'Top 5 Processes by $resourceType',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),

          // Top Processes Table
          _buildProcessTable(processes, resourceType, theme),
        ],
      ),
    );
  }

  Widget _buildLiveChart(List<ResourceDataPoint> data, Color color, String resourceType) {
    final now = DateTime.now();
    final firstTime = now.subtract(const Duration(seconds: 15));

    return SfCartesianChart(
      key: ValueKey('${resourceType}_chart_${DateTime.now().millisecondsSinceEpoch}'),
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0.5),
        labelStyle: const TextStyle(fontSize: 9),
        dateFormat: DateFormat.ms(),
        intervalType: DateTimeIntervalType.seconds,
        interval: 5,
        minimum: firstTime,
        maximum: now,
      ),
      primaryYAxis: const NumericAxis(
        minimum: 0,
        maximum: 100,
        interval: 25,
        axisLine: AxisLine(width: 0.5),
        majorTickLines: MajorTickLines(size: 4),
        labelFormat: '{value}%',
        labelStyle: TextStyle(fontSize: 10),
      ),
      series: <CartesianSeries<dynamic, dynamic>>[
        SplineAreaSeries<ResourceDataPoint, DateTime>(
          dataSource: data,
          xValueMapper: (ResourceDataPoint point, _) => point.time,
          yValueMapper: (ResourceDataPoint point, _) => point.value,
          enableTooltip: true,
          animationDuration: 0,
          color: color.useOpacity(0.3),
          borderWidth: 0,
        ),
        SplineSeries<ResourceDataPoint, DateTime>(
          dataSource: data,
          xValueMapper: (ResourceDataPoint point, _) => point.time,
          yValueMapper: (ResourceDataPoint point, _) => point.value,
          enableTooltip: true,
          animationDuration: 0,
          color: color,
          width: 2,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 4,
            width: 4,
            shape: DataMarkerType.circle,
            borderWidth: 0,
            color: color,
          ),
          emptyPointSettings: EmptyPointSettings(
            mode: EmptyPointMode.average,
            color: color,
          ),
        ),
      ],
      trackballBehavior: _trackballBehavior,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.y%',
        color: Theme.of(context).colorScheme.surface,
        textStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProcessTable(List<ProcessInfo> processes, String resourceType, ThemeData theme) {
    if (processes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Column(
          children: [
            const SizedBox(height: 8),
            const CircularProgressIndicator(strokeWidth: 2.0),
            const SizedBox(height: 8),
            Text(
              'Loading process data...',
              style: TextStyle(color: theme.colorScheme.onSurface.useOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5), // Process name
        1: FlexColumnWidth(1), // PID
        2: FlexColumnWidth(1), // Usage value
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          children: [
            _tableHeader('Process', theme),
            _tableHeader('PID', theme),
            _tableHeader(resourceType == 'CPU' ? 'CPU %' : 'Memory MB', theme),
          ],
        ),
        ...processes.map((process) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  process.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Text(process.pid.toString(), style: const TextStyle(fontSize: 13)),
              Text(
                resourceType == 'CPU'
                    ? '${process.cpuPercent.toStringAsFixed(1)}%'
                    : (resourceType == 'Memory'
                        ? '${process.memoryMB.toStringAsFixed(1)} MB'
                        : '${process.swapMB.toStringAsFixed(1)} MB'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _getColorBasedOnUsage(
                      resourceType == 'CPU'
                          ? process.cpuPercent
                          : (resourceType == 'Memory' ? process.memoryMB : process.swapMB),
                      resourceType),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _tableHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: theme.colorScheme.onSurface.useOpacity(0.8),
        ),
      ),
    );
  }

  Color _getColorBasedOnUsage(double value, String type) {
    if (type == 'CPU') {
      if (value > 80) return Colors.red;
      if (value > 50) return Theme.of(context).primaryColor;
      return Colors.green;
    } else {
      // For memory usage
      if (value > 1000) return Colors.red;
      if (value > 500) return Theme.of(context).primaryColor;
      return Colors.green;
    }
  }
}

// Data point class for the chart
class ResourceDataPoint {
  final DateTime time;
  final double value;

  ResourceDataPoint(this.time, this.value);
}
