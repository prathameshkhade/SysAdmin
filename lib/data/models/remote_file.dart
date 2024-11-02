// remote_file.dart
import 'package:dartssh2/dartssh2.dart';

enum FileType {
  file,
  directory,
  link,
  unknown
}

class RemoteFile {
  final String name;
  final String path;
  final FileType type;
  final String permissions;
  final int size;

  const RemoteFile({
    required this.name,
    required this.path,
    required this.type,
    required this.permissions,
    required this.size,
  });

  // Factory method to create from SFTP stats
  factory RemoteFile.fromStat(SftpName file, String currentPath) {
    final parts = file.longname.split(' ').where((s) => s.isNotEmpty).toList();

    // Get file size from attributes
    int fileSize = 0;
    try {
      fileSize = file.attr.size ?? 0;  // Use null-aware operator to default to 0
    } catch (e) {
      print('Error getting file size: $e');
      // Default to 0 if size cannot be determined
      fileSize = 0;
    }

    return RemoteFile(
      name: file.filename,
      path: '$currentPath/${file.filename}',
      type: _getFileTypeFromLongname(parts[0][0]),
      permissions: parts[0],
      size: fileSize,
    );
  }

  static FileType _getFileTypeFromLongname(String typeChar) {
    switch (typeChar) {
      case 'd':
        return FileType.directory;
      case 'l':
        return FileType.link;
      case '-':
        return FileType.file;
      default:
        return FileType.unknown;
    }
  }

  // Helper method to check if it's a directory
  bool get isDirectory => type == FileType.directory;

  // Helper method to check if it's a symbolic link
  bool get isLink => type == FileType.link;

  // Helper method to format size for display
  String get formattedSize {
    if (isDirectory) return 'directory';  // Show -- for directories
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // For debugging purposes
  @override
  String toString() => 'RemoteFile(name: $name, type: $type, permissions: $permissions, size: $formattedSize)';
}