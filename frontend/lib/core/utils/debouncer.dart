import 'dart:async';

/// A simple debouncer that prevents rapid-fire calls.
/// Usage: `_debouncer.run(() => doSomething());`
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

/// Guards an async action so it cannot be triggered again
/// while a previous invocation is still in-flight.
///
/// Example:
/// ```dart
/// final _likeGuard = ActionGuard();
///
/// void _onLikeTap() {
///   _likeGuard.run(() async {
///     await ApiService.post('like');
///   });
/// }
/// ```
class ActionGuard {
  bool _busy = false;

  bool get isBusy => _busy;

  Future<void> run(Future<void> Function() action) async {
    if (_busy) return; // drop duplicate
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }
}
