import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';

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
  bool _isPasswordVisible = true;
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
      }
      else if (widget.connection!.password != null) {
        _usePassword = true;
        passwordController.text = widget.connection!.password!;
      }
    }
  }

  Future<void> _pickPrivateKey() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
          dialogTitle: "Select Private Key File",
          type: FileType.any,
          allowMultiple: false,
          withData: true
      );

      if (result != null) {
        final file = File(result.files.single.path!);

        // Try to read the file as text
        String content;
        try {
          content = await file.readAsString();
        }
        catch (e) {
          // If we can't read as text, it's not a valid key file
          setState(() {
            _errorMessage = 'Selected file is not a text file';
            privateKeyController.text = '';
          });
          return;
        }

        // Validate the content as a private key
        if (_validatePrivateKey(content)) {
          // Try to parse the key to check if it's encrypted
          await _handlePrivateKey(content);
        }
        else {
          setState(() {
            _errorMessage = 'Invalid private key format';
            privateKeyController.text = '';
          });
        }
      }
    }
    catch (e) {
      setState(() {
        _errorMessage = 'Error reading private key file: ${e.toString()}';
      });
    }
  }

  Future<void> _handlePrivateKey(String keyContent) async {
    try {
      // Try to parse the key without passphrase first
      SSHKeyPair.fromPem(keyContent);

      // If we reach here, the key is not encrypted
      setState(() {
        privateKeyController.text = keyContent;
        _usePassword = false;
        _errorMessage = null;
      });
    } on SSHKeyDecryptError {
      // Key is encrypted, show passphrase dialog
      await _showPassphraseDialog(keyContent);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing private key: ${e.toString()}';
        privateKeyController.text = '';
      });
    }
  }

  Future<void> _showPassphraseDialog(String encryptedKey) async {
    final TextEditingController passphraseController = TextEditingController();
    bool isDecrypting = false;
    String? dialogError;
    bool isPassphraseVisible = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Private Key Passphrase'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This private key is encrypted. Please enter the passphrase to decrypt it.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passphraseController,
                    obscureText: !isPassphraseVisible,
                    decoration: InputDecoration(
                      labelText: 'Passphrase',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixIcon: IconButton(
                        onPressed: () => setDialogState(() => isPassphraseVisible = !isPassphraseVisible),
                        icon: Icon(
                          isPassphraseVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        ),
                      ),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dialogError!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDecrypting ? null : () {
                    // Use Navigator.pop with result to avoid the assertion error
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isDecrypting ? null : () async {
                    if (passphraseController.text.isEmpty) {
                      setDialogState(() {
                        dialogError = 'Please enter a passphrase';
                      });
                      return;
                    }

                    setDialogState(() {
                      isDecrypting = true;
                      dialogError = null;
                    });

                    try {
                      // Try to decrypt the key with the provided passphrase
                      final keyPair = SSHKeyPair.fromPem(encryptedKey, passphraseController.text);
                      debugPrint('Decrypted key: ${keyPair.first.toPem()}');

                      setState(() {
                        privateKeyController.text = keyPair.first.toPem();
                        _usePassword = false;
                        _errorMessage = null;
                      });

                      // Use Navigator.pop with result to avoid the assertion error
                      Navigator.pop(context, true);

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Private key decrypted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                    }
                    on SSHKeyDecryptError {
                      setDialogState(() {
                        isDecrypting = false;
                        dialogError = 'Incorrect passphrase. Please try again.';
                      });
                    }
                    catch (e) {
                      setDialogState(() {
                        isDecrypting = false;
                        dialogError = 'Error decrypting key: ${e.toString()}';
                      });
                    }
                  },
                  child: isDecrypting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Decrypt'),
                ),
              ],
            );
          },
        );
      },
    );
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
      if (trimmedKey.startsWith('-----BEGIN PRIVATE KEY-----') &&
          trimmedKey.endsWith('-----END PRIVATE KEY-----')) {
        return true;
      }

      // Check for EC private key format
      if (trimmedKey.startsWith('-----BEGIN EC PRIVATE KEY-----') &&
          trimmedKey.endsWith('-----END EC PRIVATE KEY-----')) {
        return true;
      }

      // Check for DSA private key format
      if (trimmedKey.startsWith('-----BEGIN DSA PRIVATE KEY-----') &&
          trimmedKey.endsWith('-----END DSA PRIVATE KEY-----')) {
        return true;
      }

      // Check for PuTTY private key format (PPK)
      if (trimmedKey.startsWith('PuTTY-User-Key-File-')) {
        return true;
      }

      return false;
    }
    catch (e) {
      return false;
    }
  }

  Future<bool> _testConnection() async {
    try {
      // Connect to the SSH server
      final socket = await SSHSocket.connect(
        hostController.text,
        int.tryParse(portController.text) ?? 22,
      ).timeout(
        const Duration(seconds: connectionTimeout),
        onTimeout: () =>
        throw TimeoutException('Connection timed out after $connectionTimeout seconds'),
      );

      // Create SSH client with auth credentials
      final client = SSHClient(
        socket,
        username: usernameController.text,
        onPasswordRequest: () => _usePassword ? passwordController.text : '',
        identities: !_usePassword && privateKeyController.text.isNotEmpty
            ? SSHKeyPair.fromPem(privateKeyController.text)
            : null,
      );

      // Verify authentication
      await client.authenticated.timeout(
        const Duration(seconds: connectionTimeout),
        onTimeout: () =>
        throw TimeoutException('Authentication timed out after $connectionTimeout seconds'),
      );

      client.close();
      return true;
    }
    on SocketException catch (e) {
      setState(() {
        if (e.message.contains('Failed host lookup')) {
          _errorMessage = 'Host not found. Please check the hostname.';
        }
        else if (e.message.contains('Connection refused')) {
          _errorMessage = 'Connection refused. Check if SSH service is running on port ${portController.text}.';
        }
        else if (e.message.contains('timed out')) {
          _errorMessage = 'Connection timed out. Host may be unreachable.';
        }
        else {
          _errorMessage = 'Network error: ${e.message}';
        }
      });
      return false;
    }
    on TimeoutException {
      setState(() {
        _errorMessage = 'Connection timed out after $connectionTimeout seconds. Please check your network.';
      });
      return false;
    }
    on SSHAuthFailError {
      setState(() {
        if (_usePassword) {
          _errorMessage = 'Authentication failed: Username or password is incorrect.';
        }
        else {
          _errorMessage = 'Authentication failed: Invalid private key or wrong username.';
        }
      });
      return false;
    }
    on SSHAuthAbortError {
      setState(() => _errorMessage = 'Authentication aborted by the user.');
      return false;
    }
    on SSHKeyDecryptError {
      setState(() {
        _errorMessage = 'Private key is encrypted. Please select the key file again and provide the passphrase.';
      });
      return false;
    }
    catch (e) {
      setState(() {
        if (e.toString().contains('algorithm negotiation fail')) {
          _errorMessage = 'Failed to negotiate SSH algorithms. The server may use incompatible settings.';
        }
        else {
          _errorMessage = 'Error: ${e.toString()}';
        }
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
        await ref
            .read(sshConnectionsProvider.notifier)
            .updateConnection(widget.originalName ?? widget.connection!.name, connection);
      } else {
        await ref.read(sshConnectionsProvider.notifier).addConnection(connection);
      }

      await ref.read(connectionManagerProvider).ensureDefaultConnection();

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
    on SocketException catch (e) {
      setState(() {
        if (e.message.contains('Failed host lookup')) {
          _errorMessage = 'Host not found. Please check the hostname.';
        }
        else if (e.message.contains('Connection refused')) {
          _errorMessage = 'Connection refused. Check if SSH service is running on port ${portController.text}.';
        }
        else if (e.message.contains('timed out')) {
          _errorMessage = 'Connection timed out. Host may be unreachable.';
        }
        else {
          _errorMessage = 'Network error: ${e.message}';
        }
      });
    }
    on TimeoutException {
      setState(() {
        _errorMessage = 'Connection timed out after $connectionTimeout seconds. Please check your network.';
      });
    }
    on SSHAuthFailError {
      setState(() {
        if (_usePassword) {
          _errorMessage = 'Authentication failed: Username or password is incorrect.';
        }
        else {
          _errorMessage = 'Authentication failed: Invalid private key or wrong username.';
        }
      });
    }
    on SSHAuthAbortError {
      setState(() => _errorMessage = 'Authentication aborted by the user.');
    }
    on SSHKeyDecryptError {
      setState(() {
        _errorMessage = 'Private key is encrypted. Please select the key file again and provide the passphrase.';
      });
    }
    catch (e) {
      setState(() {
        if (e.toString().contains('algorithm negotiation fail')) {
          _errorMessage = 'Failed to negotiate SSH algorithms. The server may use incompatible settings.';
        }
        else {
          _errorMessage = 'Error: ${e.toString()}';
        }
      });
    }
    finally {
      setState(() {
        _isTesting = false;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
      title: "${widget.connection != null ? 'Update' : 'Add'} Connection",
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 22),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100.useOpacity(0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),

              TextField(
                controller: nameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: "Connection Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: usernameController,
                keyboardType: TextInputType.text,
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
                      keyboardType: TextInputType.name,
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
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: false, signed: false),
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
                    obscureText: _isPasswordVisible,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _isPasswordVisible = !_isPasswordVisible),
                            icon: Icon(
                                _isPasswordVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                                color: theme.primaryColor)
                        )
                    )
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
                            keyboardType: TextInputType.multiline,
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
                          child:
                          const Icon(CupertinoIcons.folder, color: CupertinoColors.activeBlue),
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