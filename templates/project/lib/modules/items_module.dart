import 'package:rewo/rewo.dart';

/// Example API module — copy this file to add more resources.
class ItemsModule implements RewoModule {
  @override
  String get name => 'items';

  final _items = <Map<String, dynamic>>[];

  @override
  void register(Rewo app) {
    app.get('/api/items', (_) async => _items);

    app.post('/api/items', (ctx) async {
      final body = await ctx.jsonBody();
      final title = body['title'] as String? ?? '';
      if (title.isEmpty) throw BadRequestException('title is required');
      final item = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
      };
      _items.add(item);
      return item;
    });

    app.get('/api/items/:id', (ctx) async {
      final id = ctx.param('id')!;
      for (final item in _items) {
        if (item['id'] == id) return item;
      }
      throw NotFoundException('Item $id not found');
    });
  }
}
