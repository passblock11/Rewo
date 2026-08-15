import 'dart:convert';

import '../errors.dart';
import 'middleware.dart';

/// Simple token-based auth middleware (Bearer token = base64 userId:roles).
class AuthMiddleware extends Middleware {
  AuthMiddleware({this.optional = false});

  final bool optional;

  @override
  MiddlewareHandler get handler => (ctx, next) async {
        final auth = ctx.headers['authorization'];
        if (auth == null || !auth.startsWith('Bearer ')) {
          if (optional) return next(ctx);
          throw UnauthorizedException('Missing bearer token');
        }

        final token = auth.substring(7);
        try {
          final decoded = utf8.decode(base64Decode(token));
          final parts = decoded.split(':');
          final userId = parts.first;
          final roles = parts.length > 1 ? parts.sublist(1) : <String>[];

          return next(ctx.withAuth(userId: userId, roles: roles));
        } catch (_) {
          throw UnauthorizedException('Invalid token');
        }
      };
}

/// Role-based access middleware factory.
MiddlewareHandler roleGuard(List<String> requiredRoles) {
  return (ctx, next) async {
    if (ctx.userId == null) {
      throw UnauthorizedException();
    }
    final hasRole = requiredRoles.any(ctx.hasRole);
    if (!hasRole) {
      throw ForbiddenException('Missing required role');
    }
    return next(ctx);
  };
}

/// Creates a bearer token for testing/demo.
String createAuthToken(String userId, {List<String> roles = const []}) {
  return base64Encode(utf8.encode('$userId:${roles.join(':')}'));
}
