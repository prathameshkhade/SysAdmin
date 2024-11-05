// lib/data/models/file_permission.dart
class FilePermission {
  String type; // For storing d, l, or -
  bool ownerRead;
  bool ownerWrite;
  bool ownerExecute;
  bool groupRead;
  bool groupWrite;
  bool groupExecute;
  bool otherRead;
  bool otherWrite;
  bool otherExecute;
  bool setuid;
  bool setgid;
  bool sticky;

  FilePermission({
    this.type = '-',
    this.ownerRead = false,
    this.ownerWrite = false,
    this.ownerExecute = false,
    this.groupRead = false,
    this.groupWrite = false,
    this.groupExecute = false,
    this.otherRead = false,
    this.otherWrite = false,
    this.otherExecute = false,
    this.setgid = false,
    this.setuid = false,
    this.sticky = false
  });

  factory FilePermission.fromString(String permissions) {
    if (permissions.length != 10) {
      throw const FormatException('Invalid permission string length');
    }

    return FilePermission(
      type: permissions[0],
      ownerRead: permissions[1] == 'r',
      ownerWrite: permissions[2] == 'w',
      ownerExecute: permissions[3] == 'x' || permissions[3] == 's' || permissions[3] == 'S',
      setuid: permissions[3] == 's' || permissions[3] == 'S',
      groupRead: permissions[4] == 'r',
      groupWrite: permissions[5] == 'w',
      groupExecute: permissions[6] == 'x' || permissions[6] == 's' || permissions[6] == 'S',
      setgid: permissions[6] == 's' || permissions[6] == 'S',
      otherRead: permissions[7] == 'r',
      otherWrite: permissions[8] == 'w',
      otherExecute: permissions[9] == 'x' || permissions[9] == 't' || permissions[9] == 'T',
      sticky: permissions[9] == 't' || permissions[9] == 'T',
    );
  }

  String _getExecuteBit(bool execute, bool special) {
    if (special && execute) return 's';
    if (special && !execute) return 'S';
    if (!special && execute) return 'x';
    return '-';
  }

  @override
  String toString() {
    return '$type'
        '${ownerRead ? 'r' : '-'}'
        '${ownerWrite ? 'w' : '-'}'
        '${_getExecuteBit(ownerExecute, setuid)}'
        '${groupRead ? 'r' : '-'}'
        '${groupWrite ? 'w' : '-'}'
        '${_getExecuteBit(groupExecute, setgid)}'
        '${otherRead ? 'r' : '-'}'
        '${otherWrite ? 'w' : '-'}'
        '${sticky ? (otherExecute ? 't' : 'T') : (otherExecute ? 'x' : '-')}';
  }

  // Convert to octal representation
  String toOctal() {
    int special = (setuid ? 4 : 0) + (setgid ? 2 : 0) + (sticky ? 1 : 0);
    int owner = (ownerRead ? 4 : 0) + (ownerWrite ? 2 : 0) + (ownerExecute ? 1 : 0);
    int group = (groupRead ? 4 : 0) + (groupWrite ? 2 : 0) + (groupExecute ? 1 : 0);
    int other = (otherRead ? 4 : 0) + (otherWrite ? 2 : 0) + (otherExecute ? 1 : 0);
    return '$special$owner$group$other';
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