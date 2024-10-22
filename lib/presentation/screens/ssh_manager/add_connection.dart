import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:sysadmin/data/services/connection_manager.dart';

class AddConnectionForm extends StatefulWidget {
  const AddConnectionForm({super.key});

  @override
  State<AddConnectionForm> createState() => _AddConnectionFormState();
}

class _AddConnectionFormState extends State<AddConnectionForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController hostController = TextEditingController();
  final TextEditingController portController = TextEditingController(text: "22");
  final TextEditingController privateKeyController = TextEditingController();

  final ConnectionManager _connectionManager = ConnectionManager();
  bool _isTesting = false;
  bool _isSaving = false;
  String? _errorMessage;

  Future<bool> _testConnection() async {
    try {
      final socket = await SSHSocket.connect(
        hostController.text,
        int.tryParse(portController.text) ?? 22,
      );

      final client = SSHClient(
        socket,
        username: usernameController.text,
        onPasswordRequest: () => '', // We're using key-based auth
        identities: privateKeyController.text.isNotEmpty
            ? SSHKeyPair.fromPem(privateKeyController.text)
            : null,
      );

      await client.authenticated;
      client.close();
      return true;
    } on SSHAuthFailError {
      setState(() {
        _errorMessage = 'Authentication failed. Please check your credentials.';
      });
      return false;
    } on SSHSocketError catch (e) {
      setState(() {
        _errorMessage = 'Connection failed: ${e.message}';
      });
      return false;
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

    setState(() {
      _isTesting = true;
      _errorMessage = null;
    });

    try {
      // Test connection first
      final isConnected = await _testConnection();

      if (!isConnected) {
        setState(() => _isTesting = false);
        return;
      }

      // If connection successful, save the connection
      setState(() {
        _isTesting = false;
        _isSaving = true;
      });

      final connection = SSHConnection(
        name: nameController.text,
        host: hostController.text,
        port: int.tryParse(portController.text) ?? 22,
        username: usernameController.text,
        privateKey: privateKeyController.text,
      );

      await _connectionManager.save(connection);

      // Return to SSH Manager screen
      if (mounted) {
        Navigator.pop(context);
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

              TextField(
                controller: privateKeyController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Private Key",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: (_isTesting || _isSaving) ? null : _saveConnection,
                  child: _isTesting
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoActivityIndicator(color: Colors.white),
                      SizedBox(width: 8),
                      Text("Testing connection..."),
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
    super.dispose();
  }
}

extension on SSHSocketError {
  get message => "Something went wrong";
}
