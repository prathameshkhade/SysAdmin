import 'package:flutter/material.dart';
import '../../../data/models/remote_file.dart';
import 'file_list_title.dart';

class DirectoryView extends StatelessWidget {
  final List<RemoteFile> files;
  final String currentPath;
  final Function(String) onDirectoryTap;

  const DirectoryView({
    super.key,
    required this.files,
    required this.currentPath,
    required this.onDirectoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: files.length,
      separatorBuilder: (context, index) => const Divider(
        height: 0.1,
        thickness: 0.12,
      ),
      itemBuilder: (context, index) {
        final file = files[index];
        return FileListTile(
          file: file,
          onTap: () {
            if (file.isDirectory) {
              onDirectoryTap(file.path);
            }
          },
        );
      },
    );
  }
}