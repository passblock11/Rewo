import 'package:rewo/rewo.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:rewo/app/app.dart';

// @TestOn('vm')
void main() {
  test('native engine serves requests', () async {
    final port = 8700 + DateTime.now().millisecondsSinceEpoch % 500;
    final app = await RewoDemo.bootstrap(
      port: port,
      engine: ServerEngine.native,
    );
    final client = http.Client();
    try {
      final res = await client.get(Uri.parse('http://localhost:$port/health'));
      expect(res.statusCode, 200);
    } finally {
      client.close();
      await app.close();
    }
  });
}
