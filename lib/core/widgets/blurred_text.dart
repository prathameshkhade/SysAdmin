import 'package:flutter/material.dart';
import 'dart:ui';

class BlurredText extends StatelessWidget {
  final String text;
  final bool isBlurred;
  final TextStyle? style;

  const BlurredText({
    super.key,
    required this.text,
    required this.isBlurred,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(text, style: style),
        if (isBlurred)
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.1),
                child: Text(
                  text,
                  style: style?.copyWith(color: Colors.transparent) ?? const TextStyle(color: Colors.transparent),
                ),
              ),
            ),
          ),
      ],
    );
  }
}