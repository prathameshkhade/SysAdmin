import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/button.dart';
import 'package:sysadmin/data/services/connection_manager.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${currentConnection.name} ${currentConnection.isDefault ? 'set as' : 'removed from'} default connection'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update default connection'),
            duration: Duration(seconds: 3),
          ),
        );
      }
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

  // Widget _buildDetailItem(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 12),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(
  //           width: 100,
  //           child: Text(label, style: Theme.of(context).textTheme.displayLarge),
  //         ),
  //         Expanded(
  //           child: Text(
  //             value,
  //             style: const TextStyle(
  //               fontSize: 14,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
        } catch (e) {
          displayValue = value;
        }
      }
      return TableRow(
        decoration: BoxDecoration(
          color: alternate ? theme.secondaryHeaderColor : Colors.transparent,
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              // Container(
              //   margin: const EdgeInsets.only(top: 4),
              //   width: 50,
              //   height: 4,
              //   decoration: BoxDecoration(
              //     color: Colors.grey.withOpacity(0.5),
              //     borderRadius: BorderRadius.circular(2),
              //   ),
              // ),

              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withAlpha(20),
                  border: const Border(bottom: BorderSide(width: 0.15)),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.01),
                      offset: const Offset(0, 1),
                    ),
                  ],
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

                    const SizedBox(height: 4),

                    // Sub heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget> [
                        Text(
                            '${widget.connection.username}@${widget.connection.host}:${widget.connection.port}',
                            style: theme.textTheme.titleSmall
                        ),

                        // Default label
                        if (currentConnection.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.15),
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
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(width: 0.1)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                            onChanged: (bool value) => _toggleDefault(),
                          ),
                        ],
                      ),
                    ),

                    // Connection Information
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget> [
                          // Table Heading
                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Text("Connection Details", style: theme.textTheme.titleMedium,),
                          ),

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
                          CupertinoPageRoute(builder: (context) => TerminalScreen(connection: currentConnection))
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.folder_open_rounded,
                        title: 'File Manager',
                        onTap: () {
                          // TODO: Implement file manager logic
                        },
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

              // Scrollable Content
              // Expanded(
              //   child: ListView(
              //     controller: scrollController,
              //     padding: const EdgeInsets.all(16),
              //     children: <Widget> [
              //       _buildDetailSection('Connection Details', [
              //         _buildDetailItem('Host', connection.host),
              //         _buildDetailItem('Port', connection.port.toString()),
              //         _buildDetailItem('Username', connection.username),
              //         if (connection.password != null) _buildDetailItem('Authentication', 'Password'),
              //         if (connection.privateKey != null) _buildDetailItem('Authentication', 'Private Key'),
              //       ]),
              //
              //     ],
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }
}
