import 'package:dartssh2/dartssh2.dart';
import '../models/cron_job.dart';

class CronJobService {
  final SSHClient _sshClient;

  CronJobService(this._sshClient);

  // Convert cron expression to human readable format
  String humanReadableFormat(String expression) {
    if (expression.startsWith('@reboot')) {
      return 'At system startup';
    }

    try {
      final parts = expression.split(' ');
      if (parts.length != 5) throw const FormatException('Invalid number of parts');

      final [minute, hour, day, month, weekday] = parts;

      final sb = StringBuffer();

      // Handle special cases
      if (minute == '0' && hour == '0' && day == '1' && month == '1' && weekday == '*') {
        return 'Annually at midnight';
      }
      if (minute == '0' && hour == '0' && day == '1' && weekday == '*') {
        return 'Monthly on the 1st at midnight';
      }
      if (minute == '0' && hour == '0' && weekday == '0') {
        return 'Weekly on Sunday at midnight';
      }
      if (minute == '0' && hour == '0') {
        return 'Daily at midnight';
      }
      if (minute == '0' && day == '*' && month == '*' && weekday == '*') {
        return 'Hourly at minute 0';
      }

      // Build readable format for custom schedules
      if (minute != '*') sb.write('At minute $minute');
      if (hour != '*') {
        if (sb.isNotEmpty) sb.write(', ');
        sb.write('hour $hour');
      }
      if (day != '*') {
        if (sb.isNotEmpty) sb.write(', ');
        sb.write('day $day');
      }
      if (month != '*') {
        if (sb.isNotEmpty) sb.write(', ');
        sb.write('month $month');
      }
      if (weekday != '*') {
        if (sb.isNotEmpty) sb.write(', ');
        sb.write('on ${_getWeekday(weekday)}');
      }

      return sb.toString();
    } catch (e) {
      return 'Invalid schedule format';
    }
  }

  String _getWeekday(String day) {
    final days = {
      '0': 'Sunday',
      '1': 'Monday',
      '2': 'Tuesday',
      '3': 'Wednesday',
      '4': 'Thursday',
      '5': 'Friday',
      '6': 'Saturday',
    };
    return days[day] ?? day;
  }

  Future<List<CronJob>> getAll() async {
    final result = await _sshClient.run('crontab -l');
    final output = String.fromCharCodes(result);

    if (output.contains('no crontab')) {
      return [];
    }

    return output
        .split('\n')
        .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
        .map((line) {
      final parts = line.trim().split(' ');
      if (parts[0] == '@reboot') {
        return CronJob(
          expression: '@reboot',
          command: parts.sublist(1).join(' '),
        );
      } else {
        return CronJob(
          expression: parts.take(5).join(' '),
          command: parts.sublist(5).join(' '),
        );
      }
    })
        .toList();
  }

  Future<void> create(CronJob job) async {
    // Validate cron expression before saving
    if (!job.expression.startsWith('@reboot')) {
      try {
        job.getNextExecutions();
      } catch (e) {
        throw FormatException('Invalid cron expression: ${job.expression}');
      }
    }

    final currentJobs = await getAll();
    currentJobs.add(job);

    final cronContent = currentJobs
        .map((job) => job.expression.startsWith('@reboot')
        ? '${job.expression} ${job.command}'
        : '${job.expression} ${job.command}')
        .join('\n');

    // Write to temporary file
    await _sshClient.run('echo "$cronContent" > /tmp/crontab.tmp');

    // Install new crontab
    final result = await _sshClient.run('crontab /tmp/crontab.tmp');
    if (result.isNotEmpty) {
      throw Exception('Failed to create cron job: ${String.fromCharCodes(result)}');
    }
  }

  Future<void> delete(CronJob job) async {
    final currentJobs = await getAll();
    currentJobs.removeWhere(
            (j) => j.expression == job.expression && j.command == job.command
    );

    final cronContent = currentJobs
        .map((job) => '${job.expression} ${job.command}')
        .join('\n');

    await _sshClient.run('echo "$cronContent" > /tmp/crontab.tmp');
    final result = await _sshClient.run('crontab /tmp/crontab.tmp');
    if (result.isNotEmpty) {
      throw Exception('Failed to delete cron job: ${String.fromCharCodes(result)}');
    }
  }
}