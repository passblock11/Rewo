import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

/// HTTP response helpers — optimized for minimal allocations.
class AppResponse {
  AppResponse._();

  static const _jsonContentType = 'application/json; charset=utf-8';
  static const _textContentType = 'text/plain; charset=utf-8';

  static final _jsonHeaderCache = Map<String, List<String>>.unmodifiable({
    'content-type': [_jsonContentType],
  });

  static shelf.Response json(
    Object? data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final body = utf8.encode(jsonEncode(data));
    return shelf.Response(
      statusCode,
      body: body,
      headers: headers == null
          ? _jsonHeaderCache
          : {
              'content-type': _jsonContentType,
              ...headers,
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
        'content-type': _textContentType,
        ...?headers,
      },
    );
  }

  static shelf.Response noContent() => shelf.Response(204);

  static shelf.Response redirect(String location, {int statusCode = 302}) {
    return shelf.Response(statusCode, headers: {'location': location});
  }

  static shelf.Response fromHandlerResult(dynamic result,
      {int statusCode = 200}) {
    if (result == null) return noContent();
    if (result is shelf.Response) return result;
    if (result is String) return text(result, statusCode: statusCode);
    if (result is Map || result is List) {
      return json(result, statusCode: statusCode);
    }
    try {
      // ignore: avoid_dynamic_calls
      final encoded = (result as dynamic).toJson();
      if (encoded is Map || encoded is List) {
        return json(encoded, statusCode: statusCode);
      }
    } catch (_) {}
    return text(result.toString(), statusCode: statusCode);
  }
}
