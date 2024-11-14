import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:intl/intl.dart';
import 'package:sysadmin/presentation/widgets/bottom_sheet.dart';
import '../../../../data/models/cron_job.dart';
import '../../../../data/services/cron_job_service.dart';

class RecurringJobScreen extends StatefulWidget {
  final SSHClient sshClient;
  final Function(int) onJobCountChanged;

  const RecurringJobScreen({
    super.key,
    required this.sshClient,
    required this.onJobCountChanged,
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
      // Update parent with job count
      widget.onJobCountChanged(_jobs?.length ?? 0);
    } catch (e) {
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_jobs == null || _jobs!.isEmpty) return const Center(child: Text('No recurring jobs found'));

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        itemCount: _jobs!.length,
        itemBuilder: (context, index) {
          final job = _jobs![index];
          List<DateTime>? nextRuns;
          String scheduleDisplay;

          try {
            if (job.expression.startsWith('@reboot')) {
              scheduleDisplay = 'At system startup';
            } else {
              nextRuns = job.getNextExecutions();
              scheduleDisplay = _cronJobService.humanReadableFormat(job.expression);
            }
          }
          catch (e) {
            // Handle parsing errors gracefully
            debugPrint('Error parsing cron expression: ${job.expression}');
            scheduleDisplay = 'Invalid schedule format';
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(scheduleDisplay),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('└─ Command: ${job.command}'),
                  if (nextRuns != null && nextRuns.isNotEmpty)
                    Text('Next Run: ${_formatDateTime(nextRuns.first)}'),
                ],
              ),
              onTap: () => _showJobDetails(job),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('EEE, d MMM yyyy HH:mm').format(dt);
  }

  void _showJobDetails(CronJob job) {
    List<DateTime>? nextDates;
    String scheduleDisplay;

    try {
      if (job.expression.startsWith('@reboot')) {
        scheduleDisplay = 'At system startup';
      } else {
        nextDates = job.getNextExecutions(count: 3);
        scheduleDisplay = _cronJobService.humanReadableFormat(job.expression);
      }
    } catch (e) {
      scheduleDisplay = 'Invalid schedule format';
    }

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
                    onPressed: () {
                      // TODO: Implement edit functionality
                      Navigator.pop(context);
                    }
                ),
                ActionButtonData(
                    text: "DELETE",
                    bgColor: Colors.red,
                    onPressed: () async {
                      try {
                        await _cronJobService.delete(job);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadJobs();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  content: Text('Failed to delete job: $e')
                              )
                          );
                        }
                      }
                    }
                ),
              ],
              tables: <TableData>[
                TableData(
                    heading: "CronJob Details",
                    rows: <TableRowData>[
                      TableRowData(label: "Cron Expression", value: job.expression),
                      TableRowData(label: "Schedule", value: scheduleDisplay),
                      TableRowData(label: "Full Command", value: job.command),
                    ]
                ),
                if (nextDates != null && nextDates.isNotEmpty)
                  TableData(
                      heading: "Will be run on",
                      rows: <TableRowData>[
                        for (int i = 0; i < nextDates.length; i++)
                          TableRowData(
                              label: "Next ${i + 1}",
                              value: DateFormat('yyyy-MM-dd, hh:mm a').format(nextDates[i])
                          ),
                      ]
                  )
              ]
          ),
        )
    );
  }
}