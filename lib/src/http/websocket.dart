import 'dart:io';

import '../container.dart';
import '../context.dart';
import '../http/response.dart';
import '../middleware/middleware.dart';

/// Basic WebSocket upgrade handler.
class WebSocketHandler {
  WebSocketHandler(this.path, this.onConnect);

  final String path;
  final void Function(WebSocket socket, RequestContext ctx) onConnect;

  MiddlewareHandler asMiddleware() {
    return (ctx, next) async {
      if (ctx.path != path) return next(ctx);
      // WebSocket upgrade is handled at HttpServer level via upgrade handler
      return AppResponse.json({'error': 'Use Rewo.onWebSocket() for WS'}, statusCode: 426);
    };
  }
}

typedef WebSocketConnectHandler = void Function(WebSocket socket, RequestContext ctx);

/// Registers WebSocket upgrade on native HttpServer.
void registerWebSocket(
  HttpServer server,
  String path,
  WebSocketConnectHandler handler,
) {
  server.listen((request) async {
    if (request.uri.path == path && WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      final ctx = RequestContext(
        method: request.method,
        path: request.uri.path,
        headers: _headers(request),
        queryParameters: request.uri.queryParameters,
        pathParameters: {},
        container: ServiceContainer(),
      );
      handler(socket, ctx);
    }
  });
}

Map<String, String> _headers(HttpRequest request) {
  final map = <String, String>{};
  request.headers.forEach((k, values) => map[k.toLowerCase()] = values.join(','));
  return map;
}
