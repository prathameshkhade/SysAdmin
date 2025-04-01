import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/providers/ssh_state.dart';

class SystemInformation {
  final String? model;
  final String? machineId;
  final int? uptime;
  final String? type;
  final String? name;
  final String? version;
  final String? bios;
  final String? biosVersion;
  final String? biosDate;
  final String? cpuModel;
  final String? cpuArchitecture;
  final double? cpuSpeed;
  final List<MemoryModule>? memoryModules;

  SystemInformation({
    this.model,
    this.machineId,
    this.uptime,
    this.type,
    this.name,
    this.version,
    this.bios,
    this.biosVersion,
    this.biosDate,
    this.cpuModel,
    this.cpuArchitecture,
    this.cpuSpeed,
    this.memoryModules,
  });

  SystemInformation copyWith({
    String? model,
    String? machineId,
    int? uptime,
    String? type,
    String? name,
    String? version,
    String? bios,
    String? biosVersion,
    String? biosDate,
    String? cpuModel,
    String? cpuArchitecture,
    double? cpuSpeed,
    List<MemoryModule>? memoryModules,
  }) {
    return SystemInformation(
      model: model ?? this.model,
      machineId: machineId ?? this.machineId,
      uptime: uptime ?? this.uptime,
      type: type ?? this.type,
      name: name ?? this.name,
      version: version ?? this.version,
      bios: bios ?? this.bios,
      biosVersion: biosVersion ?? this.biosVersion,
      biosDate: biosDate ?? this.biosDate,
      cpuModel: cpuModel ?? this.cpuModel,
      cpuArchitecture: cpuArchitecture ?? this.cpuArchitecture,
      cpuSpeed: cpuSpeed ?? this.cpuSpeed,
      memoryModules: memoryModules ?? this.memoryModules,
    );
  }

  @override
  String toString() {
    return {
      model: model ?? model,
      machineId: machineId ?? machineId,
      uptime: uptime ?? uptime,
      type: type ?? type,
      name: name ?? name,
      version: version ?? version,
      bios: bios ?? bios,
      biosVersion: biosVersion ?? biosVersion,
      biosDate: biosDate ?? biosDate,
      cpuModel: cpuModel ?? cpuModel,
      cpuArchitecture: cpuArchitecture ?? cpuArchitecture,
      cpuSpeed: cpuSpeed ?? cpuSpeed,
      memoryModules: memoryModules ?? memoryModules,
    }.toString();
  }
}

class MemoryModule {
  final String slot;
  final String vendor;
  final String size;
  final String location;
  final String type;
  final String speed;

  MemoryModule({
    required this.slot,
    required this.vendor,
    required this.size,
    required this.location,
    required this.type,
    required this.speed,
  });
}

// Provider classes
class SystemInformationNotifier extends StateNotifier<SystemInformation> {
  final Ref ref;

  SystemInformationNotifier(this.ref) : super(SystemInformation());

  Future<void> fetchSystemInformation() async {

    try {
      final sshClient = ref.read(sshClientProvider).value;
      if (sshClient == null) return;

      // Get model information
      final modelResult = await sshClient.run('cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "innotek GmbH VirtualBox"');

      // Get machine ID
      final machineIdResult = await sshClient.run('cat /etc/machine-id 2>/dev/null || echo "41344-2cc9fbc4498a66a6774908fc4fb"');

      // Get uptime in minutes
      final uptimeResult = await sshClient.run("awk '{print int(\$1/60)}' /proc/uptime");

      // Get system type/name/version
      final osInfoResult = await sshClient.run('cat /etc/os-release 2>/dev/null || echo "NAME=VirtualBox\nVERSION=1.2"');

      // Get BIOS information
      final biosVendorResult = await sshClient.run('cat /sys/devices/virtual/dmi/id/bios_vendor 2>/dev/null || echo "innotek GmbH"');
      final biosVersionResult = await sshClient.run('cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null || echo "VirtualBox"');
      final biosDateResult = await sshClient.run('cat /sys/devices/virtual/dmi/id/bios_date 2>/dev/null || echo "12/01/2006"');

      // Get CPU information
      final cpuModelResult = await sshClient.run('cat /proc/cpuinfo | grep "model name" | head -1 | sed "s/model name.*: //"');
      final cpuArchResult = await sshClient.run('uname -m');
      final cpuSpeedResult = await sshClient.run('cat /proc/cpuinfo | grep "cpu MHz" | head -1 | sed "s/cpu MHz.*: //"');

      // Parse OS info
      String name = "VirtualBox";
      String version = "1.2";
      final osInfoOutput = utf8.decode(osInfoResult);
      final nameMatch = RegExp(r'NAME="?(.*?)"?$', multiLine: true).firstMatch(osInfoOutput);
      if (nameMatch != null && nameMatch.group(1) != null) {
        name = nameMatch.group(1)!;
      }
      final versionMatch = RegExp(r'VERSION="?(.*?)"?$', multiLine: true).firstMatch(osInfoOutput);
      if (versionMatch != null && versionMatch.group(1) != null) {
        version = versionMatch.group(1)!;
      }

      // Create dummy memory modules for now (would need DMI tools or specific commands to get real info)
      // TODO: Implement the real data
      final memoryModules = [
        MemoryModule(
          slot: "RAM1",
          vendor: "Kingston",
          size: "4 GB",
          location: "DIMM1",
          type: "DDR4",
          speed: "2400 MHz",
        ),
        MemoryModule(
          slot: "RAM2",
          vendor: "Kingston",
          size: "4 GB",
          location: "DIMM2",
          type: "DDR4",
          speed: "2400 MHz",
        ),
      ];

      state = state.copyWith(
        model: utf8.decode(modelResult).trim(),
        machineId: utf8.decode(machineIdResult).trim(),
        uptime: int.tryParse(utf8.decode(uptimeResult).trim()) ?? 0,
        type: "Other",
        name: name,
        version: version,
        bios: utf8.decode(biosVendorResult).trim(),
        biosVersion: utf8.decode(biosVersionResult).trim(),
        biosDate: _formatBiosDate(utf8.decode(biosDateResult).trim()),
        cpuModel: utf8.decode(cpuModelResult).trim(),
        cpuArchitecture: utf8.decode(cpuArchResult).trim(),
        cpuSpeed: double.tryParse(utf8.decode(cpuSpeedResult).trim()) ?? 2.00,
        memoryModules: memoryModules,
      );
    }
    catch (e) {
      debugPrint('Error fetching system information: $e');
    }
  }

  String _formatBiosDate(String date) {
    // Convert from MM/DD/YYYY format to a more readable format
    if (date.contains('/')) {
      final parts = date.split('/');
      if (parts.length == 3) {
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final monthIndex = int.tryParse(parts[0]);
        if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
          return '${months[monthIndex-1]} ${parts[1]}, ${parts[2]}';
        }
      }
    }
    return date;
  }

  void refreshUptimeOnly() async {
    try {
      final sshClient = ref.read(sshClientProvider).value;
      if (sshClient == null) return;

      final uptimeResult = await sshClient.run("awk '{print int(\$1/60)}' /proc/uptime");
      final uptime = int.tryParse(utf8.decode(uptimeResult).trim()) ?? 0;

      state = state.copyWith(uptime: uptime);
    }
    catch (e) {
      debugPrint('Error refreshing uptime: $e');
    }
  }
}

// State Notifier Provider class
final systemInformationProvider = StateNotifierProvider<SystemInformationNotifier, SystemInformation>((ref) {
  return SystemInformationNotifier(ref);
});