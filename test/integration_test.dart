// @TestOn('vm')

import 'dart:convert';

import 'package:dart_backend_framework/dart_backend_framework.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../example/main.dart' as example;

void main() {
  late DartServe app;
  late http.Client client;
  late int port;

  setUp(() async {
    port = 8100 + DateTime.now().millisecondsSinceEpoch % 1000;
    app = await example.AppModule.bootstrap(port: port);
    client = http.Client();
  });

  tearDown(() async {
    client.close();
    await app.close();
  });

  test('GET /health returns ok', () async {
    final res = await client.get(Uri.parse('http://localhost:$port/health'));
    expect(res.statusCode, 200);
    expect(jsonDecode(res.body), {'status': 'ok'});
  });

  test('POST /users creates user', () async {
    final res = await client.post(
      Uri.parse('http://localhost:$port/users'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': 'a@b.com', 'name': 'Alice'}),
    );
    expect(res.statusCode, 201);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    expect(body['email'], 'a@b.com');
  });

  test('GET /users lists users', () async {
    await client.post(
      Uri.parse('http://localhost:$port/users'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': 'b@b.com', 'name': 'Bob'}),
    );
    final res = await client.get(Uri.parse('http://localhost:$port/users'));
    expect(res.statusCode, 200);
    final list = jsonDecode(res.body) as List;
    expect(list, isNotEmpty);
  });

  test('validation rejects bad email', () async {
    final res = await client.post(
      Uri.parse('http://localhost:$port/users'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': 'invalid', 'name': 'X'}),
    );
    expect(res.statusCode, 422);
  });

  test('admin stats requires auth', () async {
    final res = await client.get(Uri.parse('http://localhost:$port/users/admin/stats'));
    expect(res.statusCode, 401);
  });

  test('admin stats works with admin token', () async {
    final token = createAuthToken('admin', roles: ['admin']);
    final res = await client.get(
      Uri.parse('http://localhost:$port/users/admin/stats'),
      headers: {'authorization': 'Bearer $token'},
    );
    expect(res.statusCode, 200);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    expect(body['requestedBy'], 'admin');
  });
}
