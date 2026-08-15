#!/usr/bin/env dart
import 'dart:io';

import 'package:rewo/rewo.dart';

/// Dev server with hot restart — watches lib/ and bin/ for changes.
Future<void> main(List<String> args) async {
  final entry = args.isNotEmpty ? args.first : 'bin/server.dart';
  final runner = HotRestartRunner(
    entrypoint: entry,
    watchPaths: const ['lib', 'bin'],
    args: args.skip(1).toList(),
  );

  ProcessSignal.sigint.watch().listen((_) async {
    await runner.stop();
    exit(0);
  });

  await runner.run();
}
