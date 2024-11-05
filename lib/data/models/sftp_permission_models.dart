// lib/data/models/file_permission.dart
class FilePermission {
  bool ownerRead;
  bool ownerWrite;
  bool ownerExecute;
  bool groupRead;
  bool groupWrite;
  bool groupExecute;
  bool otherRead;
  bool otherWrite;
  bool otherExecute;

  FilePermission({
    this.ownerRead = false,
    this.ownerWrite = false,
    this.ownerExecute = false,
    this.groupRead = false,
    this.groupWrite = false,
    this.groupExecute = false,
    this.otherRead = false,
    this.otherWrite = false,
    this.otherExecute = false,
  });

  // Parse permission string like "rw-r--r--"
  factory FilePermission.fromString(String permissions) {
    if (permissions.length != 9) {
      throw const FormatException('Invalid permission string length');
    }

    return FilePermission(
      ownerRead: permissions[0] == 'r',
      ownerWrite: permissions[1] == 'w',
      ownerExecute: permissions[2] == 'x',
      groupRead: permissions[3] == 'r',
      groupWrite: permissions[4] == 'w',
      groupExecute: permissions[5] == 'x',
      otherRead: permissions[6] == 'r',
      otherWrite: permissions[7] == 'w',
      otherExecute: permissions[8] == 'x',
    );
  }

  // Convert to permission string
  @override
  String toString() {
    return '${ownerRead ? 'r' : '-'}'
        '${ownerWrite ? 'w' : '-'}'
        '${ownerExecute ? 'x' : '-'}'
        '${groupRead ? 'r' : '-'}'
        '${groupWrite ? 'w' : '-'}'
        '${groupExecute ? 'x' : '-'}'
        '${otherRead ? 'r' : '-'}'
        '${otherWrite ? 'w' : '-'}'
        '${otherExecute ? 'x' : '-'}';
  }

  // Convert to octal representation
  String toOctal() {
    int owner = (ownerRead ? 4 : 0) + (ownerWrite ? 2 : 0) + (ownerExecute ? 1 : 0);
    int group = (groupRead ? 4 : 0) + (groupWrite ? 2 : 0) + (groupExecute ? 1 : 0);
    int other = (otherRead ? 4 : 0) + (otherWrite ? 2 : 0) + (otherExecute ? 1 : 0);
    return '$owner$group$other';
  }
}

// lib/data/models/unix_user.dart
class UnixUser {
  final String name;
  final String uid;

  UnixUser({required this.name, required this.uid});

  factory UnixUser.fromString(String line) {
    final parts = line.split(':');
    if (parts.length >= 3) {
      return UnixUser(
        name: parts[0],
        uid: parts[2],
      );
    }
    throw const FormatException('Invalid user string format');
  }
}

// lib/data/models/unix_group.dart
class UnixGroup {
  final String name;
  final String gid;

  UnixGroup({required this.name, required this.gid});

  factory UnixGroup.fromString(String line) {
    final parts = line.split(':');
    if (parts.length >= 3) {
      return UnixGroup(
        name: parts[0],
        gid: parts[2],
      );
    }
    throw const FormatException('Invalid group string format');
  }
}