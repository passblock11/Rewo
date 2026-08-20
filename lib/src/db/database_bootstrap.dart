import '../application.dart';
import '../config/config_validator.dart';
import 'database_config.dart';
import 'database_plugin.dart';
import 'postgres_database_plugin.dart';

/// Wires built-in database plugins and custom [DatabaseConfigurer] hooks.
class DatabaseBootstrap {
  DatabaseBootstrap({
    List<DatabasePlugin>? plugins,
  }) : _plugins = plugins ?? [PostgresDatabasePlugin()];

  final List<DatabasePlugin> _plugins;
  DatabasePlugin? _active;

  /// Connect using the first matching built-in plugin, then run [configure].
  ///
  /// If no built-in plugin matches, [configure] alone is responsible for
  /// registering a driver or ORM (MySQL, MongoDB, Drift, Stormberry, etc.).
  Future<void> connect(
    Rewo app,
    AppConfigValues values, {
    DatabaseConfigurer? configure,
  }) async {
    final config = DatabaseConfig.fromValues(values);

    for (final plugin in _plugins) {
      if (plugin.supports(config)) {
        await plugin.connect(app, config);
        _active = plugin;
        app.health.register('database', () => plugin.healthCheck(app));
        break;
      }
    }

    if (_active == null && config.isConfigured) {
      // ignore: avoid_print
      print(
        'ℹ️  ${config.kind.name} detected (${config.sourceVariable}) — '
        'no built-in plugin. Use configureDatabase to register your driver/ORM.',
      );
    }

    if (configure != null) {
      await configure(app, values);
    }
  }

  Future<void> disconnect(Rewo app) async {
    await _active?.disconnect(app);
    _active = null;
  }
}
