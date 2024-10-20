class SSHConnection {
  String name, host, username, privateKey;
  int port;
  bool isDefault;

  SSHConnection({
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.privateKey,
    this.isDefault = false,
  });

  // Converts the object --> Map<String, dynamic> for local storage
  Map<String, dynamic> toJson() => {
    'name': name,
    'host': host,
    'port': port.toString(),
    'privateKey': privateKey,
    'isDefault': isDefault.toString(),
  };

  // Converts the Map --> object
  static SSHConnection fromJson(Map<String, dynamic> json) => SSHConnection(
      name: json['name'] ?? '',
      host: json['host'] ?? '',
      port: int.parse(json['port'] ?? '22'),
      username: json['username'] ?? '',
      privateKey: json['privateKey'] ?? '',
      isDefault: json['isDefault'] == 'true'
  );
}