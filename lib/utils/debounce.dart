import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debounce utility for optimizing async operations
class Debounce {
  final Duration delay;
  Timer? _timer;

  Debounce({this.delay = const Duration(milliseconds: 500)});

  /// Debounced function call
  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancel pending debounced call
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose resources
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttle utility for limiting function calls
class Throttle {
  final Duration delay;
  DateTime? _lastCall;

  Throttle({this.delay = const Duration(milliseconds: 300)});

  /// Throttled function call
  void call(VoidCallback callback) {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= delay) {
      _lastCall = now;
      callback();
    }
  }
}

/// Async debounce for async operations
class AsyncDebounce {
  final Duration delay;
  Timer? _timer;
  Completer<void>? _completer;

  AsyncDebounce({this.delay = const Duration(milliseconds: 500)});

  /// Debounced async function call
  Future<void> call(Future<void> Function() callback) async {
    _timer?.cancel();
    _completer?.complete();
    
    _completer = Completer<void>();
    _timer = Timer(delay, () async {
      try {
        await callback();
        _completer?.complete();
      } catch (e) {
        _completer?.completeError(e);
      }
    });
    
    return _completer!.future;
  }

  /// Cancel pending debounced call
  void cancel() {
    _timer?.cancel();
    _completer?.complete();
  }

  /// Dispose resources
  void dispose() {
    _timer?.cancel();
    _completer?.complete();
  }
}