import 'dart:async';
import 'dart:io';

import 'package:rewo/rewo.dart';

/// Simple throughput benchmark — run with: dart run benchmark/bench.dart
Future<void> main(List<String> args) async {
  final port = 9090;
  final concurrency = int.tryParse(args.firstOrNull ?? '') ?? 100;
  final total = int.tryParse(args.elementAtOrNull(1) ?? '') ?? 10000;

  final app = Rewo(
    config: AppConfig.turbo(port: port),
    engine: ServerEngine.native,
  );
  app.get('/ping', (_) async => {'pong': true});

  await app.listen();

  final stopwatch = Stopwatch()..start();
  var completed = 0;
  var errors = 0;

  Future<void> worker() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      while (true) {
        final current = completed;
        if (current >= total) break;
        completed++;
        try {
          final request = await client.get('localhost', port, '/ping');
          final response = await request.close();
          await response.drain();
        } catch (_) {
          errors++;
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  await Future.wait(List.generate(concurrency, (_) => worker()));
  stopwatch.stop();

  final rps = (total / stopwatch.elapsedMilliseconds) * 1000;
  // ignore: avoid_print
  print('''
Benchmark complete
  Requests:  $total
  Concurrency: $concurrency
  Errors:    $errors
  Time:      ${stopwatch.elapsedMilliseconds}ms
  RPS:       ${rps.toStringAsFixed(0)} req/s
''');

  await app.close();
  exit(0);
}
