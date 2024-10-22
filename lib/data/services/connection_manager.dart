import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';

class ConnectionManager {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Save a connection to local secure storage
  Future<void> save(SSHConnection conn) async {
    await _secureStorage.write(
        key: conn.name,
        value: conn.toJson().toString()
    );
  }

  // Get all the saved connections from local storage
  Future<List<SSHConnection>> getAll() async {
    Map<String, String> allConnections = await _secureStorage.readAll();
    return allConnections.entries.map((entry) {
      return SSHConnection.fromJson(Map<String, String>.from(jsonDecode(entry.value)));
    }).toList();
  }

  // Delete a particular connection from local storage
  Future<void> delete(String name) async => await _secureStorage.delete(key: name);

  // Delete all the connections from local storage
  Future<void> deleteAll() async => await _secureStorage.deleteAll();
}