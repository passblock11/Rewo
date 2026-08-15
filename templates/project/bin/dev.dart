#!/usr/bin/env dart

import 'server.dart' as server;

/// Shortcut for hot-reload development.
/// Same as: dart run bin/server.dart --dev
Future<void> main(List<String> args) async {
  await server.main(['--dev', ...args]);
}
