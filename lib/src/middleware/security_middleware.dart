import 'package:shelf/shelf.dart' as shelf;

import '../context.dart';
import '../errors.dart';
import '../http/response.dart';
import 'middleware.dart';

/// Rate limiting middleware — token bucket per IP.
class RateLimitMiddleware extends Middleware {
  RateLimitMiddleware({this.maxRequests = 100, this.window = const Duration(minutes: 1)});

  final int maxRequests;
  final Duration window;
  final Map<String, _Bucket> _buckets = {};

  @override
  MiddlewareHandler get handler => (ctx, next) async {
        final key = ctx.headers['x-forwarded-for'] ?? ctx.headers['x-real-ip'] ?? 'local';
        final bucket = _buckets.putIfAbsent(key, () => _Bucket(maxRequests, window));
        if (!bucket.allow()) {
          return AppResponse.json(
            {'error': 'Too many requests'},
            statusCode: 429,
            headers: {'retry-after': '${window.inSeconds}'},
          );
        }
        return next(ctx);
      };
}

class _Bucket {
  _Bucket(this.max, this.window) : resetAt = DateTime.now().add(window);
  final int max;
  final Duration window;
  int count = 0;
  DateTime resetAt;

  bool allow() {
    final now = DateTime.now();
    if (now.isAfter(resetAt)) {
      count = 0;
      resetAt = now.add(window);
    }
    return ++count <= max;
  }
}

/// Adds security headers (Helmet-style).
class SecurityHeadersMiddleware extends Middleware {
  @override
  MiddlewareHandler get handler => (ctx, next) async {
        final response = await next(ctx);
        return response.change(headers: {
          'x-content-type-options': 'nosniff',
          'x-frame-options': 'DENY',
          'x-xss-protection': '1; mode=block',
          'referrer-policy': 'strict-origin-when-cross-origin',
        });
      };
}

/// Adds a unique request ID to every request.
class RequestIdMiddleware extends Middleware {
  static int _counter = 0;

  @override
  MiddlewareHandler get handler => (ctx, next) async {
        final id = ctx.headers['x-request-id'] ??
            'req-${++_counter}-${DateTime.now().millisecondsSinceEpoch}';
        final response = await next(ctx.withRequestId(id));
        return response.change(headers: {'x-request-id': id});
      };
}

/// Aborts requests that exceed [timeout].
class TimeoutMiddleware extends Middleware {
  TimeoutMiddleware({this.timeout = const Duration(seconds: 30)});

  final Duration timeout;

  @override
  MiddlewareHandler get handler => (ctx, next) async {
        return next(ctx).timeout(timeout, onTimeout: () {
          throw FrameworkException('Request timeout', statusCode: 408);
        });
      };
}

/// Structured request logging with request ID.
class StructuredLoggingMiddleware extends Middleware {
  StructuredLoggingMiddleware();

  @override
  MiddlewareHandler get handler => (ctx, next) async {
        final sw = Stopwatch()..start();
        final response = await next(ctx);
        sw.stop();
        // ignore: avoid_print
        print(jsonLog({
          'requestId': ctx.requestId,
          'method': ctx.method,
          'path': ctx.path,
          'status': response.statusCode,
          'durationMs': sw.elapsedMilliseconds,
        }));
        return response;
      };

  String jsonLog(Map<String, dynamic> data) => data.entries.map((e) => '${e.key}=${e.value}').join(' ');
}
