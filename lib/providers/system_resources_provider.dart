import 'dart:async';

import 'package:flutter/cupertino.dart';
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
    this.cpuCount = 0,    // Default to 1 CPU
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
class SystemResourcesNotifier extends StateNotifier<SystemResources> {
  final Ref ref;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  SystemResourcesNotifier(this.ref) : super(SystemResources()) {
    // Initial state is all zeros
  }

  void startMonitoring() {
    if (_refreshTimer != null) return;

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchResourceUsage();
    });
  }

  void stopMonitoring() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    state = SystemResources(); // Reset to zeros
  }

  void resetValues() {
    // Keeping the total values and CPU count as they are
    state = state.copyWith(
      cpuUsage: 0,
      ramUsage: 0,
      swapUsage: 0,
      usedRam: 0,
      usedSwap: 0,
    );
  }

  Future<void> _fetchResourceUsage() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final sshClientAsync = ref.read(sshClientProvider);
      final sshClient = sshClientAsync.value;

      if (sshClient == null) {
        _isRefreshing = false;
        return;
      }

      // Fetch CPU count only once if we don't have it yet
      int cpuCount = state.cpuCount;
      if (cpuCount <= 1) {
        final cpuCountResult = await sshClient.run('nproc');
        final cpuCountOutput = String.fromCharCodes(cpuCountResult).trim();
        cpuCount = int.tryParse(cpuCountOutput) ?? 1;
      }

      // Fetch CPU usage using top command
      final cpuResult = await sshClient.run('top -bn1 | grep "%Cpu(s)"');
      final cpuOutput = String.fromCharCodes(cpuResult);

      // Fetch memory usage using free command
      final memResult = await sshClient.run('free -m');
      final memOutput = String.fromCharCodes(memResult);

      // Parse CPU usage
      double cpuUsage = 0.0;
      if (cpuOutput.isNotEmpty) {
        final cpuMatch = RegExp(r'\d+\.\d+\s+id').firstMatch(cpuOutput);
        if (cpuMatch != null) {
          final idleStr = cpuMatch.group(0)?.split(' ').first;
          if (idleStr != null) {
            final idle = double.tryParse(idleStr) ?? 0.0;
            cpuUsage = 100.0 - idle;
          }
        }
      }

      // Parse RAM and Swap usage
      double totalRam = 0.0, usedRam = 0.0;
      double totalSwap = 0.0, usedSwap = 0.0;

      if (memOutput.isNotEmpty) {
        final lines = memOutput.split('\n');
        if (lines.length >= 2) {
          // Parse RAM
          final ramLine = lines[1].trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
          if (ramLine.length >= 3) {
            totalRam = double.tryParse(ramLine[1]) ?? 0.0;
            usedRam = double.tryParse(ramLine[2]) ?? 0.0;
          }

          // Parse Swap
          if (lines.length >= 3) {
            final swapLine = lines[2].trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
            if (swapLine.length >= 3) {
              totalSwap = double.tryParse(swapLine[1]) ?? 0.0;
              usedSwap = double.tryParse(swapLine[2]) ?? 0.0;
            }
          }
        }
      }

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
    }
    finally {
      _isRefreshing = false;
    }
  }
}

final systemResourcesProvider = StateNotifierProvider<SystemResourcesNotifier, SystemResources>((ref) {
  return SystemResourcesNotifier(ref);
});