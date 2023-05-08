import 'dart:async';

/// Creates a Pinger
class Pinger {
  Pinger([this._interval = const Duration(seconds: 30)]);
  final Duration _interval;

  Timer? _timer;

  /// Start Timer
  void start(void Function() func) {
    _timer = Timer.periodic(_interval, (timer) => func());
  }

  /// Stop Timer
  void stop() {
    _timer?.cancel();
  }
}
