import 'dart:io';

import 'package:rewo/rewo.dart';

/// Rewo CLI — scaffold and run projects.
///
/// ```bash
/// rewo create my_api          # scaffold new project (like express)
/// rewo dev                    # hot-restart dev server
/// rewo run [port]             # minimal demo server
/// ```
Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first == 'help' || args.first == '--help') {
    _printHelp();
    return;
  }

  final command = args.first;

  switch (command) {
    case 'create':
      await _create(args.skip(1).toList());
    case 'dev':
      await _dev(args.skip(1).toList());
    case 'run':
      await _run(args.skip(1).toList());
    default:
      // Backward compat: rewo 8080
      if (int.tryParse(command) != null) {
        await _run(args);
      } else {
        stderr.writeln('Unknown command: $command\n');
        _printHelp();
        exit(1);
      }
  }
}

Future<void> _create(List<String> args) async {
  if (args.isEmpty || args.first == '--help') {
    stdout.writeln('''
Usage: rewo create <project_name> [options]

Options:
  --output <dir>     Parent directory (default: current directory)
  --path <dir>       Use local framework path as dependency
  --git <url>        Use git URL for framework dependency
  --description <t>  Project description

Example:
  rewo create my_api
  rewo create my_api --path ../rewo  # local dev
''');
    return;
  }

  String? output;
  String? frameworkPath;
  String? gitUrl;
  String? description;
  final positional = <String>[];

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--output':
        output = args[++i];
      case '--path':
        frameworkPath = args[++i];
      case '--git':
        gitUrl = args[++i];
      case '--description':
        description = args[++i];
      default:
        if (!args[i].startsWith('--')) positional.add(args[i]);
    }
  }

  if (positional.isEmpty) {
    stderr.writeln('Error: project name required');
    exit(1);
  }

  final cmd = CreateProjectCommand(
    projectName: positional.first,
    outputDir: output,
    frameworkPath: frameworkPath,
    frameworkGitUrl: gitUrl,
    description: description,
  );

  try {
    final path = await cmd.run();
    stdout.writeln('''
✅ Created Rewo project: $path

Next steps:
  cd ${path.split(Platform.pathSeparator).last}
  dart pub get
  cp .env.example .env
  dart run bin/server.dart
''');
  } on Object catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<void> _dev(List<String> args) async {
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

Future<void> _run(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8080 : 8080;

  await Rewo.run((app) {
    app.get('/', (_) async => {
          'framework': 'Rewo',
          'hint': 'Run `rewo create my_api` to scaffold your own project',
        });
    app.get('/health', (_) async => {'status': 'ok'});
  }, config: AppConfig(port: port));

  // ignore: avoid_print
  print('Press Ctrl+C to stop');
  await ProcessSignal.sigint.watch().first;
}

void _printHelp() {
  stdout.writeln('''
Rewo CLI

Usage:
  rewo create <name>   Scaffold a new API project (Express-style)
  rewo dev [entry]     Hot-restart dev server (default: bin/server.dart)
  rewo run [port]      Run minimal demo server

Global install:
  dart pub global activate rewo
  rewo create my_api

From package:
  dart run rewo:rewo create my_api
''');
}
