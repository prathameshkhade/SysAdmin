import 'package:dartssh2/dartssh2.dart';
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
    return String.fromCharCodes(result)
        .trim()
        .split('\n')
        .map((e) => EnvVariable.fromString(e, false))
        .toList();
  }

  Future<List<EnvVariable>> fetchGlobalVariables() async {
    final result = await _sshClient.run('sudo cat /etc/environment');
    return String.fromCharCodes(result)
        .trim()
        .split('\n')
        .where((e) => e.contains('='))
        .map((e) => EnvVariable.fromString(e, true))
        .toList();
  }

  Future<void> createVariable(EnvVariable variable) async {
    final command = variable.isGlobal
        ? 'sudo sh -c \'echo "${variable.name}=${variable.value}" >> /etc/environment\''
        : 'echo "export ${variable.name}=${variable.value}" >> ~/.bashrc && source ~/.bashrc';
    await _sshClient.run(command);
  }

  Future<void> updateVariable(String oldName, EnvVariable variable) async {
    await deleteVariable(oldName, variable.isGlobal);
    await createVariable(variable);
  }

  Future<void> deleteVariable(String name, bool isGlobal) async {
    final command = isGlobal
        ? 'sudo sed -i "/^$name=/d" /etc/environment'
        : 'sed -i "/^export $name=/d" ~/.bashrc && source ~/.bashrc';
    await _sshClient.run(command);
  }
}