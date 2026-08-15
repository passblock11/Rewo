import 'package:rewo/rewo.dart';
import 'package:rewo/src/errors/error_report.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorReport', () {
    test('finds user source frame and formats dev output', () {
      try {
        throw StateError('boom');
      } catch (e, st) {
        final report = ErrorReport.from(e, st);
        expect(report.type, 'StateError');
        expect(report.message, 'boom');
        expect(
          report.formatConsole(method: 'POST', path: '/api/json_data'),
          contains('POST /api/json_data failed'),
        );
      }
    });

    test('parses package frame into lib path', () {
      const stack = '''
#0      GetJsonDataModule.register.<anonymous closure> (package:dart_serve_testing/modules/get_json_data.dart:27:33)
#1      Rewo._handleShelf.<anonymous closure> (package:rewo/src/application.dart:264:22)
''';

      final report = ErrorReport.from(
        TypeError(),
        StackTrace.fromString(stack),
      );

      expect(report.source?.file, 'lib/modules/get_json_data.dart');
      expect(report.source?.line, 27);
      expect(report.source?.column, 33);
      expect(
        report.source?.symbol,
        'GetJsonDataModule.register.<anonymous closure>',
      );
    });

    test('adds hint for null check operator errors', () {
      final report = ErrorReport.from(
        TypeError(),
        StackTrace.empty,
      );

      expect(report.hint, isNotNull);
      expect(report.hint, contains('null'));
    });
  });

  group('ErrorMiddleware', () {
    test('returns detailed JSON in development mode', () async {
      final testApp = await TestApp.create(
        (app) {
          app.get('/fail', (_) async {
            throw StateError('test failure');
          });
        },
        config: AppConfig(environment: 'development'),
      );

      final response = await testApp.call('GET', '/fail');
      expect(response, isA<Map<String, dynamic>>());

      final body = response as Map<String, dynamic>;
      expect(body['error'], 'test failure');
      expect(body['type'], 'StateError');
      expect(body['request'], {'method': 'GET', 'path': '/fail'});
      expect(body['stack'], isNotEmpty);
    });

    test('hides details in production mode', () async {
      final testApp = await TestApp.create(
        (app) {
          app.get('/fail', (_) async {
            throw StateError('secret failure');
          });
        },
        config: AppConfig(environment: 'production'),
      );

      final response = await testApp.call('GET', '/fail');
      expect(response, {'error': 'Internal server error'});
    });
  });
}
