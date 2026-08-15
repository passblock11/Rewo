import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// Scaffolds a new Rewo project (Express-style `create` command).
class CreateProjectCommand {
  CreateProjectCommand({
    required this.projectName,
    this.outputDir,
    this.frameworkPath,
    this.frameworkGitUrl,
    this.description,
    this.frameworkVersion = latestPublishedVersion,
  });

  final String projectName;
  final String? outputDir;
  final String? frameworkPath;
  final String? frameworkGitUrl;
  final String? description;
  final String frameworkVersion;

  /// Keep in sync with [pubspec.yaml] version when publishing.
  static const latestPublishedVersion = '1.0.9';

  String get snakeName => _toSnakeCase(projectName);
  String get titleName => _toTitleCase(projectName);

  Future<String> run() async {
    _validateName();

    final target = Directory(p.join(outputDir ?? '.', snakeName));
    if (target.existsSync()) {
      throw StateError('Directory already exists: ${target.path}');
    }

    final packageRoot = await _packageRoot();
    final templateDir = Directory(p.join(packageRoot, 'templates', 'project'));
    if (!templateDir.existsSync()) {
      throw StateError('Templates not found at ${templateDir.path}');
    }

    await _copyTemplate(templateDir, target);
    return target.path;
  }

  void _validateName() {
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(snakeName)) {
      throw ArgumentError(
        'Project name must be lowercase letters, numbers, and underscores '
        '(e.g. my_api). Got: $projectName',
      );
    }
  }

  Future<String> _packageRoot() async {
    final libUri = await Isolate.resolvePackageUri(
      Uri.parse('package:rewo/rewo.dart'),
    );
    if (libUri == null) {
      throw StateError('Could not resolve rewo package');
    }
    final libFile = File.fromUri(libUri);
    return libFile.parent.parent.path;
  }

  Future<void> _copyTemplate(Directory source, Directory target) async {
    await for (final entity in source.list(recursive: true)) {
      final relative = p.relative(entity.path, from: source.path);
      final destPath = p.join(target.path, _substitute(relative));
      if (entity is Directory) {
        await Directory(destPath).create(recursive: true);
      } else if (entity is File) {
        await Directory(p.dirname(destPath)).create(recursive: true);
        final content = await entity.readAsString();
        await File(destPath).writeAsString(_substitute(content));
      }
    }
  }

  String _substitute(String input) {
    var result = input
        .replaceAll('example_app', snakeName)
        .replaceAll('{{title}}', titleName)
        .replaceAll('{{description}}', description ?? 'A Rewo API project');
    if (input.contains('dependencies:') && input.contains('rewo:')) {
      result = _injectDependencies(result);
    }
    return result;
  }

  String _injectDependencies(String pubspec) {
    return pubspec.replaceFirst(
      RegExp(r'  rewo:\n(?:    .+\n)+'),
      '${_dependenciesBlock()}\n',
    );
  }

  String _dependenciesBlock() {
    if (frameworkPath != null) {
      final abs = p.normalize(p.absolute(frameworkPath!));
      return '  rewo:\n    path: $abs';
    }
    if (frameworkGitUrl != null) {
      return '''  rewo:
    git:
      url: $frameworkGitUrl''';
    }
    return '  rewo: ^$frameworkVersion';
  }

  static String _toSnakeCase(String name) {
    return name
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        .toLowerCase();
  }

  static String _toTitleCase(String name) {
    return _toSnakeCase(name)
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
