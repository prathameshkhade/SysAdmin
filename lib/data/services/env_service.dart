import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/default_shell_config.dart';
import 'package:sysadmin/providers/ssh_state.dart';
import '../models/env_variable.dart';

class EnvService {
  late final SSHClient _sshClient;
  late final DefaultShellConfig _shellConfig;

  // Private Constructor
  static Future<EnvService> create({required WidgetRef ref}) async {
    final service = EnvService._();
    service._sshClient = ref.read(sshClientProvider).value!;
    service._shellConfig = await DefaultShellConfig.detect(service._sshClient);
    return service;
  }
  EnvService._();

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
    final result = await _sshClient.run('cat /etc/environment');

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
          ? 'sudo sh -c \'echo "${variable.name}=\'${variable.value}\'" >> ${_shellConfig.globalPath}\''
          : 'echo "${_shellConfig.exportCommand} ${variable.name}=\'${variable.value}\'" >> ${_shellConfig.localPath}${_shellConfig.sourceCommand != null ? ' && ${_shellConfig.sourceCommand}' : ''}';

      await _sshClient.run(command);
      return true;
    }
    catch (e) {
      debugPrint("Error creating variable: $e");
      return false;
    }
  }

  Future<bool> updateVariable(String oldName, EnvVariable variable) async {
    try {
      // Delete old variable
      await deleteVariable(oldName, variable.isGlobal);

      // Create new variable with updated values
      final command = variable.isGlobal
          ? 'sudo sh -c \'echo "${variable.name}=\'${variable.value}\'" >> ${_shellConfig.globalPath}\''
          : 'echo "${_shellConfig.exportCommand} ${variable.name}=\'${variable.value}\'" >> ${_shellConfig.localPath}${_shellConfig.sourceCommand != null ? ' && ${_shellConfig.sourceCommand}' : ''}';

      await _sshClient.run(command);
      return true;
    }
    catch (e) {
      debugPrint("Error updating variable: $e");
      return false;
    }
  }

  Future<void> deleteVariable(String name, bool isGlobal) async {
    final path = isGlobal ? _shellConfig.globalPath : _shellConfig.localPath;
    final command = isGlobal
        ? 'sudo sed -i "/^$name=/d" $path'
        : 'sed -i "/^${_shellConfig.exportCommand} $name=/d" $path';
    await _sshClient.run(command);
  }
}
