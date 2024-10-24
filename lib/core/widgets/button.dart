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
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor ?? Theme.of(context).primaryColor, // Default color from theme
        padding: padding ?? const EdgeInsets.symmetric(vertical: 18.0, horizontal: 26.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8.0), // Default border radius
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: Colors.white
        ),
      ),
    );
  }
}
