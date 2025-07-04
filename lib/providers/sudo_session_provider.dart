import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/providers/ssh_state.dart';

// Sudo session state
enum SudoSessionStatus {
  notAuthenticated,
  authenticating,
  authenticated,
  expired,
  error
}

class SudoSessionState {
  final SudoSessionStatus status;
  final String? errorMessage;
  final DateTime? lastAuthenticated;

  const SudoSessionState({
    required this.status,
    this.errorMessage,
    this.lastAuthenticated,
  });

  SudoSessionState copyWith({
    SudoSessionStatus? status,
    String? errorMessage,
    DateTime? lastAuthenticated,
  }) {
    return SudoSessionState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastAuthenticated: lastAuthenticated ?? this.lastAuthenticated,
    );
  }

  bool get isAuthenticated => status == SudoSessionStatus.authenticated;
  bool get isSessionValid {
    if (!isAuthenticated || lastAuthenticated == null) return false;

    // Session expires after 15 minutes (like terminal sudo)
    final sessionDuration = DateTime.now().difference(lastAuthenticated!);
    return sessionDuration.inMinutes < 15;
  }
}

class SudoSessionNotifier extends StateNotifier<SudoSessionState> {
  final SSHClient sshClient;
  Timer? _sessionTimer;
  BuildContext? _currentContext;

  SudoSessionNotifier(this.sshClient) : super(const SudoSessionState(status: SudoSessionStatus.notAuthenticated));

  // Set current context for UI prompts
  void setContext(BuildContext context) {
    _currentContext = context;
  }

  // Clear context when screen disposes
  void clearContext() {
    _currentContext = null;
  }

  // Run sudo command
  Future<Map<String, dynamic>> runCommand(String command, {BuildContext? context}) async {

    /// Helper method to parse command output
    Map<String, dynamic> parseOutput(String output, String username) {

      // User creating output handling
      if (output.contains('useradd: user') && output.contains('already exists')) {
        state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'User already exists',
        );
        return {
          'success': false,
          'output': 'User already exists',
        };
      }

      // Invalid username
      if (output.contains('useradd: invalid user name')) {
        state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'Invalid username',
        );
        return {
          'success': false,
          'output': 'Invalid username format',
        };
      }

      // Home directory already exists
      if (output.contains('useradd: warning: the home directory already exists')) {
        // This is just a warning, user still created successfully
        return {
          'success': true,
          'output': '$username created successfully (home directory existed)',
        };
      }

