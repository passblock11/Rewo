import 'dart:async';
import 'dart:isolate';

/// Offloads CPU-bound work to a background isolate so the HTTP event loop stays fast.
///
/// ```dart
/// final hash = await compute(hashPassword, password);
/// ```
Future<R> compute<M, R>(R Function(M message) callback, M message) {
  return Isolate.run(() => callback(message));
}

/// Runs a zero-arg computation in an isolate.
Future<R> runInIsolate<R>(R Function() computation) {
  return Isolate.run(computation);
}
