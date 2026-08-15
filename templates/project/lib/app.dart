import 'package:rewo/rewo.dart';

import 'modules/items_module.dart';

/// Application entry — register your modules here.
class App {
  static List<RewoModule> get modules => [
        ItemsModule(),
      ];

  static Future<Rewo> run({int? port}) => RewoBootstrap.run(
        modules: modules,
        serviceName: '{{title}}',
        port: port,
      );

  /// For tests — starts server without signal handlers.
  static Future<Rewo> bootstrap({int? port}) => RewoBootstrap.start(
        modules: modules,
        serviceName: '{{title}}',
        port: port,
      );
}
