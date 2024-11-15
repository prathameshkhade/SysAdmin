import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:intl/intl.dart';
import 'package:sysadmin/core/widgets/button.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import '../../../../data/models/cron_job.dart';
import '../../../../data/services/cron_job_service.dart';

class CronJobForm extends StatefulWidget {
  final SSHClient sshClient;
  final CronJob? jobToEdit;

  const CronJobForm({
    super.key,
    required this.sshClient,
    this.jobToEdit,
  });

  @override
  State<CronJobForm> createState() => _CronJobFormState();
}

class _CronJobFormState extends State<CronJobForm> {
  final _formKey = GlobalKey<FormState>();
  late final CronJobService _cronJobService;

  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  final _minuteController = TextEditingController(text: '*');
  final _hourController = TextEditingController(text: '*');
  final _dayController = TextEditingController(text: '*');
  final _monthController = TextEditingController(text: '*');
  final _weekController = TextEditingController(text: '*');
  final _descriptionController = TextEditingController();
  final _previewController = TextEditingController(text: '* * * * * testing');

  bool _isLoading = false;
  String? _error;
  List<DateTime>? _nextExecutions;
  bool _isStartup = false;
  bool get _isEditMode => widget.jobToEdit != null;

  @override
  void initState() {
    super.initState();
    _cronJobService = CronJobService(widget.sshClient);
    if (widget.jobToEdit != null) {
      _nameController.text = widget.jobToEdit!.description ?? '';
      _commandController.text = widget.jobToEdit!.command;
      _minuteController.text = _getFieldValueFromExpression(widget.jobToEdit!.expression, 0);
      _hourController.text = _getFieldValueFromExpression(widget.jobToEdit!.expression, 1);
      _dayController.text = _getFieldValueFromExpression(widget.jobToEdit!.expression, 2);
      _monthController.text = _getFieldValueFromExpression(widget.jobToEdit!.expression, 3);
      _weekController.text = _getFieldValueFromExpression(widget.jobToEdit!.expression, 4);
      _descriptionController.text = widget.jobToEdit!.description ?? '';
      _previewController.text = '${widget.jobToEdit!.expression} ${widget.jobToEdit!.command} '
          '${widget.jobToEdit!.description?.isNotEmpty == true ? '# ${widget.jobToEdit!.description}' : ''}';
      _isStartup = widget.jobToEdit!.expression.startsWith('@reboot');
    }
    _updatePreview();
  }