      // Any other useradd failure
      if (output.contains('useradd:')) {
        final msg = output.split('useradd:').last.trim();
        state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'Useradd failed: $msg',
        );
        return {
          'success': false,
          'output': 'Useradd failed: $msg',
        };
      }

      // For successful user creation
      if (command.contains('useradd')) {
        return {
          'success': true,
          'output': '$username created successfully',
        };
      }

      // User Delete output handling
      // User does not exist
      if (output.contains('userdel: user') && output.contains('does not exist')) {
        state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'User does not exist',
        );
        return {
          'success': false,
          'output': 'User does not exist',
        };
      }

      // User deleted successfully - no home directory
      if (output.contains("not found") && output.contains("/home/")) {
        // Home directory not found, but that's okay
        return {
          'success': true,
          'output': '$username deleted successfully (no home directory)',
        };
      }

      // User in use by process
      if (output.contains("is currently used by process")) {
        if (!command.contains("-f")) {
          return {
            'success': false,
            'output': 'User is currently used by a process. Use force delete (-f).',
          };
        } else {
          // Ignore, user still deleted
          return {
            'success': true,
            'output': '$username force deleted successfully (was in use)',
          };
        }
      }

      // Invalid sudo password
      if (output.contains('Sorry, try again') || output.contains('incorrect password')) {
        state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'Invalid sudo password',
        );
        return {
          'success': false,
          'output': 'Invalid sudo password',
        };
      }

      // SELinux not available
      if (output.contains('semanage: command not found')) {
        return {
          'success': false,
          'output': 'SEManage tool is not installed on the system',
        };
      }

      // Any other userdel failure
      if (output.contains('userdel:')) {
        final msg = output.split('userdel:').last.trim();
        state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'Userdel failed: $msg',
        );
        return {
          'success': false,
          'output': 'Userdel failed: $msg',
        };
      }

      // All good
      state = state.copyWith(
        status: SudoSessionStatus.authenticated,
        lastAuthenticated: DateTime.now(),
        errorMessage: null,
      );

      return {
        'success': true,
        'output': '$username deleted successfully',
      };
    }
    /// End of helper method

    try {
      // Step 1: Attempt to run the command directly
      final result = await sshClient.run('sudo $command');
      final output = utf8.decode(result).trim();
      debugPrint("Output (direct): sudo $command -> $output");

      // If sudo doesn't prompt for password and command seems successful
      if (!_requiresSudoPassword(output) && _isSuccessful(output)) {
        final username = _extractUsername(command);
        state = state.copyWith(
          status: SudoSessionStatus.authenticated,
          lastAuthenticated: DateTime.now(),
          errorMessage: null,
        );
        _startSessionTimer();
        return {
          'success': true,
          'output': "$username deleted successfully",
        };
      }

      // Step 2: Password required or command failed — prompt for sudo password
      final ctx = context ?? _currentContext;
      if (ctx == null) {
        state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'No context available for password prompt',
        );
        return {'success': false, 'output': "No context available for password prompt"};
      }

      // Check if context is a BuildContext from a StatefulWidget
      bool isStatefulContext = ctx is StatefulElement || (ctx.owner != null && ctx.mounted);

      if (isStatefulContext && !ctx.mounted) {
        state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'Context is no longer mounted',
        );
        return {'success': false, 'output': "Context is no longer mounted"};
      }

      final password = await _promptSudoPassword(ctx);
      if (password == null || password.isEmpty) {
        state = state.copyWith(
          status: SudoSessionStatus.notAuthenticated,
          errorMessage: 'Password not provided',
        );
        return {
          'success': false,
          'output': null,
        };
      }

      // Step 3: Authenticated execution
      final authenticatedResult = await sshClient.run('echo "$password" | sudo -S $command');
      final authenticatedOutput = utf8.decode(authenticatedResult).trim();
      debugPrint("Authenticated output: $authenticatedOutput");

      // Confirm sudo session
      await sshClient.run('echo "$password" | sudo -S -v');
      _startSessionTimer();

      // Step 4: Parse output
      final username = _extractUsername(command);
      return parseOutput(authenticatedOutput, username);
    }
    catch (e) {
      debugPrint("Sudo command execution error: $e");
      state = state.copyWith(
        status: SudoSessionStatus.error,
        errorMessage: 'Command execution failed: $e',
      );
      return {
        'success': false,
        'output': 'Command execution failed: $e',
      };
    }
  }

  /// Helper method to check if sudo command output requires password
  bool _requiresSudoPassword(String output) {
    return output.contains('sudo: a terminal is required') ||
        output.contains('askpass helper') ||
        output.contains('sudo:') && output.contains('password');
  }

  bool _isSuccessful(String output) {
    return output.isEmpty ||
        (!output.contains('userdel:') && !output.contains('Exception') && !output.contains('error'));
  }

  String _extractUsername(String command) {
    return command.trim().split(" ").last;
  }


  /// Run sudo command with output
  // Future<String?> runCommandWithOutput(String command, {BuildContext? context}) async {
  //   try {
  //     // First, try to run the command directly
  //     final result = await sshClient.run('sudo $command');
  //     final output = utf8.decode(result);
  //
  //     // Check if command executed successfully (no password prompt)
  //     if (!output.contains('[sudo] password for') && !output.contains('password for')) {
  //       // Command executed successfully, update session state
  //       state = state.copyWith(
  //         status: SudoSessionStatus.authenticated,
  //         lastAuthenticated: DateTime.now(),
  //         errorMessage: null,
  //       );
  //       _startSessionTimer();
  //       return output;
  //     }
  //
  //     // Handle password prompt similar to runCommand()
  //     // ... (same logic as above)
  //
  //     // Return the authenticated command output
  //     final authenticatedResult = await sshClient.run('echo "$password" | sudo -S $command');
  //     return utf8.decode(authenticatedResult);
  //
  //   } catch (e) {
  //     debugPrint("Sudo command execution error: $e");
  //     state = state.copyWith(
  //         status: SudoSessionStatus.error,
  //         errorMessage: 'Command execution failed: $e'
  //     );
  //     return null;
  //   }
  // }

  Future<bool> validateAndRefreshSession() async {
    if (!state.isSessionValid) {
      try {
        // Try to refresh sudo session silently
        await sshClient.run('sudo -n -v');

        state = state.copyWith(
          status: SudoSessionStatus.authenticated,
          lastAuthenticated: DateTime.now(),
        );
        _startSessionTimer();
        return true;
      } catch (e) {
        // Session expired, need re-authentication
        state = state.copyWith(status: SudoSessionStatus.expired);
        return false;
      }
    }
    return true;
  }

  // Start session timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 1), () {
      expireSession();
    });
  }

  // Expire session
  void expireSession() {
    state = state.copyWith(
      status: SudoSessionStatus.expired,
    );
    _sessionTimer?.cancel();
  }

  // Clear session (when app closes or user logs out)
  void clearSession() {
    state = const SudoSessionState(status: SudoSessionStatus.notAuthenticated);
    _sessionTimer?.cancel();
  }

  // Prompt for sudo password
  Future<String?> _promptSudoPassword(BuildContext context) async {
    final theme = Theme.of(context);
    String? password;
    TextEditingController passwordController = TextEditingController();
    bool isPasswordVisible = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Sudo Authentication"),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text("This action requires sudo privileges. Please enter your sudo password to continue."),
                const SizedBox(height: 16),
                TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    keyboardType: TextInputType.visiblePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                            onPressed: () => setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            }),
                            icon: Icon(
                                isPasswordVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                                color: theme.primaryColor
                            )
                        )
                    )
                ),
                if (state.errorMessage != null && state.status == SudoSessionStatus.error) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                  ),
                ]
              ]
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                password = null;
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                password = passwordController.text.trim();
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            )
          ],
        ),
      ),
    );
    return password;
  }

  @override
  void dispose() {
    clearSession();
    super.dispose();
  }
}

// Provider for sudo session
final sudoSessionProvider =
    StateNotifierProvider.family<SudoSessionNotifier, SudoSessionState, SSHClient>(
        (ref, sshClient) {
  return SudoSessionNotifier(sshClient);
});

// Helper provider that automatically gets SSH client
final sudoSessionHelperProvider = Provider<SudoSessionNotifier?>((ref) {
  final sshClientAsync = ref.watch(sshClientProvider);

  return sshClientAsync.when(
    data: (client) {
      if (client == null) return null;
      return ref.read(sudoSessionProvider(client).notifier);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
