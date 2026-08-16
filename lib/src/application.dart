import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'container.dart';
import 'context.dart';
import 'events/event_bus.dart';
import 'http/http2_server.dart';
import 'http/native_server.dart';
import 'http/response.dart';
import 'http/route_table.dart';
import 'http/server_engine.dart';
import 'http/websocket.dart';
import 'http/websocket_route_table.dart';
import 'middleware/cors_middleware.dart';
import 'middleware/error_middleware.dart';
import 'middleware/logging_middleware.dart';
import 'middleware/middleware.dart';
import 'middleware/security_middleware.dart';
import 'middleware/static_files_middleware.dart';
import 'openapi/openapi.dart';
import 'ops/health.dart';
import 'performance/http_tuning.dart';
import 'performance/isolate_pool.dart';
import 'scheduler/scheduler.dart';
import 'transaction/transaction.dart';

export 'http/route_table.dart' show RouteHandler;

typedef ConfigureCallback = void Function(Rewo app);

abstract class RestController {
  String get basePath => '';
  void registerRoutes(RouteRegistrar registrar);
}

class RouteRegistrar {
  RouteRegistrar(this._app, this._basePath);

  final Rewo _app;
  final String _basePath;

  void get(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _app._addRoute('GET', _join(_basePath, path), handler,
        middleware: middleware, statusCode: statusCode);
  }

  void post(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _app._addRoute('POST', _join(_basePath, path), handler,
        middleware: middleware, statusCode: statusCode);
  }

  void put(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _app._addRoute('PUT', _join(_basePath, path), handler,
        middleware: middleware, statusCode: statusCode);
  }

  void patch(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _app._addRoute('PATCH', _join(_basePath, path), handler,
        middleware: middleware, statusCode: statusCode);
  }

  void delete(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _app._addRoute('DELETE', _join(_basePath, path), handler,
        middleware: middleware, statusCode: statusCode);
  }

  String _join(String base, String path) {
    final b = base.isEmpty ? '' : base.replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return '$b$p';
  }
}

class Rewo {
  Rewo({
    AppConfig? config,
    ServerEngine? engine,
    SecurityContext? securityContext,
  })  : config = config ?? AppConfig.fromEnvironment(),
        engine = engine ?? config?.engine ?? ServerEngine.shelf,
        container = ServiceContainer(),
        events = EventBus(),
        transactions = TransactionManager(),
        scheduler = Scheduler(),
        _securityContext = securityContext;

  final AppConfig config;
  final ServerEngine engine;
  final ServiceContainer container;
  final EventBus events;
  final TransactionManager transactions;
  final Scheduler scheduler;
  final SecurityContext? _securityContext;

  final Router _router = Router();
  final RouteTable _routeTable = RouteTable();
  final WebSocketRouteTable _webSocketRouteTable = WebSocketRouteTable();
  final WebSocketConnectionTracker _webSocketTracker = WebSocketConnectionTracker();
  final List<MiddlewareHandler> _globalMiddleware = [];
  final List<_RouteInput> _routes = [];
  final List<_WebSocketRouteInput> _webSocketRoutes = [];
  IsolatePool? _isolatePool;

  HttpServer? _shelfServer;
  NativeHttpServer? _nativeServer;
  Http2ServerEngine? _http2Server;

  final HealthCheck health = HealthCheck();
  final Metrics metrics = Metrics();
  final OpenApiGenerator openApi = OpenApiGenerator();

  RouteTable get routeTable => _routeTable;
  WebSocketRouteTable get webSocketRouteTable => _webSocketRouteTable;

  void compileRoutesForTest() => _compileRoutes();

  void singleton<T>(T instance) => container.registerSingleton<T>(instance);

  void factory<T>(T Function(ServiceContainer c) creator) {
    container.registerFactory<T>((c) => creator(c));
  }

  void lazy<T>(T Function(ServiceContainer c) creator) {
    container.registerLazySingleton<T>((c) => creator(c));
  }

  void use(Middleware middleware) => _globalMiddleware.add(middleware.handler);

  void useDefaults() {
    use(ErrorMiddleware(
      development: developmentErrorDetails(isProduction: config.isProduction),
    ));
    use(RequestIdMiddleware());
    use(SecurityHeadersMiddleware());
    use(RateLimitMiddleware(maxRequests: config.rateLimit));
    use(TimeoutMiddleware());
    if (!config.performance.enabled) use(CorsMiddleware());
    if (config.logRequests) {
      use(LoggingMiddleware());
    } else {
      use(StructuredLoggingMiddleware());
    }
  }

