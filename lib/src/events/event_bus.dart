/// Simple in-process event bus.
class EventBus {
  final Map<Type, List<void Function(dynamic)>> _listeners = {};

  void on<T>(void Function(T event) listener) {
    _listeners.putIfAbsent(T, () => []).add((event) => listener(event as T));
  }

  void emit<T>(T event) {
    final listeners = _listeners[T];
    if (listeners == null) return;
    for (final listener in listeners) {
      listener(event);
    }
  }

  void clear() => _listeners.clear();
}
