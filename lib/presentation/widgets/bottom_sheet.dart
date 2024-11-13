import 'package:flutter/material.dart';

class CustomBottomSheetData {
  final String title;
  final String? subtitle;
  final String? tag;
  final Color? tagColor;
  final List<TableRowData> tableData;
  final List<ActionButtonData>? actionButtons;
  final List<QuickActionData>? quickActions;
  final Widget? customContent;
  final bool showDefaultToggle;
  final bool isDefault;
  final Function(bool)? onDefaultChanged;

  CustomBottomSheetData({
    required this.title,
    this.subtitle,
    this.tag,
    this.tagColor,
    required this.tableData,
    this.actionButtons,
    this.quickActions,
    this.customContent,
    this.showDefaultToggle = false,
    this.isDefault = false,
    this.onDefaultChanged,
  });
}

class TableRowData {
  final String label;
  final String value;
  final String? Function(String)? valueFormatter;

  TableRowData({
    required this.label,
    required this.value,
    this.valueFormatter,
  });
}

class ActionButtonData {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor;
  final IconData? icon;

  ActionButtonData({
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.icon,
  });
}

class QuickActionData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  QuickActionData({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class CustomBottomSheet extends StatelessWidget {
  final CustomBottomSheetData data;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool expand;
  final bool shouldCloseOnMinExtent;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const CustomBottomSheet({
    super.key,
    required this.data,
    this.initialChildSize = 0.4,
    this.minChildSize = 0.2,
    this.maxChildSize = 0.9,
    this.expand = false,
    this.shouldCloseOnMinExtent = true,
    this.backgroundColor,
    this.borderRadius,
  });

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withAlpha(20),
        border: const Border(bottom: BorderSide(width: 0.15)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.01),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data.title, style: theme.textTheme.titleLarge),
              ),
            ],
          ),
          if (data.subtitle != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  data.subtitle!,
                  style: theme.textTheme.titleSmall,
                ),
                if (data.tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (data.tagColor ?? theme.primaryColor)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      data.tag!,
                      style: TextStyle(
                        color: data.tagColor ?? theme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (data.actionButtons == null || data.actionButtons!.isEmpty) return const SizedBox();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.actionButtons!.map((button) {
              return Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    onPressed: button.onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: button.bgColor,
                    ),
                    child: Text(button.text),
                  ),
                ),
              );
            }).toList(),
          ),
          if (data.showDefaultToggle) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Set as Default',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              value: data.isDefault,
              onChanged: data.onDefaultChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, ThemeData theme) {
    TableRow buildRow(TableRowData rowData, {bool alternate = false}) {
      String displayValue = rowData.value;
      if (rowData.valueFormatter != null) {
        displayValue = rowData.valueFormatter!(rowData.value) ?? displayValue;
      }

      return TableRow(
        decoration: BoxDecoration(
          color: alternate ? theme.secondaryHeaderColor : Colors.transparent,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(rowData.label, style: theme.textTheme.bodyMedium),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                displayValue,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Table(
      border: TableBorder.all(color: Colors.transparent),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      textBaseline: TextBaseline.alphabetic,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: List.generate(
        data.tableData.length,
            (index) => buildRow(
          data.tableData[index],
          alternate: index.isEven,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    if (data.quickActions == null || data.quickActions!.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Actions", style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          ...data.quickActions!.map((action) => ListTile(
            iconColor: theme.primaryColor,
            leading: Icon(action.icon),
            title: Text(
              action.title,
              style: theme.textTheme.labelLarge,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: action.onTap,
            contentPadding: EdgeInsets.zero,
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: expand,
      shouldCloseOnMinExtent: shouldCloseOnMinExtent,

      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.scaffoldBackgroundColor,
            borderRadius: borderRadius ?? const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),

          child: Column(
            children: [
              _buildHeader(context, theme),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: <Widget> [
                    _buildActionButtons(context),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Text(
                              "Details",
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          _buildTable(context, theme),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    _buildQuickActions(context, theme),

                    if (data.customContent != null) data.customContent!,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}