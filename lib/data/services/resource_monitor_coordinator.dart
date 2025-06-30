import 'dart:async';

import 'package:flutter/foundation.dart';

typedef ResourceCallback = Future<void> Function();

class ResourceMonitorCoordinator {
  Timer? _timer;
  final List<ResourceCallback> _callbacks = [];
  bool _isActive = false;
  bool _isExecuting = false;

  void startMonitoring({Duration interval = const Duration(seconds: 3)}) {
    if (_timer != null) return;

    _isActive = true;
    _timer = Timer.periodic(interval, (_) {
      _executeCallbacks();
    });

    // Execute immediately on start
    _executeCallbacks();
  }

  Future<void> _executeCallbacks() async {
    if (!_isActive || _isExecuting) return;

    _isExecuting = true;
    for (final callback in _callbacks) {
      try {
        await callback();
      } catch (e) {
        debugPrint('Error in resource monitor callback: $e');
      }
    }
    _isExecuting = false;
  }

  void stopMonitoring() {
    _isActive = false;
    _timer?.cancel();
    _timer = null;
  }

  void addCallback(ResourceCallback callback) {
    if (!_callbacks.contains(callback)) {
      _callbacks.add(callback);
    }
  }

  void removeCallback(ResourceCallback callback) {
    _callbacks.remove(callback);
  }

  void dispose() {
    stopMonitoring();
    _callbacks.clear();
  }
}