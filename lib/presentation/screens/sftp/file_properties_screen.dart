import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/models/file_details.dart';

class FilePropertiesScreen extends StatelessWidget {
  final FileDetails fileDetails;

  const FilePropertiesScreen({
    super.key,
    required this.fileDetails
  });

  // Helper fun for building Rows quickly
  TableRow buildRow(String key, dynamic value, ThemeData theme) {
    // Handle null values gracefully
    final displayValue = value?.toString() ?? 'N/A';
    return TableRow(
        children: <TableCell>[
          TableCell(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Text(key),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(displayValue, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ),
          ),
        ]
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
        title: "Properties",
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              // File Properties
              const SizedBox(height: 8),
              Text("File Properties", style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2), // Label column
                  1: FlexColumnWidth(2), // Value column
                },
                children: <TableRow>[
                  buildRow("Location", fileDetails.path, theme),
                  buildRow("Display Name", fileDetails.path.split('/').last, theme),
                  buildRow("Parent Folder", fileDetails.path.split('/').length > 1
                      ? fileDetails.path.split('/')[fileDetails.path.split('/').length - 2]
                      : '/', theme),
                  buildRow("Last Modified", fileDetails.modifyTime, theme),
                  buildRow("Size", fileDetails.size, theme),
                  buildRow("File Type", fileDetails.fileType, theme),
                ],
              ),

              const SizedBox(height: 32.0),

              // Additional Information
              Text("Additional Information", style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2), // Label column
                  1: FlexColumnWidth(2), // Value column
                },
                children: <TableRow>[
                  buildRow("Inode", fileDetails.inode, theme),
                  buildRow("Blocks", fileDetails.blocks, theme),
                  buildRow("IO Blocks", fileDetails.ioBlocks, theme),
                  buildRow("Links", fileDetails.links, theme),
                  buildRow("Uid", fileDetails.uid, theme),
                  buildRow("Gid", fileDetails.gid, theme),
                  buildRow("Access", fileDetails.accessTime, theme),
                  buildRow("Modify", fileDetails.modifyTime, theme),
                  buildRow("Change", fileDetails.changeTime, theme),
                  buildRow("Birth", fileDetails.birthTime, theme),
                ],
              )
            ],
          ),
        )
    );
  }
}