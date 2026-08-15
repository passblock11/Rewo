import 'dart:io';

import '../errors.dart';
import '../errors/error_report.dart';
import '../http/response.dart';
import 'middleware.dart';

/// Catches framework errors and returns JSON error responses.
class ErrorMiddleware extends Middleware {
  ErrorMiddleware({this.development = false});

  /// When true, responses include file, line, type, hint, and stack trace.
  final bool development;

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
          final report = ErrorReport.from(e, st);

          // ignore: avoid_print
          print(report.formatConsole(method: ctx.method, path: ctx.path));
          if (development) {
            // ignore: avoid_print
            print(report.stackTrace);
          }

          if (development) {
            return AppResponse.json(
              report.toJson(method: ctx.method, path: ctx.path),
              statusCode: 500,
            );
          }

          return AppResponse.json(
            {'error': 'Internal server error'},
            statusCode: 500,
          );
        }
      };
}

/// Whether detailed errors should be shown (dev server or non-production env).
bool developmentErrorDetails({required bool isProduction}) {
  if (!isProduction) return true;
  return Platform.environment['REWO_HOT_CHILD'] == '1';
}
