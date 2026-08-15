import '../errors.dart';
import '../http/response.dart';
import 'middleware.dart';

/// Catches framework errors and returns JSON error responses.
class ErrorMiddleware extends Middleware {
  @override
  MiddlewareHandler get handler => (ctx, next) async {
        try {
          return await next(ctx);
        } on FrameworkException catch (e) {
          if (e is ValidationException) {
            return AppResponse.json(
              {'error': e.message, 'fields': e.errors},
              statusCode: e.statusCode,
            );
          }
          return AppResponse.json(
            {'error': e.message},
            statusCode: e.statusCode,
          );
        } catch (e, st) {
          // ignore: avoid_print
          print('Unhandled error: $e\n$st');
          return AppResponse.json(
            {'error': 'Internal server error'},
            statusCode: 500,
          );
        }
      };
}
