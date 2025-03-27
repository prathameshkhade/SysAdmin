import 'package:flutter/material.dart';

class ResourceUsageCard extends StatefulWidget {
  final String title;
  final double usagePercentage;
  final double usedValue;
  final double totalValue;
  final String unit;
  final Duration animationDuration;

  const ResourceUsageCard({
    super.key,
    required this.title,
    required this.usagePercentage,
    required this.usedValue,
    required this.totalValue,
    this.unit = 'MB',
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<ResourceUsageCard> createState() => _ResourceUsageCardState();
}

class _ResourceUsageCardState extends State<ResourceUsageCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color currentColor = theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.usagePercentage.toStringAsFixed(2)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.usagePercentage > 80.0 ? theme.colorScheme.error : null,
              ),
            ),
            Text(
              '${widget.usedValue.toStringAsFixed(0)}/${widget.totalValue.toStringAsFixed(0)} ${widget.unit}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),

        const SizedBox(height: 12),

        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: widget.usagePercentage),
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          builder: (context, value, _) {
            return SliderTheme(
              data: SliderThemeData(
                activeTrackColor: currentColor,
                inactiveTrackColor: currentColor.withOpacity(0.2),
                thumbShape: SliderComponentShape.noThumb,
                overlayShape: SliderComponentShape.noOverlay,
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                label: widget.title,
                onChanged: (value) => setState(() {
                    currentColor = value > 80.0 ? theme.colorScheme.error : theme.primaryColor;
                }), // Disabled slider
              ),
            );
          },
        ),

        const SizedBox(height: 16),

      ],
    );
  }
}