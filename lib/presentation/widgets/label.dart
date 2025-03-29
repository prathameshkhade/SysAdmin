import 'package:flutter/material.dart';
import 'package:sysadmin/core/utils/color_extension.dart';

class Label extends StatelessWidget {
  final String label;
  final Color? bgColor;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final double fontSize;

  const Label({
    super.key,
    required this.label,
    this.bgColor,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = bgColor ?? theme.primaryColor;

    return InkWell(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor.useOpacity(0.15),
          borderRadius: borderRadius,
        ),

        child: Text(
          label,
          style: TextStyle(color: backgroundColor, fontSize: fontSize),
        ),
      ),
    );
  }
}