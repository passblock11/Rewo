import 'postgres_pool.dart';
import '../application.dart';
import 'database_config.dart';
import 'database_kind.dart';
import 'database_plugin.dart';

/// Built-in Postgres connection pool (raw SQL, no ORM required).
class PostgresDatabasePlugin implements DatabasePlugin {
  @override
  bool supports(DatabaseConfig config) =>
      config.isConfigured && config.kind == DatabaseKind.postgres;

  @override
  Future<void> connect(Rewo app, DatabaseConfig config) async {
    final pool = PostgresPool.fromUrl(config.url!);
    await pool.open();
    app.singleton<PostgresPool>(pool);
    // ignore: avoid_print
    print('📦 Postgres connected (${config.sourceVariable})');
  }

  @override
  Future<void> disconnect(Rewo app) async {
    if (app.container.isRegistered<PostgresPool>()) {
      await app.container.resolve<PostgresPool>().close();
    }
  }

  @override
  Future<bool> healthCheck(Rewo app) async {
    if (!app.container.isRegistered<PostgresPool>()) return false;
    try {
      await app.container.resolve<PostgresPool>().query('SELECT 1');
      return true;
    } on Object {
      return false;
    }
  }
}
