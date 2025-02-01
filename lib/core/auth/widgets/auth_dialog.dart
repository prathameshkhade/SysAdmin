import 'dart:io';
import 'package:flutter/material.dart';
import '../services/local_auth.dart';

class AuthenticationDialog extends StatefulWidget {
  final VoidCallback onAuthenticationSuccess;
  final VoidCallback onAuthenticationFailure;

  const AuthenticationDialog({
    super.key,
    required this.onAuthenticationSuccess,
    required this.onAuthenticationFailure,
  });

  @override
  State<AuthenticationDialog> createState() => _AuthenticationDialogState();
}

class _AuthenticationDialogState extends State<AuthenticationDialog> {
  final LocalAuthService _localAuthService = LocalAuthService();
  final bool _isAuthenticating = true;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      bool canCheckBiometrics = await _localAuthService.checkBiometrics();

      if (!canCheckBiometrics) {
        _showSetupLockDialog();
        return;
      }

      bool authenticated = await _localAuthService.authenticate();

      if (authenticated) {
        widget.onAuthenticationSuccess();
        if (mounted) Navigator.of(context).pop();
      } else {
        widget.onAuthenticationFailure();
      }
    }
    catch (e) {
      widget.onAuthenticationFailure();
    }
  }

  void _showSetupLockDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Screen Lock is Required!'),
          content: const Text('Please set up a screen lock (PIN, pattern, or biometrics) in your device settings before using SysAdmin App.'),
          actions: <TextButton>[
            TextButton(
              child: const Text('Exit App'),
              onPressed: () => exit(1),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // return Dialog(
    //   // backgroundColor: Colors.white,
    //   child: Padding(
    //     padding: const EdgeInsets.all(16.0),
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       crossAxisAlignment: CrossAxisAlignment.center,
    //       mainAxisSize: MainAxisSize.min,
    //       children: <Widget>[
    //         const Text(
    //           'Authentication Required',
    //           style: TextStyle(
    //             fontSize: 18,
    //             fontWeight: FontWeight.bold,
    //           ),
    //         ),
    //         const SizedBox(height: 16),
    //         if (_isAuthenticating) ...[
    //           const CircularProgressIndicator(),
    //           const SizedBox(height: 16),
    //           const Text('Waiting for authentication...'),
    //         ],
    //         const SizedBox(height: 16),
    //         TextButton(
    //           onPressed: () {
    //             setState(() => _isAuthenticating = true);
    //             _authenticate();
    //           },
    //           child: const Text('Try Again'),
    //         ),
    //       ],
    //     ),
    //   ),
    // );

    return AlertDialog(
      surfaceTintColor: Colors.transparent,
      elevation: 1.0,
      titlePadding: const EdgeInsets.symmetric(vertical: 8.0),
      icon: const Icon(Icons.lock_outline_rounded),
      title: const Text("SysAdmin is locked!",),
      titleTextStyle: theme.textTheme.titleLarge,
      content: const Text("Authentication is required to access the SysAdmin app"),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        TextButton(
          style: const ButtonStyle(
            alignment: Alignment.center,
            enableFeedback: true,
          ),
          child: Text(
              "Unlock Now",
              style: theme.primaryTextTheme.labelLarge!.copyWith(color: theme.primaryColor)
          ),
          onPressed: () async {
            await _authenticate();
          },
        )
      ],
    );
  }
}