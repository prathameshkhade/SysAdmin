import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';

class AddConnectionForm extends StatelessWidget {
  AddConnectionForm({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController hostController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController privateKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return IosScaffold(
      title: "Add Connection",
      body: SingleChildScrollView(  // Added to make the form scrollable
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,  // Makes children stretch horizontally
            children: <Widget>[
              // Name of Connection
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Connection Name",  // Changed label
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 15),

              // Username
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: "Username",  // Changed label
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 15),

              // Host and Port row
              Row(
                children: <Widget>[
                  // Host field
                  Expanded(  // Added Expanded
                    flex: 3,  // Takes up more space
                    child: TextField(
                      controller: hostController,
                      decoration: InputDecoration(
                        labelText: "Host",  // Changed label
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  // Port field
                  Expanded(  // Added Expanded
                    flex: 1,  // Takes up less space
                    child: TextField(
                      controller: portController,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      decoration: InputDecoration(
                        labelText: "Port",  // Changed label
                        counterText: "",  // Removes the character counter
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Private Key
              TextField(
                controller: privateKeyController,
                maxLines: 3,  // Added multiple lines for private key
                decoration: InputDecoration(
                  labelText: "Private Key",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(  // Changed to filled button
                  onPressed: () {
                    // Logic for connecting to the Linux Server
                  },
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}