import 'package:dart_backend_framework/dart_backend_framework.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceContainer', () {
    test('resolves singleton', () {
      final container = ServiceContainer();
      container.registerSingleton<String>('hello');
      expect(container.resolve<String>(), 'hello');
    });

    test('resolves lazy singleton once', () {
      var count = 0;
      final container = ServiceContainer();
      container.registerLazySingleton<String>((_) => '${++count}');
      expect(container.resolve<String>(), '1');
      expect(container.resolve<String>(), '1');
      expect(count, 1);
    });
  });

  group('Validator', () {
    test('validates required email', () {
      expect(
        () => Validator.validateOrThrow({'email': 'bad'}, {
          'email': const ValidateRule.email(),
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('passes valid data', () {
      expect(
        () => Validator.validateOrThrow(
          {'email': 'a@b.com', 'name': 'Tejas'},
          {
            'email': const ValidateRule.email(),
            'name': const ValidateRule(required: true, minLength: 2),
          },
        ),
        returnsNormally,
      );
    });
  });

  group('EventBus', () {
    test('emits events to listeners', () {
      final bus = EventBus();
      var received = 0;
      bus.on<int>((e) => received = e);
      bus.emit(42);
      expect(received, 42);
    });
  });

  group('TransactionManager', () {
    test('commits on success', () async {
      final tx = TransactionManager();
      var committed = false;
      await tx.run(() async {
        tx.onCommit(() async => committed = true);
        return 1;
      });
      expect(committed, isTrue);
    });

    test('rolls back on failure', () async {
      final tx = TransactionManager();
      var rolledBack = false;
      try {
        await tx.run(() async {
          tx.onRollback(() async => rolledBack = true);
          throw Exception('fail');
        });
      } catch (_) {}
      expect(rolledBack, isTrue);
    });
  });

  group('InMemoryRepository', () {
    test('crud operations', () async {
      final repo = InMemoryRepository<Map<String, String>, String>(
        getId: (item) => item['id']!,
      );
      await repo.save({'id': '1', 'name': 'A'});
      expect(await repo.findById('1'), {'id': '1', 'name': 'A'});
      expect(await repo.deleteById('1'), isTrue);
      expect(await repo.findById('1'), isNull);
    });
  });

  group('AuthMiddleware', () {
    test('creates token', () {
      final token = createAuthToken('user1', roles: ['admin']);
      expect(token, isNotEmpty);
    });

    test('enriches context with user and roles', () async {
      final token = createAuthToken('admin', roles: ['admin']);
      final handler = AuthMiddleware().handler;
      RequestContext? passed;

      try {
        await handler(
          RequestContext(
            method: 'GET',
            path: '/x',
            headers: {'authorization': 'Bearer $token'},
            queryParameters: {},
            pathParameters: {},
            bodyBytes: [],
            container: ServiceContainer(),
          ),
          (ctx) async {
            passed = ctx;
            return AppResponse.json({'ok': true});
          },
        );
      } catch (_) {}

      expect(passed?.userId, 'admin');
      expect(passed?.hasRole('admin'), isTrue);
    });
  });
}
