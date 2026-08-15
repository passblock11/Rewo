import 'dart:convert';
import 'dart:io';

import 'package:rewo/app/app.dart';
import 'package:rewo/rewo.dart';
import 'package:http/http.dart' as http;

/// Legacy entry — delegates to the unified server.
/// Prefer: dart run bin/server.dart
void main(List<String> args) async {
  if (args.contains('test')) {
    await runSmokeTest();
    return;
  }
  await RewoDemo.start();
}

Future<void> runSmokeTest() async {
  final app = await RewoDemo.bootstrap(port: 8081);
  final client = http.Client();
  try {
    final health = await client.get(Uri.parse('http://localhost:8081/health'));
    assert(health.statusCode == 200);

    final create = await client.post(
      Uri.parse('http://localhost:8081/api/users'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': 'test@example.com', 'name': 'Test User'}),
    );
    assert(create.statusCode == 201);

    final list = await client.get(Uri.parse('http://localhost:8081/api/users'));
    assert(list.statusCode == 200);

    final adminToken = createAuthToken('admin1', roles: ['admin']);
    final stats = await client.get(
      Uri.parse('http://localhost:8081/api/users/admin/stats'),
      headers: {'authorization': 'Bearer $adminToken'},
    );
    assert(stats.statusCode == 200);

    // ignore: avoid_print
    print('✅ All smoke tests passed');
  } finally {
    client.close();
    await app.close();
  }
}
