import 'package:rewo/rewo.dart';

class AuthModule implements RewoModule {
  @override
  String get name => 'auth';

  @override
  void register(Rewo app) {
    final jwt = app.container.resolve<JwtService>();
    final sessions = app.container.resolve<SessionStore>();
    app.mount(_AuthController(jwt, sessions));
  }
}

class _AuthController extends RestController {
  _AuthController(this._jwt, this._sessions);

  final JwtService _jwt;
  final SessionStore _sessions;

  @override
  String get basePath => '/api/auth';

  @override
  void registerRoutes(RouteRegistrar r) {
    r.post('/login', login);
    r.post('/logout', (_) async => {'ok': true});
    r.get('/me', me, middleware: [JwtMiddleware(_jwt).handler]);
  }

  Future<Map<String, dynamic>> login(RequestContext ctx) async {
    final body = await ctx.jsonBody();
    final email = body['email'] as String? ?? '';
    final password = body['password'] as String? ?? '';
    if (email.isEmpty || password != 'password') {
      throw UnauthorizedException('Invalid credentials');
    }
    final token = _jwt.sign({'sub': email, 'roles': ['user']});
    _sessions.create(userId: email);
    return {'token': token, 'type': 'Bearer'};
  }

  Future<Map<String, dynamic>> me(RequestContext ctx) async {
    return {'userId': ctx.userId, 'roles': ctx.roles};
  }
}
