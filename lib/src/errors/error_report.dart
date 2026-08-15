/// Parsed details for an unhandled exception — used in dev error responses.
class ErrorReport {
  ErrorReport({
    required this.message,
    required this.type,
    this.source,
    this.hint,
    required this.stackTrace,
  });

  final String message;
  final String type;
  final ErrorSource? source;
  final String? hint;
  final String stackTrace;

  Map<String, dynamic> toJson({
    required String method,
    required String path,
    bool includeStack = true,
  }) {
    return {
      'error': message,
      'type': type,
      'request': {'method': method, 'path': path},
      if (source != null) ...{
        'file': source!.file,
        'line': source!.line,
        'column': source!.column,
        'symbol': source!.symbol,
      },
      if (hint != null) 'hint': hint,
      if (includeStack) 'stack': stackTrace,
    };
  }

  String formatConsole({required String method, required String path}) {
    final buffer = StringBuffer()
      ..writeln('❌ $method $path failed')
      ..writeln('   $type: $message');

    final src = source;
    if (src != null) {
      buffer.writeln('   at ${src.file}:${src.line}:${src.column}');
      buffer.writeln('   in ${src.symbol}');
    }

    final hintText = hint;
    if (hintText != null) {
      buffer.writeln('   hint: $hintText');
    }

    return buffer.toString().trimRight();
  }

  static ErrorReport from(Object error, StackTrace stack) {
    final stackText = stack.toString();
    return ErrorReport(
      message: _messageFor(error),
      type: error.runtimeType.toString(),
      source: _findSourceFrame(stackText),
      hint: _hintFor(error),
      stackTrace: stackText,
    );
  }
}

class ErrorSource {
  ErrorSource({
    required this.file,
    required this.line,
    required this.column,
    required this.symbol,
  });

  final String file;
  final int line;
  final int column;
  final String symbol;
}

final _framePattern = RegExp(r'^#(\d+)\s+(.+?)\s+\((.+?):(\d+):(\d+)\)$');

const _frameworkPrefixes = [
  'package:shelf',
  'package:shelf_router',
  'package:rewo/',
  'dart:async',
  'dart:core',
  'dart:io',
];

ErrorSource? _findSourceFrame(String stackTrace) {
  for (final line in stackTrace.split('\n')) {
    final match = _framePattern.firstMatch(line.trim());
    if (match == null) continue;

    final location = match.group(3)!;
    if (_isFrameworkLocation(location)) continue;

    return ErrorSource(
      file: _displayPath(location),
      line: int.parse(match.group(4)!),
      column: int.parse(match.group(5)!),
      symbol: match.group(2)!.trim(),
    );
  }
  return null;
}

bool _isFrameworkLocation(String location) {
  for (final prefix in _frameworkPrefixes) {
    if (location.startsWith(prefix)) return true;
  }
  return location.contains('/middleware/');
}

String _displayPath(String location) {
  if (!location.startsWith('package:')) return location;

  final withoutScheme = location.substring('package:'.length);
  final separator = withoutScheme.indexOf('/');
  if (separator <= 0) return location;

  final path = withoutScheme.substring(separator + 1);
  return 'lib/$path';
}

String _messageFor(Object error) {
  if (error is TypeError) {
    return error.toString();
  }
  if (error is FormatException) {
    return error.message;
  }
  return error.toString();
}

String? _hintFor(Object error) {
  final message = error.toString();

  if (message.contains('Null check operator used on a null value')) {
    return 'A value was null but the code used !. Check route params, '
        'request body fields, or lookups before forcing non-null.';
  }

  if (error is StateError && message.contains('No element')) {
    return 'No matching item was found (for example firstWhere with no match).';
  }

  if (error is FormatException) {
    return 'Input could not be parsed. Check the value format before calling '
        'int.parse, DateTime.parse, or similar.';
  }

  if (error is ArgumentError) {
    return error.message?.toString();
  }

  return null;
}
