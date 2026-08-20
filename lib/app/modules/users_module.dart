/// Demo user CRUD routes and annotation-based controller examples.
library users_module;

import 'package:rewo/rewo.dart';

import '../models/create_user_request.dart';

part 'generated_user_controller.routes.g.dart';

/// Registers in-memory user APIs for the demo app.
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

/// Demo user entity stored in memory.
class User {
  /// Creates a user with [id], [email], and [name].
  User({required this.id, required this.email, required this.name});

  /// Unique identifier.
  final String id;

  /// Login email address.
  final String email;

  /// Display name.
  final String name;

  /// Serializes this user to JSON.
  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};
}

/// Application service for user CRUD operations.
class UserService {
  /// Creates a service backed by [repo], [events], and [transactions].
  UserService(this._repo, this._events, this._transactions);

  final InMemoryRepository<User, String> _repo;
  final EventBus _events;
  final TransactionManager _transactions;

  /// Returns all users.
  Future<List<User>> findAll() => _repo.findAll();

  /// Returns a user by [id] or throws [NotFoundException].
  Future<User> findById(String id) async {
    final user = await _repo.findById(id);
    if (user == null) throw NotFoundException('User $id not found');
    return user;
  }

  /// Validates and persists a new user from [req].
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

  /// Deletes a user by [id].
  Future<bool> delete(String id) => _repo.deleteById(id);
}

/// Emitted when a user is created successfully.
class UserCreatedEvent {
  /// Wraps the created [user].
  UserCreatedEvent(this.user);

  /// The new user record.
  final User user;
}

/// REST controller for `/api/users`.
class UserController extends RestController {
  /// Creates a controller backed by [users].
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

/// Annotation-driven controller example at `/api/v2/users`.
@Controller('/api/v2/users')
class GeneratedUserController extends RestController
    with $GeneratedUserControllerRoutes {
  @Get('/')
  Future<Map<String, dynamic>> list(RequestContext ctx) async => {'users': []};

  @Get('/:id')
  Future<Map<String, dynamic>> get(RequestContext ctx) async =>
      {'id': ctx.param('id')};

  @Post('/')
  @StatusCode(201)
  Future<Map<String, dynamic>> create(RequestContext ctx) async =>
      {'created': true};
}
