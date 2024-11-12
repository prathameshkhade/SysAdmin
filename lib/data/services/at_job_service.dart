import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import '../models/at_job.dart';

class AtJobService {
  final SSHClient sshClient;

  AtJobService(this.sshClient);

  // Get all the At jobs from server
  Future<List<AtJob>> getAll() async {
    try {
      final result = utf8.decode(await sshClient.run('atq'));

      return result
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => AtJob.fromAtqOutput(line))
          .toList();
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