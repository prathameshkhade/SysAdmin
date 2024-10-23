import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ssh_connection.dart';

class ConnectionManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _connectionsKey = 'ssh_connections';

  Future<void> save(SSHConnection connection) async {
    List<SSHConnection> connections = await getAll();
    connections.add(connection);
    await _saveAll(connections);
  }

  Future<List<SSHConnection>> getAll() async {
    try {
      String? data = await _storage.read(key: _connectionsKey);
      if (data == null || data.isEmpty) {
        return [];
      }

      List<dynamic> jsonList = json.decode(data);
      return jsonList
          .map((json) => SSHConnection.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading connections: $e');
      // If there's an error, return empty list and optionally clear corrupt data
      await _storage.delete(key: _connectionsKey);
      return [];
    }
  }

  Future<void> _saveAll(List<SSHConnection> connections) async {
    String jsonString = json.encode(
      connections.map((conn) => conn.toJson()).toList(),
    );
    await _storage.write(key: _connectionsKey, value: jsonString);
  }

  Future<void> delete(String name) async {
    List<SSHConnection> connections = await getAll();
    connections.removeWhere((conn) => conn.name == name);
    await _saveAll(connections);
  }

  Future<void> update(String originalName, SSHConnection updatedConnection) async {
    List<SSHConnection> connections = await getAll();
    int index = connections.indexWhere((conn) => conn.name == originalName);
    if (index != -1) {
      connections[index] = updatedConnection;
      await _saveAll(connections);
    }
  }
}