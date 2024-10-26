import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/button.dart';
import '../../../data/models/ssh_connection.dart';

class SSHConnectionDetailsSheet extends StatelessWidget {
  final SSHConnection connection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SSHConnectionDetailsSheet({
    super.key,
    required this.connection,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
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
      iconColor: Colors.blue,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme
    final theme = Theme.of(context);

    // Table Row builder funtion
    TableRow buildRow(String label, String value, {bool alternate = false}) {
      return TableRow(
        decoration: BoxDecoration(
          color: alternate ? theme.secondaryHeaderColor : Colors.transparent,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(label, style: theme.textTheme.bodyMedium)
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
                alignment: Alignment.centerRight,
                child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))
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
                  color: Colors.grey.withOpacity(0.01),
                  border: const Border(bottom: BorderSide(width: 0.15)),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.1),
                      blurRadius: 1,
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
                          child: Text(
                            connection.name,
                            style: theme.textTheme.titleLarge
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Sub heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget> [
                        Text(
                            '${connection.username}@${connection.host}:${connection.port}',
                            style: theme.textTheme.titleSmall
                        ),

                        // Default label
                        if (connection.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                                'Default',
                                style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)
                            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          // Edit Button
                          Expanded(flex: 1, child: Button(text: 'edit', onPressed: onEdit, bgColor: Colors.blue)),

                          const SizedBox(width: 16),

                          // Delete Button
                          Expanded(flex: 1, child: Button(text: 'delete', onPressed: onDelete, bgColor: Colors.red))
                        ],
                      ),
                    ),

                    // Connection Information
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget> [
                          // Table Heading
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                            child: Text(
                              "Connection Details",
                              style: theme.textTheme.titleMedium,
                            ),
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
                              buildRow("Created At", DateTime.now().toString(), alternate: true),
                              buildRow("Username", connection.username, alternate: false),
                              buildRow("Host", connection.host, alternate: true),
                              buildRow("Port", connection.port.toString(), alternate: false),
                              buildRow("Authentication", connection.password != null ? "Password" : "Private Key", alternate: true),
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
                        onTap: () {
                          // Implement terminal opening logic
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.file_copy,
                        title: 'File Manager',
                        onTap: () {
                          // Implement file manager logic
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.monitor,
                        title: 'System Monitor',
                        onTap: () {
                          // Implement system monitor logic
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
