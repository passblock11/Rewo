import 'dart:convert';

import '../http/route_table.dart';

/// Generates OpenAPI 3.0 spec from registered routes.
class OpenApiGenerator {
  OpenApiGenerator({this.title = 'Rewo API', this.version = '1.0.0'});

  final String title;
  final String version;

  Map<String, dynamic> generate(RouteTable table) {
    final paths = <String, dynamic>{};

    for (final route in table.all) {
      final openapiPath = route.path.replaceAllMapped(
        RegExp(r':(\w+)'),
        (m) => '{${m[1]}}',
      );
      paths.putIfAbsent(openapiPath, () => {});
      paths[openapiPath]![route.method.toLowerCase()] = {
        'summary': '${route.method} $openapiPath',
        'responses': {
          '${route.statusCode}': {'description': 'Success'},
        },
      };
    }

    return {
      'openapi': '3.0.0',
      'info': {'title': title, 'version': version},
      'paths': paths,
    };
  }

  String toJson(RouteTable table) => jsonEncode(generate(table));
}
