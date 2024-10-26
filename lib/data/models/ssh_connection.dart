class SSHConnection {
  String name, host, username;
  String? privateKey, password;
  int port;
  bool isDefault;
  late String createdAt;

  SSHConnection({
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.privateKey,
    this.password,
    this.isDefault = false,
    String? createdAt,
  }): createdAt = createdAt ?? DateTime.now().toString().substring(0, 16);

  // Converts the object --> Map<String, dynamic> for local storage
  Map<String, dynamic> toJson() => {
    'name': name,
    'host': host,
    'port': port.toString(),
    'username': username,
    'privateKey': privateKey ?? '',
    'password': password ?? '',
    'isDefault': isDefault.toString(),
    'createdAt': createdAt,
  };

  // Converts the Map --> object
  static SSHConnection fromJson(Map<String, dynamic> json) => SSHConnection(
    name: json['name'] ?? '',
    host: json['host'] ?? '',
    port: int.parse(json['port'] ?? '22'),
    username: json['username'] ?? '',
    privateKey: json['privateKey']?.isEmpty ?? true ? null : json['privateKey'],
    password: json['password']?.isEmpty ?? true ? null : json['password'],
    isDefault: json['isDefault'] == 'true',
    createdAt: json['createdAt'] ?? DateTime.now().toString().substring(0, 16),
  );
}