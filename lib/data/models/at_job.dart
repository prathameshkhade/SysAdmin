class AtJob {
  final String id;
  final DateTime executionTime;
  final String queueLetter;
  final String command;
  final String status;

  AtJob({
    required this.id,
    required this.executionTime,
    required this.command,
    this.queueLetter = '',
    this.status = 'pending',
  });

  // Parse atq command output to create AtJob object
  static AtJob fromAtqOutput(String line) {
    // Example output: "23  2024-11-18 03:00 a root  /scripts/weekly_cleanup.sh"
    final parts = line.split(RegExp(r'\s+'));

    return AtJob(
      id: parts[0],
      executionTime: DateTime.parse('${parts[1]} ${parts[2]}'),
      queueLetter: parts[3],
      command: parts.sublist(5).join(' '),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'executionTime': executionTime.toIso8601String(),
    'queueLetter': queueLetter,
    'command': command,
    'status': status,
  };

  static AtJob fromJson(Map<String, dynamic> json) => AtJob(
    id: json['id'],
    executionTime: DateTime.parse(json['executionTime']),
    queueLetter: json['queueLetter'],
    command: json['command'],
    status: json['status'],
  );

  String getFormattedNextRun() {
    return '${executionTime.day}, ${_getMonthName(executionTime.month)} ${executionTime.year} '
        '${executionTime.hour.toString().padLeft(2, '0')}:${executionTime.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}