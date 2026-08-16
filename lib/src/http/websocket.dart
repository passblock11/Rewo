import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;

import '../container.dart';
import '../context.dart';
import '../errors.dart';
import 'websocket_route_table.dart';

typedef WebSocketConnectHandler = void Function(WebSocket socket, RequestContext ctx);

/// Tracks open WebSocket connections for graceful shutdown.
class WebSocketConnectionTracker {
  final Set<WebSocket> _sockets = {};

  void track(WebSocket socket) {
    _sockets.add(socket);
    socket.done.whenComplete(() => _sockets.remove(socket));
  }

  Future<void> closeAll() async {
    final sockets = _sockets.toList();
    for (final socket in sockets) {
      await socket.close(WebSocketStatus.goingAway, 'Server shutting down');
    }
    _sockets.clear();
  }
}

/// Result of running the WebSocket auth middleware pipeline before upgrade.
class WebSocketAuthResult {
  const WebSocketAuthResult._({this.ctx, this.errorResponse});

  const WebSocketAuthResult.success(RequestContext ctx)
      : this._(ctx: ctx, errorResponse: null);

  const WebSocketAuthResult.failure(shelf.Response response)
      : this._(ctx: null, errorResponse: response);

  final RequestContext? ctx;
  final shelf.Response? errorResponse;

  bool get isSuccess => ctx != null && errorResponse == null;
}

RequestContext _buildWebSocketContext({
  required HttpRequest request,
  required CompiledWebSocketRoute route,
  required ServiceContainer container,
}) {
  return RequestContext(
    method: request.method,
    path: request.uri.path,
    headers: _headers(request),
    queryParameters: request.uri.queryParameters,
    pathParameters: route.extractParams(request.uri.path),
    container: container,
  );
}

/// Runs global + route middleware for a WebSocket handshake without upgrading.
Future<WebSocketAuthResult> authenticateWebSocketUpgrade({
  required HttpRequest request,
  required CompiledWebSocketRoute route,
  required ServiceContainer container,
}) async {
  if (!WebSocketTransformer.isUpgradeRequest(request)) {
    return WebSocketAuthResult.failure(
      shelf.Response(400, body: jsonEncode({'error': 'Not a WebSocket upgrade'})),
    );
  }

  RequestContext? authenticatedCtx;
  final ctx = _buildWebSocketContext(
    request: request,
    route: route,
    container: container,
  );

  try {
    final response = await route.pipeline.run(ctx, (c) async {
      authenticatedCtx = c;
      return shelf.Response.ok('');
    });

    if (response.statusCode >= 400) {
      return WebSocketAuthResult.failure(response);
    }
    if (authenticatedCtx == null) {
      return WebSocketAuthResult.failure(_unauthorizedResponse());
    }
    return WebSocketAuthResult.success(authenticatedCtx!);
  } on FrameworkException catch (e) {
    if (e is ValidationException) {
      return WebSocketAuthResult.failure(
        shelf.Response(
          e.statusCode,
          body: jsonEncode({'error': e.message, 'fields': e.errors}),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        ),
      );
    }
    return WebSocketAuthResult.failure(
      shelf.Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      ),
    );
  }
}

/// Handles a WebSocket upgrade on a dart:io [HttpRequest] (native engine).
Future<bool> handleWebSocketUpgrade({
  required HttpRequest request,
  required CompiledWebSocketRoute route,
  required ServiceContainer container,
}) async {
  final auth = await authenticateWebSocketUpgrade(
    request: request,
    route: route,
    container: container,
  );
  if (!auth.isSuccess) {
    await writeShelfResponseToHttp(request.response, auth.errorResponse!);
    return true;
  }

  final socket = await WebSocketTransformer.upgrade(request);
  route.handler(socket, auth.ctx!);
  return true;
}

Future<void> writeShelfResponseToHttp(
  HttpResponse response,
  shelf.Response shelfResponse,
) async {
  response.statusCode = shelfResponse.statusCode;
  shelfResponse.headers.forEach((key, value) {
    response.headers.set(key, value);
  });
  await response.addStream(shelfResponse.read());
  await response.close();
}

shelf.Response _unauthorizedResponse() {
  return shelf.Response(
    401,
    body: jsonEncode({'error': 'Unauthorized'}),
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  );
}

Map<String, String> _headers(HttpRequest request) {
  final map = <String, String>{};
  request.headers.forEach((k, values) => map[k.toLowerCase()] = values.join(','));
  return map;
}