  void useOpsEndpoints() {
    get('/health', (_) async => health.liveness());
    get('/ready', (_) async => health.readiness());
    get('/metrics', (_) async {
      metrics.increment('http_requests_total');
      return metrics.export();
    });
    get('/openapi.json', (_) async => openApi.generate(_routeTable));
  }

  void useStaticFiles(String directory, {String prefix = '/public'}) {
    use(StaticFilesMiddleware(directory, prefix: prefix));
  }

  void mount(RestController controller) {
    final registrar = RouteRegistrar(this, controller.basePath);
    controller.registerRoutes(registrar);
  }

  void get(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _addRoute('GET', path, handler, middleware: middleware, statusCode: statusCode);
  }

  void post(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _addRoute('POST', path, handler, middleware: middleware, statusCode: statusCode);
  }

  void put(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _addRoute('PUT', path, handler, middleware: middleware, statusCode: statusCode);
  }

  void patch(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _addRoute('PATCH', path, handler, middleware: middleware, statusCode: statusCode);
  }

  void delete(String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _addRoute('DELETE', path, handler, middleware: middleware, statusCode: statusCode);
  }

  /// Registers a WebSocket endpoint (native + shelf engines).
  void webSocket(
    String path,
    WebSocketConnectHandler onConnect, {
    List<MiddlewareHandler>? middleware,
  }) {
    _webSocketRoutes.add(_WebSocketRouteInput(
      path: normalizePath(path),
      handler: (socket, ctx) {
        _webSocketTracker.track(socket);
        onConnect(socket, ctx);
      },
      middleware: middleware ?? [],
    ));
  }

  void schedule(int intervalSeconds, FutureOr<void> Function() task) {
    scheduler.cronSeconds(intervalSeconds, task);
  }

  IsolatePool get isolates {
    return _isolatePool ??= sharedIsolatePool(
      workers: config.performance.isolateWorkers > 0
          ? config.performance.isolateWorkers
          : 4,
    );
  }

  Future<void> listen() async {
    _compileRoutes();

    if (config.performance.isolateWorkers > 0) {
      _isolatePool = sharedIsolatePool(workers: config.performance.isolateWorkers);
    }

    switch (engine) {
      case ServerEngine.shelf:
        await _listenShelf();
      case ServerEngine.native:
        await _listenNative();
      case ServerEngine.http2:
        await _listenHttp2();
    }
  }

