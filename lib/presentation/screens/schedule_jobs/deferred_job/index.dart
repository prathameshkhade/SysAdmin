import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';

import '../../../../data/models/at_job.dart';
import '../../../../data/services/at_job_service.dart';

class DeferredJobScreen extends StatefulWidget {
  final SSHClient sshClient;

  const DeferredJobScreen({
    super.key,
    required this.sshClient,
  });

  @override
  State<DeferredJobScreen> createState() => _DeferredJobScreenState();
}

class _DeferredJobScreenState extends State<DeferredJobScreen> {
  late AtJobService _atJobService;
  List<AtJob> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _atJobService = AtJobService(widget.sshClient);
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      setState(() => _isLoading = true);
      final jobs = await _atJobService.getAll();
      setState(() => _jobs = jobs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load jobs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        itemCount: _jobs.length,
        itemBuilder: (context, index) {
          final job = _jobs[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            // color: Colors.blue.shade50,
            child: ListTile(
              title: RichText(
                text: TextSpan(children: <TextSpan>[
                  TextSpan(text: 'Job #${job.id} \t |', style: theme.textTheme.titleMedium),
                  TextSpan(text: '\t Queue: ${job.queueLetter}', style: theme.textTheme.bodyMedium),
                ]),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('└─ Command: ${job.command}'),
                  Text('Next Run: ${job.getFormattedNextRun()}'),
                ],
              ),

              // trailing: PopupMenuButton(
              //   itemBuilder: (context) => [
              //     PopupMenuItem(
              //       child: const Text('Edit'),
              //       onTap: () {
              //         // TODO: Implement edit functionality
              //       },
              //     ),
              //     PopupMenuItem(
              //       child: const Text('Delete'),
              //       onTap: () async {
              //         try {
              //           await _atJobService.delete(job.id);
              //           _loadJobs();
              //         } catch (e) {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             SnackBar(
              //               content: Text('Failed to delete job: $e'),
              //               backgroundColor: Colors.red,
              //             ),
              //           );
              //         }
              //       },
              //     ),
              //   ],
              // ),
              trailing: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Edit Button
                  InkWell(
                    onTap: () => debugPrint('Edit clicked'),
                    child: Container(
                      height: 25,
                      width: 25,
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.edit_outlined, size: 20, color: theme.primaryColor),
                    ),
                  ),

                  const SizedBox(width: 5),

                  // Delete Button
                  InkWell(
                    onTap: () async {
                      try {
                        await _atJobService.delete(job.id);
                        _loadJobs();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete job: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 25,
                      width: 25,
                      decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
