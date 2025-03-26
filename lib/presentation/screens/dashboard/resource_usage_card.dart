import 'package:flutter/material.dart';

class ResourceUsageCard extends StatelessWidget {
  final String title;
  final double usagePercentage;
  final double usedValue;
  final double totalValue;
  final Color sliderColor;
  final String unit;

  const ResourceUsageCard({
    super.key,
    required this.title,
    required this.usagePercentage,
    required this.usedValue,
    required this.totalValue,
    required this.sliderColor,
    this.unit = 'MB',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${usagePercentage.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${usedValue.toStringAsFixed(0)}/${totalValue.toStringAsFixed(0)} $unit',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),

          const SizedBox(height: 8),

          SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              activeTrackColor: sliderColor,
              inactiveTrackColor: sliderColor.withOpacity(0.2),
              thumbColor: sliderColor,
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: usagePercentage,
              min: 0,
              max: 100,
              onChanged: null, // Disabled slider
            ),
          ),

        ],
      ),
    );
  }
}