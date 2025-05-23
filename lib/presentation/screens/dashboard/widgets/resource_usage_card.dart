import 'package:flutter/material.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/presentation/widgets/label.dart';

class ResourceUsageCard extends StatefulWidget {
  final String title;
  final double usagePercentage;
  final double usedValue;
  final double totalValue;
  final String unit;
  final Duration animationDuration;
  final bool isCpu;
  final int cpuCount;

  const ResourceUsageCard({
    super.key,
    required this.title,
    required this.usagePercentage,
    required this.usedValue,
    required this.totalValue,
    this.unit = 'MB',
    this.isCpu = false,
    this.cpuCount = 1,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<ResourceUsageCard> createState() => _ResourceUsageCardState();
}

class _ResourceUsageCardState extends State<ResourceUsageCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color currentColor = widget.usagePercentage > 80.0
      ? theme.colorScheme.error
      : (widget.usagePercentage < 20.0
          ? Colors.green
          : theme.primaryColor
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(widget.title),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1St Part: Title and Percentage
            Row(
              children: <Widget> [
                Text(widget.title),
                const SizedBox(width: 4.0),
                if(!widget.isCpu)
                  Label(
                      label: "${widget.usagePercentage.toStringAsFixed(2)}%",
                      borderRadius: BorderRadius.circular(18.0),
                      bgColor: currentColor,
                      fontSize: 11,
                      onTap: (){},
                  )
              ],
            ),

            // 2nd Part: usage ratio (used/total)
            Row(
              children: <Widget> [
                // If CPU, show the percentage of CPU usage
                if(widget.isCpu) ...<Widget>[
                  Label(
                      label: "${widget.usagePercentage.toStringAsFixed(2)}%",
                      onTap: (){},
                      bgColor: currentColor,
                      borderRadius: BorderRadius.circular(18.0),
                      fontSize: 11
                  ),
                  Text(" of ${widget.cpuCount} CPUs"),
                ]

                // Else, show the actual usage
                else ...<Text>[
                  Text(
                    '${widget.usedValue.toStringAsFixed(2)}/${widget.totalValue.toStringAsFixed(2)} ${widget.unit}',
                    style: theme.textTheme.bodyMedium,
                  )
                ]
              ],
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
                inactiveTrackColor: currentColor.useOpacity(0.2),
                thumbShape: SliderComponentShape.noThumb,
                overlayShape: SliderComponentShape.noOverlay,
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                label: widget.title,
                onChanged: (value) => setState((){})
              ),
            );
          },
        ),

        const SizedBox(height: 16),

      ],
    );
  }
}