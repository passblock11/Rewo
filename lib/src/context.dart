import 'dart:convert';
import 'dart:typed_data';

import 'package:shelf/shelf.dart' as shelf;

import 'errors.dart';
import 'http/multipart.dart';

/// Per-request context with params, body, headers, and DI access.
class RequestContext {
  RequestContext({
    required this.method,
    required this.path,
    required this.headers,
    required this.queryParameters,
    required this.pathParameters,
    required this.container,
    List<int>? bodyBytes,
    Future<List<int>> Function()? bodyLoader,
    this.userId,
    this.roles = const [],
    this.requestId,
    this.multipart,
  })  : _bodyBytes = bodyBytes,
        _bodyLoader = bodyLoader;

  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, String> queryParameters;
  final Map<String, String> pathParameters;
  final dynamic container;
  final String? userId;
  final List<String> roles;
  final String? requestId;
  final MultipartForm? multipart;

  List<int>? _bodyBytes;
  final Future<List<int>> Function()? _bodyLoader;
  Map<String, dynamic>? _jsonCache;

  Future<List<int>> get bodyBytes async {
    if (_bodyBytes != null) return _bodyBytes!;
    if (_bodyLoader != null) {
      _bodyBytes = await _bodyLoader();
      return _bodyBytes!;
    }
    return _bodyBytes ??= [];
  }

  String? param(String name) => pathParameters[name];
  String? query(String name) => queryParameters[name];

  /// Read a cookie value from the Cookie header.
  String? cookie(String name) {
    final raw = headers['cookie'];
    if (raw == null) return null;
    for (final part in raw.split(';')) {
      final kv = part.trim().split('=');
      if (kv.length == 2 && kv[0].trim() == name) return kv[1].trim();
    }
    return null;
  }

  Future<Map<String, dynamic>> jsonBody() async {
    if (_jsonCache != null) return _jsonCache!;
    final bytes = await bodyBytes;
    if (bytes.isEmpty) return _jsonCache = {};
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, dynamic>) return _jsonCache = decoded;
      throw BadRequestException('Expected JSON object body');
    } catch (e) {
      if (e is FrameworkException) rethrow;
      throw BadRequestException('Invalid JSON body');
    }
  }

  Future<T> bodyAs<T>(T Function(Map<String, dynamic> json) fromJson) async {
    return fromJson(await jsonBody());
  }

  T resolve<T>() => container.resolve<T>() as T;
  bool hasRole(String role) => roles.contains(role);

  RequestContext withAuth({required String userId, List<String> roles = const []}) {
    return _copy(userId: userId, roles: roles);
  }

  RequestContext withMultipart(MultipartForm form) => _copy(multipart: form);

  RequestContext withRequestId(String id) => _copy(requestId: id);

  RequestContext _copy({
    String? userId,
    List<String>? roles,
    String? requestId,
    MultipartForm? multipart,
    Map<String, String>? headers,
  }) {
    return RequestContext(
      method: method,
      path: path,
      headers: headers ?? this.headers,
      queryParameters: queryParameters,
      pathParameters: pathParameters,
      container: container,
      bodyBytes: _bodyBytes,
      bodyLoader: _bodyBytes == null ? _bodyLoader : null,
      userId: userId ?? this.userId,
      roles: roles ?? this.roles,
      requestId: requestId ?? this.requestId,
      multipart: multipart ?? this.multipart,
    ).._jsonCache = _jsonCache;
  }

  shelf.Request toShelfRequest(Uri uri) {
    return shelf.Request(method, uri, headers: headers, body: _bodyBytes);
  }
}

Map<String, String> buildHeaderMap(Map<String, List<String>> headersAll) {
  final map = <String, String>{};
  for (final entry in headersAll.entries) {
    map[entry.key.toLowerCase()] =
        entry.value.length == 1 ? entry.value.first : entry.value.join(',');
  }
  return map;
}

class BodyReader {
  static Future<List<int>> read(Stream<List<int>> stream) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}

/// Build a Set-Cookie header value.
String setCookie(String name, String value, {Duration maxAge = const Duration(hours: 24)}) {
  return '$name=$value; HttpOnly; Path=/; Max-Age=${maxAge.inSeconds}; SameSite=Lax';
}