  Future<void> _listenShelf() async {
    for (final route in _routeTable.all) {
      Future<shelf.Response> shelfHandler(shelf.Request request) async {
        return _handleShelf(request, route);
      }
      switch (route.method) {
        case 'GET':
          _router.get(toShelfPath(route.path), shelfHandler);
        case 'POST':
          _router.post(toShelfPath(route.path), shelfHandler);
        case 'PUT':
          _router.put(toShelfPath(route.path), shelfHandler);
        case 'DELETE':
          _router.delete(toShelfPath(route.path), shelfHandler);
        case 'PATCH':
          _router.patch(toShelfPath(route.path), shelfHandler);
      }
    }

    _shelfServer = await _bindServer(() async {
      final server = await HttpServer.bind(
        config.host,
        config.port,
        shared: true,
      );
      server.listen((request) async {
        try {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            final wsRoute = _webSocketRouteTable.match(request.uri.path);
            if (wsRoute != null) {
              await handleWebSocketUpgrade(
                request: request,
                route: wsRoute,
                container: container,
              );
              return;
            }
          }
          await shelf_io.handleRequest(request, _router.call);
        } catch (e, st) {
          // ignore: avoid_print
          print('Shelf server error: $e\n$st');
          try {
            request.response.statusCode = 500;
            request.response.write(jsonEncode({'error': 'Internal server error'}));
            await request.response.close();
          } on Object {
            // Response may already be committed.
          }
        }
      });
      return server;
    });
    tuneHttpServer(_shelfServer!, config.performance);
    _printStarted('shelf');
  }

  Future<void> _listenNative() async {
    _nativeServer = NativeHttpServer(
      config: config,
      routeTable: _routeTable,
      webSocketRouteTable: _webSocketRouteTable,
      container: container,
    );
    await _nativeServer!.listen();
  }

  Future<void> _listenHttp2() async {
    final ctx = _securityContext ?? SecurityContext();
    _http2Server = Http2ServerEngine(
      config: config,
      routeTable: _routeTable,
      container: container,
      securityContext: ctx,
    );
    await _http2Server!.listen();
    // HTTP/2 engine accepts sockets via handleSocket — use native for dev HTTP/1.1
    await _listenNative();
  }

  Future<shelf.Response> _handleShelf(shelf.Request request, CompiledRoute route) async {
    final lazy = config.performance.lazyBodyParsing;
    final ctx = RequestContext(
      method: request.method,
      path: request.requestedUri.path,
      headers: buildHeaderMap(request.headersAll),
      queryParameters: request.url.queryParameters,
      pathParameters: route.extractParams(request.requestedUri.path),
      bodyBytes: lazy ? null : await BodyReader.read(request.read()),
      bodyLoader: lazy ? () => BodyReader.read(request.read()) : null,
      container: container,
    );
    return route.pipeline.run(ctx, (c) async {
      final result = await route.handler(c);
      return AppResponse.fromHandlerResult(result, statusCode: route.statusCode);
    });
  }

  void _printStarted(String mode) {
    // ignore: avoid_print
    print('🚀 Rewo [$mode] on http://${config.host}:${config.port}'
        '${config.performance.enabled ? ' [turbo]' : ''}');
  }

  void _compileRoutes() {
    _routeTable.clear();
    _webSocketRouteTable.clear();
    for (final route in _routes) {
      final compiled = CompiledRoute(
        method: route.method,
        path: route.path,
        handler: route.handler,
        middleware: route.middleware,
        statusCode: route.statusCode,
        pipeline: MiddlewarePipeline([
          ..._globalMiddleware,
          ...route.middleware,
        ]),
      );
      _routeTable.add(compiled);
    }
    for (final route in _webSocketRoutes) {
      final compiled = CompiledWebSocketRoute(
        path: route.path,
        handler: route.handler,
        middleware: route.middleware,
        pipeline: MiddlewarePipeline([
          ..._globalMiddleware,
          ...route.middleware,
        ]),
      );
      _webSocketRouteTable.add(compiled);
    }
  }

  Future<HttpServer> _bindServer(Future<HttpServer> Function() bind) async {
    try {
      return await bind();
    } on SocketException catch (e) {
      if (_isAddressInUse(e)) {
        stderr.writeln('''
❌ Port ${config.port} is already in use.

  Stop the other server (Ctrl+C in its terminal), or free the port:
    lsof -ti:${config.port} | xargs kill

  Or set a different port in .env (PORT=3000) or: rewo run 3000
''');
      }
      rethrow;
    }
  }

  bool _isAddressInUse(SocketException e) {
    final code = e.osError?.errorCode;
    return code == 48 || code == 98 || e.message.contains('Address already in use');
  }

  Future<void> close() async {
    scheduler.stopAll();
    await _webSocketTracker.closeAll();
    await _isolatePool?.close();
    await _shelfServer?.close(force: true);
    await _nativeServer?.close();
    await _http2Server?.close();
  }

  static Future<Rewo> run(
    ConfigureCallback configure, {
    AppConfig? config,
    ServerEngine? engine,
    String envFile = '.env',
  }) async {
    await DotEnv.load(envFile);
    final app = Rewo(config: config, engine: engine);
    app.useDefaults();
    configure(app);
    await app.listen();

    Future<void> shutdown() async {
      // ignore: avoid_print
      print('Shutting down gracefully...');
      await app.close();
      exit(0);
    }

    ProcessSignal.sigint.watch().listen((_) => shutdown());
    ProcessSignal.sigterm.watch().listen((_) => shutdown());

    return app;
  }

  void _addRoute(String method, String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _routes.add(_RouteInput(
      method: method,
      path: normalizePath(path),
      handler: handler,
      middleware: middleware ?? [],
      statusCode: statusCode,
    ));
  }
}

class _RouteInput {
  _RouteInput({
    required this.method,
    required this.path,
    required this.handler,
    required this.middleware,
    required this.statusCode,
  });

  final String method;
  final String path;
  final RouteHandler handler;
  final List<MiddlewareHandler> middleware;
  final int statusCode;
}

class _WebSocketRouteInput {
  _WebSocketRouteInput({
    required this.path,
    required this.handler,
    required this.middleware,
  });

  final String path;
  final WebSocketConnectHandler handler;
  final List<MiddlewareHandler> middleware;
}
