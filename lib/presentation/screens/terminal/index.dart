import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:typed_data';

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

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
  }

  Future<void> _initializeTerminal() async {
    try {
      setState(() {
        _isConnecting = true;
        _errorMessage = null;
      });

      final client = await ref.read(sshClientProvider.future);
      if (client == null) throw Exception('Failed to initialize SSH client');

      final session = await client.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      // Set up terminal input/output
      session.stdout.listen((data) {
        terminal.write(String.fromCharCodes(data));
      });

      session.stderr.listen((data) => terminal.write(String.fromCharCodes(data)));

      terminal.onOutput = (data) => session.write(Uint8List.fromList(data.codeUnits));

      // Handle terminal resize
      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        session.resizeTerminal(width, height);
      };

      ref.read(terminalSessionProvider.notifier).state = session;

      setState(() {
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Failed to connect: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'An unknown error occurred'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _clearTerminal() {
    terminal.buffer.clear();
    terminal.buffer.setCursor(0, 0);
  }

  @override
  void dispose() {
    ref.read(terminalSessionProvider.notifier).state?.close();
    terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectionStatusProvider).value ?? false;
    final connection = ref.read(defaultConnectionProvider).value;

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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
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
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Terminal'),
              ),
              const PopupMenuItem(
                value: 'reconnect',
                child: Text('Reconnect'),
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
              child: TerminalView(
                terminal,
                controller: terminalController,
                textStyle: const TerminalStyle(fontSize: 12, fontFamily: 'Menlo'),
                padding: const EdgeInsets.all(8),
                autofocus: true,
                alwaysShowCursor: true,
                backgroundOpacity: 0.01,
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