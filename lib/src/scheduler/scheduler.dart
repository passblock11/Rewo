import 'dart:async';

/// Runs scheduled tasks at fixed intervals.
class Scheduler {
  Scheduler();

  final List<Timer> _timers = [];

  void every(Duration interval, FutureOr<void> Function() task) {
    _timers.add(Timer.periodic(interval, (_) async {
      await task();
    }));
  }

  void cronSeconds(int seconds, FutureOr<void> Function() task) {
    every(Duration(seconds: seconds), task);
  }

  void stopAll() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}
