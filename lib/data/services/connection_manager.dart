import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ssh_connection.dart';

class ConnectionManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _connectionsKey = 'ssh_connections';

  // Helper to check if connection with same host and username exists
  Future<bool> _isDuplicateConnection(SSHConnection newConn, {String? originalName}) async {
    final connections = await getAll();
    return connections.any((conn) =>
    conn.host == newConn.host &&
        conn.username == newConn.username &&
        conn.name != originalName // Exclude the connection being updated
    );
  }

  Future<void> save(SSHConnection connection) async {
    // Check for duplicate host+username combination
    if (await _isDuplicateConnection(connection)) {
      throw Exception('A connection with the same host and username already exists');
    }

    // Check for duplicate name
    List<SSHConnection> connections = await getAll();
    if (connections.any((conn) => conn.name == connection.name)) {
      throw Exception('A connection with this name already exists');
    }

    connections.add(connection);
    await _saveAll(connections);
  }

  Future<void> update(String originalName, SSHConnection updatedConnection) async {
    // Check for duplicate host+username combination
    if (await _isDuplicateConnection(updatedConnection, originalName: originalName)) {
      throw Exception('A connection with the same host and username already exists');
    }

    List<SSHConnection> connections = await getAll();

    // Check for duplicate name (excluding the original connection)
    if (originalName != updatedConnection.name &&
        connections.any((conn) => conn.name == updatedConnection.name)) {
      throw Exception('A connection with this name already exists');
    }

    int index = connections.indexWhere((conn) => conn.name == originalName);
    if (index != -1) {
      // Preserve default status if this was the default connection
      bool wasDefault = connections[index].isDefault;
      updatedConnection = SSHConnection(
        name: updatedConnection.name,
        host: updatedConnection.host,
        port: updatedConnection.port,
        username: updatedConnection.username,
        privateKey: updatedConnection.privateKey,
        password: updatedConnection.password,
        isDefault: wasDefault,
        createdAt: updatedConnection.createdAt,
      );
      connections[index] = updatedConnection;
      await _saveAll(connections);
    }
  }

  Future<void> setDefaultConnection(String name) async {
    List<SSHConnection> connections = await getAll();
    bool foundDefault = false;

    // Update all connections
    for (var i = 0; i < connections.length; i++) {
      if (connections[i].name == name) {
        connections[i] = SSHConnection(
          name: connections[i].name,
          host: connections[i].host,
          port: connections[i].port,
          username: connections[i].username,
          privateKey: connections[i].privateKey,
          password: connections[i].password,
          createdAt: connections[i].createdAt,
          isDefault: true,
        );
        foundDefault = true;
      } else {
        connections[i] = SSHConnection(
          name: connections[i].name,
          host: connections[i].host,
          port: connections[i].port,
          username: connections[i].username,
          privateKey: connections[i].privateKey,
          password: connections[i].password,
          createdAt: connections[i].createdAt,
          isDefault: false, // Ensure other connections are not default
        );
      }
    }

    if (!foundDefault) {
      throw Exception('Connection not found: $name');
    }

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

  // Handles single connection case
  Future<void> ensureDefaultConnection() async {
    List<SSHConnection> connections = await getAll();
    if (connections.length == 1 && !connections[0].isDefault) {
      connections[0] = SSHConnection(
        name: connections[0].name,
        host: connections[0].host,
        port: connections[0].port,
        username: connections[0].username,
        privateKey: connections[0].privateKey,
        password: connections[0].password,
        createdAt: connections[0].createdAt,
        isDefault: true,
      );
      await _saveAll(connections);
    }
  }

  // Get default connection helper
  Future<SSHConnection?> getDefaultConnection() async {
    try {
      List<SSHConnection> connections = await getAll();

      // First try to find a connection marked as default
      SSHConnection? defaultConn = connections.cast<SSHConnection?>().firstWhere(
            (conn) => conn?.isDefault == true,
        orElse: () => null,
      );

      // If no default is set but there's only one connection, return that
      if (defaultConn == null && connections.length == 1) return connections.first;

      return defaultConn;
    }
    catch (e) {
      debugPrint('Error getting default connection: $e');
      return null;
    }
  }
}