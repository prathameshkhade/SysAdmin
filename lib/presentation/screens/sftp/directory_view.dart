import 'package:flutter/material.dart';
import '../../../data/models/remote_file.dart';
import 'file_list_title.dart';

class DirectoryView extends StatelessWidget {
  final List<RemoteFile> files;
  final Set<RemoteFile> selectedFiles;
  final String currentPath;
  final Function(String) onDirectoryTap;
  final Function(RemoteFile) onFileLongPress;
  final Function(RemoteFile) onFileTap;

  const DirectoryView({
    super.key,
    required this.files,
    required this.selectedFiles,
    required this.currentPath,
    required this.onDirectoryTap,
    required this.onFileLongPress,
    required this.onFileTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: files.length,
      separatorBuilder: (context, index) => const Divider(
        height: 0,
        thickness: 0.08,
      ),
      itemBuilder: (context, index) {
        final file = files[index];
        final isSelected = selectedFiles.contains(file);

        return FileListTile(
          file: file,
          isSelected: isSelected,
          onTap: () => onFileTap(file),
          onLongPress: () => onFileLongPress(file),
        );
      },
    );
  }
}