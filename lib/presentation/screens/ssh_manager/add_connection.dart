import 'package:flutter/material.dart';
import 'package:sysadmin/data/services/connection_manager.dart';
import '../../../data/models/ssh_connection.dart';

class AddConnectionForm extends StatefulWidget {
  const AddConnectionForm({super.key});

  @override
  _AddConnectionFormState createState() => _AddConnectionFormState();
}

class _AddConnectionFormState extends State<AddConnectionForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController hostController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController privateKeyController = TextEditingController();
  ConnectionManager storage = ConnectionManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Connection")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Connection Name'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            Row(
              children: <Widget>[
                TextField(
                  controller: hostController,
                  decoration: const InputDecoration(labelText: 'Host'),
                ),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(labelText: 'Port'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            TextField(
              controller: privateKeyController,
              decoration: const InputDecoration(labelText: 'Private Key (Optional)'),
              maxLines: 4,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final connection = SSHConnection(
                  name: nameController.text,
                  username: usernameController.text,
                  host: hostController.text,
                  port: int.parse(portController.text),
                  privateKey: privateKeyController.text,
                );

                // Save and return
                await storage.save(connection);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
