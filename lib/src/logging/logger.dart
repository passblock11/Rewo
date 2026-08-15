import 'dart:convert';
import 'dart:developer' as developer;

/// Structured JSON logging for production.
class Logger {
  Logger(this.name);

  final String name;

  void info(String message, {Map<String, dynamic>? data}) =>
      _log('INFO', message, data);

  void warn(String message, {Map<String, dynamic>? data}) =>
      _log('WARN', message, data);

  void error(String message, {Map<String, dynamic>? data, Object? error}) =>
      _log('ERROR', message, {...?data, if (error != null) 'error': error.toString()});

  void _log(String level, String message, Map<String, dynamic>? data) {
    final entry = {
      'level': level,
      'logger': name,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      if (data != null) ...data,
    };
    developer.log(jsonEncode(entry));
  }
}
