import 'dart:developer' as developer;

import 'middleware.dart';

/// Logs incoming requests and response status.
class LoggingMiddleware extends Middleware {
  @override
  MiddlewareHandler get handler => (ctx, next) async {
        final stopwatch = Stopwatch()..start();
        developer.log('→ ${ctx.method} ${ctx.path}');
        final response = await next(ctx);
        stopwatch.stop();
        developer.log(
          '← ${ctx.method} ${ctx.path} ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
        );
        return response;
      };
}
