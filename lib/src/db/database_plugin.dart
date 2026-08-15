import '../application.dart';
import 'database_config.dart';

/// Connects a database driver or ORM to a Rewo app.
abstract class DatabasePlugin {
  bool supports(DatabaseConfig config);

  Future<void> connect(Rewo app, DatabaseConfig config);

  Future<void> disconnect(Rewo app);

  Future<bool> healthCheck(Rewo app);
}
