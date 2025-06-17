import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/providers/sudo_session_provider.dart';

class SudoService {
  final Ref ref;
  BuildContext? _context;

  SudoService(this.ref);

  void setContext(BuildContext context) {
    _context = context;
  }

  void clearContext() {
    _context = null;
  }

  Future<bool> executeCommand(String command) async {
    final sudoNotifier = ref.read(sudoSessionHelperProvider);
    if (sudoNotifier == null) {
      throw Exception('SSH client not available');
    }

    sudoNotifier.setContext(_context!);
    return await sudoNotifier.runCommand(command, context: _context);
  }

  // Alias for backward compatibility
  Future<bool> runCommand(String command) async {
    return await executeCommand(command);
  }
}

final sudoServiceProvider = Provider<SudoService>((ref) {
  return SudoService(ref);
});