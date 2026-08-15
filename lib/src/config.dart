import 'dart:io';

/// Typed application configuration loaded from environment variables.
class AppConfig {
  AppConfig({
    this.host = '0.0.0.0',
    this.port = 8080,
    this.environment = 'development',
    this.jwtSecret = 'dev-secret-change-me',
    this.databaseUrl,
    this.logRequests = true,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      host: Platform.environment['HOST'] ?? '0.0.0.0',
      port: int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080,
      environment: Platform.environment['ENV'] ?? 'development',
      jwtSecret: Platform.environment['JWT_SECRET'] ?? 'dev-secret-change-me',
      databaseUrl: Platform.environment['DATABASE_URL'],
      logRequests: Platform.environment['LOG_REQUESTS'] != 'false',
    );
  }

  final String host;
  final int port;
  final String environment;
  final String jwtSecret;
  final String? databaseUrl;
  final bool logRequests;

  bool get isProduction => environment == 'production';
}
