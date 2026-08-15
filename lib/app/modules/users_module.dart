import 'package:rewo/rewo.dart';

import '../models/create_user_request.dart';

part 'generated_user_controller.routes.g.dart';

class UsersModule implements RewoModule {
  @override
  String get name => 'users';

  @override
  void register(Rewo app) {
    final repo = InMemoryRepository<User, String>(getId: (u) => u.id);
    app.singleton(repo);
    app.singleton(UserService(
      repo,
      app.container.resolve<EventBus>(),
      app.container.resolve<TransactionManager>(),
    ));
    app.mount(UserController(app.container.resolve<UserService>()));
    app.mount(GeneratedUserController());

    app.events.on<UserCreatedEvent>((e) {
      // ignore: avoid_print
      print('📣 User created: ${e.user.email}');
    });
  }
}

class User {
  User({required this.id, required this.email, required this.name});

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

  Future<User> createFromRequest(CreateUserRequest req) async {
    return _transactions.run(() async {
      Validator.validateOrThrow(
        {'email': req.email, 'name': req.name},
        {
          'email': const ValidateRule.email(),
          'name': const ValidateRule(required: true, minLength: 2),
        },
      );
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: req.email,
        name: req.name,
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

class UserController extends RestController {
  UserController(this._users);
  final UserService _users;

  @override
  String get basePath => '/api/users';

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
    return (await _users.findById(ctx.param('id')!)).toJson();
  }

  Future<Map<String, dynamic>> create(RequestContext ctx) async {
    final req = await ctx.bodyAs(CreateUserRequest.fromJson);
    return (await _users.createFromRequest(req)).toJson();
  }

  Future<Map<String, dynamic>> remove(RequestContext ctx) async {
    return {'deleted': await _users.delete(ctx.param('id')!)};
  }

  Future<Map<String, dynamic>> adminStats(RequestContext ctx) async {
    final users = await _users.findAll();
    return {'total': users.length, 'requestedBy': ctx.userId};
  }
}

@Controller('/api/v2/users')
class GeneratedUserController extends RestController with $GeneratedUserControllerRoutes {
  @Get('/')
  Future<Map<String, dynamic>> list(RequestContext ctx) async => {'users': []};

  @Get('/:id')
  Future<Map<String, dynamic>> get(RequestContext ctx) async => {'id': ctx.param('id')};

  @Post('/')
  @StatusCode(201)
  Future<Map<String, dynamic>> create(RequestContext ctx) async => {'created': true};
}
