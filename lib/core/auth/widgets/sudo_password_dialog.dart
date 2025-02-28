import 'package:flutter/material.dart';

class SudoPasswordDialog {
  static Future<bool?> show(BuildContext context) {
    final theme = Theme.of(context);
    final TextEditingController passwordController = TextEditingController();

    return showDialog<bool>(
        context: context,
        barrierDismissible: true,

        builder: (context) => AlertDialog(
              elevation: 1.0,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),

              title: const Text('Requires Sudo Permission!'),
              titleTextStyle: theme.textTheme.titleLarge,

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text("This action requires the sudo permission. Please enter your sudo password to continue."),
                  const SizedBox(height: 25),
                  TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                  )
                ],
              ),

              actions: [
                // Confirm
                ElevatedButton(
                  onPressed: () {
                    // Logic for sudo command execution
                  },
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(theme.colorScheme.primary),
                      shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))
                      )
                  ),
                  child: Text('Confirm', style: theme.textTheme.labelLarge),
                )
              ],
        )
    );
  }
}
