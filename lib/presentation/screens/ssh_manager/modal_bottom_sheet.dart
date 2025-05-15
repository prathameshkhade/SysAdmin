import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/core/widgets/button.dart';
import 'package:sysadmin/data/services/connection_manager.dart';
import 'package:sysadmin/presentation/screens/sftp/index.dart';
import 'package:sysadmin/presentation/screens/terminal/index.dart';

import '../../../data/models/ssh_connection.dart';

class SSHConnectionDetailsSheet extends StatefulWidget {
  final SSHConnection connection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(SSHConnection) onConnectionUpdated;

  const SSHConnectionDetailsSheet({
    super.key,
    required this.connection,
    required this.onEdit,
    required this.onDelete,
    required this.onConnectionUpdated,
  });

  @override
  State<SSHConnectionDetailsSheet> createState() => _SSHConnectionDetailsSheetState();
}

class _SSHConnectionDetailsSheetState extends State<SSHConnectionDetailsSheet> {
  late bool isDefault;
  final ConnectionManager storage = ConnectionManager();
  late SSHConnection currentConnection;

  @override
  void initState() {
    super.initState();
    isDefault = widget.connection.isDefault;
    currentConnection = widget.connection;
  }

  Future<void> _toggleDefault() async {
    try {
      await storage.setDefaultConnection(currentConnection.name);

      // Get updated connection list to reflect changes
      final connections = await storage.getAll();
      final updatedConnection = connections.firstWhere(
        (conn) => conn.name == currentConnection.name,
        orElse: () => currentConnection,
      );

      setState(() {
        currentConnection = updatedConnection;
      });

      // Notify parent of the update
      widget.onConnectionUpdated(currentConnection);

      if (mounted) {
        Util.showMsg(
            context: context,
            msg: "${currentConnection.name} ${currentConnection.isDefault ? 'set as' : 'removed from'} default connection"
        );
      }
    }
    catch (e) {
      if (mounted) Util.showMsg(context: context, msg: "Failed to update default connection", isError: true);
    }
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      iconColor: Theme.of(context).primaryColor,
      leading: Icon(icon),
      title: Text(title, style: Theme.of(context).textTheme.labelLarge),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme
    final theme = Theme.of(context);

    // Table Row builder
    TableRow buildRow(String label, String value, {bool alternate = false}) {
      String displayValue = value;
      if (label == "Created At") {
        try {
          final date = DateTime.parse(value);
          displayValue = "${date.toString().substring(0, 10)} ${date.toString().substring(11, 16)}";
        } 
        catch (e) {
          displayValue = value;
        }
      }
      return TableRow(
        decoration: BoxDecoration(
          color: alternate ? theme.colorScheme.surface : Colors.transparent,
        ),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label, style: theme.textTheme.bodyMedium)
              )
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(displayValue, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))
              )
          ),
        ],
      );
    }


    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      expand: false,
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 18, bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                      bottom: BorderSide(width: 0.5, color: Colors.blueGrey.useOpacity(0.5))
                  ),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Title
                        Expanded(
                          child: Text(widget. connection.name, style: theme.textTheme.titleLarge),
                        ),
                      ],
                    ),

                    // Sub heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget> [
                        Text(
                            '${widget.connection.username}@${widget.connection.host}:${widget.connection.port}',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w300)
                        ),

                        // Default label
                        if (currentConnection.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.useOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Default', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                          ),
                      ],
                    )
                  ],
                ),
              ),

              // Action Buttons
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
                      child: Column(
                        children: <Widget> [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Expanded(flex: 1, child: Button(text: 'edit', onPressed: widget.onEdit, bgColor: Colors.blue)),
                              const SizedBox(width: 16),
                              Expanded(flex: 1, child: Button(text: 'delete', onPressed: widget.onDelete, bgColor: Colors.red)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Default connection toggle
                          SwitchListTile(
                            // contentPadding: const EdgeInsets.symmetric(horizontal: 50),
                            title: Text('Set as Default Connection', style: theme.textTheme.labelLarge),
                            value: currentConnection.isDefault,
                            onChanged: (bool value) {
                              Navigator.pop(context);
                              _toggleDefault();
                            },
                          ),

                        ],
                      ),
                    ),

                    Divider(
                      color: theme.canvasColor,
                      thickness: 1.1,
                      height : 28,
                      indent: 20,
                      endIndent: 20,
                    ),

                    // Connection Information
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget> [
                          // Table Heading
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8),
                            child: Text("Connection Details", style: theme.textTheme.titleMedium,),
                          ),

                          const SizedBox(height: 8),

                          // Table data
                          Table(
                            border: TableBorder.all(color: Colors.transparent),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2),
                            },
                            textBaseline: TextBaseline.alphabetic,
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: <TableRow> [
                              buildRow("Created At", widget.connection.createdAt, alternate: true),
                              buildRow("Username", widget.connection.username, alternate: false),
                              buildRow("Host", widget.connection.host, alternate: true),
                              buildRow("Port", widget.connection.port.toString(), alternate: false),
                              buildRow("Authentication", widget.connection.password != null ? "Password" : "Private Key", alternate: true),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Quick Actions
                    _buildDetailSection('Quick Actions', [
                      _buildActionButton(
                        icon: Icons.terminal,
                        title: 'Open Terminal',
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const TerminalScreen())
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.folder_open_rounded,
                        title: 'File Manager',
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => SftpExplorerScreen(connection: currentConnection))
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.monitor,
                        title: 'System Monitor',
                        onTap: () {
                          // TODO: Implement system monitor logic
                        },
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
