/// Model representing a Linux user based on /etc/passwd file information
/// and additional system data.
class LinuxUser {
  final String username;
  final String password; // Usually 'x' in /etc/passwd indicating shadow password
  final int uid; // User ID
  final int gid; // Primary Group ID
  final String comment; // User comment/full name (GECOS field)
  final String homeDirectory;
  final String shell;
  final DateTime? lastLogin;
  final bool isLocked;
  final DateTime? passwordLastChanged;
  final int? passwordMaxDays;
  final int? passwordMinDays;
  final int? passwordWarnDays;
  // TODO: Add List<Group> groups; when implementing group management feature

  LinuxUser({
    required this.username,
    required this.password,
    required this.uid,
    required this.gid,
    required this.comment,
    required this.homeDirectory,
    required this.shell,
    this.lastLogin,
    this.isLocked = false,
    this.passwordLastChanged,
    this.passwordMaxDays,
    this.passwordMinDays,
    this.passwordWarnDays,
  });

  /// Create a LinuxUser from a raw /etc/passwd line
  factory LinuxUser.fromPasswdLine(String line, {
    DateTime? lastLogin,
    bool isLocked = false,
    DateTime? passwordLastChanged,
    int? passwordMaxDays,
    int? passwordMinDays,
    int? passwordWarnDays,
  }) {
    final parts = line.split(':');
    if (parts.length < 7) {
      throw const FormatException('Invalid /etc/passwd line format');
    }

    return LinuxUser(
      username: parts[0],
      password: parts[1],
      uid: int.parse(parts[2]),
      gid: int.parse(parts[3]),
      comment: parts[4],
      homeDirectory: parts[5],
      shell: parts[6],
      lastLogin: lastLogin,
      isLocked: isLocked,
      passwordLastChanged: passwordLastChanged,
      passwordMaxDays: passwordMaxDays,
      passwordMinDays: passwordMinDays,
      passwordWarnDays: passwordWarnDays,
    );
  }

  /// Create a copy of this LinuxUser with modified fields
  LinuxUser copyWith({
    String? username,
    String? password,
    int? uid,
    int? gid,
    String? comment,
    String? homeDirectory,
    String? shell,
    DateTime? lastLogin,
    bool? isLocked,
    DateTime? passwordLastChanged,
    int? passwordMaxDays,
    int? passwordMinDays,
    int? passwordWarnDays,
  }) {
    return LinuxUser(
      username: username ?? this.username,
      password: password ?? this.password,
      uid: uid ?? this.uid,
      gid: gid ?? this.gid,
      comment: comment ?? this.comment,
      homeDirectory: homeDirectory ?? this.homeDirectory,
      shell: shell ?? this.shell,
      lastLogin: lastLogin ?? this.lastLogin,
      isLocked: isLocked ?? this.isLocked,
      passwordLastChanged: passwordLastChanged ?? this.passwordLastChanged,
      passwordMaxDays: passwordMaxDays ?? this.passwordMaxDays,
      passwordMinDays: passwordMinDays ?? this.passwordMinDays,
      passwordWarnDays: passwordWarnDays ?? this.passwordWarnDays,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return (other is LinuxUser && other.username == username && other.uid == uid);
  }

  @override
  int get hashCode => username.hashCode ^ uid.hashCode;

  @override
  String toString() {
    return 'LinuxUser(username: $username, uid: $uid)';
  }
}