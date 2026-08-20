import '../middleware/middleware.dart';
import 'route_table.dart';
import 'websocket.dart';

class CompiledWebSocketRoute {
  CompiledWebSocketRoute({
    required this.path,
    required this.handler,
    required this.middleware,
    required this.pipeline,
  }) : segments = path.split('/').where((s) => s.isNotEmpty).toList();

  final String path;
  final WebSocketConnectHandler handler;
  final List<MiddlewareHandler> middleware;
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

  bool matches(String path) {
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

class WebSocketRouteTable {
  final Map<String, CompiledWebSocketRoute> _static = {};
  final List<CompiledWebSocketRoute> _dynamic = [];

  void add(CompiledWebSocketRoute route) {
    if (route.isStatic) {
      _static[route.path] = route;
    } else {
      _dynamic.add(route);
    }
  }

  void clear() {
    _static.clear();
    _dynamic.clear();
  }

  CompiledWebSocketRoute? match(String path) {
    final normalized = normalizePath(path);
    final hit = _static[normalized];
    if (hit != null) return hit;
    for (final route in _dynamic) {
      if (route.matches(normalized)) return route;
    }
    return null;
  }

  List<CompiledWebSocketRoute> get all => [..._static.values, ..._dynamic];
}
