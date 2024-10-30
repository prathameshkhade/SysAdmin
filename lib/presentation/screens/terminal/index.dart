import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:xterm/xterm.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:typed_data';

class TerminalScreen extends StatefulWidget {
  final SSHConnection connection;

  const TerminalScreen({
    super.key,
    required this.connection,
  });

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final terminal = Terminal(
    maxLines: 10000,
    platform: TerminalTargetPlatform.linux,
  );

  final terminalController = TerminalController();
  SSHClient? _client;
  SSHSession? _session;
  bool _isConnecting = true;
  bool _isConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  Future<void> _connectToServer() async {
    try {
      setState(() {
        _isConnecting = true;
        _errorMessage = null;
      });

      // Initialize SSH client
      _client = SSHClient(
        await SSHSocket.connect(
          widget.connection.host,
          widget.connection.port,
          timeout: const Duration(seconds: 10),
        ),
        username: widget.connection.username,
        onPasswordRequest: () => widget.connection.password ?? '',
        identities: widget.connection.privateKey != null
            ? SSHKeyPair.fromPem(widget.connection.privateKey!) // Removed the list brackets
            : null,
      );

      // Start shell session
      _session = await _client?.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      if (_session == null) throw Exception('Failed to start shell session');

      // Set up terminal input/output
      _session?.stdout.listen((data) {
        terminal.write(String.fromCharCodes(data));
      });

      _session?.stderr.listen((data) {
        terminal.write(String.fromCharCodes(data));
      });

      terminal.onOutput = (data) {
        _session?.write(Uint8List.fromList(data.codeUnits));
      };

      // Handle terminal resize
      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        _session?.resizeTerminal(width, height);
      };

      setState(() {
        _isConnecting = false;
        _isConnected = true;
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
  }

  @override
  void dispose() {
    _session?.close();
    _client?.close();
    terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 1.0,
        title: Row(
          children: [
            // const Icon(Icons.terminal),
            // const SizedBox(width: 8),
            Text('${widget.connection.username}@${widget.connection.host}:${widget.connection.port}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            // const SizedBox(width: 8),
            // if (_isConnected)
            //   Container(
            //     width: 8,
            //     height: 8,
            //     decoration: const BoxDecoration(
            //       color: Colors.green,
            //       shape: BoxShape.circle,
            //     ),
            //   ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: _isConnecting ? null : _connectToServer,
          //   tooltip: 'Reconnect',
          // ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearTerminal();
                  break;
                case 'reconnect':
                  _connectToServer();
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
          if (_isConnected)
            Theme(
              data: Theme.of(context).copyWith(platform: TargetPlatform.linux),
              child: TerminalView(
                terminal,
                controller: terminalController,
                textStyle: const TerminalStyle(fontSize: 14, fontFamily: 'Menlo'),
                padding: const EdgeInsets.all(8),
                autofocus: true,
                // cursorType: TerminalCursorType.verticalBar,
              ),
            ),
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
                    onPressed: _connectToServer,
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