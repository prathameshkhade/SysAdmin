import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:intl/intl.dart';
import 'package:sysadmin/presentation/widgets/bottom_sheet.dart';
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

    final dates = job.getNextExecutions(count: 3);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) => CustomBottomSheet(

        data: CustomBottomSheetData(
          title: 'Expression: ${job.expression}',
          subtitle: job.command,
          actionButtons: [
            ActionButtonData(
                text: "EDIT",
                bgColor: Colors.blue,
                onPressed: (){}
            ),
            ActionButtonData(
                text: "DELETE",
                bgColor: Colors.red,
                onPressed: (){}
            ),
          ],
          tables: <TableData> [
            TableData(
                heading: "CronJob Details", 
                rows: <TableRowData> [
                  TableRowData(label: "Cron Expression", value: job.expression),
                  TableRowData(label: "Human Readable", value: _cronJobService.humanReadableFormat(job.expression)),
                  TableRowData(label: "Full Command", value: job.command),
                  // TableRowData(
                  //     label: "Last Run",
                  //     value: job.lastRun != null
                  //         ? DateFormat('yyyy-MM-dd, hh:mm a').format(job.lastRun!)
                  //         : "NA"
                  // )
                ]
            ),
            TableData(
                heading: "Will be run on",
                rows: <TableRowData> [
                  TableRowData(label: "Next 1", value: DateFormat('yyyy-MM-dd, hh:mm a').format(dates[0])),
                  TableRowData(label: "Next 2", value: DateFormat('yyyy-MM-dd, hh:mm a').format(dates[1])),
                  TableRowData(label: "Next 3", value: DateFormat('yyyy-MM-dd, hh:mm a').format(dates[2])),
                ]
            )
          ]
        ),
      )
    );
  }
}