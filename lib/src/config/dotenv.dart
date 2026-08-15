import 'dart:io';

/// Loads key=value pairs from a `.env` file into [Platform.environment].
///
/// ```dart
/// await DotEnv.load(); // loads .env from project root
/// final port = DotEnv.get('PORT', fallback: '8080');
/// ```
class DotEnv {
  DotEnv._();

  static final Map<String, String> _values = {};
  static bool _loaded = false;

  /// Load `.env` file. Later entries do not override existing env vars.
  static Future<void> load([String path = '.env']) async {
    final file = File(path);
    if (!file.existsSync()) {
      _loaded = true;
      return;
    }

    _values.clear();
    final lines = await file.readAsLines();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx <= 0) continue;
      final key = trimmed.substring(0, idx).trim();
      var value = trimmed.substring(idx + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      _values[key] = value;
    }
    _loaded = true;
  }

  static String get(String key, {String fallback = ''}) {
    return Platform.environment[key] ?? _values[key] ?? fallback;
  }

  static int getInt(String key, {int fallback = 0}) =>
      int.tryParse(get(key)) ?? fallback;

  static bool getBool(String key, {bool fallback = false}) {
    final v = get(key).toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
    return fallback;
  }

  static bool get isLoaded => _loaded;

  /// Validates required keys exist. Throws if any are missing.
  static void requireAll(List<String> keys) {
    final missing = keys.where((k) => get(k).isEmpty).toList();
    if (missing.isNotEmpty) {
      throw StateError('Missing required env vars: ${missing.join(', ')}');
    }
  }
}
