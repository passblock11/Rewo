import 'dart:io';
import 'dart:isolate';

import 'package:rewo/rewo.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dartserve_create_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('create scaffolds a runnable project', () async {
    final libUri = await Isolate.resolvePackageUri(
      Uri.parse('package:rewo/rewo.dart'),
    );
    final frameworkRoot = File.fromUri(libUri!).parent.parent.path;
    final cmd = CreateProjectCommand(
      projectName: 'my_api',
      outputDir: tempDir.path,
      frameworkPath: frameworkRoot,
      description: 'Test API',
    );

    final projectPath = await cmd.run();
    final projectDir = Directory(projectPath);

    expect(projectDir.existsSync(), isTrue);
    expect(File(p.join(projectPath, 'pubspec.yaml')).readAsStringSync(),
        contains('name: my_api'));
    expect(File(p.join(projectPath, 'bin/server.dart')).existsSync(), isTrue);
    expect(File(p.join(projectPath, 'lib/app.dart')).existsSync(), isTrue);
    expect(File(p.join(projectPath, 'lib/modules/items_module.dart')).existsSync(),
        isTrue);
    expect(File(p.join(projectPath, '.env.example')).existsSync(), isTrue);

    final pubGet = await Process.run('dart', ['pub', 'get'],
        workingDirectory: projectPath);
    expect(pubGet.exitCode, 0, reason: pubGet.stderr.toString());

    final analyze = await Process.run('dart', ['analyze'],
        workingDirectory: projectPath);
    expect(analyze.exitCode, 0, reason: analyze.stdout.toString());
  });

  test('rejects invalid project names', () {
    expect(
      () => CreateProjectCommand(projectName: '123bad').run(),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects existing directory', () async {
    final existing = Directory(p.join(tempDir.path, 'exists'));
    existing.createSync();

    final cmd = CreateProjectCommand(
      projectName: 'exists',
      outputDir: tempDir.path,
      frameworkPath: File.fromUri((await Isolate.resolvePackageUri(
        Uri.parse('package:rewo/rewo.dart'),
      ))!)
          .parent
          .parent
          .path,
    );

    expect(cmd.run(), throwsA(isA<StateError>()));
  });
}
