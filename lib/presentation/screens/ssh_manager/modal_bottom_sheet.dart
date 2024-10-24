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

  @override
  Widget build(BuildContext context) {
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
                  border: const Border(
                    bottom: BorderSide(width: 0.15)
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                        Expanded(
                          child: Text(
                            connection.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (connection.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${connection.username}@${connection.host}:${connection.port}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: <Widget> [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(width: 0.15)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 26),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget> [
                          Expanded(
                              flex: 1,
                              child: Button(text: 'edit', onPressed: onEdit, bgColor: Colors.blue)
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                              flex: 1,
                              child: Button(text: 'delete', onPressed: onDelete, bgColor: Colors.red)
                          )
                        ],
                      ),
                    ),

                    // Connection Basic Information

                    // Quick Actions
                    const SizedBox(height: 36),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
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
}
