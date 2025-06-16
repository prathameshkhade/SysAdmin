import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ssh_state.dart';
import '../../providers/sudo_session_provider.dart';

class SudoService {
  final Ref ref;

  SudoService(this.ref);

  /// Execute a command with sudo privileges
  ///
  /// [command] - The command to execute (without 'sudo' prefix)
  /// [context] - BuildContext for password prompts (optional if context is set in provider)
  ///
  /// Returns true if command executed successfully, false otherwise
  Future<bool> executeCommand(String command, {BuildContext? context}) async {
    final sudoNotifier = ref.read(sudoSessionHelperProvider);
    if (sudoNotifier == null) {
      debugPrint("SSH client not available for sudo command");
      return false;
    }

    try {
      return await sudoNotifier.runCommand(command, context: context);
    } catch (e) {
      debugPrint("Error executing sudo command: $e");
      return false;
    }
  }

  /// Check if sudo session is authenticated and valid
  bool get isAuthenticated {
    final sudoNotifier = ref.read(sudoSessionHelperProvider);
    if (sudoNotifier == null) return false;

    final state = ref.read(sudoSessionProvider(ref.read(sshClientProvider).value!));
    return state.isAuthenticated && state.isSessionValid;
  }

  /// Get current sudo session status
  SudoSessionStatus get sessionStatus {
    final sudoNotifier = ref.read(sudoSessionHelperProvider);
    if (sudoNotifier == null) return SudoSessionStatus.notAuthenticated;

    try {
      final sshClient = ref.read(sshClientProvider).value!;
      final state = ref.read(sudoSessionProvider(sshClient));
      return state.status;
    } catch (e) {
      return SudoSessionStatus.error;
    }
  }

  /// Manually authenticate sudo session
  /// Useful for pre-authenticating before running multiple commands
  Future<bool> authenticate({BuildContext? context}) async {
    final sudoNotifier = ref.read(sudoSessionHelperProvider);
    if (sudoNotifier == null) {
      debugPrint("SSH client not available for sudo authentication");
      return false;
    }

    try {
      return await sudoNotifier.authenticate(context: context);
    } catch (e) {
      debugPrint("Error authenticating sudo session: $e");
      return false;
    }
  }

  /// Clear sudo session (logout)
  void clearSession() {
    final sudoNotifier = ref.read(sudoSessionHelperProvider);
    sudoNotifier?.clearSession();
  }

  /// Set context for password prompts
  void setContext(BuildContext context) {
    final sudoNotifier = ref.read(sudoSessionHelperProvider);
    sudoNotifier?.setContext(context);
  }

  /// Clear context when screen disposes
  void clearContext() {
    final sudoNotifier = ref.read(sudoSessionHelperProvider);
    sudoNotifier?.clearContext();
  }
}

// Provider for sudo service
final sudoServiceProvider = Provider<SudoService>((ref) {
  return SudoService(ref);
});