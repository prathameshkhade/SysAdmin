import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:dartssh2/dartssh2.dart';

import '../../../providers/ssh_state.dart';

class AddConnectionForm extends ConsumerStatefulWidget {
  final SSHConnection? connection; // Make it optional for both add and edit modes
  final String? originalName; // Store original name for updating

  const AddConnectionForm({
    super.key,
    this.connection,
    this.originalName,
  });

  @override
  ConsumerState<AddConnectionForm> createState() => _AddConnectionFormState();
}

class _AddConnectionFormState extends ConsumerState<AddConnectionForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController hostController = TextEditingController();
  final TextEditingController portController = TextEditingController(text: "22");
  final TextEditingController privateKeyController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isTesting = false;
  bool _isSaving = false;
  bool _usePassword = true;
  String? _errorMessage;
  static const int connectionTimeout = 30; // seconds

  @override
  void initState() {
    super.initState();
    if (widget.connection != null) {
      // Populate form fields if editing
      nameController.text = widget.connection!.name;
      usernameController.text = widget.connection!.username;
      hostController.text = widget.connection!.host;
      portController.text = widget.connection!.port.toString();

      // Set authentication method and credentials
      if (widget.connection!.privateKey != null) {
        _usePassword = false;
        privateKeyController.text = widget.connection!.privateKey!;
      } else if (widget.connection!.password != null) {
        _usePassword = true;
        passwordController.text = widget.connection!.password!;
      }
    }
  }

  Future<void> _pickPrivateKey() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'ppk', 'key'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        if (_validatePrivateKey(content)) {
          setState(() {
            privateKeyController.text = content;
            _usePassword = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid private key format';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error reading private key file: ${e.toString()}';
      });
    }
  }

  bool _validatePrivateKey(String key) {
    try {
      // Basic validation of common private key formats
      final trimmedKey = key.trim();

      // Check for RSA private key format
      if (trimmedKey.startsWith('-----BEGIN RSA PRIVATE KEY-----') &&
          trimmedKey.endsWith('-----END RSA PRIVATE KEY-----')) {
        return true;
      }

      // Check for OpenSSH private key format
      if (trimmedKey.startsWith('-----BEGIN OPENSSH PRIVATE KEY-----') &&
          trimmedKey.endsWith('-----END OPENSSH PRIVATE KEY-----')) {
        return true;
      }

      // Check for standard private key format
      if (trimmedKey.startsWith('-----BEGIN PRIVATE KEY-----') && trimmedKey.endsWith('-----END PRIVATE KEY-----')) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testConnection() async {
    try {
      final socket = await SSHSocket.connect(
        hostController.text,
        int.tryParse(portController.text) ?? 22,
      ).timeout(
        const Duration(seconds: connectionTimeout),
        onTimeout: () => throw TimeoutException('Connection timed out after $connectionTimeout seconds'),
      );

      final client = SSHClient(
        socket,
        username: usernameController.text,
        onPasswordRequest: () => _usePassword ? passwordController.text : '',
        identities: !_usePassword && privateKeyController.text.isNotEmpty
            ? SSHKeyPair.fromPem(privateKeyController.text)
            : null,
      );

      await client.authenticated.timeout(
        const Duration(seconds: connectionTimeout),
        onTimeout: () => throw TimeoutException('Authentication timed out after $connectionTimeout seconds'),
      );

      client.close();
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
      return false;
    }
  }

  Future<void> _saveConnection() async {
    if (nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a connection name');
      return;
    }

    if (hostController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a host address');
      return;
    }

    if (usernameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a username');
      return;
    }

    if (_usePassword && passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a password');
      return;
    }

    if (!_usePassword && privateKeyController.text.isEmpty) {
      setState(() => _errorMessage = 'Please provide a private key');
      return;
    }

    setState(() {
      _isTesting = true;
      _errorMessage = null;
    });

    try {
      final isConnected = await _testConnection();

      if (!isConnected) {
        setState(() => _isTesting = false);
        return;
      }

      setState(() {
        _isTesting = false;
        _isSaving = true;
      });

      final connection = SSHConnection(
        name: nameController.text,
        host: hostController.text,
        port: int.tryParse(portController.text) ?? 22,
        username: usernameController.text,
        privateKey: !_usePassword ? privateKeyController.text : null,
        password: _usePassword ? passwordController.text : null,
        isDefault: widget.connection?.isDefault ?? false,
      );

      if (widget.connection != null) {
        // Update existing connection
        await ref.read(sshConnectionsProvider.notifier).updateConnection(
            widget.originalName ?? widget.connection!.name,
            connection
        );
      } else {
        // Add new connection
        await ref.read(sshConnectionsProvider.notifier).addConnection(connection);
      }

      // Ensure there is at least one default connection
      await ref.read(connectionManagerProvider).ensureDefaultConnection();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _isSaving = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
      title: "Add Connection",
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Connection Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: hostController,
                      decoration: InputDecoration(
                        labelText: "Host",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: portController,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: InputDecoration(
                        labelText: "Port",
                        counterText: "",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Authentication method selector
              CupertinoSegmentedControl<bool>(
                children: const {
                  true: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Password'),
                  ),
                  false: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Private Key'),
                  ),
                },
                groupValue: _usePassword,
                onValueChanged: (bool value) {
                  setState(() {
                    _usePassword = value;
                    _errorMessage = null;
                  });
                },
              ),

              const SizedBox(height: 15),

              if (_usePassword)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: privateKeyController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: "Private Key",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.all(10),
                          color: CupertinoColors.systemGrey5,
                          onPressed: _pickPrivateKey,
                          child: const Icon(CupertinoIcons.folder, color: CupertinoColors.activeBlue),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: (_isTesting || _isSaving) ? null : _saveConnection,
                  child: _isTesting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: theme.colorScheme.surface),
                            const SizedBox(width: 8),
                            const Text("Testing connection..."),
                          ],
                        )
                      : _isSaving
                          ? const Text("Saving...")
                          : const Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    hostController.dispose();
    portController.dispose();
    privateKeyController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
