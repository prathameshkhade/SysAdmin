import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/at_job.dart';
import '../../../../data/services/at_job_service.dart';

class AtJobForm extends StatefulWidget {
  final SSHClient sshClient;
  final AtJob? jobToEdit;

  const AtJobForm({
    super.key,
    required this.sshClient,
    this.jobToEdit
  });

  @override
  State<AtJobForm> createState() => _AtJobFormState();
}

class _AtJobFormState extends State<AtJobForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _commandController;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 5));
  String _selectedQueue = 'a';
  bool _isLoading = false;
  bool _isEditing = false;

  // List of queues
  final List<String> _queueOptions = ['a', 'b', 'c', 'd', 'e', 'f'];

  @override
  void initState() {
    super.initState();
    _commandController = TextEditingController();
    _isEditing = widget.jobToEdit != null;

    // Initialize with existing job data if editing
    if (_isEditing) {
      _commandController.text = widget.jobToEdit!.command;
      _selectedDateTime = widget.jobToEdit!.executionTime;
      _selectedQueue = widget.jobToEdit!.queueLetter;
    }
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await _selectDate();
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await _selectTime();
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<DateTime?> _selectDate() async {
    return await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<TimeOfDay?> _selectTime() async {
    return await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final service = AtJobService(widget.sshClient);
        // await service.create(_selectedDateTime, _commandController.text.trim());
        if (_isEditing) {
          await service.update(
            widget.jobToEdit!.id,
            _selectedDateTime,
            _commandController.text.trim(),
            _selectedQueue,
          );
        } else {
          await service.create(
            _selectedDateTime,
            _commandController.text.trim(),
            _selectedQueue,
          );
        }

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Job scheduled successfully'),
              backgroundColor: Colors.green,
          ),
        );

        // Pop and return true to trigger refresh
        Navigator.of(context).pop(true);
      }
      catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule job: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${_isEditing ? 'Update' : 'Schedule'} AT Job'),
      ),

      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Command Input
            TextFormField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: 'Command to execute',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a command';
                }
                return null;
              },
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Queue Dropdown list
            DropdownButtonFormField<String> (
              value: _selectedQueue,

              decoration: const InputDecoration(
                labelText: 'Queue',
                border: OutlineInputBorder(),
              ),

              items: _queueOptions.map((queue) => DropdownMenuItem(
                  value: queue,
                  child: Text('Queue $queue')
              )).toList(),

              onChanged: (value) => setState(() => _selectedQueue = value!),
            ),

            const SizedBox(height: 24),

            // Schedule DateTime Input
            InkWell(
              onTap: () => _selectDateTime(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(_selectedDateTime),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Button
            CupertinoButton.filled(
              onPressed: _isLoading ? null : _submitForm,
              padding: const EdgeInsets.all(16),
              child: Text(_isEditing ? 'Update Job' : 'Schedule Job')
            ),
          ],
        ),
      ),
    );
  }
}