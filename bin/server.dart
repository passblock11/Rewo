#!/usr/bin/env dart

import 'package:rewo/app/app.dart';
import 'package:rewo/rewo.dart';

/// Single entry point — compiles all APIs into one binary.
///
/// Run:   dart run bin/server.dart
/// Build: dart compile exe bin/server.dart -o server
Future<void> main(List<String> args) async {
  final port = int.tryParse(args.firstOrNull ?? '') ??
      DotEnv.getInt('PORT', fallback: 8080);

  // ignore: avoid_print
  print('Starting Rewo (all modules) on http://localhost:$port');
  // ignore: avoid_print
  print('Modules: ${moduleRegistry().map((m) => m.name).join(', ')}');

  await RewoDemo.start(port: port);
}
