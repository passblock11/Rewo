import '../auth/jwt.dart';
import '../context.dart';
import '../errors.dart';
import 'middleware.dart';

/// JWT Bearer authentication middleware.
class JwtMiddleware extends Middleware {
  JwtMiddleware(this.jwt, {this.roles = const []});

  final JwtService jwt;
  final List<String> roles;

  @override
  MiddlewareHandler get handler => (ctx, next) async {
        final auth = ctx.headers['authorization'];
        if (auth == null || !auth.startsWith('Bearer ')) {
          throw UnauthorizedException('Missing bearer token');
        }
        final payload = jwt.verify(auth.substring(7));
        final userId = payload['sub'] as String? ?? payload['userId'] as String?;
        final userRoles = (payload['roles'] as List?)?.cast<String>() ?? [];
        if (userId == null) throw UnauthorizedException('Invalid JWT payload');
        if (roles.isNotEmpty && !roles.any(userRoles.contains)) {
          throw ForbiddenException('Missing required role');
        }
        return next(ctx.withAuth(userId: userId, roles: userRoles));
      };
}

/// Cookie-based session middleware.
class SessionMiddleware extends Middleware {
  SessionMiddleware(this.store, {this.cookieName = 'session_id'});

  final SessionStore store;
  final String cookieName;

  @override
  MiddlewareHandler get handler => (ctx, next) async {
        final cookie = ctx.cookie(cookieName);
        if (cookie != null) {
          final session = store.get(cookie);
          if (session != null) {
            return next(ctx.withAuth(userId: session.userId));
          }
        }
        return next(ctx);
      };
}
