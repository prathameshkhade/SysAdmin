import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sysadmin/providers/ssh_state.dart';

class GPUInfo {
  final String model;
  final String driver;
  final String memory;
  final String type;

  GPUInfo({
    required this.model,
    required this.driver,
    required this.memory,
    required this.type,
  });
}

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
  final String? hostname;
  final String? kernel;
  final String? lastBootTime;
  final List<GPUInfo>? gpuInfo;


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
    this.hostname,
    this.kernel,
    this.lastBootTime,
    this.gpuInfo,
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
    String? hostname,
    String? kernel,
    String? lastBootTime,
    List<GPUInfo>? gpuInfo,
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
      hostname: hostname ?? this.hostname,
      kernel: kernel ?? this.kernel,
      lastBootTime: lastBootTime ?? this.lastBootTime,
      gpuInfo: gpuInfo ?? this.gpuInfo,
    );
  }

  String getValueOrDefault(String? value, {String defaultValue = 'NA'}) {
    return (value == null || value.isEmpty || value == 'NA') ? defaultValue : value;
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
      final modelResult = await sshClient.run('cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "NA"');

      // Get machine ID
      final machineIdResult = await sshClient.run('cat /etc/machine-id 2>/dev/null || echo "NA"');

      // Get uptime in minutes
      final uptimeResult = await sshClient.run("awk '{print int(\$1/60)}' /proc/uptime");

      // Get system type/name/version
      final osInfoResult = await sshClient.run('cat /etc/os-release 2>/dev/null || echo "NA"');

      // Get BIOS information
      final biosVendorResult = await sshClient.run('cat /sys/devices/virtual/dmi/id/bios_vendor 2>/dev/null || echo "NA"');
      final biosVersionResult = await sshClient.run('cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null || echo "NA"');
      final biosDateResult = await sshClient.run('cat /sys/devices/virtual/dmi/id/bios_date 2>/dev/null || echo "NA"');

      // Get CPU information
      final cpuModelResult = await sshClient.run('cat /proc/cpuinfo | grep "model name" | head -1 | sed "s/model name.*: //"');
      final cpuArchResult = await sshClient.run('uname -m');
      final cpuSpeedResult = await sshClient.run('cat /proc/cpuinfo | grep "cpu MHz" | head -1 | sed "s/cpu MHz.*: //"');

      // Parse OS info
      String name = "NA";
      String version = "NA";
      final osInfoOutput = utf8.decode(osInfoResult);
      final nameMatch = RegExp(r'NAME="?(.*?)"?$', multiLine: true).firstMatch(osInfoOutput);
      if (nameMatch != null && nameMatch.group(1) != null) {
        name = nameMatch.group(1)!;
      }
      final versionMatch = RegExp(r'VERSION="?(.*?)"?$', multiLine: true).firstMatch(osInfoOutput);
      if (versionMatch != null && versionMatch.group(1) != null) {
        version = versionMatch.group(1)!;
      }

      // // Create dummy memory modules for now (would need DMI tools or specific commands to get real info)
      // // TODO: Implement the real data
      // final memoryModules = [
      //   MemoryModule(
      //     slot: "RAM1",
      //     vendor: "Kingston",
      //     size: "4 GB",
      //     location: "DIMM1",
      //     type: "DDR4",
      //     speed: "2400 MHz",
      //   ),
      //   MemoryModule(
      //     slot: "RAM2",
      //     vendor: "Kingston",
      //     size: "4 GB",
      //     location: "DIMM2",
      //     type: "DDR4",
      //     speed: "2400 MHz",
      //   ),
      // ];

      // Get memory information using dmidecode (requires root access)
      // TODO: Need to implement the root password prompt for authentication.
      final memoryModulesResult = await sshClient.run('command -v dmidecode >/dev/null 2>&1 && sudo dmidecode -t memory 2>/dev/null || echo "NA"');
      final memoryOutput = utf8.decode(memoryModulesResult).trim();

      // Parse memory modules
      List<MemoryModule> memoryModules = [];
      if (memoryOutput != "NA") {
        // Parse dmidecode output to extract memory module information
        final moduleRegex = RegExp(r'Memory Device[\s\S]*?(?=Memory Device|$)');
        final moduleMatches = moduleRegex.allMatches(memoryOutput);

        for (final match in moduleMatches) {
          final moduleText = match.group(0) ?? '';
          if (moduleText.contains('No Module Installed')) continue;

          // Extract memory module details
          final slotMatch = RegExp(r'Locator: (.*?)$', multiLine: true).firstMatch(moduleText);
          final vendorMatch = RegExp(r'Manufacturer: (.*?)$', multiLine: true).firstMatch(moduleText);
          final sizeMatch = RegExp(r'Size: (.*?)$', multiLine: true).firstMatch(moduleText);
          final locationMatch = RegExp(r'Bank Locator: (.*?)$', multiLine: true).firstMatch(moduleText);
          final typeMatch = RegExp(r'Type: (.*?)$', multiLine: true).firstMatch(moduleText);
          final speedMatch = RegExp(r'Speed: (.*?)$', multiLine: true).firstMatch(moduleText);

          // Skip empty modules
          if (sizeMatch == null || sizeMatch.group(1)?.contains('No Module') == true) continue;

          memoryModules.add(MemoryModule(
            slot: slotMatch?.group(1)?.trim() ?? 'NA',
            vendor: vendorMatch?.group(1)?.trim() ?? 'NA',
            size: sizeMatch.group(1)?.trim() ?? 'NA',
            location: locationMatch?.group(1)?.trim() ?? 'NA',
            type: typeMatch?.group(1)?.trim() ?? 'NA',
            speed: speedMatch?.group(1)?.trim() ?? 'NA',
          ));
        }
      }

      // Fall back to simpler memory information if dmidecode doesn't work
      if (memoryModules.isEmpty) {
        final memInfoResult = await sshClient.run('cat /proc/meminfo | grep -E "MemTotal|SwapTotal" 2>/dev/null || echo "NA"');
        final memInfoOutput = utf8.decode(memInfoResult).trim();

        if (memInfoOutput != "NA") {
          final memTotalMatch = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(memInfoOutput);
          if (memTotalMatch != null) {
            final totalMemKB = int.tryParse(memTotalMatch.group(1) ?? '0') ?? 0;
            final totalMemGB = (totalMemKB / 1024 / 1024).toStringAsFixed(2);

            memoryModules.add(MemoryModule(
              slot: "System Memory",
              vendor: "NA",
              size: "$totalMemGB GB",
              location: "NA",
              type: "NA",
              speed: "NA",
            ));
          }
        }
      }

      // Get additional system information
      final hostnameResult = await sshClient.run('hostname 2>/dev/null || echo "NA"');
      final kernelResult = await sshClient.run('uname -r 2>/dev/null || echo "NA"');
      final lastBootResult = await sshClient.run('''who -b | awk '{print \$3" "\$4", "\$5}' 2>/dev/null || echo "NA"''');

      // Try lspci for GPU detection
      final gpuLspciResult = await sshClient.run('command -v lspci >/dev/null 2>&1 && lspci | grep -E "VGA|3D|Display" 2>/dev/null || echo "NA"');
      final gpuLspciOutput = utf8.decode(gpuLspciResult).trim();

      List<GPUInfo> gpuList = [];

      if (gpuLspciOutput != "NA") {
        // Parse lspci output to get GPU information
        final gpuLines = gpuLspciOutput.split('\n');

        for (final line in gpuLines) {
          if (line.isEmpty) continue;

          // Extract GPU model from lspci output
          String model = line.split(':').length > 2 ? line.split(':')[2].trim() : line;
          String type = line.contains("NVIDIA") ? "NVIDIA" : line.contains("AMD") ? "AMD" : line.contains("Intel") ? "Intel" : "Unknown";

          // Try to get more GPU info
          final gpuDriverResult = await sshClient.run('if [ "$type" = "NVIDIA" ]; then command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "NA"; else echo "NA"; fi'.replaceAll("\$type", type));
          final gpuMemoryResult = await sshClient.run('if [ "$type" = "NVIDIA" ]; then command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null || echo "NA"; else echo "NA"; fi'.replaceAll("\$type", type));

          final driverInfo = utf8.decode(gpuDriverResult).trim();
          final memoryInfo = utf8.decode(gpuMemoryResult).trim();

          gpuList.add(GPUInfo(
            model: model,
            driver: driverInfo != "NA" ? driverInfo : "Unknown",
            memory: memoryInfo != "NA" ? memoryInfo : "Unknown",
            type: type,
          ));
        }
      }

      // If no GPU is found with lspci, try a fallback method for ARM devices
      if (gpuList.isEmpty) {
        final gpuArmResult = await sshClient.run('cat /proc/device-tree/model 2>/dev/null || echo "NA"');
        final gpuArmOutput = utf8.decode(gpuArmResult).trim();

        if (gpuArmOutput != "NA" && (gpuArmOutput.contains("Raspberry Pi") || gpuArmOutput.contains("ARM"))) {
          // For ARM devices, try to detect integrated GPU
          final gpuTypeResult = await sshClient.run('grep -i gpu /proc/device-tree/compatible 2>/dev/null || echo "Integrated Graphics"');
          final gpuType = utf8.decode(gpuTypeResult).trim();

          gpuList.add(GPUInfo(
            model: "Integrated GPU ($gpuArmOutput)",
            driver: "System Default",
            memory: "Shared Memory",
            type: gpuType,
          ));
        }
      }

      state = state.copyWith(
        model: utf8.decode(modelResult).trim(),
        machineId: utf8.decode(machineIdResult).trim(),
        uptime: int.tryParse(utf8.decode(uptimeResult).trim()) ?? 0,
        type: "NA",
        name: name,
        version: version,
        bios: utf8.decode(biosVendorResult).trim(),
        biosVersion: utf8.decode(biosVersionResult).trim(),
        biosDate: _formatBiosDate(utf8.decode(biosDateResult).trim()),
        cpuModel: utf8.decode(cpuModelResult).trim(),
        cpuArchitecture: utf8.decode(cpuArchResult).trim(),
        cpuSpeed: double.tryParse(utf8.decode(cpuSpeedResult).trim()) ?? 0.0,
        memoryModules: memoryModules,
        hostname: utf8.decode(hostnameResult).trim(),
        kernel: utf8.decode(kernelResult).trim(),
        lastBootTime: utf8.decode(lastBootResult).trim(),
        gpuInfo: gpuList,
      );
    }
    catch (e) {
      debugPrint('Error fetching system information: $e');
    }
  }

  String _formatBiosDate(String date) {
    try {
      if (date.contains('/')) {
        final parts = date.split('/');
        if (parts.length == 3) {
          // Parse MM/DD/YYYY format
          final dateTime = DateTime(
            int.parse(parts[2]), // Year
            int.parse(parts[0]), // Month
            int.parse(parts[1]), // Day
          );
          // Format using intl package
          return DateFormat('MMMM d, yyyy').format(dateTime);
        }
      }
    }
    catch (e) {
      debugPrint('Error formatting BIOS date: $e');
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