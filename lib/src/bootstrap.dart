import 'dart:io';

import 'config.dart';
import 'http/server_engine.dart';
import 'module/rewo_module.dart';
import 'application.dart';
import 'auth/jwt.dart';
import 'cache/cache.dart';
import 'events/event_bus.dart';
import 'queue/job_queue.dart';
import 'storage/storage.dart';
import 'transaction/transaction.dart';
import 'dev/hot_restart.dart' show rewoHotChildEnv;

/// Bootstrap helper for application projects (like Express app setup).
class RewoBootstrap {
  /// Configure shared services, register [modules], and start listening.
  static Future<Rewo> start({
    required List<RewoModule> modules,
    String serviceName = 'Rewo API',
    String serviceVersion = '1.0.0',
    int? port,
    ServerEngine? engine,
    String envFile = '.env',
    bool enableHeartbeat = true,
  }) async {
    await DotEnv.load(envFile);
    final values = AppConfigValues.fromEnv();
    ConfigValidator.validate(values);

    final resolvedPort = port ?? values.port;
    final resolvedEngine = engine ?? _parseEngine(values.serverEngine);

    final app = Rewo(
      config: AppConfig(
        host: values.host,
        port: resolvedPort,
        environment: values.environment,
        jwtSecret: values.jwtSecret,
        storagePath: values.storagePath,
        logRequests: values.logRequests,
        rateLimit: values.rateLimit,
        engine: resolvedEngine,
      ),
      engine: resolvedEngine,
    );

    app.useDefaults();
    app.useOpsEndpoints();

    app.singleton<Storage>(LocalStorage(values.storagePath));
    app.singleton(JwtService(secret: values.jwtSecret));
    app.singleton(SessionStore());
    app.singleton(Cache());
    app.singleton(JobQueue());
    app.singleton(EventBus());
    app.singleton(TransactionManager());

    app.get(
        '/',
        (_) async => {
              'service': serviceName,
              'version': serviceVersion,
              'modules': modules.map((m) => m.name).toList(),
              'health': '/health',
              'docs': '/openapi.json',
            });

    for (final module in modules) {
      module.register(app);
    }

    app.health.register('storage', () async => true);

    await app.listen();
    return app;
  }

  /// Same as [start] but also wires graceful shutdown signals.
  static Future<Rewo> run({
    required List<RewoModule> modules,
    String serviceName = 'Rewo API',
    String serviceVersion = '1.0.0',
    int? port,
    ServerEngine? engine,
    String envFile = '.env',
  }) async {
    final app = await start(
      modules: modules,
      serviceName: serviceName,
      serviceVersion: serviceVersion,
      port: port,
      engine: engine,
      envFile: envFile,
    );

    var shuttingDown = false;
    Future<void> shutdown() async {
      if (shuttingDown) return;
      shuttingDown = true;
      final isHotReload = Platform.environment[rewoHotChildEnv] == '1';
      if (!isHotReload) {
        // ignore: avoid_print
        print('Shutting down...');
      }
      await app.close();
      exit(0);
    }

    ProcessSignal.sigint.watch().listen((_) => shutdown());
    ProcessSignal.sigterm.watch().listen((_) => shutdown());

    return app;
  }

  static ServerEngine _parseEngine(String name) => switch (name.toLowerCase()) {
        'native' => ServerEngine.native,
        'http2' => ServerEngine.http2,
        _ => ServerEngine.shelf,
      };
}
