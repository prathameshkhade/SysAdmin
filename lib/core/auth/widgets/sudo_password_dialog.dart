import 'package:flutter/material.dart';

class SudoPasswordDialog extends StatefulWidget {
  const SudoPasswordDialog({super.key});

  @override
  State<SudoPasswordDialog> createState() => _SudoPasswordDialogState();
}

class _SudoPasswordDialogState extends State<SudoPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    super.dispose();
    _passwordController.dispose();
  }

  bool onConfirm(String pass) => pass == "toor";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      elevation: 1.0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),

      title: const Text('Requires Sudo Permission'),
      titleTextStyle: theme.textTheme.titleMedium,

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text("This action requires the sudo permission. Please enter your sudo password to continue."),
          const SizedBox(height: 25),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            maxLines: 1,
            maxLength: 128,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          )
        ],
      ),

      actions: [
        // Confirm
        ElevatedButton(
          onPressed: () => {
            if (onConfirm(_passwordController.text)) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text('Correct password'),
                    duration: Duration(seconds: 2),
                  )
              ),
              Navigator.of(context).pop(true)
            }
            else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Invalid password!'),
                duration: Duration(seconds: 2),
              ))
            }
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
    );
  }
}

