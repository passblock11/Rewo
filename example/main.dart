import 'dart:convert';

import 'package:dart_backend_framework/dart_backend_framework.dart';
import 'package:http/http.dart' as http;

class User {
  User({required this.id, required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String email;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};
}

class UserService {
  UserService(this._repo, this._events, this._transactions);

  final InMemoryRepository<User, String> _repo;
  final EventBus _events;
  final TransactionManager _transactions;

  Future<List<User>> findAll() => _repo.findAll();

  Future<User> findById(String id) async {
    final user = await _repo.findById(id);
    if (user == null) throw NotFoundException('User $id not found');
    return user;
  }

  Future<User> create(Map<String, dynamic> body) async {
    return _transactions.run(() async {
      Validator.validateOrThrow(body, {
        'email': const ValidateRule.email(),
        'name': const ValidateRule(required: true, minLength: 2),
      });

      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: body['email'] as String,
        name: body['name'] as String,
      );
      await _repo.save(user);
      _events.emit(UserCreatedEvent(user));
      return user;
    });
  }

  Future<bool> delete(String id) => _repo.deleteById(id);
}

class UserCreatedEvent {
  UserCreatedEvent(this.user);
  final User user;
}

@Controller('/users')
class UserController extends RestController {
  UserController(this._users);

  final UserService _users;

  @override
  String get basePath => '/users';

  @override
  void registerRoutes(RouteRegistrar r) {
    r.get('/', list);
    r.get('/admin/stats', adminStats, middleware: [
      AuthMiddleware().handler,
      roleGuard(['admin']),
    ]);
    r.get('/:id', get);
    r.post('/', create, statusCode: 201);
    r.delete('/:id', remove);
  }

  Future<List<Map<String, dynamic>>> list(RequestContext ctx) async {
    final users = await _users.findAll();
    return users.map((u) => u.toJson()).toList();
  }

  Future<Map<String, dynamic>> get(RequestContext ctx) async {
    final user = await _users.findById(ctx.param('id')!);
    return user.toJson();
  }

  Future<Map<String, dynamic>> create(RequestContext ctx) async {
    final user = await _users.create(ctx.jsonBody());
    return user.toJson();
  }

  Future<Map<String, dynamic>> remove(RequestContext ctx) async {
    final deleted = await _users.delete(ctx.param('id')!);
    return {'deleted': deleted};
  }

  @Secured(roles: ['admin'])
  Future<Map<String, dynamic>> adminStats(RequestContext ctx) async {
    final users = await _users.findAll();
    return {'total': users.length, 'requestedBy': ctx.userId};
  }
}

class HealthController extends RestController {
  @override
  void registerRoutes(RouteRegistrar r) {
    r.get('/health', (_) async => {'status': 'ok'});
  }
}

class AppModule {
  static Future<DartServe> bootstrap({int port = 8080}) async {
    final app = DartServe(config: AppConfig(port: port, logRequests: true));
    app.useDefaults();

    final repo = InMemoryRepository<User, String>(getId: (u) => u.id);
    app.singleton(repo);
    app.singleton(EventBus());
    app.singleton(TransactionManager());
    app.singleton(UserService(
      app.container.resolve<InMemoryRepository<User, String>>(),
      app.container.resolve<EventBus>(),
      app.container.resolve<TransactionManager>(),
    ));
    app.mount(UserController(app.container.resolve<UserService>()));
    app.mount(HealthController());

    app.events.on<UserCreatedEvent>((e) {
      // ignore: avoid_print
      print('📣 User created: ${e.user.email}');
    });

    app.schedule(30, () async {
      // ignore: avoid_print
      print('⏱️ Scheduled heartbeat');
    });

    await app.listen();
    return app;
  }
}

void main(List<String> args) async {
  if (args.contains('test')) {
    await runSmokeTest();
    return;
  }
  await AppModule.bootstrap();
}

Future<void> runSmokeTest() async {
  final app = await AppModule.bootstrap(port: 8081);
  final client = http.Client();
  try {
    final health = await client.get(Uri.parse('http://localhost:8081/health'));
    assert(health.statusCode == 200);

    final create = await client.post(
      Uri.parse('http://localhost:8081/users'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': 'test@example.com', 'name': 'Test User'}),
    );
    assert(create.statusCode == 201);

    final list = await client.get(Uri.parse('http://localhost:8081/users'));
    assert(list.statusCode == 200);

    final adminToken = createAuthToken('admin1', roles: ['admin']);
    final stats = await client.get(
      Uri.parse('http://localhost:8081/users/admin/stats'),
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
