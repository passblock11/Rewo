import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../config/dotenv.dart';

/// Environment flag set on child processes spawned by [HotRestartRunner].
const rewoHotChildEnv = 'REWO_HOT_CHILD';

/// Run [start] normally, or with hot reload when `--dev` / `-d` is passed.
///
/// ```dart
/// Future<void> main(List<String> args) async {
///   await DevServer.run(
///     args: args,
///     entrypoint: 'bin/server.dart',
///     start: _startServer,
///   );
/// }
/// ```
class DevServer {
  /// CLI port override from args (e.g. `rewo run --dev 3000` → `3000`).
  static int? cliPort(List<String> args) {
    if (args.isEmpty) return null;
    return int.tryParse(args.first);
  }

  /// Port from CLI arg or `.env` (`PORT`). Call [DotEnv.load] first.
  static int resolvedPort(List<String> args, {int fallback = 8080}) {
    return cliPort(args) ?? DotEnv.getInt('PORT', fallback: fallback);
  }

  static Future<void> run({
    required List<String> args,
    required String entrypoint,
    required Future<void> Function(List<String> args) start,
    List<String> watchPaths = const ['lib', 'bin', '.env'],
  }) async {
    final devMode = args.contains('--dev') || args.contains('-d');
    final serverArgs =
        args.where((a) => a != '--dev' && a != '-d').toList(growable: false);

    if (devMode && Platform.environment[rewoHotChildEnv] != '1') {
      final runner = HotRestartRunner(
        entrypoint: entrypoint,
        watchPaths: watchPaths,
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

    await start(serverArgs);
  }
}

/// Watches source files and restarts [entrypoint] on save (nodemon-style).
class HotRestartRunner {
  HotRestartRunner({
    required this.entrypoint,
    this.watchPaths = const ['lib', 'bin'],
    this.args = const [],
    this.debounce = const Duration(milliseconds: 400),
    this.childEnvironment = const {},
  });

  final String entrypoint;
  final List<String> watchPaths;
  final List<String> args;
  final Duration debounce;
  final Map<String, String> childEnvironment;

  Process? _process;
  StreamSubscription? _watchSub;
  Timer? _debounceTimer;
  bool _restarting = false;
  String? _pendingChange;

  Future<void> run() async {
    // ignore: avoid_print
    print('🔥 Hot reload watching: ${watchPaths.join(', ')}');
    // ignore: avoid_print
    print('   Entry: $entrypoint — save a .dart file to restart');
    await _start();

    final watchers = <Watcher>[];
    for (final watchPath in watchPaths) {
      final path = p.normalize(p.join(Directory.current.path, watchPath));
      if (File(path).existsSync()) {
        watchers.add(FileWatcher(path));
      } else if (Directory(path).existsSync()) {
        watchers.add(DirectoryWatcher(path));
      }
    }

    if (watchers.isEmpty) {
      // ignore: avoid_print
      print('⚠️  No watch paths found — hot reload disabled');
      return;
    }

    _watchSub = StreamGroup.merge(watchers.map((w) => w.events)).listen((event) {
      if (_shouldRestart(event.path, event.type)) {
        _pendingChange = p.basename(event.path);
        _scheduleRestart();
      }
    });
  }

  bool _shouldRestart(String path, ChangeType type) {
    if (path.contains('${p.separator}.dart_tool${p.separator}')) return false;
    if (path.endsWith('.dart') &&
        (type == ChangeType.ADD || type == ChangeType.MODIFY)) {
      return true;
    }
    if (p.basename(path) == '.env' && type == ChangeType.MODIFY) {
      return true;
    }
    return false;
  }

  void _scheduleRestart() {
    if (_restarting) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _restart);
  }

  Future<void> _restart() async {
    if (_restarting) return;
    _restarting = true;
    _debounceTimer?.cancel();
    final changed = _pendingChange;
    _pendingChange = null;
    // ignore: avoid_print
    print('♻️  Hot restarting${changed != null ? ' ($changed changed)' : ''}...');

    final port = await _resolvePort();
    final proc = _process;
    _process = null;
    if (proc != null) {
      proc.kill(ProcessSignal.sigterm);
      final code = await proc.exitCode.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          proc.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      if (code == -1) {
        proc.kill(ProcessSignal.sigkill);
        await proc.exitCode.timeout(const Duration(seconds: 2), onTimeout: () => -1);
      }
      await _waitForPortRelease(port);
    }

    await _start();
    _restarting = false;
  }

  Future<int> _resolvePort() async {
    final fromArgs = args.isNotEmpty ? int.tryParse(args.first) : null;
    if (fromArgs != null) return fromArgs;
    try {
      await DotEnv.load();
      return DotEnv.getInt('PORT', fallback: 8080);
    } on Object {
      return 8080;
    }
  }

  Future<void> _waitForPortRelease(int port) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      try {
        final socket =
            await ServerSocket.bind(InternetAddress.anyIPv4, port);
        await socket.close();
        return;
      } on SocketException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    // ignore: avoid_print
    print('⚠️  Port $port still in use — starting anyway (may fail)');
  }

  Future<void> _start() async {
    _process = await Process.start(
      'dart',
      ['run', entrypoint, ...args],
      environment: {...Platform.environment, ...childEnvironment},
      workingDirectory: Directory.current.path,
    );
    _process!.stdout.transform(const SystemEncoding().decoder).listen(stdout.write);
    _process!.stderr.transform(const SystemEncoding().decoder).listen(stderr.write);
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    await _watchSub?.cancel();
    final proc = _process;
    _process = null;
    if (proc != null) {
      proc.kill(ProcessSignal.sigint);
      await proc.exitCode.timeout(const Duration(seconds: 2), onTimeout: () => -1);
    }
  }
}

/// Merges multiple streams — minimal helper to avoid extra dependency.
class StreamGroup<T> {
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>.broadcast();
    for (final stream in streams) {
      stream.listen(controller.add, onError: controller.addError);
    }
    return controller.stream;
  }
}
