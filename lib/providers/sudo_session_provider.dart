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
  final SSHSession? authenticatedSession;

  const SudoSessionState({
    required this.status,
    this.errorMessage,
    this.lastAuthenticated,
    this.authenticatedSession,
  });

  SudoSessionState copyWith({
    SudoSessionStatus? status,
    String? errorMessage,
    DateTime? lastAuthenticated,
    SSHSession? authenticatedSession,
  }) {
    return SudoSessionState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastAuthenticated: lastAuthenticated ?? this.lastAuthenticated,
      authenticatedSession: authenticatedSession ?? this.authenticatedSession,
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

  // Authenticate sudo session
  Future<bool> authenticate({BuildContext? context}) async {
    final ctx = context ?? _currentContext;
    if (ctx == null) {
      state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'No context available for password prompt'
      );
      return false;
    }

    state = state.copyWith(status: SudoSessionStatus.authenticating);

    try {
      // Prompt for sudo password
      final password = await _promptSudoPassword(ctx);
      if (password == null || password.isEmpty) {
        state = state.copyWith(
            status: SudoSessionStatus.notAuthenticated,
            errorMessage: 'Password not provided'
        );
        return false;
      }

      // Create authenticated session
      final session = await sshClient.shell(
          pty: const SSHPtyConfig(type: 'xterm')
      );

      final completer = Completer<bool>();
      bool passwordPromptReceived = false;
      bool authenticationSuccessful = false;
      final outputBuffer = StringBuffer();

      session.stdout.listen((data) {
        final output = utf8.decode(data);
        outputBuffer.write(output);
        debugPrint("SUDO SESSION STDOUT: $output");

        if (output.contains("[sudo] password for")) {
          passwordPromptReceived = true;
          // Send password
          session.write(utf8.encode('$password\n'));
        } else if (passwordPromptReceived && output.contains('\$')) {
          // Command prompt appeared after password - authentication successful
          authenticationSuccessful = true;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        } else if (output.contains("Sorry, try again") || output.contains("incorrect password")) {
          // Authentication failed
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      });

      session.stderr.listen((data) {
        final error = utf8.decode(data);
        debugPrint("SUDO SESSION STDERR: $error");
        if (error.contains("Sorry, try again") || error.contains("incorrect password")) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      });

      // Start sudo validation
      session.write(utf8.encode('sudo -v\n'));

      // Wait for authentication result with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );

      if (result && authenticationSuccessful) {
        state = state.copyWith(
          status: SudoSessionStatus.authenticated,
          lastAuthenticated: DateTime.now(),
          authenticatedSession: session,
          errorMessage: null,
        );

        // Start session timer
        _startSessionTimer();
        return true;
      } else {
        session.close();
        state = state.copyWith(
            status: SudoSessionStatus.error,
            errorMessage: 'Invalid sudo password'
        );
        return false;
      }
    } catch (e) {
      debugPrint("Sudo authentication error: $e");
      state = state.copyWith(
          status: SudoSessionStatus.error,
          errorMessage: 'Authentication failed: $e'
      );
      return false;
    }
  }

  // Run sudo command
  Future<bool> runCommand(String command, {BuildContext? context}) async {
    // Check if session is valid
    if (!state.isSessionValid) {
      final authenticated = await authenticate(context: context);
      if (!authenticated) return false;
    }

    final session = state.authenticatedSession;
    if (session == null) return false;

    try {
      final completer = Completer<bool>();
      bool commandCompleted = false;
      final outputBuffer = StringBuffer();

      session.stdout.listen((data) {
        final output = utf8.decode(data);
        outputBuffer.write(output);
        debugPrint("SUDO COMMAND STDOUT: $output");

        // Check for command completion indicators
        if (output.contains('\$') && !commandCompleted) {
          commandCompleted = true;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      });

      session.stderr.listen((data) {
        final error = utf8.decode(data);
        debugPrint("SUDO COMMAND STDERR: $error");

        // If there's an error, still complete the command
        if (!commandCompleted && error.isNotEmpty) {
          commandCompleted = true;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      });

      // Execute the command
      session.write(utf8.encode('$command\n'));

      // Wait for command completion
      final result = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("Command timeout: $command");
          return false;
        },
      );

      return result;
    } catch (e) {
      debugPrint("Error running sudo command: $e");
      return false;
    }
  }

  // Validate current session
  Future<bool> validateSession() async {
    if (!state.isAuthenticated || state.authenticatedSession == null) {
      return false;
    }

    try {
      final session = state.authenticatedSession!;

      // Send sudo -n (non-interactive) to check if we still have sudo privileges
      final completer = Completer<bool>();
      session.stdout.listen((data) {
        final output = utf8.decode(data);
        if (output.contains('\$')) {
          completer.complete(true);
        }
      });

      session.stderr.listen((data) {
        final error = utf8.decode(data);
        if (error.contains("password is required")) {
          completer.complete(false);
        }
      });

      session.write(utf8.encode('sudo -n true\n'));

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint("Session validation error: $e");
      return false;
    }
  }

  // Start session timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 15), () {
      expireSession();
    });
  }

  // Expire session
  void expireSession() {
    state.authenticatedSession?.close();
    state = state.copyWith(
      status: SudoSessionStatus.expired,
      authenticatedSession: null,
    );
    _sessionTimer?.cancel();
  }

  // Clear session (when app closes or user logs out)
  void clearSession() {
    state.authenticatedSession?.close();
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