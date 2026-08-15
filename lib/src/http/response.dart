import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

/// HTTP response helpers.
class AppResponse {
  AppResponse._();

  static shelf.Response json(
    Object? data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return shelf.Response(
      statusCode,
      body: jsonEncode(data),
      headers: {
        'content-type': 'application/json',
        ...?headers,
      },
    );
  }

  static shelf.Response text(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return shelf.Response(
      statusCode,
      body: body,
      headers: {
        'content-type': 'text/plain; charset=utf-8',
        ...?headers,
      },
    );
  }

  static shelf.Response noContent() => shelf.Response(204);

  static shelf.Response redirect(String location, {int statusCode = 302}) {
    return shelf.Response(statusCode, headers: {'location': location});
  }

  static shelf.Response fromHandlerResult(dynamic result, {int statusCode = 200}) {
    if (result == null) return noContent();
    if (result is shelf.Response) return result;
    if (result is String) return text(result, statusCode: statusCode);
    if (result is Map || result is List) {
      return json(result, statusCode: statusCode);
    }
    if (_hasToJson(result)) {
      return json((result as dynamic).toJson(), statusCode: statusCode);
    }
    return text(result.toString(), statusCode: statusCode);
  }

  static bool _hasToJson(Object? value) {
    try {
      // ignore: avoid_dynamic_calls
      (value as dynamic).toJson;
      return true;
    } catch (_) {
      return false;
    }
  }
}
