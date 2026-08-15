import '../application.dart';
import '../config/config_validator.dart';
import '../config/dotenv.dart';
import 'database_kind.dart';

/// Parsed database connection settings from environment variables.
///
/// Reads `DATABASE_URL` (runtime) and optional `DIRECT_URL` (migrations/DDL).
/// Also accepts `MYSQL_URL`, `MONGODB_URI`, `SQLITE_PATH`, etc.
class DatabaseConfig {
  DatabaseConfig({
    required this.url,
    this.directUrl,
    required this.kind,
    this.sourceVariable = 'DATABASE_URL',
  });

  factory DatabaseConfig.fromEnv() {
    final candidates = <String, String>{
      'DATABASE_URL': DotEnv.get('DATABASE_URL'),
      'MYSQL_URL': DotEnv.get('MYSQL_URL'),
      'MONGODB_URI': DotEnv.get('MONGODB_URI'),
      'MONGO_URL': DotEnv.get('MONGO_URL'),
      'SQLITE_PATH': DotEnv.get('SQLITE_PATH'),
      'SQLSERVER_URL': DotEnv.get('SQLSERVER_URL'),
    };

    String? url;
    String? source;
    for (final entry in candidates.entries) {
      if (entry.value.isNotEmpty) {
        url = entry.value;
        source = entry.key;
        break;
      }
    }

    if (url == null) {
      return DatabaseConfig(url: null, kind: DatabaseKind.unknown);
    }

    final normalized = source == 'SQLITE_PATH' && !url.contains('://')
        ? 'sqlite://$url'
        : url;

    return DatabaseConfig(
      url: normalized,
      directUrl: DotEnv.get('DIRECT_URL').isEmpty ? null : DotEnv.get('DIRECT_URL'),
      kind: DatabaseKind.fromUrl(normalized),
      sourceVariable: source ?? 'DATABASE_URL',
    );
  }

  factory DatabaseConfig.fromValues(AppConfigValues values) {
    if (values.databaseUrl == null || values.databaseUrl!.isEmpty) {
      return DatabaseConfig.fromEnv();
    }
    return DatabaseConfig(
      url: values.databaseUrl,
      directUrl: values.directUrl,
      kind: DatabaseKind.fromUrl(values.databaseUrl!),
    );
  }

  final String? url;
  final String? directUrl;
  final DatabaseKind kind;
  final String sourceVariable;

  bool get isConfigured => url != null && url!.isNotEmpty;

  /// Best URL for migrations (direct/session connection when available).
  String? get migrationUrl {
    if (directUrl != null && directUrl!.isNotEmpty) return directUrl;
    if (url == null) return null;
    final uri = Uri.parse(url!);
    final params = Map<String, String>.from(uri.queryParameters)..remove('pgbouncer');
    return uri.replace(queryParameters: params.isEmpty ? null : params).toString();
  }
}

/// Hook to register **any** database driver or ORM on the DI container.
typedef DatabaseConfigurer = Future<void> Function(
  Rewo app,
  AppConfigValues config,
);
