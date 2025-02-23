import 'package:dartssh2/dartssh2.dart';

class DefaultShellConfig {
  final String localPath;
  final String globalPath;
  final String exportCommand;
  final String shellName;

  const DefaultShellConfig._({
    required this.localPath,
    required this.globalPath,
    required this.exportCommand,
    required this.shellName,
  });

  /// Factory method to create ShellConfig based on shell path
  factory DefaultShellConfig.fromShellPath(String shellPath) {
    // Extract shell name from path (e.g., /bin/zsh -> zsh)
    final shellName = shellPath.split('/').last;

    switch (shellName) {
      case 'bash':
        return const DefaultShellConfig._(
          shellName: 'bash',
          localPath: '~/.bashrc',
          globalPath: '/etc/profile',
          exportCommand: 'export',
        );

      case 'zsh':
        return const DefaultShellConfig._(
          shellName: 'zsh',
          localPath: '~/.zshenv',
          globalPath: '/etc/zsh/zshenv',
          exportCommand: 'export',
        );

      case 'fish':
        return const DefaultShellConfig._(
          shellName: 'fish',
          localPath: '~/.config/fish/config.fish',
          globalPath: '/etc/fish/config.fish',
          exportCommand: 'set -x',
        );

      case 'tcsh':
      case 'csh':
        return const DefaultShellConfig._(
          shellName: 'tcsh/csh',
          localPath: '~/.tcshrc',
          globalPath: '/etc/csh.cshrc',
          exportCommand: 'setenv',
        );

      case 'ksh':
        return const DefaultShellConfig._(
          shellName: 'ksh',
          localPath: '~/.kshrc',
          globalPath: '/etc/profile',
          exportCommand: 'export',
        );

      case 'dash':
        return const DefaultShellConfig._(
          shellName: 'dash',
          localPath: '~/.profile',
          globalPath: '/etc/profile',
          exportCommand: 'export',
        );

      case 'elvish':
        return const DefaultShellConfig._(
          shellName: 'elvish',
          localPath: '~/.config/elvish/rc.elv',
          globalPath: '/etc/elvish/rc.elv',
          exportCommand: 'set-env',
        );

      case 'xonsh':
        return const DefaultShellConfig._(
          shellName: 'xonsh',
          localPath: '~/.xonshrc',
          globalPath: '/etc/xonshrc',
          exportCommand: '\$',
        );

      default: // Fallback to bash configuration
        return const DefaultShellConfig._(
          shellName: 'unknown (using bash)',
          localPath: '~/.bashrc',
          globalPath: '/etc/profile',
          exportCommand: 'export',
        );
    }
  }

  /// Async factory to detect current shell and create appropriate config
  static Future<DefaultShellConfig> detect(SSHClient client) async {
    final result = await client.run('echo \$SHELL');
    final shellPath = String.fromCharCodes(result).trim();
    return DefaultShellConfig.fromShellPath(shellPath);
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