import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

import 'errors.dart';

/// Per-request context with params, body, headers, and DI access.
class RequestContext {
  RequestContext({
    required this.method,
    required this.path,
    required this.headers,
    required this.queryParameters,
    required this.pathParameters,
    required this.bodyBytes,
    required this.container,
    this.userId,
    this.roles = const [],
  });

  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, String> queryParameters;
  final Map<String, String> pathParameters;
  final List<int> bodyBytes;
  final dynamic container;
  final String? userId;
  final List<String> roles;

  String? param(String name) => pathParameters[name];

  String? query(String name) => queryParameters[name];

  Map<String, dynamic> jsonBody() {
    if (bodyBytes.isEmpty) return {};
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      throw BadRequestException('Expected JSON object body');
    } catch (e) {
      if (e is FrameworkException) rethrow;
      throw BadRequestException('Invalid JSON body');
    }
  }

  T resolve<T>() => container.resolve<T>() as T;

  bool hasRole(String role) => roles.contains(role);

  shelf.Request toShelfRequest(Uri uri) {
    return shelf.Request(
      method,
      uri,
      headers: headers,
      body: bodyBytes,
    );
  }
}
