import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/presentation/widgets/delete_confirmation_dialog.dart';

import '../../../../data/models/at_job.dart';
import '../../../../data/services/at_job_service.dart';
import 'form.dart';

class DeferredJobScreen extends StatefulWidget {
  final SSHClient sshClient;
  final Function(int) onJobCountChanged;

  const DeferredJobScreen({
    super.key,
    required this.sshClient,
    required this.onJobCountChanged,
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
      // Update parent with job count
      widget.onJobCountChanged(_jobs.length);
    }
    catch (e) {
      if (mounted) {
        Util.showMsg(context: context, msg: "Failed to load jobs: $e", isError: true);
      }
    }
    finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, AtJob job) async {
    return showDialog<bool> (
        context: context,
        builder: (context) => DeleteConfirmationDialog(
            title: "Delete Job?",
            content: Text('Are you sure you want to delete "Job #${job.id}" scheduled at "${job.executionTime}"?')
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                              color: theme.colorScheme.primary.useOpacity(0.2),
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
                              if (confirmDelete == true) {
                                await _atJobService.delete(job.id);
                                _loadJobs();
                              }
                            }
                            catch (e) {
                              if(mounted) {
                                  WidgetsBinding.instance.addPostFrameCallback(
                                      (_) => Util.showMsg(context: context, msg: "Failed to delete job: $e", isError: true)
                                  );
                              }
                            }
                          },

                          child: Container(
                            height: 25,
                            width: 25,
                            decoration: BoxDecoration(
                                color: theme.colorScheme.error.useOpacity(0.2),
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
