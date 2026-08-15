import 'dart:io';

import 'package:path/path.dart' as p;

/// Abstract file storage — swap local disk for S3 later.
abstract class Storage {
  Future<void> write(String path, List<int> bytes);
  Future<List<int>> read(String path);
  Future<bool> exists(String path);
  Future<void> delete(String path);
  Future<List<String>> list(String directory);
  String url(String path);
}

/// Local disk storage with path traversal protection.
class LocalStorage implements Storage {
  LocalStorage(this.root);

  final String root;

  String _resolve(String path) {
    final normalized = p.normalize(p.join(root, path));
    final rootPath = p.normalize(root);
    if (!normalized.startsWith(rootPath)) {
      throw ArgumentError('Path traversal detected: $path');
    }
    return normalized;
  }

  @override
  Future<void> write(String path, List<int> bytes) async {
    final file = File(_resolve(path));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  @override
  Future<List<int>> read(String path) async {
    return File(_resolve(path)).readAsBytes();
  }

  @override
  Future<bool> exists(String path) async => File(_resolve(path)).existsSync();

  @override
  Future<void> delete(String path) async {
    final file = File(_resolve(path));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<List<String>> list(String directory) async {
    final dir = Directory(_resolve(directory));
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .map((f) => p.relative(f.path, from: _resolve(directory)))
        .toList();
  }

  @override
  String url(String path) => '/files/$path';
}

/// Helper for reading/writing text files.
class FileHelper {
  FileHelper(this.storage);
  final Storage storage;

  Future<String> readText(String path) async {
    return String.fromCharCodes(await storage.read(path));
  }

  Future<void> writeText(String path, String content) async {
    await storage.write(path, content.codeUnits);
  }

  Future<void> appendText(String path, String content) async {
    final existing = await storage.exists(path)
        ? String.fromCharCodes(await storage.read(path))
        : '';
    await storage.write(path, '$existing$content'.codeUnits);
  }
}
