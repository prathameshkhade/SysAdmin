class AtJob {
  final String id;
  final DateTime executionTime;
  final String queueLetter;
  final String command;
  final String username;
  final String status;

  AtJob({
    required this.id,
    required this.executionTime,
    required this.queueLetter,
    required this.command,
    required this.username,
    this.status = 'pending',
  });

  // Parse atq command output to create AtJob object
  static AtJob fromAtqOutput(String line) {
    // Example output: "8    Tue Nov 12 09:04:00 2024 a prathamesh"
    try {
      // Split by whitespace while preserving the date/time parts
      final parts = line.trim().split(RegExp(r'\s+'));

      // Extract job ID (first part)
      final id = parts[0];

      // Extract queue letter (usually 'a')
      final queueLetter = parts[6];

      // Extract username (last part)
      final username = parts[7];

      // Reconstruct the datetime string
      // Format: "Tue Nov 12 09:04:00 2024"
      final dateTimeStr = '${parts[1]} ${parts[2]} ${parts[3]} ${parts[4]} ${parts[5]}';

      // Parse the datetime
      final executionTime = _parseDateTime(dateTimeStr);

      return AtJob(
        id: id,
        executionTime: executionTime,
        queueLetter: queueLetter,
        username: username,
        command: '', // We'll need to fetch this separately with 'at -c jobid'
      );
    }
    catch (e) {
      throw FormatException('Failed to parse AT job line: $line. Error: $e');
    }
  }

  // Helper method to parse the datetime string
  static DateTime _parseDateTime(String dateStr) {
    // Example input: "Tue Nov 12 09:04:00 2024"
    try {
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
      };

      final parts = dateStr.split(' ');
      final month = months[parts[1]]!;
      final day = int.parse(parts[2]);
      final timeParts = parts[3].split(':');
      final year = int.parse(parts[4]);

      return DateTime(
        year,
        month,
        day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    }
    catch (e) {
      throw FormatException('Invalid date format: $dateStr');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'executionTime': executionTime.toIso8601String(),
    'queueLetter': queueLetter,
    'command': command,
    'username': username,
    'status': status,
  };

  static AtJob fromJson(Map<String, dynamic> json) => AtJob(
    id: json['id'],
    executionTime: DateTime.parse(json['executionTime']),
    queueLetter: json['queueLetter'],
    command: json['command'],
    username: json['username'],
    status: json['status'],
  );

  String getFormattedNextRun() {
    final now = DateTime.now();
    final executionDate = executionTime;

    // Format the month
    final month = _getMonthName(executionDate.month);

    // Format the time
    final hour = executionDate.hour.toString().padLeft(2, '0');
    final minute = executionDate.minute.toString().padLeft(2, '0');

    // Get day of week
    final dayOfWeek = _getDayOfWeek(executionDate.weekday);

    return '$dayOfWeek, $month ${executionDate.day} ${executionDate.year} $hour:$minute';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getDayOfWeek(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }
}