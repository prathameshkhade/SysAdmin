import 'package:cron_parser/cron_parser.dart';

class CronJob {
  final String expression;      // Raw cron expression
  final String command;         // Command to execute
  final DateTime? lastRun;      // Last execution time
  final String? lastOutput;     // Output from last run
  final bool isActive;          // Whether job is active
  final String? description;    // Optional description

  CronJob({
    required this.expression,
    required this.command,
    this.lastRun,
    this.lastOutput,
    this.isActive = true,
    this.description,
  });

  // Parse crontab line into CronJob object
  factory CronJob.fromCrontabLine(String line) {
    final parts = line.trim().split(' ');
    if (parts.length < 6) throw Exception('Invalid crontab line');

    final expression = parts.sublist(0, 5).join(' ');
    final command = parts.sublist(5).join(' ');

    return CronJob(
      expression: expression,
      command: command,
    );
  }

  // Convert CronJob back to crontab line format
  String toCrontabLine() {
    return '$expression $command';
  }

  // Get next N execution times
  List<DateTime> getNextExecutions({int count = 3}) {
    if (expression.startsWith('@reboot')) {
      throw UnsupportedError('Cannot predict next execution for @reboot jobs');
    }

    final cronIterator = Cron().parse(expression, 'Asia/Kolkata');
    // final now = DateTime.now();

    List<DateTime> executions = [];
    DateTime next = cronIterator.next(); // Get the next date

    // Loops run for 3 times
    for (int i = 0; i < count; i++) {
      executions.add(next);           // Add the date to <DateTime> executions []
      next = cronIterator.next();     // Get the next date
    }

    return executions;
  }

  // For JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'expression': expression,
      'command': command,
      'lastRun': lastRun?.toIso8601String(),
      'lastOutput': lastOutput,
      'isActive': isActive,
      'description': description,
    };
  }

  // Create from JSON
  factory CronJob.fromJson(Map<String, dynamic> json) {
    return CronJob(
      expression: json['expression'],
      command: json['command'],
      lastRun: json['lastRun'] != null ? DateTime.parse(json['lastRun']) : null,
      lastOutput: json['lastOutput'],
      isActive: json['isActive'] ?? true,
      description: json['description'],
    );
  }
}