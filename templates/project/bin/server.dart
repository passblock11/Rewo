#!/usr/bin/env dart

import 'dart:async';

import 'package:example_app/app.dart';
import 'package:rewo/rewo.dart';

/// Entry point — compile with: dart compile exe bin/server.dart -o server
///
/// Dev (hot reload): dart run bin/server.dart --dev
/// Production:       dart run bin/server.dart
Future<void> main(List<String> args) async {
  await DevServer.run(
    args: args,
    entrypoint: 'bin/server.dart',
    start: _startServer,
  );
}

Future<void> _startServer(List<String> args) async {
  final port = int.tryParse(args.firstOrNull ?? '') ??
      DotEnv.getInt('PORT', fallback: 8080);

  // ignore: avoid_print
  print('Starting {{title}} on http://localhost:$port');
  await App.run(port: port);

  // Keep the process alive (server + signal handlers run in background).
  await Completer<void>().future;
}
