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
  Future<bool> runCommand(String command, {BuildContext? context}) async {
    try {
      // First, try to run the command directly
      final result = await sshClient.run('sudo $command');
      final output = utf8.decode(result);
      debugPrint("sudo $command: $output");

      // Check if command executed successfully (no password prompt)
      if (!output.startsWith("sudo") &&
          !output.contains('sudo: a terminal is required to read the password') &&
          !output.endsWith('askpass helper')
      ) {
        // Command executed successfully, update session state
        state = state.copyWith(
          status: SudoSessionStatus.authenticated,
          lastAuthenticated: DateTime.now(),
          errorMessage: null,
        );
        _startSessionTimer();
        return true;
      }

      // Password required - prompt user
      final ctx = context ?? _currentContext;
      if (ctx == null) {
        state = state.copyWith(
            status: SudoSessionStatus.error,
            errorMessage: 'No context available for password prompt'
        );
        return false;
      }

      final password = await _promptSudoPassword(ctx);
      if (password == null || password.isEmpty) {
        state = state.copyWith(
            status: SudoSessionStatus.notAuthenticated,
            errorMessage: 'Password not provided'
        );
        return false;
      }

      // Execute command with password using echo method
      final authenticatedResult = await sshClient.run('echo "$password" | sudo -S $command');
      final authenticatedOutput = utf8.decode(authenticatedResult);

      debugPrint("Authenticated output (\"echo \"$password\" | sudo -S $command) -> $authenticatedOutput");

      // Update the error message if any
      if (authenticatedOutput.contains("userdel:")) {
        var output = authenticatedOutput.split(':').last.trim();
        debugPrint("Command execution failed: $output");
        state = state.copyWith(
            status: SudoSessionStatus.error,
            errorMessage: 'Command execution failed: $output'
        );
        return false;
      }

      // Check if authentication was successful
      if (authenticatedOutput.contains('Sorry, try again') ||
          authenticatedOutput.contains('incorrect password')) {
        state = state.copyWith(
            status: SudoSessionStatus.error,
            errorMessage: 'Invalid sudo password'
        );
        return false;
      }

      // Authentication successful - establish session
      await sshClient.run('echo "$password" | sudo -S -v');

      state = state.copyWith(
        status: SudoSessionStatus.authenticated,
        lastAuthenticated: DateTime.now(),
        errorMessage: null,
      );

      _startSessionTimer();
      return true;

    }
    catch (e) {
      debugPrint("Sudo command execution error: $e");
      state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'Command execution failed: $e'
      );
      return false;
    }
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
final sudoSessionProvider = StateNotifierProvider.family<SudoSessionNotifier, SudoSessionState, SSHClient>((ref, sshClient) {
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