import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content is String ? Text(content.toString()) : content,
      actions: [
        TextButton(
          onPressed: () => onCancel != null ? onCancel!() : Navigator.pop(context, false),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => onConfirm != null ? onConfirm!() : Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('DELETE'),
        ),
      ],
    );
  }
}