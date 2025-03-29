import 'package:flutter/material.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/widgets/button.dart';

class CustomBottomSheetData {
  final String title;
  final String? subtitle;
  final String? tag;
  final Color? tagColor;
  final List<TableData>? tables;
  final List<ActionButtonData> actionButtons;
  final List<QuickActionData>? quickActions;
  final Widget? customContent;
  final Widget extraActionWidget;
  final bool isDefault;
  final Function(bool)? onDefaultChanged;

  CustomBottomSheetData({
    required this.title,
    this.subtitle,
    this.tag,
    this.tagColor,
    this.tables,
    required this.actionButtons,
    this.quickActions,
    this.customContent,
    this.extraActionWidget = const SizedBox(width: 0),
    this.isDefault = false,
    this.onDefaultChanged,
  });
}

class TableData {
  final String heading;
  final List<TableRowData> rows;

  TableData({
    required this.heading,
    required this.rows,
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
    // Header implementation remains the same
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
            color: Colors.blue.useOpacity(0.01),
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
                      color: (data.tagColor ?? theme.primaryColor).useOpacity(0.15),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Button(
                    text: data.actionButtons[0].text.toUpperCase(),
                    onPressed: data.actionButtons[0].onPressed,
                    bgColor: data.actionButtons[0].bgColor,
                  )
              ),
              const SizedBox(width: 16),
              Expanded(
                  flex: 1,
                  child: Button(
                    text: data.actionButtons[1].text.toUpperCase(),
                    onPressed: data.actionButtons[1].onPressed,
                    bgColor: data.actionButtons[1].bgColor,
                  )),
            ],
          ),

          // Extra Action Widget
          if(data.extraActionWidget.runtimeType != SizedBox) data.extraActionWidget
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, ThemeData theme, TableData tableData) {
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
        tableData.rows.length,
        (index) => buildRow(
          tableData.rows[index],
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
            borderRadius: borderRadius ??
                const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
          ),
          child: Column(
            children: [
              _buildHeader(context, theme),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: <Widget>[
                    _buildActionButtons(context),

                    Divider(
                      indent: 20.0,
                      endIndent: 20.0,
                      color: theme.colorScheme.surface,
                    ),

                    // Build multiple tables if they exist
                    if (data.tables != null) ...[
                      ...data.tables!.map((tableData) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Text(
                                    tableData.heading,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                _buildTable(context, theme, tableData),
                              ],
                            ),
                          )),
                    ],

                    const SizedBox(height: 18),

                    if (data.customContent != null) data.customContent!,

                    const SizedBox(height: 18),

                    _buildQuickActions(context, theme),
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
