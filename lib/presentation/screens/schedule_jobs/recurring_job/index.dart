import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import '../../../../data/models/cron_job.dart';
import '../../../../data/services/cron_job_service.dart';

class RecurringJobScreen extends StatefulWidget {
  final SSHClient sshClient;

  const RecurringJobScreen({
    super.key,
    required this.sshClient,
  });

  @override
  State<RecurringJobScreen> createState() => _RecurringJobScreenState();
}

class _RecurringJobScreenState extends State<RecurringJobScreen> {
  late final CronJobService _cronJobService;
  List<CronJob>? _jobs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cronJobService = CronJobService(widget.sshClient);
    _loadJobs();
  }

  // Load all the jobs form server using CronJobService
  Future<void> _loadJobs() async {
    try {
      setState(() => _isLoading = true);
      final jobs = await _cronJobService.getAll();
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    }
    catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Text('Failed to load jobs: $e')
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while isLoading
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // If no jobs are present
    if (_jobs == null || _jobs!.isEmpty) return const Center(child: Text('No recurring jobs found'));

    return ListView.builder(
      itemCount: _jobs!.length,
      itemBuilder: (context, index) {
        final job = _jobs![index];
        final nextRuns = job.getNextExecutions();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(_cronJobService.humanReadableFormat(job.expression)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('└─ Command: ${job.command}'),
                Text('Next Run: ${_formatDateTime(nextRuns.first)}'),
              ],
            ),
            onTap: () => _showJobDetails(job),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showJobDetails(CronJob job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.25,
        builder: (_, controller) {
          final nextRuns = job.getNextExecutions(count: 3);

          return SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cron Expression: ${job.expression}'),
                const SizedBox(height: 8),
                Text('Human Readable: ${_cronJobService.humanReadableFormat(job.expression)}'),
                const SizedBox(height: 8),
                Text('Full Command: ${job.command}'),
                const SizedBox(height: 16),
                const Text('Next 3 Execution Times:'),
                ...nextRuns.map((dt) => Text('  • ${_formatDateTime(dt)}')),
                if (job.lastRun != null) ...[
                  const SizedBox(height: 8),
                  Text('Last Run: ${_formatDateTime(job.lastRun!)}'),
                ],
                if (job.lastOutput != null) ...[
                  const SizedBox(height: 8),
                  Text('Output: ${job.lastOutput}'),
                ],
                const SizedBox(height: 8),
                Text('Status: ${job.isActive ? 'Active' : 'Inactive'}'),
              ],
            ),
          );
        },
      ),
    );
  }
}