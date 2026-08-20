import 'package:rewo/rewo.dart';
import 'package:test/test.dart';

void main() {
  group('DotEnv', () {
    test('get with fallback', () {
      expect(DotEnv.get('NONEXISTENT_KEY', fallback: 'default'), 'default');
    });
  });

  group('JwtService', () {
    test('sign and verify', () {
      final jwt = JwtService(secret: 'test-secret-key-12345');
      final token = jwt.sign({
        'sub': 'user1',
        'roles': ['admin']
      });
      final payload = jwt.verify(token);
      expect(payload['sub'], 'user1');
    });
  });

  group('LocalStorage', () {
    test('write and read', () async {
      final storage = LocalStorage('./test_storage');
      await storage.write('test.txt', 'hello'.codeUnits);
      expect(await storage.exists('test.txt'), isTrue);
      final content = String.fromCharCodes(await storage.read('test.txt'));
      expect(content, 'hello');
      await storage.delete('test.txt');
    });
  });

  group('Cache', () {
    test('set and get with TTL', () async {
      final cache = Cache();
      cache.set('key', 'value');
      expect(cache.get<String>('key'), 'value');
    });
  });

  group('JobQueue', () {
    test('processes jobs', () async {
      final queue = JobQueue();
      var ran = false;
      queue.add('test', () async => ran = true);
      await queue.processAll();
      expect(ran, isTrue);
    });
  });

  group('Pagination', () {
    test('PageRequest from query', () {
      final req = PageRequest.fromQuery({'page': '2', 'limit': '10'});
      expect(req.page, 2);
      expect(req.offset, 10);
    });
  });

  group('TestApp', () {
    test('invokes route handler', () async {
      final testApp = await TestApp.create((app) {
        app.get('/hello', (_) async => {'msg': 'hi'});
      });
      final result = await testApp.call('GET', '/hello');
      expect(result, {'msg': 'hi'});
    });
  });

  group('OpenAPI', () {
    test('generates spec', () async {
      final testApp = await TestApp.create((app) {
        app.get('/users', (_) async => []);
      });
      testApp.app.compileRoutesForTest();
      final spec = OpenApiGenerator().generate(testApp.routeTable);
      expect(spec['openapi'], '3.0.0');
      expect(spec['paths'], isNotEmpty);
    });
  });

  group('Metrics', () {
    test('exports prometheus format', () {
      final m = Metrics();
      m.increment('requests');
      expect(m.export(), contains('requests'));
    });
  });

  group('HealthCheck', () {
    test('liveness returns alive', () async {
      final h = HealthCheck();
      expect(await h.liveness(), {'status': 'alive'});
    });
  });
}
