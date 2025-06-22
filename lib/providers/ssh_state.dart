import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:sysadmin/data/services/connection_manager.dart';
import 'package:sysadmin/data/services/ssh_session_manager.dart';

// Provider for ConnectionManager instance
final connectionManagerProvider = Provider<ConnectionManager>((ref) {
  return ConnectionManager();
});

// Provider for the SSH session manager
final sshSessionManagerProvider = Provider<SSHSessionManager>((ref) {
  final manager = SSHSessionManager();
  ref.onDispose(() {
    manager.clear();
  });
  return manager;
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
  final sessionManager = ref.read(sshSessionManagerProvider);

  return defaultConnAsync.when(
    data: (connection) async {
      if (connection == null) return null;

      try {
        // First close any existing client in the session manager
        sessionManager.setClient(null);

        final client = SSHClient(
          await SSHSocket.connect(
            connection.host,
            connection.port,
            timeout: const Duration(seconds: 10),
          ),
          username: connection.username,
          onPasswordRequest: () => connection.password ?? '',
          identities: connection.privateKey != null
              ? SSHKeyPair.fromPem(connection.privateKey!)
              : null,
        );

        // Set the client in the session manager
        sessionManager.setClient(client);

        ref.onDispose(() {
          // Let the session manager handle the client lifecycle
          debugPrint("SSH client provider disposed");
        });

        return client;
      }
      catch (e) {
        debugPrint('Failed to connect: $e');
        throw Exception('Failed to connect: $e');
      }
    },
    loading: () async => null,
    error: (e, s) {
      throw e;
    },
  );
});

// Provider for connection status
final connectionStatusProvider = StreamProvider.autoDispose<bool>((ref) {
  final sessionManager = ref.watch(sshSessionManagerProvider);

  return Stream.periodic(const Duration(seconds: 2), (_) async {
    try {
      if (!sessionManager.isConnected) return false;

      final result = await sessionManager.execute('echo "PING"')
          .timeout(const Duration(seconds: 2));
      return result.trim() == "PING";
    } catch (e) {
      return false;
    }
  }).asyncMap((future) => future);
});