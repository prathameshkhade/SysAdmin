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
    // Parse stat output into key-value pairs
    final Map<String, String> statInfo = {};
    final lines = statOutput.split('\n');

    for (var line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          statInfo[key] = value;
        }
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
  String? get device => parsedStatInfo['Device'];
  String? get inode => parsedStatInfo['Inode'];
  String? get links => parsedStatInfo['Links'];
  String? get access => parsedStatInfo['Access'];
  String? get uid => parsedStatInfo['Uid'];
  String? get gid => parsedStatInfo['Gid'];
  String? get accessTime => parsedStatInfo['Access'];
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
    Device: $device
    Inode: $inode
    Access: $access
    Owner: $uid
    Group: $gid
  ''';
}