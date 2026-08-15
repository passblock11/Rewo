/// Marks a class as a REST controller with an optional base path.
class Controller {
  const Controller([this.path = '']);
  final String path;
}

/// Marks a class for dependency injection.
class Injectable {
  const Injectable({this.scope = Scope.singleton});
  final Scope scope;
}

enum Scope { singleton, transient }

/// HTTP route annotations.
class Get {
  const Get(this.path);
  final String path;
}

class Post {
  const Post(this.path);
  final String path;
}

class Put {
  const Put(this.path);
  final String path;
}

class Delete {
  const Delete(this.path);
  final String path;
}

class Patch {
  const Patch(this.path);
  final String path;
}

/// Sets the HTTP status code for a route handler response.
class StatusCode {
  const StatusCode(this.code);
  final int code;
}

/// Marks a handler parameter as the request body (JSON).
class Body {
  const Body();
}

/// Binds a handler parameter to a path variable.
class PathParam {
  const PathParam(this.name);
  final String name;
}

/// Binds a handler parameter to a query parameter.
class QueryParam {
  const QueryParam(this.name, {this.required = false});
  final String name;
  final bool required;
}

/// Binds a handler parameter to a request header.
class HeaderParam {
  const HeaderParam(this.name, {this.required = false});
  final String name;
  final bool required;
}

/// Applies middleware to a controller or route handler.
class UseMiddleware {
  const UseMiddleware(this.middleware);
  final Type middleware;
}

/// Marks a method as scheduled (cron-like interval in seconds).
class Scheduled {
  const Scheduled(this.intervalSeconds);
  final int intervalSeconds;
}

/// Marks a method as requiring authentication / roles.
class Secured {
  const Secured({this.roles = const []});
  final List<String> roles;
}

/// Wraps a method in a transactional boundary.
class Transactional {
  const Transactional();
}

/// Marks a field for validation.
class Validate {
  const Validate({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.email = false,
    this.min,
    this.max,
  });

  final bool required;
  final int? minLength;
  final int? maxLength;
  final bool email;
  final num? min;
  final num? max;
}

/// Application entry annotation.
class DartApp {
  const DartApp();
}
