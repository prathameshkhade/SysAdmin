class FileDetails {
  final String path;
  final String fileOutput;    // Raw output of 'file' command
  final String statOutput;    // Raw output of 'stat' command
  final Map<String, String> parsedStatInfo;  // Parsed stat information

  FileDetails({
    required this.path,
    required this.fileOutput,
    required this.statOutput,
    required this.parsedStatInfo,
  });

  // Factory method to create FileDetails from command outputs
  factory FileDetails.fromCommandOutputs({
    required String path,
    required String fileOutput,
    required String statOutput,
  }) {
    final Map<String, String> statInfo = {};
    final lines = statOutput.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('File:')) {
        statInfo['File'] = line.split('File:')[1].trim();
      }
      else if (line.startsWith('Size:')) {
        // Parse Size, Blocks, and IO Block from the same line
        final parts = line.split(RegExp(r'\s+'));
        statInfo['Size'] = parts[1];
        statInfo['Blocks'] = parts[3];
        statInfo['IO Block'] = parts[6];
      }
      else if (line.startsWith('Device:')) {
        // Parse Device, Inode, and Links
        final parts = line.split(RegExp(r'\s+'));
        statInfo['Device'] = parts[1];
        statInfo['Inode'] = parts[3];
        statInfo['Links'] = parts[5];
      }
      else if (line.startsWith('Access:') && line.contains('Uid:')) {
        // Parse Access permissions, Uid, and Gid
        final permParts = line.split('Uid:');
        final accessPerm = permParts[0].split('Access:')[1].trim();
        statInfo['Access Permission'] = accessPerm;

        final uidGidParts = permParts[1].split('Gid:');
        statInfo['Uid'] = uidGidParts[0].trim().replaceAll(RegExp(r'[()]'), '');
        statInfo['Gid'] = uidGidParts[1].trim().replaceAll(RegExp(r'[()]'), '');
      }
      else if (line.startsWith('Access:') && !line.contains('Uid:')) {
        statInfo['Access Time'] = line.split('Access:')[1].trim();
      }
      else if (line.startsWith('Modify:')) {
        statInfo['Modify'] = line.split('Modify:')[1].trim();
      }
      else if (line.startsWith('Change:')) {
        statInfo['Change'] = line.split('Change:')[1].trim();
      }
      else if (line.startsWith('Birth:')) {
        statInfo['Birth'] = line.split('Birth:')[1].trim();
      }
    }

    return FileDetails(
      path: path,
      fileOutput: fileOutput.split(':').last.trim(),
      statOutput: statOutput,
      parsedStatInfo: statInfo,
    );
  }

  // Getter methods for commonly accessed stat information
  String? get fileType => fileOutput;
  String? get size => parsedStatInfo['Size'];
  String? get blocks => parsedStatInfo['Blocks'];
  String? get ioBlocks => parsedStatInfo['IO Block'];
  String? get device => parsedStatInfo['Device'];
  String? get inode => parsedStatInfo['Inode'];
  String? get links => parsedStatInfo['Links'];
  String? get accessPermission => parsedStatInfo['Access Permission'];
  String? get uid => parsedStatInfo['Uid'];
  String? get owner => parsedStatInfo['Uid']?.split('/').last;
  String? get gid => parsedStatInfo['Gid'];
  String? get group => parsedStatInfo['Gid']?.split('/').last;
  String? get accessTime => parsedStatInfo['Access Time'];
  String? get modifyTime => parsedStatInfo['Modify'];
  String? get changeTime => parsedStatInfo['Change'];
  String? get birthTime => parsedStatInfo['Birth'];

  // For debugging purposes
  @override
  String toString() => '''
    FileDetails:
    Path: $path
    File Type: $fileType
    Size: $size
    Blocks: $blocks
    IO Block: $ioBlocks
    Device: $device
    Inode: $inode
    Links: $links
    Access Permission: $accessPermission
    Uid: $uid
    Gid: $gid
    Access Time: $accessTime
    Modify Time: $modifyTime
    Change Time: $changeTime
    Birth Time: $birthTime
  ''';
}