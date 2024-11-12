import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';

import '../../../../data/models/at_job.dart';
import '../../../../data/services/at_job_service.dart';
import 'form.dart';

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

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, AtJob job) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Job?'),
        content: Text('Are you sure you want to delete "Job #${job.id}" scheduled at "${job.executionTime}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
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
                    trailing: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Edit Button
                        InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => AtJobForm(
                                  sshClient: widget.sshClient,
                                  jobToEdit: job,  // Pass the job to edit
                                ),
                              ),
                            );

                            if (result == true) {
                              _loadJobs();  // Refresh the list after editing
                            }
                          },
                          child: Container(
                            height: 25,
                            width: 25,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.edit_outlined, size: 20, color: theme.primaryColor),
                          ),
                        ),

                        const SizedBox(width: 5),

                        // Delete Button
                        InkWell(
                          onTap: () async {
                            try {
                              final bool? confirmDelete = await _showDeleteConfirmationDialog(context, job);
                              if (!mounted) return;
                              if (confirmDelete == true) {
                                await _atJobService.delete(job.id);
                                _loadJobs();
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete job: $e'),
                                  backgroundColor: theme.colorScheme.error,
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
