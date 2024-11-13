import 'package:dartssh2/dartssh2.dart';
import '../models/cron_job.dart';

class CronJobService {
  final SSHClient _sshClient;

  CronJobService(this._sshClient);

  // Get all cron jobs
  Future<List<CronJob>> getAll() async {
    try {
      final result = await _sshClient.run('crontab -l');
      final output = String.fromCharCodes(result);

      if (output.contains('no crontab')) {
        return [];
      }

      return output
          .split('\n')
          .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
          .map((line) => CronJob.fromCrontabLine(line))
          .toList();
    }
    catch (e) {
      throw Exception('Failed to get cron jobs: $e');
    }
  }

  // Create new cron job
  Future<void> create(CronJob job) async {
    try {
      // Get existing jobs
      final jobs = await getAll();
      jobs.add(job);

      // Create temporary file with all jobs
      const tempFile = '/tmp/crontab_new';
      final content = '${jobs.map((j) => j.toCrontabLine()).join('\n')}\n';

      // Write to temp file and install new crontab
      await _sshClient.run('echo "$content" > $tempFile');
      await _sshClient.run('crontab $tempFile');
      await _sshClient.run('rm $tempFile');
    }
    catch (e) {
      throw Exception('Failed to create cron job: $e');
    }
  }

  // Delete cron job
  Future<void> delete(CronJob job) async {
    try {
      final jobs = await getAll();
      jobs.removeWhere(
              (j) => j.expression == job.expression && j.command == job.command
      );

      const tempFile = '/tmp/crontab_new';
      final content = '${jobs.map((j) => j.toCrontabLine()).join('\n')}\n';

      await _sshClient.run('echo "$content" > $tempFile');
      await _sshClient.run('crontab $tempFile');
      await _sshClient.run('rm $tempFile');
    }
    catch (e) {
      throw Exception('Failed to delete cron job: $e');
    }
  }

  // Convert cron expression to human readable format
  String humanReadableFormat(String expression) {
    final parts = expression.split(' ');
    if (parts.length != 5) throw Exception('Invalid cron expression');

    final minute = parts[0];
    final hour = parts[1];
    final dayOfMonth = parts[2];
    final month = parts[3];
    final dayOfWeek = parts[4];

    final List<String> segments = [];

    // Handle special cases first
    if (expression == '* * * * *') return 'Every minute';
    if (expression == '0 * * * *') return 'Every hour';
    if (expression == '0 0 * * *') return 'Every day at midnight';

    // Time component
    if (minute != '*' && hour != '*') {
      final hourInt = int.parse(hour);
      final minuteInt = int.parse(minute);
      final time = DateTime(2024, 1, 1, hourInt, minuteInt);
      segments.add('at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
    }

    // Day of week
    if (dayOfWeek != '*') {
      final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      if (dayOfWeek.contains(',')) {
        final daysList = dayOfWeek.split(',').map((d) => days[int.parse(d) % 7]).toList();
        segments.insert(0, 'Every ${daysList.join(' and ')}');
      }
      else {
        segments.insert(0, 'Every ${days[int.parse(dayOfWeek) % 7]}');
      }
    }

    return segments.join(' ');
  }
}