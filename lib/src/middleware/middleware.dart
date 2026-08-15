import 'package:shelf/shelf.dart' as shelf;

import '../context.dart';

typedef NextHandler = Future<shelf.Response> Function(RequestContext ctx);
typedef MiddlewareHandler = Future<shelf.Response> Function(
  RequestContext ctx,
  NextHandler next,
);

/// Base class for middleware.
abstract class Middleware {
  MiddlewareHandler get handler;
}

class MiddlewarePipeline {
  MiddlewarePipeline(this._middlewares);

  final List<MiddlewareHandler> _middlewares;

  Future<shelf.Response> run(
    RequestContext ctx,
    Future<shelf.Response> Function(RequestContext ctx) terminal,
  ) async {
    Future<shelf.Response> dispatch(int index, RequestContext current) {
      if (index >= _middlewares.length) {
        return terminal(current);
      }
      return _middlewares[index](current, (nextCtx) => dispatch(index + 1, nextCtx));
    }

    return dispatch(0, ctx);
  }
}
