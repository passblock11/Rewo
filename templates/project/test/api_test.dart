import 'dart:convert';

import 'package:{{project_name}}/app.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  late http.Client client;
  late int port;

  setUpAll(() async {
    port = 8200 + DateTime.now().millisecondsSinceEpoch % 500;
    await App.bootstrap(port: port);
    client = http.Client();
  });

  tearDownAll(() async {
    client.close();
  });

  test('GET /health returns alive', () async {
    final res = await client.get(Uri.parse('http://localhost:$port/health'));
    expect(res.statusCode, 200);
    expect(jsonDecode(res.body), {'status': 'alive'});
  });

  test('items CRUD', () async {
    final create = await client.post(
      Uri.parse('http://localhost:$port/api/items'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'title': 'First item'}),
    );
    expect(create.statusCode, 200);

    final list = await client.get(Uri.parse('http://localhost:$port/api/items'));
    expect(list.statusCode, 200);
    expect(jsonDecode(list.body), isNotEmpty);
  });
}
