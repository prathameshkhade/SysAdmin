import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/providers/ssh_state.dart';
import 'package:sysadmin/providers/system_resources_provider.dart';

class ProcessInfo {
  final String name;
  final int pid;
  final double cpuPercent;
  final double memoryMB;
  final double swapMB;

  ProcessInfo({
    required this.name,
    required this.pid,
    this.cpuPercent = 0.0,
    this.memoryMB = 0.0,
    this.swapMB = 0.0,
  });
}

class ProcessMonitorState {
  final List<ProcessInfo> cpuProcesses;
  final List<ProcessInfo> memoryProcesses;
  final List<ProcessInfo> swapProcesses;
  final bool isLoading;
  final String? error;

  ProcessMonitorState({
    this.cpuProcesses = const [],
    this.memoryProcesses = const [],
    this.swapProcesses = const [],
    this.isLoading = false,
    this.error,
  });

  ProcessMonitorState copyWith({
    List<ProcessInfo>? cpuProcesses,
    List<ProcessInfo>? memoryProcesses,
    List<ProcessInfo>? swapProcesses,
    bool? isLoading,
    String? error,
  }) {
    return ProcessMonitorState(
      cpuProcesses: cpuProcesses ?? this.cpuProcesses,
      memoryProcesses: memoryProcesses ?? this.memoryProcesses,
      swapProcesses: swapProcesses ?? this.swapProcesses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProcessMonitorNotifier extends StateNotifier<ProcessMonitorState> {
  final Ref ref;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  bool _disposed = false;

  ProcessMonitorNotifier(this.ref) : super(ProcessMonitorState());

  @override
  void dispose() {
    _disposed = true;
    stopMonitoring();
    super.dispose();
  }

  void startMonitoring() {
    if (_refreshTimer != null || _disposed) return;

    // Start with an initial fetch
    _fetchTopProcesses();

    // Set up periodic monitoring (3 second intervals to avoid overwhelming SSH connection)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_disposed) {
        _fetchTopProcesses();
      }
    });
  }

  void stopMonitoring() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _fetchTopProcesses() async {
    if (_isRefreshing || _disposed) return;
    _isRefreshing = true;

    try {
      final sshClientAsync = ref.read(sshClientProvider);
      final sshClient = sshClientAsync.value;

      if (sshClient == null || _disposed) {
        if (!_disposed) {
          state = state.copyWith(
            isLoading: false,
            error: 'SSH client not available',
          );
        }
        _isRefreshing = false;
        return;
      }

      // Update loading state (only if not disposed)
      if (!_disposed) {
        state = state.copyWith(isLoading: true, error: null);
      }

      // Fetch top CPU processes with a timeout
      final cpuResult = await sshClient
          .run('ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head -n 6')
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Command timed out');
      });

      if (_disposed) {
        _isRefreshing = false;
        return;
      }

      final cpuOutput = String.fromCharCodes(cpuResult).trim();

      // Fetch top memory processes with a timeout
      final memResult = await sshClient
          .run('ps -eo pid,pmem,pcpu,comm --sort=-pmem | head -n 6')
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Command timed out');
      });

      if (_disposed) {
        _isRefreshing = false;
        return;
      }

      final memOutput = String.fromCharCodes(memResult).trim();

      // For swap, we use a more efficient command
      final swapResult = await sshClient
          .run('grep VmSwap /proc/[0-9]*/status 2>/dev/null | ' +
              'sort -nr -k2 | head -n 5 | ' +
              'sed -e "s/[^0-9]\\+\\([0-9]\\+\\)[^0-9]\\+\\([0-9]\\+\\).*/\\1 \\2/" | ' +
              'while read pid swap; do comm=`cat /proc/\$pid/comm 2>/dev/null`; echo "\$pid \$swap \$comm"; done')
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Command timed out');
      });

      if (_disposed) {
        _isRefreshing = false;
        return;
      }

      final swapOutput = String.fromCharCodes(swapResult).trim();

      // Parse process data
      final List<ProcessInfo> cpuProcesses = _parseProcessOutput(cpuOutput, 'cpu');
      final List<ProcessInfo> memProcesses = _parseProcessOutput(memOutput, 'mem');
      final List<ProcessInfo> swapProcesses = _parseSwapProcessOutput(swapOutput);

      // Update state with new data (only if not disposed)
      if (!_disposed) {
        state = state.copyWith(
          cpuProcesses: cpuProcesses,
          memoryProcesses: memProcesses,
          swapProcesses: swapProcesses,
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      if (!_disposed) {
        debugPrint('Error fetching process data: $e');
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch process data',
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  List<ProcessInfo> _parseProcessOutput(String output, String type) {
    final List<ProcessInfo> processes = [];
    final lines = output.split('\n');

    // Skip the header line
    if (lines.length > 1) {
      for (int i = 1; i < lines.length && processes.length < 5; i++) {
        final line = lines[i].trim().replaceAll(RegExp(r'\s+'), ' ');
        final parts = line.split(' ');

        if (parts.length >= 4) {
          try {
            final pid = int.parse(parts[0]);
            final cpuPercent = type == 'cpu' ? double.parse(parts[1]) : double.parse(parts[2]);
            final memPercent = type == 'mem' ? double.parse(parts[1]) : double.parse(parts[2]);

            // Get memory in MB (approximate based on percentage of total RAM)
            final totalRam = ref.read(systemResourcesProvider).totalRam;
            final memoryMB = (memPercent / 100) * totalRam;

            // Get process name (which might contain spaces)
            final name = parts.sublist(3).join(' ');

            processes.add(ProcessInfo(
              name: name,
              pid: pid,
              cpuPercent: cpuPercent,
              memoryMB: memoryMB,
              swapMB: 0, // We don't have swap info here
            ));
          } catch (e) {
            debugPrint('Error parsing process line: $line - $e');
          }
        }
      }
    }

    return processes;
  }

  List<ProcessInfo> _parseSwapProcessOutput(String output) {
    final List<ProcessInfo> processes = [];
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final parts = line.trim().split(' ');
      if (parts.length >= 3) {
        try {
          final pid = int.parse(parts[0]);
          final swapKB = double.parse(parts[1]);
          final swapMB = swapKB / 1024; // Convert KB to MB

          // Get process name
          final name = parts.sublist(2).join(' ');

          processes.add(ProcessInfo(
            name: name,
            pid: pid,
            cpuPercent: 0, // We don't have CPU info here
            memoryMB: 0, // We don't have memory info here
            swapMB: swapMB,
          ));
        } catch (e) {
          debugPrint('Error parsing swap process line: $line - $e');
        }
      }
    }

    return processes;
  }
}

final processMonitorProvider =
    StateNotifierProvider<ProcessMonitorNotifier, ProcessMonitorState>((ref) {
  return ProcessMonitorNotifier(ref);
});
