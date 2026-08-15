import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;

import '../context.dart';
import '../http/response.dart';
import '../storage/storage.dart';
import 'middleware.dart';

/// Serves static files from a directory at [prefix].
class StaticFilesMiddleware extends Middleware {
  StaticFilesMiddleware(this.root, {this.prefix = '/public'});

  final String root;
  final String prefix;

  @override
  MiddlewareHandler get handler => (ctx, next) async {
        if (!ctx.path.startsWith(prefix)) return next(ctx);
        final relative = ctx.path.substring(prefix.length);
        if (relative.contains('..')) {
          return AppResponse.json({'error': 'Forbidden'}, statusCode: 403);
        }
        final file = File(p.join(root, relative));
        if (!file.existsSync()) return next(ctx);
        final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
        final bytes = await file.readAsBytes();
        return shelf.Response.ok(bytes, headers: {
          'content-type': mime,
          'cache-control': 'public, max-age=3600',
        });
      };
}

/// Serve files from [Storage] at [prefix].
MiddlewareHandler storageFiles(Storage storage, {String prefix = '/files'}) {
  return (ctx, next) async {
    if (!ctx.path.startsWith(prefix)) return next(ctx);
    final relative = ctx.path.substring(prefix.length).replaceFirst('/', '');
    if (relative.contains('..') || !await storage.exists(relative)) {
      return AppResponse.json({'error': 'Not found'}, statusCode: 404);
    }
    final bytes = await storage.read(relative);
    final mime = lookupMimeType(relative) ?? 'application/octet-stream';
    return shelf.Response.ok(bytes, headers: {'content-type': mime});
  };
}
