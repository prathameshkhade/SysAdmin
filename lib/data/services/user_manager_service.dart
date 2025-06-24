import 'package:flutter/material.dart';
import 'package:sysadmin/data/services/ssh_session_manager.dart';

import '../../core/services/sudo_service.dart';
import '../models/linux_user.dart';

class UserManagerService {
  final SSHSessionManager sessionManager;
  final SudoService sudoService;

  UserManagerService(this.sessionManager, this.sudoService);

  /// Retrieves all Linux users from the system
  Future<List<LinuxUser>> getAllUsers() async {
    try {
      // Get basic user info from /etc/passwd
      final passwdResult = await sessionManager.execute('cat /etc/passwd');

      if (passwdResult.isEmpty) {
        throw Exception('Failed to read /etc/passwd: $passwdResult');
      }

      // Get account status (locked/unlocked) using passwd -S
      final shadowInfoResult = await sessionManager.execute(
          'for user in \$(cut -d: -f1 /etc/passwd); do passwd -S \$user 2>/dev/null || echo \$user L; done'
      );

      // Parse passwd lines into LinuxUser objects
      final List<LinuxUser> users = [];
      final lines = passwdResult.split("\n");

      // Create a map for account status
      final Map<String, bool> lockedStatusMap = _parseLockedStatus(shadowInfoResult);

      // Create a map for password aging information
      final Map<String, Map<String, dynamic>> shadowInfoMap = _parseShadowInfo(shadowInfoResult);

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        try {
          final parts = line.split(':');
          final username = parts[0];

          // // Get last login time information
          // final lastLoginResult = await sessionManager.execute('last -F $username -n 1 | head -n 1');
          //
          // // Create a map for last login times
          // final DateTime? lastLoginDatetime = _parseLastLoginTimes(lastLoginResult);


          final user = LinuxUser.fromPasswdLine(
            line,
            // lastLogin: lastLoginDatetime,
            isLocked: lockedStatusMap[username] ?? false,
            passwordLastChanged: shadowInfoMap[username]?['lastChanged'],
            passwordMaxDays: shadowInfoMap[username]?['maxDays'],
            passwordMinDays: shadowInfoMap[username]?['minDays'],
            passwordWarnDays: shadowInfoMap[username]?['warnDays'],
          );

          users.add(user);
        }
        catch (e) {
          debugPrint('Error parsing user line: $e');
        }
      }

      return users;
    }
    catch (e) {
      debugPrint('Error in getAllUsers: $e');
      throw Exception('Failed to retrieve users: $e');
    }
  }

  /// Create a new Linux user
  Future<bool?> createUser({
    required LinuxUser user,
    String? password,
    bool createHomeDirectory = true,
    bool createUserGroup = true,
    String? customShell,
    DateTime? expireDate,
  }) async {
    final cmd = StringBuffer('useradd ');

    // Parse the parameters
    cmd.write(createHomeDirectory ? "-m " : "-M ");
    if (createUserGroup) cmd.write("-U ");
    if (customShell != null && customShell.isNotEmpty && customShell != 'default') cmd.write("-s $customShell ");
    if (user.comment.isNotEmpty) cmd.write("-c \"${user.comment}\" ");
    if (user.homeDirectory != "/home/${user.username}") cmd.write("-d ${user.homeDirectory} ");
    if (expireDate != null) {
      final expireDateStr = "${expireDate.year}-${expireDate.month.toString().padLeft(2, '0')}-${expireDate.day.toString().padLeft(2, '0')}";
      cmd.write("-e $expireDateStr ");
    }
    // Add the password
    if (password != null && password.isNotEmpty) {
      cmd.write("-p \$(echo $password | openssl passwd -6 -stdin) ");
    }

    // Add the username
    cmd.write(user.username);

    try {
      final res = await sudoService.executeCommand(cmd.toString());
      if (!res["success"]) {
        if(res["output"] == null) return null;
        throw Exception(res["output"] ?? "Failed to create user");
      }

      return true;
    }
    catch (e) {
      debugPrint("Error while creating user: $e");
      throw Exception("Error while creating user: $e");
    }
  }

  /// Update an existing Linux user
  Future<Map<String, dynamic>> updateUser({
    required LinuxUser originalUser,
    required LinuxUser updatedUser,
    String? newPassword,
    bool changeShell = false,
    bool changeHomeDirectory = false,
    bool moveHomeDirectory = false,
  }) async {
   StringBuffer cmd = StringBuffer("usermod ");
   final String username = originalUser.username;
   final String newUsername = updatedUser.username;

   try {
     // Add all needed options to a single usermod command
     // Change username if different
     if (username != newUsername) {
       cmd.write('-l $newUsername ');
     }

     // Change comment/full name if different
     if (originalUser.comment != updatedUser.comment) {
       cmd.write('-c "${updatedUser.comment}" ');
     }

     // Change shell if different and changeShell is true
     if (changeShell && originalUser.shell != updatedUser.shell && updatedUser.shell != 'default') {
       cmd.write('-s ${updatedUser.shell} ');
     }

     // Change home directory if different and changeHomeDirectory is true
     if (changeHomeDirectory && originalUser.homeDirectory != updatedUser.homeDirectory) {
       final moveFlag = moveHomeDirectory ? '-m ' : '';
       cmd.write('$moveFlag-d ${updatedUser.homeDirectory} ');
     }

     // Change password if provided
     if (newPassword != null && newPassword.isNotEmpty) {
       cmd.write("-p \$(echo '$newPassword' | openssl passwd -6 -stdin) ");
     }

     // Add the username at the end (the user to modify)
     cmd.write(username);

     // Execute the usermod command if any changes were requested
     if (cmd.toString() != "usermod $username") {
       final res = await sudoService.executeCommand(cmd.toString());
       if (!res["success"]) {
         if (res["output"] == null) {
           return {'success': false, 'output': null}; // User cancelled sudo
         }

         // Handle specific errors
         String errorMessage = _parseUsermodError(res["output"] ?? "Unknown error");
         return {'success': false, 'output': errorMessage};
       }
     }

     return {'success': true, 'output': 'User updated successfully'};
    }
    catch (e) {
      debugPrint("Error while updating user: $e");
      return {'success': false, 'output': 'Unexpected error occurred while updating user'};
    }
  }

  /// Parse usermod command errors into user-friendly messages
  String _parseUsermodError(String error) {
    if (error.contains('already exists')) {
      return 'Username already exists. Please choose a different username.';
    }
    else if (error.contains('invalid user name')) {
      return 'Invalid username format. Use only lowercase letters, numbers, underscores, and hyphens.';
    }
    else if (error.contains('does not exist')) {
      return 'User does not exist or cannot be found.';
    }
    else if (error.contains('currently used by process')) {
      return 'Cannot modify user as they are currently logged in. Please ask them to log out first.';
    }
    else if (error.contains('permission denied') || error.contains('not permitted')) {
      return 'Permission denied. Administrator privileges required.';
    }
    else if (error.contains('invalid shell')) {
      return 'Invalid shell specified. Please select a valid shell from the list.';
    }
    else if (error.contains('home directory')) {
      return 'Error with home directory operation. Please check the path and permissions.';
    }
    else {
      return 'Failed to update user: ${error.length > 100 ? '${error.substring(0, 100)}...' : error}';
    }
  }

  /// Parse password change errors into user-friendly messages
  // String _parsePasswordError(String error) {
  //   if (error.contains('weak password') || error.contains('too simple')) {
  //     return 'Password is too weak. Please use a stronger password.';
  //   }
  //   else if (error.contains('too short')) {
  //     return 'Password is too short. Please use a longer password.';
  //   }
  //   else if (error.contains('based on dictionary word')) {
  //     return 'Password is based on dictionary word. Please use a more secure password.';
  //   }
  //   else {
  //     return error.length > 100 ? '${error.substring(0, 100)}...' : error;
  //   }
  // }

  /// Delete a Linux user
  Future<bool?> deleteUser({
    required LinuxUser user,
    bool removeHomeDirectory = false,
    bool removeForcefully = false,
    bool removeSELinuxMapping = false,
  }) async {
    final cmd = StringBuffer('userdel ');

    // Parse the parameters
    if (removeHomeDirectory) cmd.write("-r ");
    if (removeForcefully) cmd.write("-f ");
    if (removeSELinuxMapping) cmd.write("-Z ");

    // final command - append the username
    cmd.write(user.username);

    // Delete the user using the improved sudo service
    try {
      final res = await sudoService.executeCommand(cmd.toString());
      if (!res["success"]) {
        // return null if password is not entered by the user
        if(res["output"] == null) return null;
        throw Exception(res["output"] ?? "Failed to delete user");
      }
      return true;
    }
    catch (e) {
      debugPrint("Error while deleting user: $e");
      throw Exception("Error while deleting user: $e");
    }
  }

  /// Helper method to parse last login times
  /// eg. prathame tty7         :0               Sun Jun 22 17:58:29 2025 - still logged in
  // DateTime? _parseLastLoginTimes(String lastOutput) {
  //   DateTime? lastLoginDateTime;
  //   if (lastOutput != "\n") {
  //     var dateExpr = RegExp(r'([A-Za-z]{3} [A-Za-z]{3} \d{1,2} \d{2}:\d{2}:\d{2} \d{4})');
  //     final match = dateExpr.firstMatch(lastOutput);
  //
  //     if (match != null) {
  //       String datetimeStr = match.group(0)!;
  //
  //       // Parse the string to DateTime
  //       final format = DateFormat('EEE MMM dd HH:mm:ss yyyy');
  //       lastLoginDateTime = format.parse(datetimeStr);
  //
  //       debugPrint("Last logged in: $lastLoginDateTime");
  //     }
  //     else {
  //       debugPrint("No match found for last login time");
  //     }
  //   }
  //
  //   return lastLoginDateTime;
  // }

  Map<String, bool> _parseLockedStatus(String statusOutput) {
    // Keep original implementation
    final Map<String, bool> lockedMap = {};
    final lines = statusOutput.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        final parts = line.split(' ');
        if (parts.length < 2) continue;

        final username = parts[0];
        final isLocked = parts.contains('L');
        lockedMap[username] = isLocked;
      }
      catch (e) {
        debugPrint('Error parsing account status: $e');
      }
    }

    return lockedMap;
  }

  Map<String, Map<String, dynamic>> _parseShadowInfo(String shadowOutput) {
    // Keep original implementation
    final Map<String, Map<String, dynamic>> infoMap = {};
    final lines = shadowOutput.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        final parts = line.split(' ');
        if (parts.length < 2) continue;

        final username = parts[0];
        final info = <String, dynamic>{};

        // Parse shadow password info
        if (parts.length >= 3) {
          info['status'] = parts[1]; // 'P' for usable password, 'L' for locked

          if (parts.length >= 4) {
            final lastChangedDays = int.tryParse(parts[2]);
            if (lastChangedDays != null) {
              // Convert days since 1970-01-01 to DateTime
              info['lastChanged'] = DateTime.fromMillisecondsSinceEpoch(
                  lastChangedDays * 24 * 60 * 60 * 1000
              );
            }

            if (parts.length >= 5) {
              info['minDays'] = int.tryParse(parts[3]);

              if (parts.length >= 6) {
                info['maxDays'] = int.tryParse(parts[4]);

                if (parts.length >= 7) {
                  info['warnDays'] = int.tryParse(parts[5]);
                }
              }
            }
          }
        }

        infoMap[username] = info;
      }
      catch (e) {
        debugPrint('Error parsing shadow info: $e');
      }
    }

    return infoMap;
  }
}