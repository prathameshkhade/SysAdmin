import 'package:flutter/material.dart';
import 'package:sysadmin/presentation/widgets/label.dart';

class OverviewContainer extends StatelessWidget {
  final String title;
  final Label? label;
  final List<Widget>? children;

  const OverviewContainer({
    super.key,
    required this.title,
    this.label,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: theme.colorScheme.surface,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.bodyLarge,
              ),
              if (label != null) label!,
            ],
          ),

          const SizedBox(height: 16),

          if (children != null) ...children!,

        ],
      ),
    );
  }
}