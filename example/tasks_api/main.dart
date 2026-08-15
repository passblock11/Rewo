import 'package:rewo/app/app.dart';
import 'package:rewo/rewo.dart';

/// Legacy entry — delegates to the unified server.
/// Prefer: dart run bin/server.dart
Future<void> main(List<String> args) async {
  await DotEnv.load();
  final port = int.tryParse(args.firstOrNull ?? '') ?? DotEnv.getInt('PORT', fallback: 8080);
  // ignore: avoid_print
  print('Starting Rewo (all modules) on http://localhost:$port');
  await RewoDemo.start(port: port);
}
