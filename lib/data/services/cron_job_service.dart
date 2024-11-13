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

    // Handle months
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    String getTimeString(String hour, String minute) {
      int h = int.parse(hour);
      String period = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '${h.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')} $period';
    }

    String parseComponent(String value, List<String> referenceList, [bool isMonth = false]) {
      if (value == '*') return '';

      List<String> results = [];
      // Handle step values
      if (value.contains('/')) {
        final parts = value.split('/');
        final start = parts[0] == '*' ? '0' : parts[0];
        final step = int.parse(parts[1]);
        int current = int.parse(start);
        while (current < (isMonth ? 12 : referenceList.length)) {
          results.add(referenceList[current]);
          current += step;
        }
        return results.join(',');
      }

      // Handle ranges
      if (value.contains('-')) {
        final range = value.split('-');
        final start = int.parse(range[0]);
        final end = int.parse(range[1]);
        for (int i = start; i <= end; i++) {
          results.add(referenceList[isMonth ? i - 1 : i]);
        }
        return results.join('-');
      }

      // Handle lists
      if (value.contains(',')) {
        return value.split(',')
            .map((v) => referenceList[isMonth ? int.parse(v) - 1 : int.parse(v)])
            .join(',');
      }

      // Single value
      return referenceList[isMonth ? int.parse(value) - 1 : int.parse(value)];
    }

    // Build the output components
    List<String> output = [];

    // WeekDay
    String weekDayStr = parseComponent(dayOfWeek, days);
    if (weekDayStr.isNotEmpty) {
      output.add('WeekOfDay($weekDayStr)');
    }

    // Date
    if (dayOfMonth != '*') {
      output.add('Date($dayOfMonth)');
    }

    // Month
    String monthStr = parseComponent(month, months, true);
    if (monthStr.isNotEmpty) {
      output.add('Month($monthStr)');
    }

    // Add current year
    output.add('Year(${DateTime.now().year})');

    // Time
    if (hour != '*' || minute != '*') {
      String timeStr = 'at ';
      if (hour == '*') {
        timeStr += 'every hour';
        if (minute != '*') {
          timeStr += ' at ${minute.padLeft(2, '0')} minutes';
        }
      } else if (minute == '*') {
        timeStr += 'every minute of ${hour}th hour';
      } else {
        timeStr += getTimeString(hour, minute);
      }
      output.add(timeStr);
    }

    return output.join(', ');
  }
}