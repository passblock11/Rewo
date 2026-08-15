import 'dart:convert';

import '../context.dart';
import '../middleware/middleware.dart';

/// Parses multipart/form-data uploads from request body.
class MultipartParser {
  static Future<MultipartForm> parse(RequestContext ctx) async {
    final contentType = ctx.headers['content-type'] ?? '';
    if (!contentType.startsWith('multipart/form-data')) {
      throw ArgumentError('Expected multipart/form-data');
    }

    final boundaryMatch = RegExp(r'boundary=(.+)$').firstMatch(contentType);
    if (boundaryMatch == null) throw ArgumentError('Missing boundary');
    final boundary = '--${boundaryMatch.group(1)}';
    final bytes = await ctx.bodyBytes;
    final text = utf8.decode(bytes);
    final parts = text.split(boundary).where((p) => p.trim().isNotEmpty && p.trim() != '--');

    final fields = <String, String>{};
    final files = <String, MultipartFile>{};

    for (final part in parts) {
      final sections = part.split('\r\n\r\n');
      if (sections.length < 2) continue;
      final headers = sections.first;
      final body = sections.sublist(1).join('\r\n\r\n').replaceAll('\r\n--', '').trim();

      final nameMatch = RegExp(r'name="([^"]+)"').firstMatch(headers);
      if (nameMatch == null) continue;
      final name = nameMatch.group(1)!;

      final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(headers);
      if (filenameMatch != null) {
        files[name] = MultipartFile(
          fieldName: name,
          filename: filenameMatch.group(1)!,
          bytes: utf8.encode(body),
        );
      } else {
        fields[name] = body;
      }
    }

    return MultipartForm(fields: fields, files: files);
  }
}

class MultipartForm {
  MultipartForm({required this.fields, required this.files});
  final Map<String, String> fields;
  final Map<String, MultipartFile> files;
}

class MultipartFile {
  MultipartFile({required this.fieldName, required this.filename, required this.bytes});
  final String fieldName;
  final String filename;
  final List<int> bytes;
}

/// Middleware that parses multipart and attaches to context extensions.
MiddlewareHandler multipartParser() {
  return (ctx, next) async {
    final contentType = ctx.headers['content-type'] ?? '';
    if (contentType.startsWith('multipart/form-data')) {
      final form = await MultipartParser.parse(ctx);
      return next(ctx.withMultipart(form));
    }
    return next(ctx);
  };
}
