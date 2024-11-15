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
      final segments = <String>[];

      // Minute parsing
      segments.add(_parseMinute(minute));

      // Hour parsing
      if (hour != '*') segments.add(_parseHour(hour));

      // Day parsing
      if (day != '*') segments.add(_parseDay(day));

      // Month parsing
      if (month != '*') segments.add(_parseMonth(month));

      // Weekday parsing
      if (weekday != '*') segments.add(_parseWeekday(weekday));

      return segments.join(', ');
    }
    catch (e) {
      return 'Invalid schedule format';
    }
  }

  String _parseMinute(String minute) {
    if (minute == '*') return 'Every minute';
    if (minute.startsWith('*/')) {
      return 'Every ${minute.substring(2)} minutes';
    }
    if (minute.contains('-')) {
      final parts = minute.split('-');
      return 'Every minute between ${_formatTime(parts[0])} and ${_formatTime(parts[1])}';
    }
    if (minute.contains(',')) {
      final minutes = minute.split(',');
      return 'At minutes ${minutes.map(_formatTime).join(', ')}';
    }
    return 'At minute ${_formatTime(minute)}';
  }

  String _parseHour(String hour) {
    if (hour == '*') return 'every hour';
    if (hour.startsWith('*/')) {
      return 'every ${hour.substring(2)} hours';
    }
    if (hour.contains('-')) {
      final parts = hour.split('-');
      return 'between ${_formatHour(parts[0])} and ${_formatHour(parts[1])}';
    }
    if (hour.contains(',')) {
      final hours = hour.split(',');
      return 'at ${hours.map(_formatHour).join(', ')}';
    }
    return 'at ${_formatHour(hour)}';
  }

  String _parseDay(String day) {
    if (day == '*') return 'every day';
    if (day.startsWith('*/')) {
      return 'every ${day.substring(2)} days';
    }
    if (day.contains('-')) {
      final parts = day.split('-');
      return 'between day ${parts[0]} and ${parts[1]}';
    }
    if (day.contains(',')) {
      final days = day.split(',');
      return 'on days ${days.join(', ')}';
    }
    return 'on day $day';
  }

  String _parseMonth(String month) {
    final months = {
      '1': 'January', '2': 'February', '3': 'March',
      '4': 'April', '5': 'May', '6': 'June',
      '7': 'July', '8': 'August', '9': 'September',
      '10': 'October', '11': 'November', '12': 'December'
    };

    if (month == '*') return 'every month';
    if (month.startsWith('*/')) {
      return 'every ${month.substring(2)} months';
    }
    if (month.contains('-')) {
      final parts = month.split('-');
      return 'from ${months[parts[0]]} to ${months[parts[1]]}';
    }
    if (month.contains(',')) {
      final monthsList = month.split(',');
      return 'in ${monthsList.map((m) => months[m]).join(', ')}';
    }
    return 'in ${months[month]}';
  }

  String _parseWeekday(String weekday) {
    final days = {
      '0': 'Sunday', '1': 'Monday', '2': 'Tuesday',
      '3': 'Wednesday', '4': 'Thursday', '5': 'Friday', '6': 'Saturday'
    };

    if (weekday == '*') return 'every day of the week';
    if (weekday.startsWith('*/')) {
      return 'every ${weekday.substring(2)} days of the week';
    }
    if (weekday.contains('-')) {
      final parts = weekday.split('-');
      return 'from ${days[parts[0]]} through ${days[parts[1]]}';
    }
    if (weekday.contains(',')) {
      final weekdays = weekday.split(',');
      return 'on ${weekdays.map((w) => days[w]).join(', ')}';
    }
    return 'on ${days[weekday]}';
  }

  String _formatTime(String minute) {
    return minute.padLeft(2, '0');
  }

  String _formatHour(String hour) {
    final hourInt = int.parse(hour);
    final period = hourInt < 12 ? 'AM' : 'PM';
    final hour12 = hourInt == 0 ? 12 : (hourInt > 12 ? hourInt - 12 : hourInt);
    return '$hour12:00 $period';
  }

  // Get all cron jobs
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
      final commentIndex = line.indexOf('#');
      String description = '';
      String actualCommand = line;

      if (commentIndex != -1) {
        description = line.substring(commentIndex + 1).trim();
        actualCommand = line.substring(0, commentIndex).trim();
      }

      final parts = actualCommand.trim().split(' ');
      if (parts[0] == '@reboot') {
        return CronJob(
          expression: '@reboot',
          command: parts.sublist(1).join(' '),
          description: description,
        );
      } else {
        return CronJob(
          expression: parts.take(5).join(' '),
          command: parts.sublist(5).join(' '),
          description: description,
        );
      }
    }).toList();
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
        .map((job) {
      final baseCommand = job.expression.startsWith('@reboot')
          ? '${job.expression} ${job.command}'
          : '${job.expression} ${job.command}';
      return job.description?.isNotEmpty == true
          ? '$baseCommand # ${job.description}'
          : baseCommand;
    })
        .join('\n');

    // Write to temporary file
    await _sshClient.run('echo "$cronContent" > /tmp/crontab.tmp');

    // Install new crontab
    final result = await _sshClient.run('crontab /tmp/crontab.tmp');
    if (result.isNotEmpty) {
      throw Exception('Failed to create cron job: ${String.fromCharCodes(result)}');
    }
  }

  Future<void> update(CronJob oldJob, CronJob newJob) async {
    final currentJobs = await getAll();
    final index = currentJobs.indexWhere((job) =>
    job.expression == oldJob.expression && job.command == oldJob.command);
    if (index == -1) {
      throw Exception('Job not found in crontab');
    }
    currentJobs[index] = newJob;

    final cronContent = currentJobs
        .map((job) {
      final baseCommand = job.expression.startsWith('@reboot')
          ? '${job.expression} ${job.command}'
          : '${job.expression} ${job.command}';
      return job.description?.isNotEmpty == true
          ? '$baseCommand # ${job.description}'
          : baseCommand;
    })
        .join('\n');

    // Write to temporary file
    await _sshClient.run('echo "$cronContent" > /tmp/crontab.tmp');

    // Install new crontab
    final result = await _sshClient.run('crontab /tmp/crontab.tmp');
    if (result.isNotEmpty) {
      throw Exception('Failed to update cron job: ${String.fromCharCodes(result)}');
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