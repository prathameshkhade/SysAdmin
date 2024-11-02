import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../data/models/remote_file.dart';

class FileListTile extends StatelessWidget {
  final RemoteFile file;
  final VoidCallback? onTap;

  const FileListTile({
    super.key,
    required this.file,
    this.onTap,
  });

  IconData _getFileTypeIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'apk':
        return Icons.android;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surface,
        radius: 24,
        child: Icon(
          file.isDirectory
              ? Icons.folder
              : file.isLink
                  ? Icons.link
                  : _getFileTypeIcon(file.name),
          color: file.isDirectory
              ? theme.primaryColor
              : file.isLink
                  ? Colors.green
                  : theme.colorScheme.surface,
          size: 28,
        ),
      ),

      title: Text(file.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400,)),

      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Text> [
          // Size
          Text(file.formattedSize, style: theme.textTheme.titleSmall),

          // permissions
          Text(file.permissions, style: theme.textTheme.titleSmall),
        ]
      ),

      onTap: onTap,
    );
  }
}
