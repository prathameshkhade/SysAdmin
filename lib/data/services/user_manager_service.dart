import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

import '../../core/services/sudo_service.dart';
import '../models/linux_user.dart';

class UserManagerService {
  final SSHClient sshClient;
  final SudoService sudoService;

  UserManagerService(this.sshClient, this.sudoService);

  /// Retrieves all Linux users from the system
  Future<List<LinuxUser>> getAllUsers() async {
    try {
      // Get basic user info from /etc/passwd
      final passwdResult = await sshClient.run('cat /etc/passwd');
      final output = utf8.decode(passwdResult);

      if (output.isEmpty) {
        throw Exception('Failed to read /etc/passwd: $output');
      }

      // Get last login time information
      final lastLoginResult = await sshClient.execute(
        'last -F | head -n 50', // Limit to 50 entries for performance
      );

      // Get account status (locked/unlocked) using passwd -S
      final shadowInfoResult = await sshClient.execute(
          'for user in \$(cut -d: -f1 /etc/passwd); do passwd -S \$user 2>/dev/null || echo \$user L; done'
      );

      // Parse passwd lines into LinuxUser objects
      final List<LinuxUser> users = [];
      final lines = output.split("\n");

      // Create a map for last login times
      final Map<String, DateTime?> lastLoginMap = _parseLastLoginTimes(lastLoginResult.stdout.toString());

      // Create a map for account status
      final Map<String, bool> lockedStatusMap = _parseLockedStatus(shadowInfoResult.stdout.toString());

      // Create a map for password aging information
      final Map<String, Map<String, dynamic>> shadowInfoMap = _parseShadowInfo(shadowInfoResult.stdout.toString());

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        try {
          final parts = line.split(':');
          final username = parts[0];

          final user = LinuxUser.fromPasswdLine(
            line,
            lastLogin: lastLoginMap[username],
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
    if (createHomeDirectory) cmd.write("-m ");
    if (createUserGroup) cmd.write("-U ");
    if (customShell != null && customShell.isNotEmpty) cmd.write("-s $customShell ");
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
  Map<String, DateTime?> _parseLastLoginTimes(String lastOutput) {
    // Keep original implementation
    final Map<String, DateTime?> lastLoginMap = {};
    final lines = lastOutput.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Skip lines that don't match the expected format
      if (!line.contains(' ')) continue;

      final parts = line.split(' ').where((part) => part.isNotEmpty).toList();
      if (parts.length < 4) continue;

      final username = parts[0];
      try {
        // Format typically looks like: username tty1 host Wed Jun 12 14:32:01 2025
        // We need to extract the date part (removing the IP/host if present)
        int dateStartIndex = 3;

        // Try to reconstruct a parsable date
        // First, identify if there's a day of week prefix (Mon, Tue, Wed, etc.)
        final possibleDateParts = parts.sublist(dateStartIndex);
        String dateTimeStr = possibleDateParts.join(' ');

        // Attempt to parse this date format
        DateTime? parsedDate;

        // Try common format: day-of-week month day HH:MM:SS year
        try {
          // Example: "Wed Jun 12 14:32:01 2025"
          parsedDate = DateTime.parse(dateTimeStr);
        } catch (_) {
          // If that fails, try more general approach for handling various formats
          try {
            // Pattern like "Jun 12 14:32:01 2025"
            final dateRegex = RegExp(r'([A-Za-z]{3}\s+\d{1,2}\s+\d{1,2}:\d{2}:\d{2}\s+\d{4})');
            final match = dateRegex.firstMatch(dateTimeStr);
            if (match != null) {
              final extractedDate = match.group(1);
              if (extractedDate != null) {
                // Convert month abbreviation to number
                final months = {
                  'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
                  'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
                  'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
                };

                // Split the date parts
                final dateParts = extractedDate.split(' ');
                if (dateParts.length >= 4) {
                  final month = months[dateParts[0]];
                  final day = dateParts[1].padLeft(2, '0');
                  final time = dateParts[2];
                  final year = dateParts[3];

                  // Convert to ISO format
                  final isoDate = '$year-$month-$day $time';
                  parsedDate = DateTime.parse(isoDate);
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing last login date for $username: $e');
          }
        }

        lastLoginMap[username] = parsedDate;
      } catch (e) {
        debugPrint('Error parsing last login for $username: $e');
      }
    }

    return lastLoginMap;
  }

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