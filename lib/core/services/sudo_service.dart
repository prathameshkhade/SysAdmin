import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/providers/sudo_session_provider.dart';

class SudoService {
  final Ref ref;
  BuildContext? _context;
  SudoSessionNotifier? _sudoNotifier;

  SudoService(this.ref);

  void setContext(BuildContext context) {
    _context = context;
    _getSudoNotifier()?.setContext(context);
  }

  void clearContext() {
    _context = null;
    _getSudoNotifier()?.clearContext();
  }

  Future<Map<String, dynamic>> executeCommand(String command) async {
    final sudoNotifier = _getSudoNotifier();
    if (sudoNotifier == null) {
      return {
        'success': false,
        'output': 'SSH client not available'
      };
    }

    if (_context == null) {
      return {
        'success': false,
        'output': 'No context available for sudo authentication'
      };
    }

    return await sudoNotifier.runCommand(command, context: _context);
  }

  // Alias for backward compatibility
  Future<Map<String, dynamic>> runCommand(String command) async {
    return await executeCommand(command);
  }

  // Helper to get and cache the sudo notifier
  SudoSessionNotifier? _getSudoNotifier() {
    if (_sudoNotifier != null) return _sudoNotifier;
    _sudoNotifier = ref.read(sudoSessionHelperProvider);
    return _sudoNotifier;
  }
}

final sudoServiceProvider = Provider<SudoService>((ref) {
  return SudoService(ref);
});