class SSHConnection {
  String name, host, username;
  String? privateKey, password;  // Made privateKey optional and added optional password
  int port;
  bool isDefault;

  SSHConnection({
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.privateKey,
    this.password,
    this.isDefault = false,
  });

  // Converts the object --> Map<String, dynamic> for local storage
  Map<String, dynamic> toJson() => {
    'name': name,
    'host': host,
    'port': port.toString(),
    'username': username,
    'privateKey': privateKey ?? '',  // Use empty string if null
    'password': password ?? '',      // Use empty string if null
    'isDefault': isDefault.toString(),
  };

  // Converts the Map --> object
  static SSHConnection fromJson(Map<String, dynamic> json) => SSHConnection(
      name: json['name'] ?? '',
      host: json['host'] ?? '',
      port: int.parse(json['port'] ?? '22'),
      username: json['username'] ?? '',
      privateKey: json['privateKey']?.isEmpty ?? true ? null : json['privateKey'],  // Convert empty string to null
      password: json['password']?.isEmpty ?? true ? null : json['password'],        // Convert empty string to null
      isDefault: json['isDefault'] == 'true'
  );
}