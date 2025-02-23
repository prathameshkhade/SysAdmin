import 'package:dartssh2/dartssh2.dart';

class ShellConfig {
  final String localConfigPath;
  final String globalConfigPath;
  final String exportCommand;
  final String shellName;

  const ShellConfig._({
    required this.localConfigPath,
    required this.globalConfigPath,
    required this.exportCommand,
    required this.shellName,
  });

  /// Factory method to create ShellConfig based on shell path
  factory ShellConfig.fromShellPath(String shellPath) {
    // Extract shell name from path (e.g., /bin/zsh -> zsh)
    final shellName = shellPath.split('/').last;

    switch (shellName) {
      case 'bash':
        return const ShellConfig._(
          shellName: 'bash',
          localConfigPath: '~/.bashrc',
          globalConfigPath: '/etc/profile',
          exportCommand: 'export',
        );

      case 'zsh':
        return const ShellConfig._(
          shellName: 'zsh',
          localConfigPath: '~/.zshrc',
          globalConfigPath: '/etc/zsh/zshenv',
          exportCommand: 'export',
        );

      case 'fish':
        return const ShellConfig._(
          shellName: 'fish',
          localConfigPath: '~/.config/fish/config.fish',
          globalConfigPath: '/etc/fish/config.fish',
          exportCommand: 'set -x',
        );

      case 'tcsh':
      case 'csh':
        return const ShellConfig._(
          shellName: 'tcsh/csh',
          localConfigPath: '~/.tcshrc',
          globalConfigPath: '/etc/csh.cshrc',
          exportCommand: 'setenv',
        );

      case 'ksh':
        return const ShellConfig._(
          shellName: 'ksh',
          localConfigPath: '~/.kshrc',
          globalConfigPath: '/etc/profile',
          exportCommand: 'export',
        );

      case 'dash':
        return const ShellConfig._(
          shellName: 'dash',
          localConfigPath: '~/.profile',
          globalConfigPath: '/etc/profile',
          exportCommand: 'export',
        );

      case 'elvish':
        return const ShellConfig._(
          shellName: 'elvish',
          localConfigPath: '~/.config/elvish/rc.elv',
          globalConfigPath: '/etc/elvish/rc.elv',
          exportCommand: 'set-env',
        );

      case 'xonsh':
        return const ShellConfig._(
          shellName: 'xonsh',
          localConfigPath: '~/.xonshrc',
          globalConfigPath: '/etc/xonshrc',
          exportCommand: '\$',
        );

      default: // Fallback to bash configuration
        return const ShellConfig._(
          shellName: 'unknown (using bash)',
          localConfigPath: '~/.bashrc',
          globalConfigPath: '/etc/profile',
          exportCommand: 'export',
        );
    }
  }

  /// Async factory to detect current shell and create appropriate config
  static Future<ShellConfig> detect(SSHClient client) async {
    final result = await client.run('echo \$SHELL');
    final shellPath = String.fromCharCodes(result).trim();
    return ShellConfig.fromShellPath(shellPath);
  }

  /// Get alternative local config paths for the shell
  List<String> get alternativeLocalPaths {
    switch (shellName) {
      case 'bash':
        return ['~/.bash_profile'];
      case 'zsh':
        return ['~/.zshenv', '~/.zprofile'];
      case 'fish':
        return ['~/.config/fish/conf.d/*.fish'];
      case 'tcsh/csh':
        return ['~/.cshrc'];
      case 'ksh':
        return ['~/.profile'];
      default:
        return [];
    }
  }

  /// Get alternative global config paths for the shell
  List<String> get alternativeGlobalPaths {
    switch (shellName) {
      case 'bash':
        return ['/etc/bash.bashrc', '/etc/profile.d/*.sh'];
      case 'zsh':
        return ['/etc/zshrc', '/etc/zsh/zshrc'];
      case 'fish':
        return ['/etc/fish/conf.d/*.fish'];
      case 'tcsh/csh':
        return ['/etc/csh.login'];
      default:
        return [];
    }
  }

  /// Check if the shell requires sourcing after modification
  bool get requiresSourceAfterModification {
    return ['bash', 'zsh', 'ksh', 'dash'].contains(shellName);
  }

  /// Get source command if required
  String? get sourceCommand {
    if (!requiresSourceAfterModification) return null;

    switch (shellName) {
      case 'bash':
        return 'source ~/.bashrc';
      case 'zsh':
        return 'source ~/.zshrc';
      case 'ksh':
        return '. ~/.kshrc';
      case 'dash':
        return '. ~/.profile';
      default:
        return null;
    }
  }
}