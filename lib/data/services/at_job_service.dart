import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import '../models/at_job.dart';

class AtJobService {
  final SSHClient sshClient;

  AtJobService(this.sshClient);

  // Get list of all the jobs
  Future<List<AtJob>> getAll() async {
    try {
      final result = await sshClient.run('atq');
      final output = utf8.decode(result);
      final List<AtJob> jobs = [];

      final jobLines = output.split('\n').where((line) => line.trim().isNotEmpty);

      for (var line in jobLines) {
        try {
          // Parse basic job info
          final job = AtJob.fromAtqOutput(line);

          // Fetch command for this job
          final commandResult = await sshClient.run('at -c ${job.id}');
          final commandOutput = utf8.decode(commandResult);

          // Process command output to get the actual command
          final commandLines = commandOutput.split('\n').where((line) => line.trim().isNotEmpty).toList();

          // The actual command is usually in the last line
          final command = commandLines.isNotEmpty ? commandLines.last.trim() : '';

          // Create new job instance with the command
          jobs.add(AtJob(
            id: job.id,
            executionTime: job.executionTime,
            queueLetter: job.queueLetter,
            command: command,
            username: job.username,
            status: job.status,
          ));
        } catch (e) {
          debugPrint('Error processing job: $e');
          continue;
        }
      }

      return jobs;
    } catch (e) {
      throw Exception('Failed to fetch AT jobs: $e');
    }
  }

  // Create a job
  Future<void> create(DateTime executionTime, String command, String queue) async {
    try {
      // Format the date for the at command
      final formattedDate = _formatDateForAtCommand(executionTime);

      // Create the at job using a here-document to properly handle the command
      final atCommand = '''at -q $queue $formattedDate << 'EOT'
$command
EOT''';

      final result = await sshClient.run(atCommand);
      final output = utf8.decode(result);

      // Check if the output contains the expected "job X at" message
      // This is actually a success message, not an error
      if (!output.contains('job') || !output.contains('at')) {
        throw Exception('Unexpected response from server: $output');
      }

      // No need to verify with atq since we got the success message
    } catch (e) {
      if (e.toString().contains('job') && e.toString().contains('at')) {
        // This was actually a success, not an error
        return;
      }
      throw Exception('Failed to create AT job: $e');
    }
  }

  // Update a job
  Future<void> update(String jobId, DateTime executionTime, String command, String queue) async {
    try {
      // First remove the old job
      await delete(jobId);

      // Then create new job with updated details
      await create(executionTime, command, queue);
    } catch (e) {
      throw Exception('Failed to update AT job: $e');
    }
  }

  // Format the date
  String _formatDateForAtCommand(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year.toString();

    return '$hour:$minute $month/$day/$year';
  }

  // Deletes a job
  Future<void> delete(String jobId) async {
    try {
      await sshClient.execute('atrm $jobId');
    } catch (e) {
      throw Exception('Failed to delete AT job: $e');
    }
  }

  // Get the Job details from server
  Future<String> getJobDetails(String jobId) async {
    try {
      final result = await sshClient.run('at -c $jobId');
      return utf8.decode(result);
    } catch (e) {
      throw Exception('Failed to get job details: $e');
    }
  }
}
