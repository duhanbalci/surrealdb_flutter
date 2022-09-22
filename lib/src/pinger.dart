import 'dart:async';

class Pinger {
  final Duration _interval;

  Pinger([this._interval = const Duration(seconds: 30)]);

  Timer? _timer;

  void start(Function func) {
    _timer = Timer.periodic(_interval, (timer) => func());
  }

  void stop() {
    _timer?.cancel();
  }
}
