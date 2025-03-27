import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Util {
  static void showMsg({
    required BuildContext context,
    required String msg,
    Color? bgColour,
    Color? txtColour,
    bool isError = false,
  }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 1.0,
        backgroundColor: isError ? theme.colorScheme.error : bgColour,
        duration: const Duration(seconds: 3),

        content: Text(
          msg,
          style: TextStyle(
              fontSize: 14,
              color: txtColour
          ),
        ),
      ),
    );
  }
}