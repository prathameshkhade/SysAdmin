import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:sysadmin/core/widgets/button.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import '../../../../data/models/cron_job.dart';
import '../../../../data/services/cron_job_service.dart';

class CronJobForm extends StatefulWidget {
  final SSHClient sshClient;

  const CronJobForm({
    super.key,
    required this.sshClient,
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

  // bool _enableErrorLogging = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cronJobService = CronJobService(widget.sshClient);
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
    super.dispose();
  }

  // Handles Quick Schedule button clicks
  void _handleQuickSchedule(String type) {
    switch (type) {
      case 'startup':
        setState(() {
          _minuteController.text = '@reboot';
        });
        break;
      case 'hourly':
        setState(() {
          _minuteController.text = '0';
          _hourController.text = '*';
        });
        break;
      case 'daily':
        setState(() {
          _minuteController.text = '0';
          _hourController.text = '0';
        });
        break;
      case 'weekly':
        setState(() {
          _minuteController.text = '0';
          _hourController.text = '0';
          _weekController.text = '0';
        });
        break;
      case 'monthly':
        setState(() {
          _minuteController.text = '0';
          _hourController.text = '0';
          _dayController.text = '1';
        });
        break;
      case 'yearly':
        setState(() {
          _minuteController.text = '0';
          _hourController.text = '0';
          _dayController.text = '1';
          _monthController.text = '1';
        });
        break;
    }
  }

  // Handles form submission
  Future<void> _submitForm() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final expression = '${_minuteController.text} ${_hourController.text} '
          '${_dayController.text} ${_monthController.text} ${_weekController.text}';

      final job = CronJob(
        expression: expression,
        command: _commandController.text.trim(),
        description: _nameController.text.trim(),
      );

      await _cronJobService.create(job);

      // Return true to refresh the list of jobs
      if (mounted) Navigator.pop(context, true);

    }
    catch (e) {
      setState(() {
        _error = 'Failed to create job: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
      title: 'New Cron Job',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    text: schedule
                  ),
              ],
            ),
            const SizedBox(height: 24),

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
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Job Preview
            Text('Preview', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commandController,
              readOnly: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),

            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),

            // Schedule Button
            CupertinoButton.filled(
              onPressed: _submitForm,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.surface),
                      ),
                    )
                  : const Text('Schedule Job'),
            )
          ],
        ),
      ),
    );
  }
}