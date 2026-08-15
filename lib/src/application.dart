import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'container.dart';
import 'context.dart';
import 'events/event_bus.dart';
import 'http/response.dart';
import 'middleware/cors_middleware.dart';
import 'middleware/error_middleware.dart';
import 'middleware/logging_middleware.dart';
import 'middleware/middleware.dart';
import 'scheduler/scheduler.dart';
import 'transaction/transaction.dart';

typedef ConfigureCallback = void Function(DartServe app);
typedef RouteHandler = Future<dynamic> Function(RequestContext ctx);

abstract class RestController {
  String get basePath => '';
  void registerRoutes(RouteRegistrar registrar);
}

class RouteRegistrar {
  RouteRegistrar(this._app, this._basePath);

  final DartServe _app;
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

class DartServe {
  DartServe({AppConfig? config})
      : config = config ?? AppConfig.fromEnvironment(),
        container = ServiceContainer(),
        events = EventBus(),
        transactions = TransactionManager(),
        scheduler = Scheduler();

  final AppConfig config;
  final ServiceContainer container;
  final EventBus events;
  final TransactionManager transactions;
  final Scheduler scheduler;

  final Router _router = Router();
  final List<MiddlewareHandler> _globalMiddleware = [];
  final List<_RouteDefinition> _routes = [];
  HttpServer? _server;

  void singleton<T>(T instance) => container.registerSingleton<T>(instance);

  void factory<T>(T Function(ServiceContainer c) creator) {
    container.registerFactory<T>((c) => creator(c));
  }

  void lazy<T>(T Function(ServiceContainer c) creator) {
    container.registerLazySingleton<T>((c) => creator(c));
  }

  void use(Middleware middleware) => _globalMiddleware.add(middleware.handler);

  void useDefaults() {
    use(ErrorMiddleware());
    use(CorsMiddleware());
    if (config.logRequests) use(LoggingMiddleware());
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

  void schedule(int intervalSeconds, FutureOr<void> Function() task) {
    scheduler.cronSeconds(intervalSeconds, task);
  }

  Future<void> listen() async {
    for (final route in _routes) {
      Future<shelf.Response> shelfHandler(shelf.Request request) async {
        final ctx = await _buildContext(request, route);
        final pipeline = MiddlewarePipeline([
          ..._globalMiddleware,
          ...route.middleware,
        ]);
        final response = await pipeline.run(ctx, (c) async {
          final result = await route.handler(c);
          return AppResponse.fromHandlerResult(result, statusCode: route.statusCode);
        });
        return response;
      }

      switch (route.method) {
        case 'GET':
          _router.get(route.shelfPath, shelfHandler);
        case 'POST':
          _router.post(route.shelfPath, shelfHandler);
        case 'PUT':
          _router.put(route.shelfPath, shelfHandler);
        case 'DELETE':
          _router.delete(route.shelfPath, shelfHandler);
        case 'PATCH':
          _router.patch(route.shelfPath, shelfHandler);
      }
    }

    _server = await shelf_io.serve(_router.call, config.host, config.port);
    // ignore: avoid_print
    print('🚀 DartServe running on http://${config.host}:${config.port}');
  }

  Future<void> close() async {
    scheduler.stopAll();
    await _server?.close(force: true);
  }

  static Future<DartServe> run(ConfigureCallback configure, {AppConfig? config}) async {
    final app = DartServe(config: config);
    app.useDefaults();
    configure(app);
    await app.listen();
    return app;
  }

  void _addRoute(String method, String path, RouteHandler handler,
      {List<MiddlewareHandler>? middleware, int statusCode = 200}) {
    _routes.add(_RouteDefinition(
      method: method,
      path: _normalizePath(path),
      shelfPath: _toShelfPath(path),
      handler: handler,
      middleware: middleware ?? [],
      statusCode: statusCode,
    ));
  }

  Future<RequestContext> _buildContext(shelf.Request request, _RouteDefinition route) async {
    final body = await request.read().expand((e) => e).toList();
    return RequestContext(
      method: request.method,
      path: request.requestedUri.path,
      headers: {for (final h in request.headersAll.entries) h.key.toLowerCase(): h.value.join(',')},
      queryParameters: request.url.queryParameters,
      pathParameters: _matchPathParams(route.path, request.requestedUri.path),
      bodyBytes: body,
      container: container,
    );
  }

  Map<String, String> _matchPathParams(String routePath, String actualPath) {
    final routeSegments = routePath.split('/').where((s) => s.isNotEmpty).toList();
    final actualSegments = actualPath.split('/').where((s) => s.isNotEmpty).toList();
    final params = <String, String>{};
    if (routeSegments.length != actualSegments.length) return params;
    for (var i = 0; i < routeSegments.length; i++) {
      final segment = routeSegments[i];
      if (segment.startsWith(':')) {
        params[segment.substring(1)] = actualSegments[i];
      }
    }
    return params;
  }
}

class _RouteDefinition {
  _RouteDefinition({
    required this.method,
    required this.path,
    required this.shelfPath,
    required this.handler,
    required this.middleware,
    required this.statusCode,
  });

  final String method;
  final String path;
  final String shelfPath;
  final RouteHandler handler;
  final List<MiddlewareHandler> middleware;
  final int statusCode;
}

String _normalizePath(String path) {
  var p = path.trim();
  if (!p.startsWith('/')) p = '/$p';
  p = p.replaceAll(RegExp(r'/+'), '/');
  if (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

String _toShelfPath(String path) {
  return _normalizePath(path).replaceAllMapped(RegExp(r':(\w+)'), (m) => '<${m[1]}>');
}
