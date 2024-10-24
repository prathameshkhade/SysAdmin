import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? bgColor;
  final double? borderRadius;
  final EdgeInsets? padding;

  const Button({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(bgColor ?? Theme.of(context).primaryColor), // Background color
        padding: WidgetStateProperty.all(
          padding ?? const EdgeInsets.symmetric(vertical: 18.0, horizontal: 26.0), // Padding
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8.0), // Border radius
          ),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );

  }
}
