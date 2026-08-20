import '../context.dart';
import '../middleware/middleware.dart';

typedef RouteHandler = Future<dynamic> Function(RequestContext ctx);

/// Compiled route used by all server engines (Shelf, native, HTTP/2).
class CompiledRoute {
  CompiledRoute({
    required this.method,
    required this.path,
    required this.handler,
    required this.middleware,
    required this.statusCode,
    required this.pipeline,
  }) : segments = path.split('/').where((s) => s.isNotEmpty).toList();

  final String method;
  final String path;
  final RouteHandler handler;
  final List<MiddlewareHandler> middleware;
  final int statusCode;
  final MiddlewarePipeline pipeline;
  final List<String> segments;

  bool get isStatic => !path.contains(':');

  Map<String, String> extractParams(String actualPath) {
    final actualSegments =
        actualPath.split('/').where((s) => s.isNotEmpty).toList();
    final params = <String, String>{};
    if (segments.length != actualSegments.length) return params;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.startsWith(':')) {
        params[segment.substring(1)] = actualSegments[i];
      }
    }
    return params;
  }

  bool matches(String method, String path) {
    if (this.method != method) return false;
    if (segments.length != path.split('/').where((s) => s.isNotEmpty).length) {
      return false;
    }
    final actualSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.startsWith(':')) continue;
      if (segment != actualSegments[i]) return false;
    }
    return true;
  }
}

/// O(1) static route lookup + linear scan for param routes.
class RouteTable {
  final Map<String, Map<String, CompiledRoute>> _static = {};
  final List<CompiledRoute> _dynamic = [];

  void add(CompiledRoute route) {
    if (route.isStatic) {
      _static.putIfAbsent(route.method, () => {})[route.path] = route;
    } else {
      _dynamic.add(route);
    }
  }

  void clear() {
    _static.clear();
    _dynamic.clear();
  }

  CompiledRoute? match(String method, String path) {
    final normalized = normalizePath(path);
    final hit = _static[method]?[normalized];
    if (hit != null) return hit;
    for (final route in _dynamic) {
      if (route.matches(method, normalized)) return route;
    }
    return null;
  }

  List<CompiledRoute> get all => [
        for (final m in _static.values) ...m.values,
        ..._dynamic,
      ];
}

String normalizePath(String path) {
  var p = path.trim();
  if (!p.startsWith('/')) p = '/$p';
  p = p.replaceAll(RegExp(r'/+'), '/');
  if (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

String toShelfPath(String path) {
  return normalizePath(path)
      .replaceAllMapped(RegExp(r':(\w+)'), (m) => '<${m[1]}>');
}
