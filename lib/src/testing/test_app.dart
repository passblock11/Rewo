import '../application.dart';
import '../config.dart';
import '../context.dart';
import '../container.dart';
import '../events/event_bus.dart';
import '../http/route_table.dart';
import '../middleware/cors_middleware.dart';
import '../middleware/error_middleware.dart';
import '../transaction/transaction.dart';

/// Test utility — invoke route handlers without a real HTTP server.
class TestApp {
  TestApp(this._app);

  final Rewo _app;

  static Future<TestApp> create(
    void Function(Rewo app) configure, {
    AppConfig? config,
  }) async {
    final app = Rewo(config: config);
    app.use(ErrorMiddleware());
    app.use(CorsMiddleware());
    configure(app);
    return TestApp(app);
  }

  Future<dynamic> call(
    String method,
    String path, {
    Map<String, String>? headers,
    Map<String, String>? query,
    List<int>? body,
  }) async {
    _app.compileRoutesForTest();
    final route = _app.routeTable.match(method, path);
    if (route == null) throw StateError('No route: $method $path');

    final ctx = RequestContext(
      method: method,
      path: path,
      headers: headers ?? {},
      queryParameters: query ?? {},
      pathParameters: route.extractParams(path),
      bodyBytes: body,
      container: _app.container,
    );

    return route.handler(ctx);
  }

  Rewo get app => _app;
  ServiceContainer get container => _app.container;
  EventBus get events => _app.events;
  TransactionManager get transactions => _app.transactions;
  RouteTable get routeTable => _app.routeTable;
}

/// Bootstrap: load .env, validate config, return values.
Future<AppConfigValues> bootstrapEnv({String envFile = '.env'}) async {
  await DotEnv.load(envFile);
  final values = AppConfigValues.fromEnv();
  ConfigValidator.validate(values);
  return values;
}
