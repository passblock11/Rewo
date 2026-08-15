import 'package:rewo/rewo.dart';

import 'modules/auth_module.dart';
import 'modules/notes_module.dart';
import 'modules/tasks_module.dart';
import 'modules/users_module.dart';

/// Central registry — add new modules here only.
List<RewoModule> moduleRegistry() => [
      AuthModule(),
      UsersModule(),
      TasksModule(),
      NotesModule(),
    ];

/// Built-in demo application (framework repo).
class RewoDemo {
  static Future<Rewo> start({
    int? port,
    ServerEngine? engine,
    String envFile = '.env',
  }) =>
      RewoBootstrap.run(
        modules: moduleRegistry(),
        serviceName: 'Rewo API',
        port: port,
        engine: engine,
        envFile: envFile,
      );

  static Future<Rewo> bootstrap({
    int? port,
    ServerEngine? engine,
    String envFile = '.env',
  }) =>
      RewoBootstrap.start(
        modules: moduleRegistry(),
        serviceName: 'Rewo API',
        port: port,
        engine: engine,
        envFile: envFile,
      );
}
