import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:xterm/xterm.dart';

import '../../../core/utils/util.dart';
import '../../../providers/ssh_state.dart';
// Import your shortcut bar widget
// import 'terminal_shortcut_bar.dart'; // Uncomment and adjust path as needed

// Create a provider for terminal session
final terminalSessionProvider = StateProvider.autoDispose<SSHSession?>((ref) => null);

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({
    super.key,
  });

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final terminal = Terminal(
      maxLines: 10000,
      platform: TerminalTargetPlatform.linux
  );

  final terminalController = TerminalController();
  bool _isConnecting = true;
  String? _errorMessage;
  double _fontSize = 9.0;
  double _baseScaleFactor = 1.0;
  bool _showShortcutBar = true; // Toggle for shortcut bar visibility

  // Track the SSH session and initialization future
  SSHSession? _session;
  Future<void>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeTerminal();
  }

  Future<void> _initializeTerminal() async {
    try {
      setState(() {
        _isConnecting = true;
        _errorMessage = null;
      });

      final client = await ref.read(sshClientProvider.future);
      if (client == null) throw Exception('Failed to initialize SSH client');

      _session = await client.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      // Set up terminal input/output
      _session!.stdout.listen((data) {
        if (mounted) {
          terminal.write(String.fromCharCodes(data));
        }
      });

      _session!.stderr.listen((data) {
        if (mounted) {
          terminal.write(String.fromCharCodes(data));
        }
      });

      // Fix for backspace handling
      terminal.onOutput = (data) {
        if (mounted) {
          // Special handling for backspace to ensure it works across all systems
          if (data == '\x7f' || data == '\b') {
            _session!.write(Uint8List.fromList([8])); // ASCII backspace
          }
          else {
            // Normal handling for all other characters
            _session!.write(Uint8List.fromList(data.codeUnits));
          }
        }
      };

      // Handle terminal resize
      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        if (mounted) {
          _session!.resizeTerminal(width, height);
        }
      };

      ref.read(terminalSessionProvider.notifier).state = _session;

      setState(() {
        _isConnecting = false;
      });
    }
    catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Failed to connect: ${e.toString()}';
        });

        // Show error
        Util.showMsg(context: context, msg: _errorMessage ?? "An unknown error occurred.", isError: true);
      }
    }
  }

  void _clearTerminal() {
    terminal.buffer.clear();
    terminal.buffer.setCursor(0, 0);
  }

  void _toggleShortcutBar() {
    setState(() {
      _showShortcutBar = !_showShortcutBar;
    });
  }

  void _handleShortcutKeyPress(String key) {
    if (_session != null && mounted) {
      _session!.write(Uint8List.fromList(key.codeUnits));
    }
  }

  @override
  void dispose() {
    // Cancel the initialization future if it's still running
    _initializationFuture?.ignore();

    // Close the SSH session
    _session?.close();

    // Dispose of the terminal controller
    terminalController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = ref.watch(connectionStatusProvider).value ?? false;
    final connection = ref.read(defaultConnectionProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              '${connection!.username}@${connection.host}:${connection.port}',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.inverseSurface.useOpacity(0.5)
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        actions: [
          // Toggle shortcut bar button
          IconButton(
            onPressed: _toggleShortcutBar,
            icon: Icon(
              _showShortcutBar ? Icons.keyboard_hide : Icons.keyboard,
              color: _showShortcutBar ? Colors.blue : Colors.grey,
            ),
            tooltip: _showShortcutBar ? 'Hide Shortcut Bar' : 'Show Shortcut Bar',
          ),
          PopupMenuButton<String>(
            color: theme.colorScheme.surface.useOpacity(0.85),
            tooltip: 'Terminal Options',
            popUpAnimationStyle: AnimationStyle(curve: Curves.linearToEaseOut),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearTerminal();
                  break;
                case 'reconnect':
                  _initializeTerminal();
                  break;
                case 'toggle_shortcuts':
                  _toggleShortcutBar();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear_all_outlined, color: CupertinoColors.systemGrey),
                  title: Text('Clear Terminal'),
                ),
              ),
              const PopupMenuItem(
                value: 'reconnect',
                child: ListTile(
                  leading: Icon(Icons.refresh, color: CupertinoColors.systemGrey),
                  title: Text('Reconnect'),
                ),
              ),
              PopupMenuItem(
                value: 'toggle_shortcuts',
                child: ListTile(
                  leading: Icon(
                      _showShortcutBar ? Icons.keyboard_hide : Icons.keyboard,
                      color: CupertinoColors.systemGrey
                  ),
                  title: Text(_showShortcutBar ? 'Hide Shortcuts' : 'Show Shortcuts'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Main terminal area
          Expanded(
            child: Stack(
              children: [
                // Terminal View if connected
                if (isConnected)
                  Theme(
                    data: Theme.of(context).copyWith(platform: TargetPlatform.linux),
                    child: GestureDetector(
                      onScaleStart: (details) => _baseScaleFactor = _fontSize / 12.0,
                      onScaleUpdate: (details) =>
                          setState(
                                  () => _fontSize = (12.0 * _baseScaleFactor * details.scale).clamp(8.0, 18.0)
                          ),
                      child: TerminalView(
                        terminal,
                        controller: terminalController,
                        textStyle: TerminalStyle(fontSize: _fontSize, fontFamily: 'Menlo'),
                        padding: const EdgeInsets.all(8),
                        autofocus: true,
                        alwaysShowCursor: true,
                        backgroundOpacity: 0.01,
                      ),
                    ),
                  ),

                // Connecting to server animation
                if (_isConnecting)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Connecting to server...'),
                      ],
                    ),
                  ),

                // Show error if not connected
                if (_errorMessage != null && !_isConnecting)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _initializeTerminal,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Shortcut bar at bottom
          if (isConnected)
            TerminalShortcutBar(
              onKeyPressed: _handleShortcutKeyPress,
              isVisible: _showShortcutBar,
              onToggleVisibility: _toggleShortcutBar,
            ),
        ],
      ),
    );
  }
}

