import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import '../../../../data/models/cron_job.dart';
import '../../../../data/services/cron_job_service.dart';

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

  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  final _minuteController = TextEditingController(text: '*');
  final _hourController = TextEditingController(text: '*');
  final _dayController = TextEditingController(text: '*');
  final _monthController = TextEditingController(text: '*');
  final _weekController = TextEditingController(text: '*');

  bool _enableErrorLogging = false;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name (Optional)',
                hintText: 'cache cleaner',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Command Field
            TextFormField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: 'Command',
                hintText: 'rm -rf /var/cache',
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
            const Text(
              'Quick Schedule',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var schedule in ['Startup', 'Hourly', 'Daily', 'Weekly', 'Monthly', 'Yearly'])
                  ElevatedButton(
                    onPressed: () => _handleQuickSchedule(schedule.toLowerCase()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(schedule),
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
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Job Preview
            const Text(
              'Job',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commandController,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 16),

            // Error Logging Checkbox
            Row(
              children: [
                Checkbox(
                  value: _enableErrorLogging,
                  onChanged: (value) {
                    setState(() {
                      _enableErrorLogging = value ?? false;
                    });
                  },
                ),
                const Text('Enable error logging'),
              ],
            ),
            const SizedBox(height: 16),

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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}