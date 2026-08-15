import 'dart:io';

/// Health check registry for liveness/readiness probes.
class HealthCheck {
  HealthCheck();

  final Map<String, Future<bool> Function()> _checks = {};

  void register(String name, Future<bool> Function() check) {
    _checks[name] = check;
  }

  Future<Map<String, dynamic>> liveness() async => {'status': 'alive'};

  Future<Map<String, dynamic>> readiness() async {
    final results = <String, String>{};
    var allOk = true;

    for (final entry in _checks.entries) {
      try {
        final ok = await entry.value();
        results[entry.key] = ok ? 'ok' : 'fail';
        if (!ok) allOk = false;
      } catch (e) {
        results[entry.key] = 'error: $e';
        allOk = false;
      }
    }

    return {
      'status': allOk ? 'ready' : 'not_ready',
      'checks': results,
    };
  }
}

/// Prometheus-compatible metrics collector.
class Metrics {
  final Map<String, int> _counters = {};
  final Map<String, List<double>> _histograms = {};

  void increment(String name, {int by = 1}) {
    _counters[name] = (_counters[name] ?? 0) + by;
  }

  void observe(String name, double value) {
    _histograms.putIfAbsent(name, () => []).add(value);
  }

  String export() {
    final buffer = StringBuffer();
    for (final entry in _counters.entries) {
      buffer.writeln('# TYPE ${entry.key} counter');
      buffer.writeln('${entry.key} ${entry.value}');
    }
    for (final entry in _histograms.entries) {
      final values = entry.value;
      if (values.isEmpty) continue;
      final sum = values.reduce((a, b) => a + b);
      buffer.writeln('# TYPE ${entry.key} summary');
      buffer.writeln('${entry.key}_count ${values.length}');
      buffer.writeln('${entry.key}_sum $sum');
    }
    return buffer.toString();
  }
}

/// Graceful shutdown handler.
Future<void> gracefulShutdown(Future<void> Function() onShutdown) async {
  await Future.any([
    ProcessSignal.sigint.watch().first,
    ProcessSignal.sigterm.watch().first,
  ]);
  await onShutdown();
}
