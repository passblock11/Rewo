import 'dart:io';

import 'package:dart_backend_framework/dart_backend_framework.dart';

/// CLI: dart run bin/dart_serve.dart [port]
void main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8080 : 8080;

  await DartServe.run((app) {
    app.singleton(EventBus());
    app.singleton(TransactionManager());

    app.get('/', (_) async => {
          'framework': 'DartServe',
          'version': '0.1.0',
          'docs': 'See README.md',
        });

    app.get('/health', (_) async => {'status': 'ok'});

    app.schedule(60, () async {
      // ignore: avoid_print
      print('⏱️ Heartbeat');
    });
  }, config: AppConfig(port: port));

  // ignore: avoid_print
  print('Press Ctrl+C to stop');
  await ProcessSignal.sigint.watch().first;
}
