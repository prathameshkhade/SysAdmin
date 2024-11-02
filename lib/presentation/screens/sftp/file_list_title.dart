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

  Widget _buildFileIcon() {
    final iconData = file.isDirectory
        ? Icons.folder
        : file.isLink
        ? Icons.link
        : _getFileTypeIcon(file.name);

    final iconColor = file.isDirectory
        ? Colors.blue
        : file.isLink
        ? Colors.green
        : Colors.grey[400];

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

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
    return ListTile(
      leading: _buildFileIcon(),
      title: Text(
        file.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            file.formattedSize,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            file.permissions,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}