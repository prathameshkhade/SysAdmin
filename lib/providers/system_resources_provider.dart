import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/providers/ssh_state.dart';

class SystemResources {
  final double cpuUsage;
  final double ramUsage;
  final double swapUsage;
  final double totalRam;  // in MB
  final double totalSwap; // in MB
  final double usedRam;   // in MB
  final double usedSwap;  // in MB
  final int cpuCount;     // Number of CPUs

  SystemResources({
    this.cpuUsage = 0.0,
    this.ramUsage = 0.0,
    this.swapUsage = 0.0,
    this.totalRam = 0.0,
    this.totalSwap = 0.0,
    this.usedRam = 0.0,
    this.usedSwap = 0.0,
    this.cpuCount = 0,
  });

  SystemResources copyWith({
    double? cpuUsage,
    double? ramUsage,
    double? swapUsage,
    double? totalRam,
    double? totalSwap,
    double? usedRam,
    double? usedSwap,
    int? cpuCount,
  }) {
    return SystemResources(
      cpuUsage: cpuUsage ?? this.cpuUsage,
      ramUsage: ramUsage ?? this.ramUsage,
      swapUsage: swapUsage ?? this.swapUsage,
      totalRam: totalRam ?? this.totalRam,
      totalSwap: totalSwap ?? this.totalSwap,
      usedRam: usedRam ?? this.usedRam,
      usedSwap: usedSwap ?? this.usedSwap,
      cpuCount: cpuCount ?? this.cpuCount,
    );
  }
}

class OptimizedSystemResourcesNotifier extends StateNotifier<SystemResources> {
  final Ref ref;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  // Cache for previous CPU stats to calculate usage
  List<int>? _prevCpuStats;

  OptimizedSystemResourcesNotifier(this.ref) : super(SystemResources()) {
    // Initial state is all zeros
  }

  void startMonitoring() {
    if (_refreshTimer != null) return;

    _refreshTimer = Timer.periodic(
        const Duration(seconds: 1),
            (_) async => await _fetchResourceUsage()
    );
  }

  void stopMonitoring() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _prevCpuStats = null;
    state = SystemResources(); // Reset to zeros
  }

  void resetValues() {
    // Reset all usage values while preserving system information
    state = SystemResources(
      cpuUsage: 0.0,
      ramUsage: 0.0,
      swapUsage: 0.0,
      usedRam: 0.0,
      usedSwap: 0.0,
      totalRam: state.totalRam,
      totalSwap: state.totalSwap,
      cpuCount: state.cpuCount,
    );
  }

  void restart() {
    stopMonitoring();
    resetValues();
    startMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchResourceUsage() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final sessionManager = ref.read(sshSessionManagerProvider);

      // Fetch CPU count only once if we don't have it yet
      int cpuCount = state.cpuCount;
      if (cpuCount <= 1) {
        // Read directly from /proc/cpuinfo
        final cpuInfoResult = await sessionManager.execute('cat /proc/cpuinfo | grep -c processor');
        cpuCount = int.tryParse(cpuInfoResult.trim()) ?? 1;
      }

      // Read CPU stats directly from /proc/stat
      final cpuStatResult = await sessionManager.execute('cat /proc/stat | head -1');

      // Read memory info directly from /proc/meminfo
      final memInfoResult = await sessionManager.execute('cat /proc/meminfo');

      // Parse CPU usage
      double cpuUsage = 0.0;
      if (cpuStatResult.isNotEmpty) {
        // Format: cpu user nice system idle iowait irq softirq steal guest guest_nice
        final parts = cpuStatResult.trim().split(RegExp(r'\s+'));
        if (parts.length > 4) {
          final user = int.tryParse(parts[1]) ?? 0;
          final nice = int.tryParse(parts[2]) ?? 0;
          final system = int.tryParse(parts[3]) ?? 0;
          final idle = int.tryParse(parts[4]) ?? 0;
          final iowait = parts.length > 5 ? (int.tryParse(parts[5]) ?? 0) : 0;
          final irq = parts.length > 6 ? (int.tryParse(parts[6]) ?? 0) : 0;
          final softirq = parts.length > 7 ? (int.tryParse(parts[7]) ?? 0) : 0;
          final steal = parts.length > 8 ? (int.tryParse(parts[8]) ?? 0) : 0;

          final currentStats = [user, nice, system, idle, iowait, irq, softirq, steal];

          if (_prevCpuStats != null) {
            int idleDelta = idle - _prevCpuStats![3];
            if (parts.length > 5) {
              idleDelta += iowait - _prevCpuStats![4];
            }

            int totalDelta = 0;
            for (int i = 0; i < currentStats.length; i++) {
              if (i < _prevCpuStats!.length) {
                totalDelta += currentStats[i] - _prevCpuStats![i];
              }
            }

            if (totalDelta > 0) {
              cpuUsage = 100.0 * (1.0 - idleDelta / totalDelta);
            }
          }

          _prevCpuStats = currentStats;
        }
      }

      // Parse RAM and Swap usage
      double totalRam = 0.0, freeRam = 0.0, availableRam = 0.0;
      double totalSwap = 0.0, freeSwap = 0.0;

      if (memInfoResult.isNotEmpty) {
        final lines = memInfoResult.split('\n');
        for (final line in lines) {
          if (line.startsWith('MemTotal:')) {
            totalRam = _parseMemInfoValue(line) / 1024.0; // Convert to MB
          }
          else if (line.startsWith('MemFree:')) {
            freeRam = _parseMemInfoValue(line) / 1024.0;
          }
          else if (line.startsWith('MemAvailable:')) {
            availableRam = _parseMemInfoValue(line) / 1024.0;
          }
          else if (line.startsWith('SwapTotal:')) {
            totalSwap = _parseMemInfoValue(line) / 1024.0;
          }
          else if (line.startsWith('SwapFree:')) {
            freeSwap = _parseMemInfoValue(line) / 1024.0;
          }
        }
      }

      // Calculate used RAM (prefer MemAvailable if present)
      double usedRam = 0.0;
      if (availableRam > 0) {
        usedRam = totalRam - availableRam;
      }
      else {
        usedRam = totalRam - freeRam;
      }

      double usedSwap = totalSwap - freeSwap;

      // Calculate percentages
      final ramUsage = totalRam > 0 ? (usedRam / totalRam) * 100 : 0.0;
      final swapUsage = totalSwap > 0 ? (usedSwap / totalSwap) * 100 : 0.0;

      // Update state
      state = state.copyWith(
        cpuUsage: cpuUsage,
        ramUsage: ramUsage,
        swapUsage: swapUsage,
        totalRam: totalRam,
        totalSwap: totalSwap,
        usedRam: usedRam,
        usedSwap: usedSwap,
        cpuCount: cpuCount,
      );
    }
    catch (e) {
      debugPrint('Error fetching system resources: $e');
      // Do not update state on error to maintain previous values
    }
    finally {
      _isRefreshing = false;
    }
  }

  double _parseMemInfoValue(String line) {
    final match = RegExp(r':\s*(\d+)').firstMatch(line);
    if (match != null && match.group(1) != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }
}

final optimizedSystemResourcesProvider = StateNotifierProvider<OptimizedSystemResourcesNotifier, SystemResources>((ref) {
  return OptimizedSystemResourcesNotifier(ref);
});