// Inline shortcut bar widget (you can move this to a separate file)
class TerminalShortcutBar extends StatefulWidget {
  final Function(String) onKeyPressed;
  final VoidCallback? onToggleVisibility;
  final bool isVisible;

  const TerminalShortcutBar({
    super.key,
    required this.onKeyPressed,
    this.onToggleVisibility,
    this.isVisible = true,
  });

  @override
  State<TerminalShortcutBar> createState() => _TerminalShortcutBarState();
}

class _TerminalShortcutBarState extends State<TerminalShortcutBar> {
  bool _ctrlPressed = false;
  bool _altPressed = false;

  final List<ShortcutKey> _topRowKeys = [
    ShortcutKey('ESC', '\x1b'),
    ShortcutKey('/', '/'),
    ShortcutKey('-', '-'),
    ShortcutKey('HOME', '\x1b[H'),
    ShortcutKey('↑', '\x1b[A'),
    ShortcutKey('END', '\x1b[F'),
    ShortcutKey('PGUP', '\x1b[5~'),
  ];

  final List<ShortcutKey> _bottomRowKeys = [
    ShortcutKey('TAB', '\t'),
    ShortcutKey('CTRL', '', isModifier: true),
    ShortcutKey('ALT', '', isModifier: true),
    ShortcutKey('←', '\x1b[D'),
    ShortcutKey('↓', '\x1b[B'),
    ShortcutKey('→', '\x1b[C'),
    ShortcutKey('PGDN', '\x1b[6~'),
  ];

  void _handleKeyPress(ShortcutKey key) {
    if (key.isModifier) {
      setState(() {
        if (key.label == 'CTRL') {
          _ctrlPressed = !_ctrlPressed;
          if (_ctrlPressed) _altPressed = false;
        }
        else if (key.label == 'ALT') {
          _altPressed = !_altPressed;
          if (_altPressed) _ctrlPressed = false;
        }
      });
      return;
    }

    String output = key.value;

    if (_ctrlPressed && key.label.length == 1) {
      int ctrlCode = key.label.toLowerCase().codeUnitAt(0) - 96;
      if (ctrlCode > 0 && ctrlCode < 27) {
        output = String.fromCharCode(ctrlCode);
      }
    }
    else if (_altPressed) {
      output = '\x1b${key.value}';
    }

    widget.onKeyPressed(output);

    if (_ctrlPressed || _altPressed) {
      setState(() {
        _ctrlPressed = false;
        _altPressed = false;
      });
    }
  }

  Widget _buildShortcutKey(ShortcutKey key) {
    bool isActive = (key.label == 'CTRL' && _ctrlPressed) ||
        (key.label == 'ALT' && _altPressed);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Material(
          color: isActive
              ? Colors.red.useOpacity(0.8)
              : Colors.grey[800]?.useOpacity(0.9),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _handleKeyPress(key),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                key.label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[300],
                  fontSize: key.label.length > 3 ? 10 : 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.useOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: Colors.grey[700]!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: _topRowKeys.map(_buildShortcutKey).toList(),
              ),
              const SizedBox(height: 6),
              Row(
                children: _bottomRowKeys.map(_buildShortcutKey).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShortcutKey {
  final String label;
  final String value;
  final bool isModifier;

  ShortcutKey(this.label, this.value, {this.isModifier = false});
}