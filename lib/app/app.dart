/// Built-in demo modules shipped with the Rewo framework repository.
library app;

import 'package:rewo/rewo.dart';

import 'modules/auth_module.dart';
import 'modules/notes_module.dart';
import 'modules/tasks_module.dart';
import 'modules/users_module.dart';

/// Returns the default demo [RewoModule] list used by [RewoDemo].
List<RewoModule> moduleRegistry() => [
      AuthModule(),
      UsersModule(),
      TasksModule(),
      NotesModule(),
    ];

/// Starts the built-in demo API bundled with the Rewo framework repo.
class RewoDemo {
  /// Creates a demo app instance without blocking on [Rewo.listen].
  RewoDemo._();

  /// Configures modules and begins serving HTTP requests.
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

  /// Configures modules and returns the app before listening (for tests/custom startup).
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
