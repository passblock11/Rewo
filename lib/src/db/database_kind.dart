/// Supported database families. Rewo ships built-in plugins for [postgres].
/// Other kinds use [DatabaseConfigurer] — bring your own driver or ORM.
enum DatabaseKind {
  postgres,
  mysql,
  mariadb,
  sqlite,
  mongodb,
  sqlserver,
  unknown;

  static DatabaseKind fromUrl(String url) {
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase() ?? '';
    return switch (scheme) {
      'postgresql' || 'postgres' => DatabaseKind.postgres,
      'mysql' => DatabaseKind.mysql,
      'mariadb' => DatabaseKind.mariadb,
      'sqlite' || 'sqlite3' => DatabaseKind.sqlite,
      'mongodb' || 'mongo' => DatabaseKind.mongodb,
      'sqlserver' || 'mssql' => DatabaseKind.sqlserver,
      _ => DatabaseKind.unknown,
    };
  }
}
