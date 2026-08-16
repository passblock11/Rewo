import 'dart:convert';
import 'dart:io';

import 'package:rewo/rewo.dart';
import 'package:test/test.dart';

Rewo _createWsApp({
  required int port,
  required ServerEngine engine,
  required JwtService jwt,
  void Function(WebSocket socket, RequestContext ctx)? onConnect,
}) {
  final app = Rewo(
    config: AppConfig(
      host: 'localhost',
      port: port,
      jwtSecret: 'test-secret',
      logRequests: false,
      rateLimit: 10000,
    ),
    engine: engine,
  );
  app.useDefaults();
  app.webSocket(
    '/ws/test',
    onConnect ??
        (socket, ctx) {
          socket.add(jsonEncode({'type': 'welcome', 'user': ctx.userId}));
        },
    middleware: [JwtMiddleware(jwt).handler],
  );
  return app;
}

void main() {
  group('webSocket native engine', () {
    late JwtService jwt;

    setUp(() {
      jwt = JwtService(secret: 'test-secret');
    });

    test('rejects missing JWT when useDefaults() is enabled', () async {
      final port = 8800 + DateTime.now().millisecondsSinceEpoch % 500;
      final app = _createWsApp(port: port, engine: ServerEngine.native, jwt: jwt);
      await app.listen();

      try {
        await WebSocket.connect('ws://localhost:$port/ws/test');
        fail('Expected connection to fail');
      } on Object {
        // Upgrade must be rejected before a socket is established.
      }

      await app.close();
    });

    test('accepts valid JWT via query token', () async {
      final port = 8900 + DateTime.now().millisecondsSinceEpoch % 500;
      String? connectedUserId;
      final app = _createWsApp(
        port: port,
        engine: ServerEngine.native,
        jwt: jwt,
        onConnect: (socket, ctx) {
          connectedUserId = ctx.userId;
          socket.add(jsonEncode({'type': 'welcome'}));
        },
      );
      await app.listen();

      final token = jwt.sign({
        'sub': 'user-1',
        'roles': ['user'],
        'type': 'access',
      });

      final socket = await WebSocket.connect(
        'ws://localhost:$port/ws/test?token=$token',
      );
      final message = await socket.first;
      expect(connectedUserId, 'user-1');
      expect(jsonDecode(message as String), {'type': 'welcome'});
      await socket.close();
      await app.close();
    });

    test('accepts valid JWT via Authorization header', () async {
      final port = 9000 + DateTime.now().millisecondsSinceEpoch % 500;
      final app = _createWsApp(port: port, engine: ServerEngine.native, jwt: jwt);
      await app.listen();

      final token = jwt.sign({
        'sub': 'user-2',
        'roles': ['user'],
        'type': 'access',
      });

      final socket = await WebSocket.connect(
        'ws://localhost:$port/ws/test',
        headers: {'Authorization': 'Bearer $token'},
      );
      final message = jsonDecode(await socket.first as String) as Map<String, dynamic>;
      expect(message['type'], 'welcome');
      expect(message['user'], 'user-2');
      await socket.close();
      await app.close();
    });

    test('resolve() works inside webSocket handler', () async {
      final port = 9100 + DateTime.now().millisecondsSinceEpoch % 500;
      final app = Rewo(
        config: AppConfig(
          host: 'localhost',
          port: port,
          jwtSecret: 'test-secret',
          logRequests: false,
        ),
        engine: ServerEngine.native,
      );
      app.singleton<String>('chat-service');
      app.webSocket(
        '/ws/test',
        (socket, ctx) {
          final service = ctx.resolve<String>();
          socket.add(jsonEncode({'service': service}));
        },
        middleware: [JwtMiddleware(jwt).handler],
      );
      await app.listen();

      final token = jwt.sign({'sub': 'user-3', 'type': 'access'});
      final socket = await WebSocket.connect(
        'ws://localhost:$port/ws/test?token=$token',
      );
      expect(
        jsonDecode(await socket.first as String),
        {'service': 'chat-service'},
      );
      await socket.close();
      await app.close();
    });
  });

  group('webSocket shelf engine', () {
    test('accepts valid JWT via query token', () async {
      final port = 9200 + DateTime.now().millisecondsSinceEpoch % 500;
      final jwt = JwtService(secret: 'test-secret');
      final app = _createWsApp(port: port, engine: ServerEngine.shelf, jwt: jwt);
      await app.listen();

      final token = jwt.sign({
        'sub': 'shelf-user',
        'roles': ['user'],
        'type': 'access',
      });

      final socket = await WebSocket.connect(
        'ws://localhost:$port/ws/test?token=$token',
      );
      final message = jsonDecode(await socket.first as String) as Map<String, dynamic>;
      expect(message['type'], 'welcome');
      expect(message['user'], 'shelf-user');
      await socket.close();
      await app.close();
    });
  });
}
