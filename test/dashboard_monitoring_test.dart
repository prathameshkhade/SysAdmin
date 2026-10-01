import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysadmin/presentation/screens/dashboard/index.dart';
import 'package:sysadmin/providers/ssh_state.dart';
import 'package:sysadmin/data/models/ssh_connection.dart';
import 'package:sysadmin/data/services/connection_manager.dart';
import 'package:sysadmin/providers/system_information_provider.dart';
import 'package:sysadmin/providers/system_resources_provider.dart';
import 'data/services/ssh_session_manager_test.dart' show FakeClient, bytes;

class Connections extends ConnectionManager {
  @override
  Future<List<SSHConnection>> getAll() async => [];
}

class Resources extends OptimizedSystemResourcesNotifier {
  int starts = 0;
  bool monitoring = false;
  @override
  void stopMonitoring({bool resetState = true}) {
    monitoring = false;
    super.stopMonitoring(resetState: resetState);
  }

  Resources(super.ref);
  @override
  void startMonitoring() {
    if (monitoring) return;
    monitoring = true;
    starts++;
  }
}

class Information extends SystemInformationNotifier {
  int fetches = 0;
  Information(super.ref);
  @override
  Future<void> fetchSystemInformation() async {
    fetches++;
  }
}

void main() {
  testWidgets(
    'disconnected dashboard rebuilds do not start monitoring or fetch information',
    (tester) async {
      late Resources resources;
      late Information information;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionManagerProvider.overrideWith((ref) => Connections()),
            sshClientProvider.overrideWith((ref) async => null),
            defaultConnectionProvider.overrideWith(
              (ref) => const AsyncData(null),
            ),
            connectionStatusProvider.overrideWith((ref) => Stream.value(false)),
            optimizedSystemResourcesProvider.overrideWith(
              (ref) => resources = Resources(ref),
            ),
            systemInformationProvider.overrideWith(
              (ref) => information = Information(ref),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      ProviderScope.containerOf(
        tester.element(find.byType(DashboardScreen)),
      ).read(systemInformationProvider);
      expect(resources.starts, 0);
      expect(information.fetches, 0);
    },
  );
  testWidgets('resource rebuilds fetch information once per client', (
    tester,
  ) async {
    late Resources resources;
    late Information information;
    final status = StreamController<bool>();
    addTearDown(status.close);
    final client = FakeClient((_) async => bytes(''));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionManagerProvider.overrideWith((ref) => Connections()),
          sshClientProvider.overrideWith((ref) async => client),
          defaultConnectionProvider.overrideWith(
            (ref) => const AsyncData(null),
          ),
          connectionStatusProvider.overrideWith((ref) => status.stream),
          optimizedSystemResourcesProvider.overrideWith(
            (ref) => resources = Resources(ref),
          ),
          systemInformationProvider.overrideWith(
            (ref) => information = Information(ref),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    status.add(true);
    await tester.pump();
    await tester.pump();
    expect(information.fetches, 1);
    expect(resources.starts, 1);
    for (var i = 0; i < 3; i++) {
      resources.resetValues();
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
    expect(information.fetches, 1);
    expect(resources.starts, 1);
    status.add(false);
    await tester.pump();
    await tester.pump();
    expect(resources.monitoring, isFalse);
    status.add(true);
    await tester.pump();
    await tester.pump();
    expect(resources.monitoring, isTrue);
    expect(resources.starts, 2);
    expect(information.fetches, 1);
  });
}
