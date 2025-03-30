import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:xterm/xterm.dart';

import '../../../core/utils/util.dart';
import '../../../providers/ssh_state.dart';

// Create a provider for terminal session
final terminalSessionProvider = StateProvider.autoDispose<SSHSession?>((ref) => null);

class TerminalScreen extends ConsumerStatefulWidget {
  // final SSHConnection connection;

  const TerminalScreen({
    super.key,
    // required this.connection,
  });

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final terminal = Terminal(
    maxLines: 10000,
    platform: TerminalTargetPlatform.linux,
  );

  final terminalController = TerminalController();
  bool _isConnecting = true;
  String? _errorMessage;
  double _fontSize = 12.0;
  double _baseScaleFactor = 1.0;

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
          _session!.write(Uint8List.fromList(data.codeUnits));
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
    final isConnected = ref
        .watch(connectionStatusProvider)
        .value ?? false;
    final connection = ref
        .read(defaultConnectionProvider)
        .value;

    return Scaffold(
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 1.0,
        title: Row(
          children: [
            Text(
              '${connection!.username}@${connection.host}:${connection.port}',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(width: 8),
          ],
        ),
        actions: [
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
              }
            },
            itemBuilder: (context) =>
            [
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
            ],
          ),
        ],
      ),
      body: Stack(
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
    );
  }
}