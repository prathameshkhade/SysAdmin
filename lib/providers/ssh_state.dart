// ssh_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:sysadmin/data/services/connection_manager.dart';

// Provider for ConnectionManager instance
final connectionManagerProvider = Provider<ConnectionManager>((ref) {
  return ConnectionManager();
});

// AsyncNotifier to manage the list of SSH connections
class SSHConnectionsNotifier extends AsyncNotifier<List<SSHConnection>> {
  @override
  Future<List<SSHConnection>> build() async {
    return ref.read(connectionManagerProvider).getAll();
  }

  Future<void> refreshConnections() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(connectionManagerProvider).getAll());
  }

  Future<void> addConnection(SSHConnection connection) async {
    await ref.read(connectionManagerProvider).save(connection);
    await refreshConnections();
  }

  Future<void> updateConnection(String originalName, SSHConnection connection) async {
    await ref.read(connectionManagerProvider).update(originalName, connection);
    await refreshConnections();
  }

  Future<void> deleteConnection(String name) async {
    await ref.read(connectionManagerProvider).delete(name);
    await refreshConnections();
  }

  Future<void> setDefaultConnection(String name) async {
    await ref.read(connectionManagerProvider).setDefaultConnection(name);
    await refreshConnections();
  }

  Future<void> ensureDefaultConnection() async {
    await ref.read(connectionManagerProvider).ensureDefaultConnection();
    await refreshConnections();
  }
}

// Provider for the SSH connections list
final sshConnectionsProvider = AsyncNotifierProvider<SSHConnectionsNotifier, List<SSHConnection>>(() {
  return SSHConnectionsNotifier();
});

// Provider for the default SSH connection
final defaultConnectionProvider = Provider<AsyncValue<SSHConnection?>>((ref) {
  final connections = ref.watch(sshConnectionsProvider);

  return connections.when(
    data: (connections) {
      final defaultConn = connections.cast<SSHConnection?>().firstWhere(
            (conn) => conn?.isDefault == true,
            orElse: () => connections.isNotEmpty ? connections.first : null,
          );
      return AsyncData(defaultConn);
    },
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

// Provider for the SSH client
final sshClientProvider = FutureProvider.autoDispose<SSHClient?>((ref) async {
  final defaultConnAsync = ref.watch(defaultConnectionProvider);

  return defaultConnAsync.when(
    data: (connection) async {
      if (connection == null) return null;

      try {
        final client = SSHClient(
          await SSHSocket.connect(
            connection.host,
            connection.port,
            timeout: const Duration(seconds: 10),
          ),
          username: connection.username,
          onPasswordRequest: () => connection.password ?? '',
          identities: connection.privateKey != null
              ? SSHKeyPair.fromPem(connection.privateKey!) // Removed the list brackets
              : null,
        );

        // Dispose the client when the provider is disposed
        ref.onDispose(() async {
          client.close();
        });

        return client;
      } catch (e) {
        throw Exception('Failed to connect: $e');
      }
    },
    loading: () async => null,
    error: (e, s) async => null,
  );
});

// Provider for connection status
final connectionStatusProvider = StreamProvider.autoDispose<bool>((ref) {
  final clientFuture = ref.watch(sshClientProvider.future);

  return Stream.periodic(const Duration(seconds: 5), (_) async {
    final client = await clientFuture;
    if (client == null) return false;

    try {
      await client.ping();
      return true;
    }
    catch (_) {
      return false;
    }
  }).asyncMap((future) => future);
});
