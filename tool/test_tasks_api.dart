import 'dart:convert';
import 'dart:io';

/// Run API smoke tests against a running Tasks API server.
/// Usage: dart run tool/test_tasks_api.dart [port]
Future<void> main(List<String> args) async {
  final port = int.tryParse(args.firstOrNull ?? '') ?? 8080;
  final base = 'http://localhost:$port';
  final client = HttpClient();

  Future<HttpClientResponse> req(
    String method,
    String path, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final request = await client.openUrl(method, Uri.parse('$base$path'));
    headers?.forEach(request.headers.set);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(body);
    }
    return request.close();
  }

  Future<Map<String, dynamic>> jsonBody(HttpClientResponse res) async {
    final text = await res.transform(utf8.decoder).join();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  void pass(String name) => print('✅ $name');

  try {
    // Health
    final health = await req('GET', '/health');
    assert(health.statusCode == 200);
    pass('GET /health');

    // Login
    final loginRes = await req(
      'POST',
      '/api/auth/login',
      body: jsonEncode({'email': 'you@example.com', 'password': 'password'}),
    );
    assert(loginRes.statusCode == 200);
    final login = await jsonBody(loginRes);
    final token = login['token'] as String;
    pass('POST /api/auth/login');

    // Me
    final meRes = await req('GET', '/api/auth/me', headers: {
      'authorization': 'Bearer $token',
    });
    assert(meRes.statusCode == 200);
    pass('GET /api/auth/me');

    // Create task
    final createRes = await req(
      'POST',
      '/api/tasks',
      body: jsonEncode({'title': 'Learn Rewo', 'description': 'Build APIs'}),
    );
    assert(createRes.statusCode == 201);
    final task = await jsonBody(createRes);
    final taskId = task['id'] as String;
    pass('POST /api/tasks');

    // List tasks
    final listRes = await req('GET', '/api/tasks');
    assert(listRes.statusCode == 200);
    pass('GET /api/tasks');

    // Toggle task
    final toggleRes = await req('PATCH', '/api/tasks/$taskId/toggle');
    assert(toggleRes.statusCode == 200);
    final toggled = await jsonBody(toggleRes);
    assert(toggled['done'] == true);
    pass('PATCH /api/tasks/:id/toggle');

    // Save note (file write)
    final noteRes = await req(
      'POST',
      '/api/notes',
      body: jsonEncode({'text': 'Hello from Rewo!'}),
    );
    assert(noteRes.statusCode == 200);
    pass('POST /api/notes');

    // OpenAPI
    final openApiRes = await req('GET', '/openapi.json');
    assert(openApiRes.statusCode == 200);
    pass('GET /openapi.json');

  print('\n🎉 All API tests passed on port $port');
  } catch (e, st) {
    print('❌ Test failed: $e\n$st');
    exit(1);
  } finally {
    client.close(force: true);
  }
}
