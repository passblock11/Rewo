import 'dotenv.dart';

/// Validates application configuration at startup.
class ConfigValidator {
  static void validate(AppConfigValues config) {
    final errors = <String>[];

    if (config.port < 1 || config.port > 65535) {
      errors.add('PORT must be 1-65535');
    }
    if (config.isProduction && config.jwtSecret == 'dev-secret-change-me') {
      errors.add('JWT_SECRET must be set in production');
    }
    if (config.isProduction && config.jwtSecret.length < 16) {
      errors.add('JWT_SECRET must be at least 16 characters in production');
    }

    if (errors.isNotEmpty) {
      throw StateError('Config validation failed:\n- ${errors.join('\n- ')}');
    }
  }
}

/// Immutable config values resolved from env + dotenv.
class AppConfigValues {
  AppConfigValues({
    required this.host,
    required this.port,
    required this.environment,
    required this.jwtSecret,
    this.databaseUrl,
    this.storagePath = './storage',
    this.logRequests = true,
    this.rateLimit = 100,
    this.serverEngine = 'shelf',
  });

  factory AppConfigValues.fromEnv() {
    return AppConfigValues(
      host: DotEnv.get('HOST', fallback: '0.0.0.0'),
      port: DotEnv.getInt('PORT', fallback: 8080),
      environment: DotEnv.get('ENV', fallback: 'development'),
      jwtSecret: DotEnv.get('JWT_SECRET', fallback: 'dev-secret-change-me'),
      databaseUrl: DotEnv.get('DATABASE_URL').isEmpty ? null : DotEnv.get('DATABASE_URL'),
      storagePath: DotEnv.get('STORAGE_PATH', fallback: './storage'),
      logRequests: DotEnv.getBool('LOG_REQUESTS', fallback: true),
      rateLimit: DotEnv.getInt('RATE_LIMIT', fallback: 100),
      serverEngine: DotEnv.get('SERVER_ENGINE', fallback: 'shelf'),
    );
  }

  final String host;
  final int port;
  final String environment;
  final String jwtSecret;
  final String? databaseUrl;
  final String storagePath;
  final bool logRequests;
  final int rateLimit;
  final String serverEngine;

  bool get isProduction => environment == 'production';
}
