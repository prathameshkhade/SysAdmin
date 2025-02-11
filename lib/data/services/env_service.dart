import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/providers/ssh_state.dart';
import '../models/env_variable.dart';

class EnvService {
  late final SSHClient _sshClient;

  EnvService({required WidgetRef ref}) {
    _sshClient = ref.read(sshClientProvider).value!;
  }

  Future<List<EnvVariable>> fetchLocalVariables() async {
    final result = await _sshClient.run('env');

    // Debug: Print the raw result
    debugPrint("${result.length}");
    debugPrint(String.fromCharCodes(result));

    return String.fromCharCodes(result)
        .trim()
        .split('\n')
        .map((e) => EnvVariable.fromString(e, false))
        .toList();
  }


  Future<List<EnvVariable>> fetchGlobalVariables() async {
    final result = await _sshClient.run('sudo cat /etc/environment');

    // Debug: Print the raw result
    debugPrint("${result.length}");
    debugPrint(String.fromCharCodes(result));

    return String.fromCharCodes(result)
        .trim()
        .split('\n')
        .where((e) => e.contains('='))
        .map((e) => EnvVariable.fromString(e, true))
        .toList();
  }

  FutureOr<bool> createVariable(EnvVariable variable) async {
    try {
      final command = variable.isGlobal
          ? 'sudo sh -c \'echo "${variable.name}=${variable.value}" >> /etc/environment\''
          : 'echo "export ${variable.name}=${variable.value}" >> ~/.bashrc && . ~/.bashrc';

      await _sshClient.run(command);

      // Add a small delay to ensure file operations complete
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }
    catch (e) {
      debugPrint("Error creating variable: $e");
      return false;
    }
  }

  Future<bool> updateVariable(String oldName, EnvVariable variable) async {
    try {
      await deleteVariable(oldName, variable.isGlobal);
      return await createVariable(variable);
    }
    catch (e) {
      debugPrint("Error updating variable: $e");
      return false;
    }
  }

  Future<void> deleteVariable(String name, bool isGlobal) async {
    final command = isGlobal
        ? 'sudo sed -i "/^$name=/d" /etc/environment'
        : 'sed -i "/^export $name=/d" ~/.bashrc && source ~/.bashrc';
    await _sshClient.run(command);
  }
}
