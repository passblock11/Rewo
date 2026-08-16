import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;

import '../config.dart';
import '../container.dart';
import '../context.dart';
import '../errors.dart';
import '../performance/http_tuning.dart';
import 'response.dart';
import 'route_table.dart';
import 'websocket.dart';
import 'websocket_route_table.dart';

/// High-performance HTTP server using dart:io directly (bypasses Shelf).
class NativeHttpServer {
  NativeHttpServer({
    required this.config,
    required this.routeTable,
    required this.webSocketRouteTable,
    required this.container,
  });

  final AppConfig config;
  final RouteTable routeTable;
  final WebSocketRouteTable webSocketRouteTable;
  final ServiceContainer container;

  HttpServer? _server;

  Future<void> listen() async {
    _server = await HttpServer.bind(config.host, config.port, shared: true);
    tuneHttpServer(_server!, config.performance);

    _server!.listen((request) async {
      try {
        await _handle(request);
      } catch (e, st) {
        // ignore: avoid_print
        print('Native server error: $e\n$st');
        await _writeJson(request.response, 500, {'error': 'Internal server error'});
      }
    });

    // ignore: avoid_print
    print('🚀 Rewo [native] on http://${config.host}:${config.port}');
  }

  Future<void> _handle(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final wsRoute = webSocketRouteTable.match(request.uri.path);
      if (wsRoute != null) {
        final handled = await handleWebSocketUpgrade(
          request: request,
          route: wsRoute,
          container: container,
        );
        if (handled) return;
      }
    }

    final route = routeTable.match(request.method, request.uri.path);
    if (route == null) {
      request.response.statusCode = 404;
      await request.response.close();
      return;
    }

    final lazy = config.performance.lazyBodyParsing;
    final ctx = RequestContext(
      method: request.method,
      path: request.uri.path,
      headers: _headers(request),
      queryParameters: request.uri.queryParameters,
      pathParameters: route.extractParams(request.uri.path),
      bodyLoader: lazy ? () => BodyReader.read(request) : null,
      bodyBytes: lazy ? null : await BodyReader.read(request),
      container: container,
    );

    try {
      final shelfResponse = await route.pipeline.run(ctx, (c) async {
        final result = await route.handler(c);
        return AppResponse.fromHandlerResult(result, statusCode: route.statusCode);
      });
      await _writeShelfResponse(request.response, shelfResponse);
    } on FrameworkException catch (e) {
      if (e is ValidationException) {
        await _writeJson(request.response, e.statusCode, {
          'error': e.message,
          'fields': e.errors,
        });
      } else {
        await _writeJson(request.response, e.statusCode, {'error': e.message});
      }
    }
  }

  Future<void> close() async {
    await _server?.close(force: true);
  }

  Map<String, String> _headers(HttpRequest request) {
    final map = <String, String>{};
    request.headers.forEach((k, values) {
      map[k.toLowerCase()] = values.join(',');
    });
    return map;
  }

  Future<void> _writeShelfResponse(
    HttpResponse response,
    shelf.Response shelfResponse,
  ) async {
    response.statusCode = shelfResponse.statusCode;
    shelfResponse.headers.forEach((k, v) => response.headers.set(k, v));
    await response.addStream(shelfResponse.read());
    await response.close();
  }

  Future<void> _writeJson(
    HttpResponse response,
    int status,
    Map<String, dynamic> body,
  ) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }
}
