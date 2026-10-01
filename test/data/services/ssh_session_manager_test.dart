import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sysadmin/data/services/ssh_session_manager.dart';

class FakeClient implements SSHClient {
  final Future<Uint8List> Function(String) handler;
  FakeClient(this.handler);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #isClosed) return false;
    if (invocation.memberName == #run) {
      return handler(invocation.positionalArguments.first as String);
    }
    return super.noSuchMethod(invocation);
  }
}

Uint8List bytes(String value) => Uint8List.fromList(utf8.encode(value));

void main() {
  test(
    'failed command completes its own future and preserves next command',
    () async {
      final first = Completer<Uint8List>();
      final commands = <String>[];
      final manager = SSHSessionManager()
        ..setClient(
          FakeClient((command) {
            commands.add(command);
            return command == 'first'
                ? first.future
                : Future.value(bytes('second'));
          }),
        );
      final failed = manager.execute('first');
      final failure = expectLater(failed, throwsStateError);
      final next = manager.execute('second');
      first.completeError(StateError('command failed'));
      await failure.timeout(const Duration(seconds: 1));
      expect(await next.timeout(const Duration(seconds: 1)), 'second');
      expect(commands, ['first', 'second']);
    },
  );

  test(
    'clear settles queued commands without discarding active result',
    () async {
      final active = Completer<Uint8List>();
      final manager = SSHSessionManager()
        ..setClient(FakeClient((_) => active.future));
      final running = manager.execute('active');
      final queued = manager.execute('queued');
      final cancelled = expectLater(queued, throwsStateError);
      manager.clear();
      active.complete(bytes('done'));
      expect(await running, 'done');
      await cancelled.timeout(const Duration(seconds: 1));
    },
  );

  test('command lasting over three seconds succeeds', () async {
    final manager = SSHSessionManager()
      ..setClient(
        FakeClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 3100));
          return bytes('slow');
        }),
      );
    expect(
      await manager.execute('slow').timeout(const Duration(seconds: 5)),
      'slow',
    );
  });
}
