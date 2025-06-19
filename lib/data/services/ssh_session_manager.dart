import 'dart:async';
import 'dart:collection';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

class _SSHTask {
  final String command;
  final Completer<String> completer;

  _SSHTask(this.command, this.completer);
}

class SSHSessionManager {
  SSHClient? _client;
  bool _isExecuting = false;
  bool _isReconnecting = false;
  final _executionQueue = Queue<_SSHTask>();

  // Maximum number of retries for a failed command
  static const int _maxRetries = 3;

  void setClient(SSHClient? client) {
    _client = client;
    // Process any pending tasks when client is set
    if (_client != null) {
      _processQueue();
    }
  }

  Future<String> execute(String command, {int retryCount = 0}) async {
    // Return empty string if client is null to avoid errors
    if (_client == null) {
      return '';
    }

    // Queue commands and execute them one at a time
    final completer = Completer<String>();
    _executionQueue.add(_SSHTask(command, completer));
    _processQueue();
    return completer.future;
  }

  void _processQueue() async {
    if (_isExecuting || _executionQueue.isEmpty || _client == null || _isReconnecting) return;
    _isExecuting = true;

    try {
      final task = _executionQueue.removeFirst();
      final result = await _client!.run(task.command)
          .timeout(const Duration(seconds: 5));

      if (!task.completer.isCompleted) {
        task.completer.complete(String.fromCharCodes(result));
      }
    } catch (e) {
      debugPrint('SSH command error: $e');

      if (_executionQueue.isNotEmpty) {
        final failedTask = _executionQueue.removeFirst();
        if (!failedTask.completer.isCompleted) {
          failedTask.completer.completeError(e);
        }
      }

      // If the client is closed or has a connection error, signal the need for reconnection
      if (e is SSHChannelOpenError || (_client?.isClosed ?? true)) {
        _isReconnecting = true;

        // Clear and fail all pending tasks
        while (_executionQueue.isNotEmpty) {
          final task = _executionQueue.removeFirst();
          if (!task.completer.isCompleted) {
            task.completer.completeError(e);
          }
        }

        _isReconnecting = false;
      }
    } finally {
      _isExecuting = false;
      // Process next task if any
      if (_executionQueue.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), _processQueue);
      }
    }
  }

  bool get isConnected => _client != null && !(_client?.isClosed ?? true);

  void clear() {
    _executionQueue.clear();
  }
}