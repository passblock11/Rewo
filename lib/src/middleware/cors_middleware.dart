import 'package:shelf/shelf.dart' as shelf;

import '../context.dart';
import 'middleware.dart';

/// Adds CORS headers to responses.
class CorsMiddleware extends Middleware {
  CorsMiddleware({
    this.allowedOrigins = const ['*'],
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    this.allowedHeaders = const ['*'],
  });

  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;

  @override
  MiddlewareHandler get handler => (ctx, next) async {
        if (ctx.method == 'OPTIONS') {
          return shelf.Response(204, headers: _corsHeaders(ctx));
        }
        final response = await next(ctx);
        return response.change(headers: {
          ...response.headers,
          ..._corsHeaders(ctx),
        });
      };

  Map<String, String> _corsHeaders(RequestContext ctx) {
    final origin = ctx.headers['origin'] ?? ctx.headers['Origin'] ?? '*';
    final allowOrigin = allowedOrigins.contains('*') ||
            allowedOrigins.contains(origin)
        ? origin
        : allowedOrigins.first;

    return {
      'access-control-allow-origin': allowOrigin,
      'access-control-allow-methods': allowedMethods.join(', '),
      'access-control-allow-headers': allowedHeaders.join(', '),
    };
  }
}
