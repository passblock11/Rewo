/// Framework-specific exceptions.
class FrameworkException implements Exception {
  FrameworkException(this.message, {this.statusCode = 500});
  final String message;
  final int statusCode;

  @override
  String toString() => 'FrameworkException($statusCode): $message';
}

class NotFoundException extends FrameworkException {
  NotFoundException(String message) : super(message, statusCode: 404);
}

class BadRequestException extends FrameworkException {
  BadRequestException(String message) : super(message, statusCode: 400);
}

class UnauthorizedException extends FrameworkException {
  UnauthorizedException([String message = 'Unauthorized'])
      : super(message, statusCode: 401);
}

class ForbiddenException extends FrameworkException {
  ForbiddenException([String message = 'Forbidden'])
      : super(message, statusCode: 403);
}

class ValidationException extends FrameworkException {
  ValidationException(this.errors) : super('Validation failed', statusCode: 422);
  final Map<String, String> errors;
}
