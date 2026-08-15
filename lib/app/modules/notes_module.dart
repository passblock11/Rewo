import 'dart:convert';

import 'package:rewo/rewo.dart';

class NotesModule implements RewoModule {
  @override
  String get name => 'notes';

  @override
  void register(Rewo app) {
    final storage = app.container.resolve<Storage>();

    app.post('/api/notes', (ctx) async {
      final body = await ctx.jsonBody();
      final text = body['text'] as String? ?? '';
      if (text.isEmpty) throw BadRequestException('text is required');
      final path = 'notes/${DateTime.now().millisecondsSinceEpoch}.txt';
      await storage.write(path, utf8.encode(text));
      return {'saved': true, 'path': path, 'url': storage.url(path)};
    });

    app.get('/api/notes/:name', (ctx) async {
      final name = ctx.param('name')!;
      final path = 'notes/$name';
      if (!await storage.exists(path)) throw NotFoundException('Note not found');
      final content = utf8.decode(await storage.read(path));
      return {'name': name, 'content': content};
    });
  }
}
