import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http2/transport.dart';

import '../config.dart';
import '../container.dart';
import '../context.dart';
import '../errors.dart';
import 'response.dart';
import 'route_table.dart';

/// HTTP/2 server (TLS required). Multiplexes many streams over one connection.
class Http2ServerEngine {
  Http2ServerEngine({
    required this.config,
    required this.routeTable,
    required this.container,
    required this.securityContext,
  });

  final AppConfig config;
  final RouteTable routeTable;
  final ServiceContainer container;
  final SecurityContext securityContext;

  ServerSocket? _server;

  Future<void> listen() async {
    // HTTP/2 streams are handled via [handleSocket] when behind a TLS terminator.
    // ignore: avoid_print
    print(
        '🚀 Rewo [http2] ready — use handleSocket() or native HTTP/1.1 fallback');
  }

  Future<void> close() async {
    await _server?.close();
  }

  /// Handle a raw TLS socket upgraded to HTTP/2 (called by reverse proxy adapter).
  Future<void> handleSocket(Socket socket) async {
    final connection = ServerTransportConnection.viaSocket(socket);
    connection.incomingStreams.listen(_handleStream);
  }

  Future<void> _handleStream(ServerTransportStream stream) async {
    final headers = <String, String>{};
    var method = 'GET';
    var path = '/';
    final bodyChunks = <int>[];

    await for (final message in stream.incomingMessages) {
      if (message is HeadersStreamMessage) {
        for (final h in message.headers) {
          final name = String.fromCharCodes(h.name).toLowerCase();
          final value = String.fromCharCodes(h.value);
          headers[name] = value;
          if (name == ':method') method = value;
          if (name == ':path') path = Uri.parse(value).path;
        }
      } else if (message is DataStreamMessage) {
        bodyChunks.addAll(message.bytes);
        if (message.endStream) {
          await _dispatch(stream, method, path, headers, bodyChunks);
        }
      }
    }
  }

  Future<void> _dispatch(
    ServerTransportStream stream,
    String method,
    String path,
    Map<String, String> headers,
    List<int> bodyBytes,
  ) async {
    final route = routeTable.match(method, path);
    if (route == null) {
      _sendJson(stream, 404, {'error': 'Not found'});
      return;
    }

    final ctx = RequestContext(
      method: method,
      path: path,
      headers: headers,
      queryParameters: Uri.parse('http://local$path').queryParameters,
      pathParameters: route.extractParams(path),
      bodyBytes: bodyBytes,
      container: container,
    );

    try {
      final response = await route.pipeline.run(ctx, (c) async {
        final result = await route.handler(c);
        return AppResponse.fromHandlerResult(result,
            statusCode: route.statusCode);
      });
      final body = await response.read().expand((e) => e).toList();
      _sendBytes(stream, response.statusCode, body);
    } on FrameworkException catch (e) {
      _sendJson(stream, e.statusCode, {'error': e.message});
    }
  }

  void _sendJson(
      ServerTransportStream stream, int status, Map<String, dynamic> body) {
    _sendBytes(stream, status, utf8.encode(jsonEncode(body)));
  }

  void _sendBytes(ServerTransportStream stream, int status, List<int> body) {
    stream.sendHeaders(
      [
        Header.ascii(':status', status.toString()),
        Header.ascii('content-type', 'application/json'),
      ],
      endStream: body.isEmpty,
    );
    if (body.isNotEmpty) {
      stream.sendData(Uint8List.fromList(body), endStream: true);
    }
  }
}
