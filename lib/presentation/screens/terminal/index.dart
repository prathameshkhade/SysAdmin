import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/presentation/screens/terminal/shortcut_key.dart';
import 'package:sysadmin/presentation/screens/terminal/terminal_shortcut_bar.dart';
import 'package:xterm/xterm.dart';

import '../../../core/utils/util.dart';
import '../../../providers/ssh_state.dart';
import 'modifier_state_provider.dart';
import 'terminal_shortcut.dart';

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

  // Define shortcut keys similar to Termux
  final List<ShortcutKey> _topRowKeys = [
    ShortcutKey('ESC', '\x1b'),
    ShortcutKey('/', '/'),
    ShortcutKey('~', '~'),
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

  final terminalController = TerminalController();
  bool _isConnecting = true;          // Flag to track connection status
  String? _errorMessage;              // Error message for connection issues
  double _fontSize = 9.0;             // Default font size
  double _baseScaleFactor = 1.0;      // Base factor for scaling font size
  bool _showShortcutBar = true;       // Toggle for shortcut bar visibility

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

      terminal.onOutput = (data) {
        if (mounted) {
          final modifierState = ref.read(modifierStateProvider);

          // If shortcut bar modifiers are active, handle combinations
          if (modifierState.ctrlPressed || modifierState.altPressed) {
            _handleModifierCombination(data, modifierState);
            return; // Don't send to normal output
          }

          // Normal handling when no modifiers are active
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

  void _handleModifierCombination(String data, ModifierState modifierState) {
    String sequence = '';

    if (modifierState.ctrlPressed) {
      // Handle Ctrl+key combinations
      if (data.length == 1) {
        final char = data.toLowerCase();
        switch (char) {
          case 'a':
            sequence = '\x01'; // Ctrl+A (start of line)
            break;
          case 'b':
            sequence = '\x02'; // Ctrl+B (back char)
            break;
          case 'c':
            sequence = '\x03'; // Ctrl+C (SIGINT)
            break;
          case 'd':
            sequence = '\x04'; // Ctrl+D (EOF)
            break;
          case 'e':
            sequence = '\x05'; // Ctrl+E (end of line)
            break;
          case 'f':
            sequence = '\x06'; // Ctrl+F (forward char)
            break;
          case 'g':
            sequence = '\x07'; // Ctrl+G (bell/abort)
            break;
          case 'h':
            sequence = '\x08'; // Ctrl+H (backspace)
            break;
          case 'i':
            sequence = '\x09'; // Ctrl+I (tab)
            break;
          case 'j':
            sequence = '\x0a'; // Ctrl+J (newline)
            break;
          case 'k':
            sequence = '\x0b'; // Ctrl+K (kill to end of line)
            break;
          case 'l':
            sequence = '\x0c'; // Ctrl+L (clear screen)
            break;
          case 'm':
            sequence = '\x0d'; // Ctrl+M (return)
            break;
          case 'n':
            sequence = '\x0e'; // Ctrl+N (next command)
            break;
          case 'o':
            sequence = '\x0f'; // Ctrl+O
            break;
          case 'p':
            sequence = '\x10'; // Ctrl+P (previous command)
            break;
          case 'q':
            sequence = '\x11'; // Ctrl+Q (resume output)
            break;
          case 'r':
            sequence = '\x12'; // Ctrl+R (reverse search)
            break;
          case 's':
            sequence = '\x13'; // Ctrl+S (stop output)
            break;
          case 't':
            sequence = '\x14'; // Ctrl+T (transpose chars)
            break;
          case 'u':
            sequence = '\x15'; // Ctrl+U (kill to start of line)
            break;
          case 'v':
            sequence = '\x16'; // Ctrl+V (literal insert)
            break;
          case 'w':
            sequence = '\x17'; // Ctrl+W (kill word backward)
            break;
          case 'x':
            sequence = '\x18'; // Ctrl+X
            break;
          case 'y':
            sequence = '\x19'; // Ctrl+Y (yank)
            break;
          case 'z':
            sequence = '\x1a'; // Ctrl+Z (SIGTSTP)
            break;
          default:
            sequence = data; // Fallback to normal character
        }
      }
    }
    else if (modifierState.altPressed) {
      // Handle Alt+key combinations
      if (data.length == 1) {
        final char = data.toLowerCase();
        switch (char) {
          case 'b':
            sequence = '\x1bb'; // Alt+B (move word back)
            break;
          case 'f':
            sequence = '\x1bf'; // Alt+F (move word forward)
            break;
          default:
            sequence = '\x1b$char'; // Alt+key sends ESC+key
        }
      }
      else {
        sequence = '\x1b$data'; // Alt+key sends ESC+key
      }
    }

    // Send the sequence to the session
    if (sequence.isNotEmpty && _session != null) {
      _session!.write(Uint8List.fromList(sequence.codeUnits));
    }

    // Reset modifiers after use
    ref.read(modifierStateProvider.notifier).reset();
  }

  void _clearTerminal() {
    terminal.buffer.clear();
    terminal.buffer.setCursor(0, 0);
  }

  void _toggleShortcutBar() => setState(() => _showShortcutBar = !_showShortcutBar);

  void _handleShortcutKeyPress(String rawInput) {
    if (_session != null && mounted) {
      _session!.write(Uint8List.fromList(rawInput.codeUnits));
    }
  }

  void _handleKeyInput(TerminalKey key, {bool ctrl = false, bool alt = false}) {
    if (mounted) {
      terminal.keyInput(key, ctrl: ctrl, alt: alt);
    }
  }

  void _handlePhysicalKeyEvent(KeyEvent event) {
    final modifierState = ref.read(modifierStateProvider);

    // Only handle key down events to avoid double processing
    if (event is! KeyDownEvent) return;

    // If shortcut bar modifiers are active, let the terminal shortcuts handle it
    if (modifierState.ctrlPressed || modifierState.altPressed) {
      return; // Let the existing shortcut system handle it
    }

    // For normal keys without shortcut bar modifiers, proceed normally
    // The existing terminal shortcut system will handle Ctrl/Alt combinations from physical keyboard
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

          // Menu button for terminal options
          PopupMenuButton<String>(
            tooltip: 'Terminal Options',
            // popUpAnimationStyle: AnimationStyle(curve: Curves.linearToEaseOut),
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

            // Menu items
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

      // Main body of the terminal screen
      body: Column(
        children: [
          // Main terminal area
          Expanded(
            child: Stack(
              children: [
                // Terminal View if connected
                if (isConnected)
                  if (isConnected)
                    KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: _handlePhysicalKeyEvent,
                      child: TerminalShortcutActions(
                        terminal: terminal,
                        child: Theme(
                          data: Theme.of(context).copyWith(platform: TargetPlatform.linux),
                          child: GestureDetector(
                            onScaleStart: (details) => _baseScaleFactor = _fontSize / 9.0,
                            onScaleUpdate: (details) => setState(
                                () => _fontSize = (9.0 * _baseScaleFactor * details.scale).clamp(8.0, 18.0)
                            ),
                            child: TerminalView(
                              terminal,
                              controller: terminalController,
                              textStyle: TerminalStyle(fontSize: _fontSize, fontFamily: 'Menlo'),
                              padding: const EdgeInsets.all(8),
                              autofocus: true,
                              alwaysShowCursor: true,
                              backgroundOpacity: 0.01,
                              shortcuts: getTerminalShortcuts(),
                            ),
                          ),
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

          // Shortcut bar at bottom - now only passing two rows
          if (isConnected)
            TerminalShortcutBar(
                shortcutKeys: [_topRowKeys, _bottomRowKeys],
                onRawInput: _handleShortcutKeyPress,
                onKeyInput: _handleKeyInput,
                isVisible: _showShortcutBar,
                onToggleVisibility: _toggleShortcutBar,
            ),
        ],
      ),
    );
  }
}
