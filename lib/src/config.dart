import 'config/dotenv.dart';
import 'http/server_engine.dart';
import 'performance/performance_config.dart';

export 'config/config_validator.dart' show AppConfigValues, ConfigValidator;
export 'config/dotenv.dart' show DotEnv;
export 'performance/performance_config.dart' show PerformanceConfig;

/// Typed application configuration loaded from environment variables.
class AppConfig {
  AppConfig({
    this.host = '0.0.0.0',
    this.port = 8080,
    this.environment = 'development',
    this.jwtSecret = 'dev-secret-change-me',
    this.databaseUrl,
    this.storagePath = './storage',
    this.logRequests = true,
    this.rateLimit = 100,
    this.engine = ServerEngine.shelf,
    PerformanceConfig? performance,
  }) : performance = performance ??
            (environment == 'production'
                ? PerformanceConfig.turbo()
                : const PerformanceConfig(enabled: false));

  factory AppConfig.fromEnvironment() {
    final env = DotEnv.get('ENV', fallback: 'development');
    final isProd = env == 'production';
    return AppConfig(
      host: DotEnv.get('HOST', fallback: '0.0.0.0'),
      port: DotEnv.getInt('PORT', fallback: 8080),
      environment: env,
      jwtSecret: DotEnv.get('JWT_SECRET', fallback: 'dev-secret-change-me'),
      databaseUrl: DotEnv.get('DATABASE_URL').isEmpty ? null : DotEnv.get('DATABASE_URL'),
      storagePath: DotEnv.get('STORAGE_PATH', fallback: './storage'),
      logRequests: DotEnv.getBool('LOG_REQUESTS', fallback: !isProd),
      rateLimit: DotEnv.getInt('RATE_LIMIT', fallback: 100),
      engine: _parseEngine(DotEnv.get('SERVER_ENGINE', fallback: 'shelf')),
      performance: isProd ? PerformanceConfig.turbo() : null,
    );
  }

  factory AppConfig.turbo({int port = 8080, ServerEngine engine = ServerEngine.native}) =>
      AppConfig(
        port: port,
        environment: 'production',
        logRequests: false,
        engine: engine,
        performance: PerformanceConfig.turbo(),
      );

  final String host;
  final int port;
  final String environment;
  final String jwtSecret;
  final String? databaseUrl;
  final String storagePath;
  final bool logRequests;
  final int rateLimit;
  final ServerEngine engine;
  final PerformanceConfig performance;

  bool get isProduction => environment == 'production';

  static ServerEngine _parseEngine(String name) => switch (name.toLowerCase()) {
        'native' => ServerEngine.native,
        'http2' => ServerEngine.http2,
        _ => ServerEngine.shelf,
      };
}
