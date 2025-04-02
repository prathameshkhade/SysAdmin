import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/presentation/widgets/overview_container.dart';
import 'package:sysadmin/providers/system_information_provider.dart';
import 'package:sysadmin/providers/system_resources_provider.dart';

class SystemInformationScreen extends ConsumerStatefulWidget {
  const SystemInformationScreen({super.key});

  @override
  ConsumerState<SystemInformationScreen> createState() => _SystemInformationScreenState();
}

class _SystemInformationScreenState extends ConsumerState<SystemInformationScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSystemInformation();
  }

  Future<void> _loadSystemInformation() async {
    setState(() => _isLoading = true);
    await ref.read(systemInformationProvider.notifier).fetchSystemInformation();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final systemInfo = ref.watch(systemInformationProvider);
    final systemResources = ref.watch(systemResourcesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("System Information"),
        elevation: 1.0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadSystemInformation,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic System Information
            OverviewContainer(
              title: "System Information",
              children: <Widget>[
                _buildInfoRow(context, "Model", systemInfo.model ?? "innotek GmbH VirtualBox"),
                _buildInfoRow(context, "Machine ID", systemInfo.machineId ?? "41344-2cc9fbc4498a66a6774908fc4fb"),
                _buildInfoRow(context, "Uptime", Util.formatTime(systemInfo.uptime ?? 0)),
                _buildInfoRow(context, "Type", systemInfo.type ?? "Other"),
                _buildInfoRow(context, "Name", systemInfo.name ?? "VirtualBox"),
                _buildInfoRow(context, "Version", systemInfo.version ?? "1.2"),
              ],
            ),

            const SizedBox(height: 24),

            // BIOS Information
            OverviewContainer(
              title: "BIOS Information",
              children: <Widget>[
                _buildInfoRow(context, "BIOS", systemInfo.bios ?? "innotek GmbH"),
                _buildInfoRow(context, "BIOS version", systemInfo.biosVersion ?? "VirtualBox"),
                _buildInfoRow(context, "BIOS date", systemInfo.biosDate ?? "December 1, 2006"),
              ],
            ),

            const SizedBox(height: 24),

            // CPU Information
            OverviewContainer(
              title: "CPU Information",
              children: <Widget>[
                _buildInfoRow(context, "CPU", systemInfo.cpuModel ?? "2x Intel(R) Core(TM) i3-5005U CPU @ 2.00GHz"),
                _buildInfoRow(context, "Architecture", systemInfo.cpuArchitecture ?? "x86_64"),
                _buildInfoRow(context, "Cores", "${systemResources.cpuCount}"),
                _buildInfoRow(context, "Clock Speed", "${systemInfo.cpuSpeed?.toStringAsFixed(2) ?? "2.00"} GHz"),
              ],
            ),

            const SizedBox(height: 24),

            // Memory Information
            OverviewContainer(
              title: "Memory Information",
              children: <Widget>[
                _buildMemoryTableHeader(context),
                if (systemInfo.memoryModules != null)
                  ...systemInfo.memoryModules!.map((module) =>
                      _buildMemoryTableRow(
                        context,
                        module.slot,
                        module.vendor,
                        module.size,
                        module.location,
                        module.type,
                        module.speed,
                      ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTableHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _buildTableHeaderCell(context, "Slot", 1),
          _buildTableHeaderCell(context, "Vendor", 1),
          _buildTableHeaderCell(context, "Size", 1),
          _buildTableHeaderCell(context, "Location", 1),
          _buildTableHeaderCell(context, "Type", 1),
          _buildTableHeaderCell(context, "Speed", 1),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(BuildContext context, String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMemoryTableRow(BuildContext context, String slot, String vendor,
      String size, String location, String type, String speed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildTableCell(context, slot, 1),
          _buildTableCell(context, vendor, 1),
          _buildTableCell(context, size, 1),
          _buildTableCell(context, location, 1),
          _buildTableCell(context, type, 1),
          _buildTableCell(context, speed, 1),
        ],
      ),
    );
  }

  Widget _buildTableCell(BuildContext context, String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}