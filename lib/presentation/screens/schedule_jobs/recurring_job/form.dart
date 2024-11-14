import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import '../../../../data/models/cron_job.dart';
import '../../../../data/services/cron_job_service.dart';
import '../../../widgets/cron_schedule_picker.dart';

class RecurringJobForm extends StatefulWidget {
  final SSHClient sshClient;

  const RecurringJobForm({
    super.key,
    required this.sshClient,
  });

  @override
  State<RecurringJobForm> createState() => _RecurringJobFormState();
}

class _RecurringJobFormState extends State<RecurringJobForm> {
  final _formKey = GlobalKey<FormState>();
  late final CronJobService _cronJobService;

  final _commandController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _cronExpression = '* * * * *';
  bool _isLoading = false;
  String? _error;

  // Initialize with a default value
  ScheduleType _scheduleType = ScheduleType.simple;

  @override
  void initState() {
    super.initState();
    _cronJobService = CronJobService(widget.sshClient);
  }

  @override
  void dispose() {
    _commandController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final job = CronJob(
        expression: _cronExpression,
        command: _commandController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      await _cronJobService.create(job);

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create job: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Recurring Job'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Command Input
            TextFormField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: 'Command *',
                hintText: 'Enter the command to execute',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a command';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Input
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter a description for this job',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Schedule Type Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedule Type', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<ScheduleType>(
                      segments: const [
                        ButtonSegment(
                          value: ScheduleType.simple,
                          label: Text('Simple'),
                        ),
                        ButtonSegment(
                          value: ScheduleType.custom,
                          label: Text('Custom'),
                        ),
                      ],
                      selected: {_scheduleType},
                      onSelectionChanged: (Set<ScheduleType> selection) {
                        setState(() => _scheduleType = selection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Schedule Picker based on type
            if (_scheduleType == ScheduleType.simple)
              SimpleSchedulePicker(
                onChanged: (expression) {
                  setState(() => _cronExpression = expression);
                },
              )
            else
              CustomSchedulePicker(
                onChanged: (expression) {
                  setState(() => _cronExpression = expression);
                },
              ),

            const SizedBox(height: 16),

            // Preview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preview', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Cron Expression: $_cronExpression'),
                    const SizedBox(height: 4),
                    Text(
                      'Runs: ${_cronJobService.humanReadableFormat(_cronExpression)}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Next 3 executions:',
                      style: theme.textTheme.titleSmall,
                    ),
                    ...CronJob(
                      expression: _cronExpression,
                      command: _commandController.text,
                    ).getNextExecutions().map((dt) => Text('• ${_formatDateTime(dt)}'))
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Schedule Job'),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
