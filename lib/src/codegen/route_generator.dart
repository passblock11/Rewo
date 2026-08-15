import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations.dart';

const _get = TypeChecker.fromRuntime(Get);
const _post = TypeChecker.fromRuntime(Post);
const _put = TypeChecker.fromRuntime(Put);
const _delete = TypeChecker.fromRuntime(Delete);
const _patch = TypeChecker.fromRuntime(Patch);
const _status = TypeChecker.fromRuntime(StatusCode);

/// Generates route registration mixins from @Controller + @Get/@Post annotations.
class RouteGenerator extends GeneratorForAnnotation<Controller> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) return '';

    final className = element.name;
    final basePath = annotation.read('path').stringValue;
    final buffer = StringBuffer();

    buffer.writeln('mixin \$${className}Routes on RestController {');
    buffer.writeln('  @override');
    buffer.writeln('  String get basePath => \'$basePath\';');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void registerRoutes(RouteRegistrar r) {');
    buffer.writeln('    final c = this as $className;');

    for (final method in element.methods.where((m) => !m.isPrivate && !m.isStatic)) {
      final route = _readRoute(method);
      if (route == null) continue;

      final status = _readStatusCode(method);
      final statusArg = status != 200 ? ', statusCode: $status' : '';

      buffer.writeln("    r.${route.method}('${route.path}', c.${method.name}$statusArg);");
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  _RouteInfo? _readRoute(MethodElement method) {
    final get = _reader(_get, method);
    if (get != null) return _RouteInfo('get', get.read('path').stringValue);
    final post = _reader(_post, method);
    if (post != null) return _RouteInfo('post', post.read('path').stringValue);
    final put = _reader(_put, method);
    if (put != null) return _RouteInfo('put', put.read('path').stringValue);
    final del = _reader(_delete, method);
    if (del != null) return _RouteInfo('delete', del.read('path').stringValue);
    final patch = _reader(_patch, method);
    if (patch != null) return _RouteInfo('patch', patch.read('path').stringValue);
    return null;
  }

  int _readStatusCode(MethodElement method) {
    final reader = _reader(_status, method);
    if (reader == null) return 200;
    return reader.read('code').intValue;
  }

  ConstantReader? _reader(TypeChecker checker, Element element) {
    final object = checker.firstAnnotationOf(element);
    if (object == null) return null;
    return ConstantReader(object);
  }
}

class _RouteInfo {
  _RouteInfo(this.method, this.path);
  final String method;
  final String path;
}

Builder routeBuilder(BuilderOptions options) =>
    SharedPartBuilder([RouteGenerator()], 'routes');
