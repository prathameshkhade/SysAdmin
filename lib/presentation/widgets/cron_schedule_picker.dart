import 'package:flutter/material.dart';

enum ScheduleType { simple, custom }

class SimpleSchedulePicker extends StatefulWidget {
  final void Function(String expression) onChanged;

  const SimpleSchedulePicker({
    super.key,
    required this.onChanged,
  });

  @override
  State<SimpleSchedulePicker> createState() => _SimpleSchedulePickerState();
}

class _SimpleSchedulePickerState extends State<SimpleSchedulePicker> {
  String _frequency = 'daily';
  TimeOfDay _time = TimeOfDay.now();
  int _dayOfWeek = DateTime.monday;
  int _dayOfMonth = 1;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'minute',
                  child: Text('Every Minute'),
                ),
                DropdownMenuItem(
                  value: 'hourly',
                  child: Text('Hourly'),
                ),
                DropdownMenuItem(
                  value: 'daily',
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: 'weekly',
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: 'monthly',
                  child: Text('Monthly'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _frequency = value);
                _updateExpression();
              },
            ),
            const SizedBox(height: 16),

            // Show time picker for daily/weekly/monthly
            if (_frequency != 'minute' && _frequency != 'hourly')
              ListTile(
                title: const Text('Time'),
                trailing: Text(_time.format(context)),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _time,
                  );
                  if (picked != null) {
                    setState(() => _time = picked);
                    _updateExpression();
                  }
                },
              ),

            // Show day picker for weekly
            if (_frequency == 'weekly')
              DropdownButtonFormField<int>(
                value: _dayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Monday')),
                  DropdownMenuItem(value: 2, child: Text('Tuesday')),
                  DropdownMenuItem(value: 3, child: Text('Wednesday')),
                  DropdownMenuItem(value: 4, child: Text('Thursday')),
                  DropdownMenuItem(value: 5, child: Text('Friday')),
                  DropdownMenuItem(value: 6, child: Text('Saturday')),
                  DropdownMenuItem(value: 7, child: Text('Sunday')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _dayOfWeek = value);
                  _updateExpression();
                },
              ),

            // Show day picker for monthly
            if (_frequency == 'monthly')
              DropdownButtonFormField<int>(
                value: _dayOfMonth,
                decoration: const InputDecoration(
                  labelText: 'Day of Month',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  31,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _dayOfMonth = value);
                  _updateExpression();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _updateExpression() {
    String expression;
    switch (_frequency) {
      case 'minute':
        expression = '* * * * *';
        break;
      case 'hourly':
        expression = '0 * * * *';
        break;
      case 'daily':
        expression = '${_time.minute} ${_time.hour} * * *';
        break;
      case 'weekly':
        expression = '${_time.minute} ${_time.hour} * * $_dayOfWeek';
        break;
      case 'monthly':
        expression = '${_time.minute} ${_time.hour} $_dayOfMonth * *';
        break;
      default:
        expression = '* * * * *';
    }
    widget.onChanged(expression);
  }
}

class CustomSchedulePicker extends StatefulWidget {
  final void Function(String expression) onChanged;

  const CustomSchedulePicker({
    super.key,
    required this.onChanged,
  });

  @override
  State<CustomSchedulePicker> createState() => _CustomSchedulePickerState();
}

class _CustomSchedulePickerState extends State<CustomSchedulePicker> {
  final _minuteController = TextEditingController(text: '*');
  final _hourController = TextEditingController(text: '*');
  final _dayController = TextEditingController(text: '*');
  final _monthController = TextEditingController(text: '*');
  final _weekdayController = TextEditingController(text: '*');

  @override
  void initState() {
    super.initState();
    _updateExpression();

    _minuteController.addListener(_updateExpression);
    _hourController.addListener(_updateExpression);
    _dayController.addListener(_updateExpression);
    _monthController.addListener(_updateExpression);
    _weekdayController.addListener(_updateExpression);
  }

  @override
  void dispose() {
    _minuteController.dispose();
    _hourController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _weekdayController.dispose();
    super.dispose();
  }

  void _updateExpression() {
    final expression = [
      _minuteController.text,
      _hourController.text,
      _dayController.text,
      _monthController.text,
      _weekdayController.text,
    ].join(' ');
    widget.onChanged(expression);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    List<String>? quickValues,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            helperText: 'Enter values, ranges, or steps',
          ),
          validator: _validateCronField,
        ),
        if (quickValues != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: quickValues
                .map((value) => ActionChip(
                      label: Text(value),
                      onPressed: () => controller.text = value,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  String? _validateCronField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Field cannot be empty';
    }

    // Allow asterisk
    if (value == '*') return null;

    // Allow step values
    if (value.startsWith('*/')) {
      final step = int.tryParse(value.substring(2));
      if (step != null && step > 0) return null;
    }

    // Allow ranges and lists
    final parts = value.split(',');
    for (final part in parts) {
      if (part.contains('-')) {
        final range = part.split('-');
        if (range.length != 2) return 'Invalid range format';

        final start = int.tryParse(range[0]);
        final end = int.tryParse(range[1]);

        if (start == null || end == null) {
          return 'Range values must be numbers';
        }
        if (start >= end) {
          return 'Range start must be less than end';
        }
      } else {
        final num = int.tryParse(part);
        if (num == null) return 'Must be a number';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(
              controller: _minuteController,
              label: 'Minute (0-59)',
              hint: 'e.g., *, */5, 0,30, 15-45',
              quickValues: ['*', '*/5', '*/15', '*/30', '0'],
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _hourController,
              label: 'Hour (0-23)',
              hint: 'e.g., *, */2, 9-17, 0',
              quickValues: ['*', '*/2', '*/4', '0', '12'],
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _dayController,
              label: 'Day of Month (1-31)',
              hint: 'e.g., *, 1, 1-15, 1,15',
              quickValues: ['*', '1', '15', '1-15'],
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _monthController,
              label: 'Month (1-12)',
              hint: 'e.g., *, 1, 1-6, 1,6,12',
              quickValues: ['*', '*/3', '1-6', '1,6,12'],
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _weekdayController,
              label: 'Day of Week (0-6)',
              hint: 'e.g., *, 1-5, 0,6',
              quickValues: ['*', '1-5', '0,6', '1'],
            ),
            const SizedBox(height: 16),
            // Helper text
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Reference:'),
                    SizedBox(height: 8),
                    Text('* = every value'),
                    Text('*/n = every nth value'),
                    Text('a-b = range from a to b'),
                    Text('a,b = specific values a and b'),
                    SizedBox(height: 8),
                    Text('Example: 0 9-17 * * 1-5'),
                    Text('Runs every hour from 9 AM to 5 PM on weekdays'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
