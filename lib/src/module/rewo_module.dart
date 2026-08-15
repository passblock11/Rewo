import '../application.dart';

/// A pluggable API module. Create one per feature, register in [moduleRegistry].
abstract class RewoModule {
  String get name;

  /// Register routes, services, and event listeners on the app.
  void register(Rewo app);
}
