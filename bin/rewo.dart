import 'dart:io';

import 'package:rewo/rewo.dart';

/// Rewo CLI — scaffold and run projects.
///
/// ```bash
/// rewo create my_api          # scaffold new project (like express)
/// rewo run --dev              # hot-reload dev server (current project)
/// rewo run                    # production server (current project)
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
      final devArgs = args.skip(1).toList();
      if (devArgs.isNotEmpty &&
          devArgs.first.endsWith('.dart') &&
          !devArgs.first.startsWith('--')) {
        await _runProject([
          '--dev',
          '--entry',
          devArgs.first,
          ...devArgs.skip(1),
        ]);
      } else {
        await _runProject(['--dev', ...devArgs]);
      }
    case 'run':
      await _runProject(args.skip(1).toList());
    default:
      stderr.writeln('Unknown command: $command\n');
      _printHelp();
      exit(1);
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
  rewo run --dev    # development (hot reload)
  rewo run          # production
''');
  } on Object catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

Future<void> _runProject(List<String> args) async {
  const defaultEntry = 'bin/server.dart';
  final devMode = args.contains('--dev') || args.contains('-d');

  String entry = defaultEntry;
  final serverArgs = <String>[];

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--dev' || arg == '-d') {
      continue;
    }
    if (arg == '--entry' && i + 1 < args.length) {
      entry = args[++i];
      continue;
    }
    serverArgs.add(arg);
  }

  if (!File(entry).existsSync()) {
    stderr.writeln('''
Error: $entry not found in ${Directory.current.path}

Run from your Rewo project root, or scaffold one:

  rewo create my_api
  cd my_api
  rewo run --dev
''');
    exit(1);
  }

  if (devMode) {
    final runner = HotRestartRunner(
      entrypoint: entry,
      watchPaths: const ['lib', 'bin', '.env'],
      args: serverArgs,
      childEnvironment: {rewoHotChildEnv: '1'},
    );

    ProcessSignal.sigint.watch().listen((_) async {
      await runner.stop();
      exit(0);
    });

    await runner.run();
    return;
  }

  final process = await Process.start(
    'dart',
    ['run', entry, ...serverArgs],
    workingDirectory: Directory.current.path,
  );

  process.stdout.transform(const SystemEncoding().decoder).listen(stdout.write);
  process.stderr.transform(const SystemEncoding().decoder).listen(stderr.write);

  ProcessSignal.sigint.watch().listen((_) async {
    process.kill(ProcessSignal.sigint);
    exit(0);
  });

  exit(await process.exitCode);
}

void _printHelp() {
  stdout.writeln('''
Rewo CLI

Usage:
  rewo create <name>       Scaffold a new API project (Express-style)
  rewo run [--dev] [port]  Run bin/server.dart (production, or --dev for hot reload)
  rewo dev [entry] [port]  Shortcut for rewo run --dev

Examples:
  rewo run --dev           Development with hot reload
  rewo run                 Production server
  rewo run 3000            Production on port 3000
  rewo run --dev 3000      Dev server on port 3000

Global install:
  dart pub global activate rewo
  rewo create my_api

From package:
  dart run rewo:rewo create my_api
''');
}
