import 'package:rewo/rewo.dart';
import 'package:test/test.dart';

void main() {
  group('RouteTable', () {
    late RouteTable table;

    setUp(() {
      table = RouteTable();
      table.add(_route('GET', '/health'));
      table.add(_route('GET', '/users/:id'));
      table.add(_route('POST', '/users'));
    });

    test('matches static routes in O(1)', () {
      expect(table.match('GET', '/health'), isNotNull);
      expect(table.match('GET', '/health')!.path, '/health');
    });

    test('matches param routes', () {
      final hit = table.match('GET', '/users/42');
      expect(hit, isNotNull);
      expect(hit!.extractParams('/users/42'), {'id': '42'});
    });

    test('returns null for unknown routes', () {
      expect(table.match('DELETE', '/health'), isNull);
    });
  });

  group('IsolatePool', () {
    test('runs computation on worker', () async {
      final pool = IsolatePool(workers: 2);
      final result = await pool.run(_double, 21);
      expect(result, 42);
      await pool.close();
    });
  });

  group('bodyAs', () {
    test('parses typed model', () async {
      final ctx = RequestContext(
        method: 'POST',
        path: '/',
        headers: {},
        queryParameters: {},
        pathParameters: {},
        bodyBytes: [
          123,
          34,
          101,
          109,
          97,
          105,
          108,
          34,
          58,
          34,
          97,
          64,
          98,
          46,
          99,
          111,
          109,
          34,
          44,
          34,
          110,
          97,
          109,
          101,
          34,
          58,
          34,
          65,
          34,
          125
        ],
        container: ServiceContainer(),
      );
      final map = await ctx.jsonBody();
      expect(map['email'], 'a@b.com');
    });
  });
}

CompiledRoute _route(String method, String path) {
  return CompiledRoute(
    method: method,
    path: path,
    handler: (_) async => {},
    middleware: const [],
    statusCode: 200,
    pipeline: MiddlewarePipeline(const []),
  );
}

int _double(int v) => v * 2;