  String _getFieldValueFromExpression(String expression, int index) {
    return expression.split(' ')[index];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _minuteController.dispose();
    _hourController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _weekController.dispose();
    _descriptionController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  // Validate cron expression
  bool _validateCronExpression() {
    try {
      if (_isStartup) return true;

      final expression = '${_minuteController.text} ${_hourController.text} '
          '${_dayController.text} ${_monthController.text} ${_weekController.text}';

      // Create a temporary CronJob to validate expression
      final tempJob = CronJob(
        expression: expression,
        command: 'test',
        description: 'validation',
      );

      // This will throw an error if expression is invalid
      tempJob.getNextExecutions();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _updatePreview() {
    setState(() {
      if (_isStartup) {
        _previewController.text = '@reboot ${_commandController.text.trim()}'
            '${_descriptionController.text.trim().isNotEmpty ? ' # ${_descriptionController.text.trim()}' : ''}';
        return;
      }

      if (!_validateCronExpression()) {
        _nextExecutions = null;
        return;
      }

      try {
        final expression = '${_minuteController.text} ${_hourController.text} '
            '${_dayController.text} ${_monthController.text} ${_weekController.text}';

        final job = CronJob(
          expression: expression,
          command: _commandController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        _nextExecutions = job.getNextExecutions(count: 5);

        // Update the preview text field
        _previewController.text = '$expression ${_commandController.text.trim()}'
            '${_descriptionController.text.trim().isNotEmpty ? ' # ${_descriptionController.text.trim()}' : ''}';
      } catch (e) {
        _nextExecutions = null;
      }
    });
  }

  // Handles Quick Schedule button clicks
  void _handleQuickSchedule(String type) {
    setState(() {
      _isStartup = type == 'startup';

      if (_isStartup) {
        _minuteController.text = '@reboot';
        _hourController.text = '';
        _dayController.text = '';
        _monthController.text = '';
        _weekController.text = '';
        _previewController.text = '@reboot ${_commandController.text.trim()}'
            '${_descriptionController.text.trim().isNotEmpty ? ' # ${_descriptionController.text.trim()}' : ''}';
      } else {
        switch (type) {
          case 'hourly':
            _minuteController.text = '0';
            _hourController.text = '*';
            _dayController.text = '*';
            _monthController.text = '*';
            _weekController.text = '*';
            break;
          case 'daily':
            _minuteController.text = '0';
            _hourController.text = '0';
            _dayController.text = '*';
            _monthController.text = '*';
            _weekController.text = '*';
            break;
          case 'weekly':
            _minuteController.text = '0';
            _hourController.text = '0';
            _dayController.text = '*';
            _monthController.text = '*';
            _weekController.text = '0';
            break;
          case 'monthly':
            _minuteController.text = '0';
            _hourController.text = '0';
            _dayController.text = '1';
            _monthController.text = '*';
            _weekController.text = '*';
            break;
          case 'yearly':
            _minuteController.text = '0';
            _hourController.text = '0';
            _dayController.text = '1';
            _monthController.text = '1';
            _weekController.text = '*';
            break;
        }
      }
      _updatePreview();
    });
  }

  // Handles form submission
  Future<void> _submitForm() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    if (!_validateCronExpression()) {
      setState(() {
        _error = 'Invalid cron expression. Please check the schedule.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final job = _getUpdatedJob();
      if (_isEditMode) {
        await _cronJobService.update(widget.jobToEdit!, job);
      } else {
        await _cronJobService.create(job);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Failed to ${_isEditMode ? 'update' : 'create'} job: $e';
        _isLoading = false;
      });
    }
  }

  CronJob _getUpdatedJob() {
    return CronJob(
      expression: _isStartup
          ? '@reboot'
          : '${_minuteController.text} ${_hourController.text} '
              '${_dayController.text} ${_monthController.text} ${_weekController.text}',
      command: _commandController.text.trim(),
      description: _nameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
      title: '${widget.jobToEdit} New Cron Job',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Show error message if any
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ),

            // Command Field
            Text('Command to be Executed', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: 'Command',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a command';
                }
                return null;
              },
              onChanged: (value) => setState(() => _updatePreview()),
            ),
            const SizedBox(height: 24),

            // Description Field
            Text('Description', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onChanged: (value) => setState(() => _updatePreview()),
            ),
            const SizedBox(height: 24),

            // Quick Schedule
            Text('Quick Schedule', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var schedule in ['Startup', 'Hourly', 'Daily', 'Weekly', 'Monthly', 'Yearly'])
                  Button(
                    onPressed: () => _handleQuickSchedule(schedule.toLowerCase()),
                    text: schedule,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            if (!_isStartup) ...[
              // Cron Schedule Fields
              Row(
                children: [
                  for (var field in [
                    {'label': 'Minute', 'controller': _minuteController},
                    {'label': 'Hour', 'controller': _hourController},
                    {'label': 'Day', 'controller': _dayController},
                    {'label': 'Month', 'controller': _monthController},
                    {'label': 'Week', 'controller': _weekController},
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field['label'] as String),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: field['controller'] as TextEditingController,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              onChanged: (_) => _updatePreview(),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Job Preview
            Text('Preview', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _previewController,
              readOnly: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            if (_nextExecutions != null) ...[
              const SizedBox(height: 16),
              Text('Next Executions:', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              for (var date in _nextExecutions!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '└─ ${DateFormat('EEE, d MMM yyyy HH:mm').format(date)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: CupertinoButton.filled(
          onPressed: _submitForm,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) CircularProgressIndicator(color: theme.colorScheme.surface),
              const SizedBox(width: 5),
              _isLoading ? const Text('Scheduling...') : const Text('Schedule Job'),
            ],
          ),
        ),
      ),
    );
  }
}
