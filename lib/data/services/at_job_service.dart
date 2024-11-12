import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/cupertino.dart';
import '../models/at_job.dart';

class AtJobService {
  final SSHClient sshClient;

  AtJobService(this.sshClient);

  // Get all the At jobs from server
  Future<List<AtJob>> getAll() async {
    try {
      final result = await sshClient.run('atq');
      final output = utf8.decode(result);

      final jobs = output
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => AtJob.fromAtqOutput(line))
          .toList();

      // Fetch command for each job
      for (var job in jobs) {
        try {
          final commandResult = await sshClient.run('at -c ${job.id}');
          final commandOutput = utf8.decode(commandResult);
          // The last non-empty line is typically the command
          final command = commandOutput
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .last;
          job = AtJob(
            id: job.id,
            executionTime: job.executionTime,
            queueLetter: job.queueLetter,
            command: command,
            username: job.username,
            status: job.status,
          );
        }
        catch (e) {
          // If we can't get the command, just leave it empty
          debugPrint('Failed to fetch command for job ${job.id}: $e');
        }
      }

      return jobs;
    }
    catch (e) {
      throw Exception('Failed to fetch AT jobs: $e');
    }
  }

  // Creates a job
  Future<void> create(DateTime executionTime, String command) async {
    try {
      // Format the date for the at command
      final formattedDate = '${executionTime.hour}:${executionTime.minute} ${executionTime.month}/${executionTime.day}/${executionTime.year}';

      // Create a temporary script with the command
      await sshClient.execute('echo "$command" | at $formattedDate');
    }
    catch (e) {
      throw Exception('Failed to create AT job: $e');
    }
  }

  // Deletes a job
  Future<void> delete(String jobId) async {
    try {
      await sshClient.execute('atrm $jobId');
    }
    catch (e) {
      throw Exception('Failed to delete AT job: $e');
    }
  }

  // Get the Job details from server
  Future<String> getJobDetails(String jobId) async {
    try {
      final result = await sshClient.run('at -c $jobId');
      return utf8.decode(result);
    }
    catch (e) {
      throw Exception('Failed to get job details: $e');
    }
  }
}